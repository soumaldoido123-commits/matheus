// Confere se todo "Enum.Tipo.Valor" usado no codigo existe de verdade na API do Roblox.
//   node enum-check.mjs
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
const defs = readFileSync(defsPath, "utf8");

// EnumX_INTERNAL: "declare extern type EnumMaterial_INTERNAL extends Enum with\n\tAir: EnumMaterial\n..."
const enums = new Map();
const re = /declare extern type Enum(\w+)_INTERNAL extends Enum with\n([\s\S]*?)\nend/g;
for (const m of defs.matchAll(re)) {
  const members = new Set([...m[2].matchAll(/^\s*([A-Za-z_0-9]+)\s*:/gm)].map((x) => x[1]));
  enums.set(m[1], members);
}

function walk(dir) {
  const out = [];
  for (const f of readdirSync(dir)) {
    const p = join(dir, f);
    if (statSync(p).isDirectory()) out.push(...walk(p));
    else if (/\.luau$/.test(f)) out.push(p);
  }
  return out;
}

let bad = 0;
let total = 0;
for (const p of walk(srcDir)) {
  const text = readFileSync(p, "utf8");
  text.split("\n").forEach((line, i) => {
    for (const m of line.matchAll(/\bEnum\.([A-Za-z]+)\.([A-Za-z_0-9]+)/g)) {
      total++;
      const [_, type, value] = m;
      const members = enums.get(type);
      if (!members) {
        console.log(`${relative(srcDir, p)}:${i + 1}  Enum.${type} nao existe`);
        bad++;
      } else if (!members.has(value)) {
        console.log(`${relative(srcDir, p)}:${i + 1}  Enum.${type}.${value} nao existe`);
        bad++;
      }
    }
  });
}
console.log(bad === 0 ? `OK: ${total} usos de Enum conferidos (${enums.size} enums conhecidos).` : `${bad} problema(s) em ${total} usos.`);
process.exit(bad ? 1 : 0);
