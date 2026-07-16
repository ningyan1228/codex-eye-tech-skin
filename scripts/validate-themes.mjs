import { readFile } from "node:fs/promises";
import { basename, join } from "node:path";

const themeFiles = ["aurora-calm-dark", "aurora-calm-light"];
const hexColor = /^#[0-9a-f]{6}$/i;
const supportedCodeThemes = new Set([
  "codex",
]);

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function validateTheme(theme, file) {
  const label = basename(file);
  assert(["dark", "light"].includes(theme.variant), `${label}: invalid variant`);
  assert(supportedCodeThemes.has(theme.codeThemeId), `${label}: unsupported code theme`);
  assert(Number.isInteger(theme.theme.contrast) && theme.theme.contrast >= 0 && theme.theme.contrast <= 100, `${label}: contrast must be an integer from 0 to 100`);
  assert(typeof theme.theme.opaqueWindows === "boolean", `${label}: opaqueWindows must be boolean`);
  assert(typeof theme.theme.fonts?.code === "string" && typeof theme.theme.fonts?.ui === "string", `${label}: fonts must be strings`);

  for (const key of ["accent", "ink", "surface"]) {
    assert(hexColor.test(theme.theme[key]), `${label}: ${key} is not a six-digit hex color`);
  }
  for (const key of ["diffAdded", "diffRemoved", "skill"]) {
    assert(hexColor.test(theme.theme.semanticColors?.[key]), `${label}: semanticColors.${key} is not a six-digit hex color`);
  }
}

for (const stem of themeFiles) {
  const jsonPath = join("themes", `${stem}.json`);
  const textPath = join("themes", `${stem}.txt`);
  const source = JSON.parse(await readFile(jsonPath, "utf8"));
  const imported = (await readFile(textPath, "utf8")).trim();

  validateTheme(source, jsonPath);
  assert(imported.startsWith("codex-theme-v1:"), `${textPath}: missing Codex theme prefix`);
  const encodedTheme = JSON.parse(imported.slice("codex-theme-v1:".length));
  validateTheme(encodedTheme, textPath);
  assert(JSON.stringify(source) === JSON.stringify(encodedTheme), `${textPath}: does not match ${jsonPath}`);
  console.log(`OK  ${stem} (${source.variant})`);
}
