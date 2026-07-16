import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");

function parseArgs(argv) {
  const options = { port: 9336, mode: "watch", timeoutMs: 30000, screenshot: null };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--port") options.port = Number(argv[++index]);
    else if (arg === "--once") options.mode = "once";
    else if (arg === "--watch") options.mode = "watch";
    else if (arg === "--verify") options.mode = "verify";
    else if (arg === "--remove") options.mode = "remove";
    else if (arg === "--timeout-ms") options.timeoutMs = Number(argv[++index]);
    else if (arg === "--screenshot") options.screenshot = path.resolve(argv[++index]);
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!Number.isInteger(options.port) || options.port < 1024 || options.port > 65535) throw new Error(`Invalid port: ${options.port}`);
  return options;
}

class CdpSession {
  constructor(target) {
    this.socket = new WebSocket(target.webSocketDebuggerUrl);
    this.nextId = 1;
    this.pending = new Map();
    this.listeners = new Map();
    this.closed = false;
  }

  async open() {
    await new Promise((resolve, reject) => {
      this.socket.addEventListener("open", resolve, { once: true });
      this.socket.addEventListener("error", reject, { once: true });
    });
    this.socket.addEventListener("message", (event) => this.onMessage(event));
    this.socket.addEventListener("close", () => this.close());
    await this.send("Runtime.enable");
    await this.send("Page.enable");
    return this;
  }

  onMessage(event) {
    const message = JSON.parse(String(event.data));
    if (!message.id) {
      for (const listener of this.listeners.get(message.method) ?? []) listener(message.params ?? {});
      return;
    }
    const waiter = this.pending.get(message.id);
    if (!waiter) return;
    this.pending.delete(message.id);
    if (message.error) waiter.reject(new Error(`${message.error.message} (${message.error.code})`));
    else waiter.resolve(message.result);
  }

  on(method, listener) {
    this.listeners.set(method, [...(this.listeners.get(method) ?? []), listener]);
  }

  send(method, params = {}) {
    if (this.closed) return Promise.reject(new Error("CDP socket closed"));
    return new Promise((resolve, reject) => {
      const id = this.nextId++;
      this.pending.set(id, { resolve, reject });
      this.socket.send(JSON.stringify({ id, method, params }));
    });
  }

  async evaluate(expression) {
    const result = await this.send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true });
    if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description ?? result.exceptionDetails.text);
    return result.result?.value;
  }

  close() {
    if (this.closed) return;
    this.closed = true;
    try { this.socket.close(); } catch {}
    for (const waiter of this.pending.values()) waiter.reject(new Error("CDP socket closed"));
    this.pending.clear();
  }
}

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function waitForTargets(port, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  let lastError;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(`http://127.0.0.1:${port}/json/list`);
      const targets = await response.json();
      const pages = targets.filter((target) => target.type === "page" && target.url.startsWith("app://"));
      if (pages.length) return pages;
    } catch (error) { lastError = error; }
    await delay(350);
  }
  throw new Error(`No Codex renderer target on loopback port ${port}: ${lastError?.message ?? "timed out"}`);
}

function mimeType(file) {
  return ({ ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp" })[path.extname(file).toLowerCase()] ?? "image/png";
}

async function loadPayload() {
  const [css, template, backgroundConfig] = await Promise.all([
    fs.readFile(path.join(root, "assets", "cyber-skin.css"), "utf8"),
    fs.readFile(path.join(root, "assets", "renderer-inject.js"), "utf8"),
    fs.readFile(path.join(root, "assets", "background.json"), "utf8"),
  ]);
  const settings = JSON.parse(backgroundConfig);
  const imagePath = path.join(root, "assets", settings.file);
  const image = await fs.readFile(imagePath);
  const dataUrl = `data:${mimeType(imagePath)};base64,${image.toString("base64")}`;
  return template
    .replace("__CYBER_CSS_JSON__", JSON.stringify(css))
    .replace("__CYBER_ART_JSON__", JSON.stringify(dataUrl))
    .replace("__CYBER_LABEL_JSON__", JSON.stringify(settings.label ?? "Custom background"));
}

async function verify(session) {
  return session.evaluate(`(() => {
    const box = (selector) => { const node = document.querySelector(selector); if (!node) return null; const r = node.getBoundingClientRect(); return { width: Math.round(r.width), height: Math.round(r.height) }; };
    const chrome = document.getElementById('codex-cyber-skin-chrome');
    const result = {
      installed: document.documentElement.classList.contains('codex-cyber-skin'),
      stylePresent: Boolean(document.getElementById('codex-cyber-skin-style')),
      chromePresent: Boolean(chrome),
      chromePointerEvents: getComputedStyle(chrome || document.body).pointerEvents,
      sidebar: box('aside.app-shell-left-panel'),
      composer: box('.composer-surface-chrome')
    };
    result.pass = result.installed && result.stylePresent && result.chromePresent && result.chromePointerEvents === 'none' && Boolean(result.sidebar) && Boolean(result.composer);
    return result;
  })()`);
}

async function remove(session) {
  return session.evaluate(`(() => { window.__CODEX_CYBER_SKIN_DISABLED__ = true; return window.__CODEX_CYBER_SKIN_STATE__?.cleanup?.() ?? true; })()`);
}

async function capture(session, output) {
  await fs.mkdir(path.dirname(output), { recursive: true });
  const image = await session.send("Page.captureScreenshot", { format: "png", fromSurface: true, captureBeyondViewport: false });
  await fs.writeFile(output, Buffer.from(image.data, "base64"));
}

async function runOnce(options) {
  const targets = await waitForTargets(options.port, options.timeoutMs);
  const payload = options.mode === "remove" ? null : await loadPayload();
  const output = [];
  for (const target of targets) {
    const session = await new CdpSession(target).open();
    try {
      if (options.mode === "remove") await remove(session);
      else { await session.evaluate(payload); await delay(700); }
      const result = options.mode === "remove" ? await session.evaluate("!document.documentElement.classList.contains('codex-cyber-skin')") : await verify(session);
      if (options.screenshot) await capture(session, options.screenshot);
      output.push({ title: target.title, result });
    } finally { session.close(); }
  }
  console.log(JSON.stringify({ mode: options.mode, port: options.port, targets: output }, null, 2));
  if (options.mode === "verify" && output.some((item) => !item.result.pass)) process.exitCode = 2;
}

async function runWatch(options) {
  const payload = await loadPayload();
  const sessions = new Map();
  let stopping = false;
  process.on("SIGINT", () => { stopping = true; });
  process.on("SIGTERM", () => { stopping = true; });
  while (!stopping) {
    let targets = [];
    try { targets = await waitForTargets(options.port, 2000); } catch { await delay(900); continue; }
    const ids = new Set(targets.map((target) => target.id));
    for (const [id, session] of sessions) if (!ids.has(id) || session.closed) { session.close(); sessions.delete(id); }
    for (const target of targets) {
      if (sessions.has(target.id)) continue;
      try {
        const session = await new CdpSession(target).open();
        session.on("Page.loadEventFired", () => setTimeout(() => session.evaluate(payload).catch(() => {}), 250));
        await session.evaluate(payload);
        sessions.set(target.id, session);
        console.log(`[cyber-skin] injected ${target.title || target.url}`);
      } catch (error) { console.error(`[cyber-skin] ${error.message}`); }
    }
    await delay(900);
  }
  for (const session of sessions.values()) session.close();
}

const options = parseArgs(process.argv.slice(2));
if (options.mode === "watch") await runWatch(options);
else await runOnce(options);
