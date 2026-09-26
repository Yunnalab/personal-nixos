// pi 的渲染器补丁 —— 由 pi-material-black-simple v0.2.2 的
// extensions/material-black-simple/patch.ts 转写而来。
//
// 转写内容仅三处：去掉 TS 类型注解、把 CONFIG_DIR 固定为 ".pi"、
// 把「探测运行中的 pi」换成显式传入包根目录（构建期没有正在运行的 pi）。
// 所有字符串锚点、注入片段均与上游逐字相同；改上游时请同步改这里。
//
// 为什么需要它：Nix store 只读，扩展在运行时无法写 pi 的 dist（EROFS），
// 所以在 Nix 构建期就把补丁打进去。扩展启动后检测到 "already" 便不再写盘。
//
// 用法：node patch-pi.mjs <pi-package-root> [--strict]
//   幂等；锚点缺失时打印告警并以 0 退出（--strict 时退出码 1），
//   以免上游改动把整个系统 rebuild 卡死。
//   MBS_BACKUP_SUFFIX="" 可关闭 .orig 备份（构建期不需要）。
import { copyFileSync, existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const CONFIG_DIR = ".pi";
const THEME_NAME = "material_black_simple";
const BACKUP_SUFFIX = process.env.MBS_BACKUP_SUFFIX ?? ".orig";

const REL = "dist/modes/interactive/components/assistant-message.js";
const REL_USER = "dist/modes/interactive/components/user-message.js";

const FLAG_ANCHOR = "        const hasVisibleContent = message.content.some(";
const MD_ANCHOR = `                this.contentContainer.addChild(new Markdown(content.text.trim(), this.outputPad, 0, this.markdownTheme, undefined, {
                    transform: createMarkdownTransform("assistant", this.isStreaming, this.markdownTransformers),
                }));`;

/**
 * Only a *finalized* message with no tool call is a final answer.
 *
 * `stopReason` is unreliable as a "is it done" signal: providers can populate it
 * on a message that is still streaming, which made intermediate text briefly
 * flash with the final-answer background. Upstream's own `isStreaming` flag is
 * the honest signal - it is true between message_start and message_end and
 * false for history/replay renders.
 */
const FLAG_INJECT =
  '        const isIntermediate = this.isStreaming || message.stopReason === "aborted" || message.stopReason === "error" || message.content.some((c) => c.type === "toolCall");\n';

// Runtime helpers injected into the component module. The patched code runs
// inside pi's own bundle and cannot import from this extension, so the config
// is read from disk (cached for 1s to avoid per-render file reads).
const HELPER_ANCHOR = "export class AssistantMessageComponent extends Container {";
const HELPERS = `import { createRequire as __mbsCreateRequire } from "node:module";
const __mbsRequire = __mbsCreateRequire(import.meta.url);
const __mbsConfigPath = __mbsRequire("node:path").join(__mbsRequire("node:os").homedir(), ${JSON.stringify(CONFIG_DIR)}, "material-black-simple.json");
let __mbsCache = { at: 0, value: { overlay: false } };
function __mbsConfig() {
    const now = Date.now();
    if (now - __mbsCache.at < 1000) return __mbsCache.value;
    let value = { overlay: false };
    try {
        value = { overlay: false, ...JSON.parse(__mbsRequire("node:fs").readFileSync(__mbsConfigPath, "utf8")) };
    }
    catch { }
    __mbsCache = { at: now, value };
    return value;
}
/** Styling applies to material_black_simple, or to any theme when overlay is on. */
function __mbsActive() {
    const cfg = __mbsConfig();
    return cfg.overlay || theme.name === "${THEME_NAME}";
}
function __mbsHex(hex) {
    const n = parseInt(hex.slice(1), 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}
function __mbsFg(override, fallbackKey) {
    if (override)
        return (text) => \`\\x1b[38;2;\${__mbsHex(override).join(";")}m\${text}\\x1b[39m\`;
    return (text) => theme.fg(fallbackKey, text);
}
function __mbsBg(override, fallbackKey) {
    if (override)
        return (text) => \`\\x1b[48;2;\${__mbsHex(override).join(";")}m\${text}\\x1b[49m\`;
    return fallbackKey ? (text) => theme.bg(fallbackKey, text) : undefined;
}
`;

const HELPER_INJECT = `${HELPERS}${HELPER_ANCHOR}`;

// user-message.js: same helpers, plus overrides for the user bubble.
const USER_ANCHOR = "export class UserMessageComponent extends Container {";
const USER_HELPER_INJECT = `${HELPERS}${USER_ANCHOR}`;
const USER_BOX_ANCHOR = `        const contentBox = new Box(this.outputPad, 1, (content) => theme.bg("userMessageBg", content));
        contentBox.addChild(new Markdown(this.text, 0, 0, this.markdownTheme, {
            color: (content) => theme.fg("userMessageText", content),
        }, {`;
const USER_BOX_INJECT = `        const __mbsCfg = __mbsConfig();
        const __mbsOn = __mbsActive();
        const contentBox = new Box(this.outputPad, 1, __mbsOn && __mbsCfg.inputBg
            ? __mbsBg(__mbsCfg.inputBg, "userMessageBg")
            : (content) => theme.bg("userMessageBg", content));
        contentBox.addChild(new Markdown(this.text, 0, 0, this.markdownTheme, {
            color: __mbsOn && __mbsCfg.inputFontColor
                ? __mbsFg(__mbsCfg.inputFontColor, "userMessageText")
                : (content) => theme.fg("userMessageText", content),
        }, {`;

const MD_REPLACEMENT = `                const __mbsCfg = __mbsConfig();
                this.contentContainer.addChild(new Markdown(content.text.trim(), this.outputPad, 0, this.markdownTheme, !__mbsActive()
                    ? undefined
                    : isIntermediate
                        ? {
                            color: __mbsFg(__mbsCfg.intermediateFontColor, "muted"),
                            bgColor: __mbsBg(__mbsCfg.intermediateBg, undefined),
                        }
                        : {
                            color: __mbsFg(__mbsCfg.finalFontColor, "text"),
                            bgColor: __mbsBg(__mbsCfg.finalOutputBg, "selectedBg"),
                        }, {
                    transform: createMarkdownTransform("assistant", this.isStreaming, this.markdownTransformers),
                }));`;


const BUNDLE_MD_ANCHOR = 'new Markdown(content.text.trim(),this.outputPad,0,this.markdownTheme,void 0,{transform:createMarkdownTransform("assistant",this.isStreaming,this.markdownTransformers)})';
const BUNDLE_USER_BG_ANCHOR = 'new Box(this.outputPad,1,content=>theme.bg("userMessageBg",content))';
const BUNDLE_USER_FG_ANCHOR = 'new Markdown(this.text,0,0,this.markdownTheme,{color:content=>theme.fg("userMessageText",content)}';
const BUNDLE_HELPERS = `${HELPERS}
function __mbsAssistantStyle(message, isStreaming) {
    if (!__mbsActive()) return undefined;
    const cfg = __mbsConfig();
    const isIntermediate = isStreaming || message.stopReason === "aborted" || message.stopReason === "error" || message.content.some((c) => c.type === "toolCall");
    return isIntermediate
        ? { color: __mbsFg(cfg.intermediateFontColor, "muted"), bgColor: __mbsBg(cfg.intermediateBg, undefined) }
        : { color: __mbsFg(cfg.finalFontColor, "text"), bgColor: __mbsBg(cfg.finalOutputBg, "selectedBg") };
}
`;


export function patchBundle(file) {
  try {
    const src = readFileSync(file, "utf8");
    if (src.includes("function __mbsAssistantStyle(")) return { status: "already", file };
    for (const anchor of [BUNDLE_MD_ANCHOR, BUNDLE_USER_BG_ANCHOR, BUNDLE_USER_FG_ANCHOR]) {
      if (src.split(anchor).length !== 2) {
        return { status: "failed", file, reason: "expected one renderer anchor in runtime bundle (upstream changed)" };
      }
    }
    const next = BUNDLE_HELPERS + src
      .replace(BUNDLE_MD_ANCHOR, BUNDLE_MD_ANCHOR.replace("this.markdownTheme,void 0,", "this.markdownTheme,__mbsAssistantStyle(message,this.isStreaming),"))
      .replace(BUNDLE_USER_BG_ANCHOR, 'new Box(this.outputPad,1,__mbsActive()?__mbsBg(__mbsConfig().inputBg,"userMessageBg"):content=>theme.bg("userMessageBg",content))')
      .replace(BUNDLE_USER_FG_ANCHOR, 'new Markdown(this.text,0,0,this.markdownTheme,{color:__mbsActive()?__mbsFg(__mbsConfig().inputFontColor,"userMessageText"):content=>theme.fg("userMessageText",content)}');
    if (BACKUP_SUFFIX && !existsSync(`${file}${BACKUP_SUFFIX}`)) copyFileSync(file, `${file}${BACKUP_SUFFIX}`);
    writeFileSync(file, next);
    return { status: "patched", file };
  } catch (error) {
    return { status: "failed", file, reason: error instanceof Error ? error.message : String(error) };
  }
}

export function patchFile(file) {
  let src;
  try {
    src = readFileSync(file, "utf8");
  } catch (e) {
    return { status: "failed", file, reason: `unreadable: ${(e).message}` };
  }

  if (src.includes("isIntermediate")) return { status: "already", file };

  for (const [name, anchor] of [
    ["class header", HELPER_ANCHOR],
    ["hasVisibleContent", FLAG_ANCHOR],
    ["Markdown call", MD_ANCHOR],
  ]) {
    const n = src.split(anchor).length - 1;
    if (n !== 1) {
      return { status: "failed", file, reason: `expected 1 "${name}" anchor, found ${n} (upstream changed)` };
    }
  }

  const next = src
    .replace(HELPER_ANCHOR, HELPER_INJECT)
    .replace(FLAG_ANCHOR, FLAG_INJECT + FLAG_ANCHOR)
    .replace(MD_ANCHOR, MD_REPLACEMENT);

  try {
    if (BACKUP_SUFFIX && !existsSync(`${file}${BACKUP_SUFFIX}`)) copyFileSync(file, `${file}${BACKUP_SUFFIX}`);
    writeFileSync(file, next);
  } catch (e) {
    return { status: "failed", file, reason: `not writable: ${(e).message}` };
  }

  return { status: "patched", file };
}

/** Patch user-message.js so input bg/font overrides apply. */
function patchUser(file) {
  let src;
  try {
    src = readFileSync(file, "utf8");
  } catch (e) {
    return { status: "failed", file, reason: `unreadable: ${(e).message}` };
  }

  if (src.includes("__mbsConfig")) return { status: "already", file };

  for (const [name, anchor] of [
    ["class header", USER_ANCHOR],
    ["content box", USER_BOX_ANCHOR],
  ]) {
    const n = src.split(anchor).length - 1;
    if (n !== 1) {
      return { status: "failed", file, reason: `expected 1 "${name}" anchor, found ${n} (upstream changed)` };
    }
  }

  const next = src.replace(USER_ANCHOR, USER_HELPER_INJECT).replace(USER_BOX_ANCHOR, USER_BOX_INJECT);

  try {
    if (BACKUP_SUFFIX && !existsSync(`${file}${BACKUP_SUFFIX}`)) copyFileSync(file, `${file}${BACKUP_SUFFIX}`);
    writeFileSync(file, next);
  } catch (e) {
    return { status: "failed", file, reason: `not writable: ${(e).message}` };
  }

  return { status: "patched", file };
}


/** 某个 pi 包根目录下需要打的全部目标文件。 */
function targetsFor(root) {
  const chunks = join(root, "dist/bundle/chunks");
  const bundled = existsSync(chunks)
    ? readdirSync(chunks).filter((name) => name.endsWith(".js"))
      .map((name) => join(chunks, name))
      .filter((file) => readFileSync(file, "utf8").includes("AssistantMessageComponent=class extends Container{"))
    : [];
  return { standalone: join(root, REL), user: join(root, REL_USER), bundled };
}

const root = process.argv[2];
const strict = process.argv.includes("--strict");
if (!root) {
  console.error("用法：node patch-pi.mjs <pi-package-root> [--strict]");
  process.exit(2);
}
if (!existsSync(join(root, REL))) {
  console.error(`patch-pi: ${root} 不是 pi 包根目录（缺少 ${REL}）`);
  process.exit(2);
}

const { standalone, user, bundled } = targetsFor(root);
if (bundled.length === 0) {
  console.log("patch-pi: 警告：未找到运行期 bundle chunk（上游布局可能已变）");
}
const results = [patchFile(standalone), patchUser(user), ...bundled.map(patchBundle)];
let unpatched = 0;
for (const r of results) {
  const state = r.status === "patched" ? "已打补丁" : r.status === "already" ? "本来就是补丁状态" : "未能打补丁";
  console.log(`patch-pi: ${state}：${r.file}${r.reason ? `（${r.reason}）` : ""}`);
  if (r.status === "failed") unpatched++;
}
if (unpatched > 0) {
  console.log(`patch-pi: 警告：${unpatched} 个文件因上游改动未打补丁，material-black-simple 的最终回答底色会失效`);
  console.log("patch-pi: 请对照上游 dist 更新 patch-pi.mjs 里的锚点");
}
process.exit(unpatched > 0 && strict ? 1 : 0);
