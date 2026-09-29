// Verifica se os nomes de metodos/propriedades usados (":Metodo(" e ".Propriedade") existem na API
// do Roblox (definicoes completas do luau-lsp) OU sao definidos no proprio projeto.
// Pega erros de digitacao e "APIs inventadas" que o analisador nao ve.
//   node api-check.mjs
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, relative, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const srcDir = join(here, "..", "src");
const defsPath = join(here, ".cache", "globalTypes.d.luau");
if (!existsSync(defsPath)) {
  console.error("Rode 'node check.mjs' antes (baixa as definicoes).");
  process.exit(2);
}
const api = readFileSync(defsPath, "utf8");
const apiWords = new Set(api.match(/[A-Za-z_][A-Za-z0-9_]*/g));

function walk(dir) {
  const out = [];
  for (const f of readdirSync(dir)) {
    const p = join(dir, f);
    if (statSync(p).isDirectory()) out.push(...walk(p));
    else if (/\.luau$/.test(f)) out.push(p);
  }
  return out;
}
const files = walk(srcDir).map((p) => ({ p, text: readFileSync(p, "utf8") }));

// nomes definidos no projeto
const mine = new Set();
for (const { text } of files) {
  for (const m of text.matchAll(/\b([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)/g)) mine.add(m[1]);
  for (const m of text.matchAll(/function\s+[\w.:]*?[.:]?([A-Za-z_][A-Za-z0-9_]*)\s*\(/g)) mine.add(m[1]);
  for (const m of text.matchAll(/\blocal\s+(?:function\s+)?([A-Za-z_][A-Za-z0-9_]*)/g)) mine.add(m[1]);
  for (const m of text.matchAll(/\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*=/g)) mine.add(m[1]);
  for (const m of text.matchAll(/,\s*([A-Za-z_][A-Za-z0-9_]*)\s*=/g)) mine.add(m[1]);
  for (const m of text.matchAll(/\b([A-Za-z_][A-Za-z0-9_]*)\s*:\s*[A-Za-z{(]/g)) mine.add(m[1]); // tipos/params
}
// nomes de campos de tabelas literais multi-linha: "\tNome = ..." ja coberto por "=".

const builtin = new Set(
  "abs acos asin atan atan2 ceil clamp cos cosh deg exp floor fmod frexp huge ldexp log log10 max min modf noise pi pow rad random randomseed round sign sin sinh sqrt tan tanh char byte format find gmatch gsub len lower match rep reverse sub upper insert remove sort concat unpack pack move create find freeze isfrozen clone clear getn clock date time difftime band bor bxor bnot lshift rshift arshift rrotate lrotate extract replace countlz countrz btest yield running status wrap resume isyieldable close traceback info trace new".split(" "),
);

const unknown = new Map();
for (const { p, text } of files) {
  const stripped = text.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--.*$/gm, "").replace(/"(?:[^"\\]|\\.)*"/g, '""').replace(/'(?:[^'\\]|\\.)*'/g, "''");
  const lines = stripped.split("\n");
  lines.forEach((line, i) => {
    for (const m of line.matchAll(/[:.]([A-Za-z_][A-Za-z0-9_]*)/g)) {
      const name = m[1];
      if (builtin.has(name) || apiWords.has(name) || mine.has(name)) continue;
      const key = name;
      if (!unknown.has(key)) unknown.set(key, []);
      unknown.get(key).push(`${relative(srcDir, p)}:${i + 1}`);
    }
  });
}

if (unknown.size === 0) {
  console.log("OK: todos os nomes usados existem na API do Roblox ou no projeto.");
} else {
  console.log(`Nomes desconhecidos (${unknown.size}) — confira se sao erros de digitacao:`);
  for (const [name, locs] of [...unknown.entries()].sort()) {
    console.log(`  ${name}   ${locs.slice(0, 3).join(", ")}${locs.length > 3 ? " ..." : ""}`);
  }
}
