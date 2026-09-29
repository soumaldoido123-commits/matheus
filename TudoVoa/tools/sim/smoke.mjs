// Teste de fumaca: carrega todos os modulos do servidor no mock, constroi todos os
// brinquedos, o mundo inteiro (sem terreno) e simula agarrar/arremessar com um jogador falso.
//   node sim/smoke.mjs
import { createSim } from "./sim.mjs";

const lua = await createSim();
const res = lua.execute(`
local results = {}
local failures = 0
local function try(name, fn)
	local ok, err = xpcall(fn, debug.traceback)
	if ok then
		table.insert(results, "OK    " .. name)
	else
		failures += 1
		table.insert(results, "FAIL  " .. name .. "\\n" .. tostring(err))
	end
end
local function R(name) return require({ Name = name }) end

try("shared: Config/Util/Toys/Abilities/Remotes", function()
	R("Config"); R("Util"); R("Toys"); R("AbilityDefs"); R("Remotes")
end)

try("Util: formatNumber/weightedPick/Spring", function()
	local Util = R("Util")
	assert(Util.formatNumber(1234567) == "1.2M", Util.formatNumber(1234567))
	assert(Util.formatNumber(999) == "999", Util.formatNumber(999))
	assert(Util.formatNumber(12500) == "12.5K", Util.formatNumber(12500))
	assert(Util.formatTime(125) == "2:05")
	local it = Util.weightedPick({ {1}, {2} }, function(x) return x[1] end)
	assert(it)
	local sp = Util.Spring.new(0, 10, 1)
	sp.Target = 1
	for _ = 1, 120 do sp:Step(1/60) end
	assert(math.abs(sp.Position - 1) < 0.05, sp.Position)
end)

try("Remotes.init", function()
	R("Remotes").init()
	assert(R("Remotes").get("Grab"))
end)

try("ToyFactory.build para todos os brinquedos", function()
	local Toys = R("Toys")
	local TF = R("ToyFactory")
	for _, toy in Toys.List do
		local m = TF.build(toy.id)
		assert(m, toy.id)
		assert(m.PrimaryPart, toy.id .. " sem PrimaryPart")
	end
end)

try("ToyFactory.spawn", function()
	local Toys = R("Toys")
	local TF = R("ToyFactory")
	for _, toy in Toys.List do
		local m = TF.spawn(toy.id, CFrame.new(0, 10, 0), workspace)
		assert(m and m.Parent, toy.id)
	end
end)

try("WorldGen.height", function()
	local WG = R("WorldGen")
	local h = WG.height(0, 0)
	assert(math.abs(h - 26) < 4, "hub deveria estar perto de 26, deu " .. h)
end)

try("Scenery.build (sem escrita de terreno)", function()
	local WG = R("WorldGen")
	WG.build = function(cb) if cb then cb(1) end end
	-- raios "para baixo" acertam o terreno calculado pela funcao de altura
	workspace.Raycast = function(self, origin, direction)
		if direction.Y < -50 then
			local mat, h, slope = WG.materialAt(origin.X, origin.Z)
			if h < 0 then
				return { Position = Vector3.new(origin.X, 0, origin.Z), Normal = Vector3.new(0, 1, 0), Material = Enum.Material.Water }
			end
			return { Position = Vector3.new(origin.X, h, origin.Z), Normal = Vector3.new(0, 1 / math.sqrt(1 + slope * slope), 0), Material = mat }
		end
		return nil
	end
	R("Build").init()
	local Scenery = R("Scenery")
	Scenery.build()
end)

for _, modName in { "Data", "Physics", "Ragdoll", "Scoring", "Board", "Blasts", "Pickups", "ToyPassive", "ToySpawner", "Grab", "AbilityService", "Shop", "Zones", "Atmosphere" } do
	try("init " .. modName, function()
		R(modName).init()
	end)
end

-- jogador falso ---------------------------------------------------------------------------------------------
local player, char, hrp
try("jogador falso entra e carrega dados", function()
	player = Instance.new("Player")
	player.Name = "Teste"
	player.UserId = 42
	player.DisplayName = "Teste"
	char = Instance.new("Model")
	char.Name = "Teste"
	hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Position = Vector3.new(0, 30, 0)
	hrp.Parent = char
	local hum = Instance.new("Humanoid")
	hum.Health = 100
	hum.Parent = char
	char.Parent = workspace
	player.Character = char
	game:GetService("Players").PlayerAdded:Fire(player)
	local Data = R("Data")
	assert(Data.isLoaded(player), "dados nao carregaram")
	assert(Data.get(player).Coins == R("Config").Economy.StartCoins)
	Data.addXP(player, 500)
	assert(Data.get(player).Level > 1, "nao subiu de nivel")
	Data.addCoins(player, 100)
end)

try("upgrade + compra na loja", function()
	local Data = R("Data")
	local d = Data.get(player)
	d.SkillPoints = 5
	local ok, msg = Data.buyUpgrade(player, "Power")
	assert(ok, msg)
	d.Level = 20
	d.Coins = 5000
	local shop = R("Remotes").get("Shop").OnServerInvoke
	local ok2, msg2 = shop(player, "buyToy", "foguete")
	assert(ok2, msg2)
	local ok3, msg3 = shop(player, "buyTether", "Ouro")
	assert(ok3, msg3)
end)

try("agarrar e arremessar um objeto", function()
	local Toys = R("Toys")
	local TF = R("ToyFactory")
	local Grab = R("Grab")
	local body = TF.spawn("caixa", CFrame.new(5, 30, 0), workspace).PrimaryPart
	local ok, info = R("Remotes").get("Grab").OnServerInvoke(player, body, Vector3.zero)
	assert(ok, tostring(info))
	assert(#Grab.holdsOf(player) == 1)
	-- arremesso
	local throwSig = R("Remotes").get("Throw").OnServerEvent
	throwSig:Fire(player, body, Vector3.new(0, 0.3, -1), 0.8)
	assert(#Grab.holdsOf(player) == 0, "hold deveria ter terminado")
	assert(body:GetAttribute("Thrower") == 42)
	_ = Toys
end)

try("habilidade shock/dash/stasis", function()
	local ab = R("Remotes").get("UseAbility").OnServerEvent
	local Data = R("Data")
	Data.get(player).Level = 30
	ab:Fire(player, "dash")
	ab:Fire(player, "shock")
	local TF = R("ToyFactory")
	local body = TF.spawn("bola", CFrame.new(3, 30, 0), workspace).PrimaryPart
	ab:Fire(player, "stasis", body)
	assert(body:GetAttribute("Frozen"), "nao congelou")
end)

return failures, table.concat(results, "\\n")
`);
console.log(res[1]);
console.log("\nfalhas:", res[0]);
process.exit(res[0] ? 1 : 0);
