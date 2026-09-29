// Carrega o mock do Roblox + os modulos reais de src/ num runtime Luau (WASM) para
// executar logica pura fora do Studio.
import { Lua } from "@luau-rs/luau";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, dirname, basename } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const srcDir = join(here, "..", "..", "src");

function walk(dir) {
  const out = [];
  for (const f of readdirSync(dir)) {
    const p = join(dir, f);
    if (statSync(p).isDirectory()) out.push(...walk(p));
    else if (/\.luau$/.test(f)) out.push(p);
  }
  return out;
}

export async function createSim() {
  const lua = await Lua.create({ sandbox: false });
  lua.execute(readFileSync(join(here, "mock.luau"), "utf8"));
  const seen = new Map();
  for (const f of walk(srcDir)) {
    let name = basename(f).replace(/\.luau$/, "");
    name = name.replace(/\.(server|client)$/, "");
    if (name === "init") name = basename(dirname(f));
    if (seen.has(name)) {
      throw new Error(`Nome de modulo duplicado "${name}": ${seen.get(name)} e ${f}. Renomeie um deles.`);
    }
    seen.set(name, f);
    const src = readFileSync(f, "utf8");
    // cabecalho na mesma linha do codigo para os numeros de linha baterem com o arquivo
    lua.execute(`__define(${JSON.stringify(name)}, function(script) ${src}\nend)`, { name: "=" + f.slice(srcDir.length + 1) });
  }
  return lua;
}
