// Gera uma imagem PNG do mapa (altura + material) para inspecionar o layout do mundo.
//   node sim/heightmap.mjs [saida.png]
import { createSim } from "./sim.mjs";
import { writeFileSync } from "node:fs";
import zlib from "node:zlib";

const out = process.argv[2] || "heightmap.png";
const lua = await createSim();

const STEP = 8; // studs por pixel
const res = lua.execute(`
	local WG = require({ Name = "WorldGen" })
	local Config = require({ Name = "Config" })
	local half = Config.World.Half
	local step = ${STEP}
	local n = (2 * half) // step
	local hs, ms = {}, {}
	local t0 = os.clock()
	for j = 0, n - 1 do
		local z = -half + (j + 0.5) * step
		for i = 0, n - 1 do
			local x = -half + (i + 0.5) * step
			local mat, h = WG.materialAt(x, z)
			hs[#hs + 1] = h
			ms[#ms + 1] = mat.Name
		end
	end
	return n, table.concat(ms, ","), table.concat(hs, ","), os.clock() - t0
`);
const [n, matStr, hStr, secs] = res;
const mats = matStr.split(",");
const hs = hStr.split(",").map(Number);
console.log(`grade ${n}x${n}, ${secs.toFixed(2)}s (Luau WASM)`);
let min = Infinity,
  max = -Infinity,
  land = 0;
for (const h of hs) {
  if (h < min) min = h;
  if (h > max) max = h;
  if (h > 0) land++;
}
console.log(`altura: min ${min.toFixed(1)} max ${max.toFixed(1)}  terra firme: ${((land / hs.length) * 100).toFixed(1)}%`);

const COLORS = {
  Grass: [104, 212, 72], LeafyGrass: [70, 186, 88], Ground: [156, 108, 72], Mud: [122, 88, 62],
  Sand: [250, 226, 156], Sandstone: [232, 176, 110], Rock: [128, 122, 140], Slate: [88, 96, 118],
  Basalt: [66, 58, 76], CrackedLava: [255, 106, 24], Snow: [244, 250, 255], Glacier: [178, 226, 250],
  Ice: [168, 226, 255], Cobblestone: [176, 168, 190], Pavement: [190, 190, 200],
};
const SCALE = Number(process.env.SCALE || 3);
const W = n * SCALE, H = n * SCALE;
const raw = Buffer.alloc((W * 3 + 1) * H);
for (let j = 0; j < H; j++) {
  raw[j * (W * 3 + 1)] = 0;
  for (let i = 0; i < W; i++) {
    const idx = Math.floor(j / SCALE) * n + Math.floor(i / SCALE);
    const h = hs[idx];
    let c = COLORS[mats[idx]] || [255, 0, 255];
    // agua
    if (h < 0) {
      const d = Math.max(0, Math.min(1, (h + 40) / 40));
      c = [30 + 40 * d, 120 + 70 * d, 190 + 40 * d];
    }
    // sombreamento simples (luz vindo do noroeste)
    const ci = Math.floor(i / SCALE), cj = Math.floor(j / SCALE);
    const hx = hs[idx + (ci + 1 < n ? 1 : 0)] - hs[idx - (ci > 0 ? 1 : 0)];
    const hz = hs[idx + (cj + 1 < n ? n : 0)] - hs[idx - (cj > 0 ? n : 0)];
    const shade = Math.max(0.55, Math.min(1.35, 1 - (hx + hz) * 0.012));
    const o = j * (W * 3 + 1) + 1 + i * 3;
    raw[o] = Math.min(255, c[0] * shade);
    raw[o + 1] = Math.min(255, c[1] * shade);
    raw[o + 2] = Math.min(255, c[2] * shade);
  }
}
function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(zlib.crc32(td) >>> 0);
  return Buffer.concat([len, td, crc]);
}
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(W, 0);
ihdr.writeUInt32BE(H, 4);
ihdr[8] = 8; ihdr[9] = 2; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
const png = Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  chunk("IHDR", ihdr),
  chunk("IDAT", zlib.deflateSync(raw)),
  chunk("IEND", Buffer.alloc(0)),
]);
writeFileSync(out, png);
console.log("salvo em", out);
