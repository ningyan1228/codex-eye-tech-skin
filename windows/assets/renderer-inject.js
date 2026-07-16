((cssText, artDataUrl, label) => {
  const stateKey = "__CODEX_CYBER_SKIN_STATE__";
  const styleId = "codex-cyber-skin-style";
  const chromeId = "codex-cyber-skin-chrome";
  const previous = window[stateKey];

  previous?.observer?.disconnect();
  if (previous?.timer) clearInterval(previous.timer);
  if (previous?.scheduler?.timeout) clearTimeout(previous.scheduler.timeout);
  if (previous?.artUrl) URL.revokeObjectURL(previous.artUrl);
  window.__CODEX_CYBER_SKIN_DISABLED__ = false;

  const comma = artDataUrl.indexOf(",");
  const bytes = Uint8Array.from(atob(artDataUrl.slice(comma + 1)), (char) => char.charCodeAt(0));
  const mime = artDataUrl.slice(5, comma).split(";")[0] || "image/png";
  const artUrl = URL.createObjectURL(new Blob([bytes], { type: mime }));

  const ensure = () => {
    if (window.__CODEX_CYBER_SKIN_DISABLED__) return;
    const root = document.documentElement;
    if (!root || !document.body) return;
    root.classList.add("codex-cyber-skin");
    root.style.setProperty("--cyber-art", `url("${artUrl}")`);

    let style = document.getElementById(styleId);
    if (!style) {
      style = document.createElement("style");
      style.id = styleId;
      (document.head || root).appendChild(style);
    }
    if (style.textContent !== cssText) style.textContent = cssText;

    const shell = document.querySelector("main.main-surface") || document.querySelector("main");
    let chrome = document.getElementById(chromeId);
    if (!chrome) {
      chrome = document.createElement("div");
      chrome.id = chromeId;
      chrome.setAttribute("aria-hidden", "true");
      chrome.innerHTML = '<div class="cyber-scanline"></div><div class="cyber-brand"></div><div class="cyber-corner"></div>';
      document.body.appendChild(chrome);
    }
    chrome.querySelector(".cyber-brand")?.remove();
    if (shell) {
      const box = shell.getBoundingClientRect();
      chrome.style.left = `${Math.round(box.left)}px`;
      chrome.style.top = `${Math.round(box.top)}px`;
      chrome.style.width = `${Math.round(box.width)}px`;
      chrome.style.height = `${Math.round(box.height)}px`;
    }
  };

  const cleanup = () => {
    window.__CODEX_CYBER_SKIN_DISABLED__ = true;
    document.documentElement?.classList.remove("codex-cyber-skin");
    document.documentElement?.style.removeProperty("--cyber-art");
    document.getElementById(styleId)?.remove();
    document.getElementById(chromeId)?.remove();
    const active = window[stateKey];
    active?.observer?.disconnect();
    if (active?.timer) clearInterval(active.timer);
    if (active?.scheduler?.timeout) clearTimeout(active.scheduler.timeout);
    if (active?.artUrl) URL.revokeObjectURL(active.artUrl);
    delete window[stateKey];
    return true;
  };

  const scheduler = { timeout: null };
  const scheduleEnsure = () => {
    if (scheduler.timeout) clearTimeout(scheduler.timeout);
    scheduler.timeout = setTimeout(() => { scheduler.timeout = null; ensure(); }, 160);
  };
  const observer = new MutationObserver(scheduleEnsure);
  observer.observe(document.documentElement, { childList: true, subtree: true });
  const timer = setInterval(ensure, 5000);
  window[stateKey] = { ensure, cleanup, observer, timer, scheduler, artUrl, version: "1.0.0" };
  ensure();
  return { installed: true, version: "1.0.0" };
})(__CYBER_CSS_JSON__, __CYBER_ART_JSON__, __CYBER_LABEL_JSON__)
