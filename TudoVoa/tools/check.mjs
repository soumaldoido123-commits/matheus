// Valida todo o codigo Luau de src/ com o analisador oficial do Luau (WASM).
//
//   npm install && node check.mjs [--quiet] [--all-strict]
//
// Passo 1 (nonstrict): erros de sintaxe, variaveis/globais indefinidas, argumentos, lints.
// Passo 2 (strict, filtrado): so "chave nao existe em tipo X" (erros de digitacao em
//   propriedades/metodos do Roblox). O resto do modo strict gera falsos positivos porque
//   o analisador nao entende GetService/Instance.new/FindFirstChild como o luau-lsp.
import { Analysis } from "@luau-rs/luau/analysis";
import { readFileSync, readdirSync, statSync, existsSync, mkdirSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { join, relative, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { makeDefs } from "./make-defs.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const srcDir = join(here, "..", "src");
const quiet = process.argv.includes("--quiet");
const allStrict = process.argv.includes("--all-strict");

function walk(dir) {
  const out = [];
  for (const f of readdirSync(dir)) {
    const p = join(dir, f);
    if (statSync(p).isDirectory()) out.push(...walk(p));
    else if (/\.(luau|lua)$/.test(f)) out.push(p);
  }
  return out;
}

// Definicoes da API do Roblox (as mesmas do luau-lsp). Baixa 1 vez e guarda em .cache/
const cacheDir = join(here, ".cache");
const defsPath = join(cacheDir, "globalTypes.d.luau");
if (!existsSync(defsPath)) {
  mkdirSync(cacheDir, { recursive: true });
  console.log("Baixando definicoes da API do Roblox (1x)...");
  execFileSync("curl", [
    "-sSfL", "-o", defsPath,
    "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau",
  ]);
}
const reducedPath = join(cacheDir, "roblox.d.luau");
makeDefs(defsPath, reducedPath); // subconjunto que o analisador em WASM aguenta
const defsSource = readFileSync(reducedPath, "utf8");

const files = walk(srcDir).map((f) => ({
  name: relative(srcDir, f).replaceAll("\\", "/"),
  path: f,
  text: readFileSync(f, "utf8"),
  script: /\.(server|client)\.luau$|init\.(server|client)/.test(f),
}));

async function run(strict) {
  const analysis = await Analysis.create({
    mode: strict ? "strict" : "nonstrict",
    lint: true,
    definitions: [{ name: "roblox.d.luau", source: defsSource }],
  });
  for (const f of files) {
    let text = f.text;
    if (strict) text = text.replace(/^--!(nonstrict|nocheck|strict)/, "--!strict");
    analysis.setModule(f.name, text, f.script ? "script" : "module");
  }
  return analysis.checkModules(files.map((f) => f.name));
}

let errors = 0;
let warnings = 0;
const fmt = (name, d) =>
  `${name}:${d.location.begin.line + 1}:${d.location.begin.column + 1}  ${d.severity.toUpperCase()}  [${d.code}]  ${d.message}`;

console.log("== Passo 1: analise normal");
for (const { name, result } of await run(false)) {
  for (const d of result.diagnostics) {
    if (d.severity === "error") errors++;
    else warnings++;
    if (quiet && d.severity !== "error") continue;
    console.log(fmt(name, d));
  }
  if (result.timeoutModules.length) console.log("TIMEOUT:", result.timeoutModules.join(","));
}

console.log("== Passo 2: digitacao de propriedades/metodos (strict filtrado)");
let typos = 0;
const IGNORED_TYPES = /external type '(Instance|Model|Folder|GuiObject|nil)'/;
for (const { name, result } of await run(true)) {
  for (const d of result.diagnostics) {
    if (d.severity !== "error") continue;
    const isKey = d.code === 1002 && /not found in external type/.test(d.message);
    if (allStrict || (isKey && !IGNORED_TYPES.test(d.message))) {
      typos++;
      console.log(fmt(name, d));
    }
  }
}
errors += typos;
console.log(`\n${files.length} arquivos: ${errors} erro(s), ${warnings} aviso(s)`);
process.exit(errors ? 1 : 0);
