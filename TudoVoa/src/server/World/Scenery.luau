--!nonstrict
--[[
	Scenery: coordena a construcao do mundo (terreno + cenario + brinquedos espalhados).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Server = script.Parent.Parent
local ToySpawner = require(Server:WaitForChild("ToySpawner"))
local Zones = require(Server:WaitForChild("Zones"))

local WorldGen = require(script.Parent:WaitForChild("WorldGen"))
local Build = require(script.Parent:WaitForChild("Build"))
local Nature = require(script.Parent:WaitForChild("Nature"))
local Hub = require(script.Parent:WaitForChild("Hub"))
local Farm = require(script.Parent:WaitForChild("Farm"))
local Snow = require(script.Parent:WaitForChild("Snow"))
local Volcano = require(script.Parent:WaitForChild("Volcano"))
local Beach = require(script.Parent:WaitForChild("Beach"))
local Sky = require(script.Parent:WaitForChild("Sky"))
local Cave = require(script.Parent:WaitForChild("Cave"))
local Interactive = require(script.Parent:WaitForChild("Interactive"))

local Scenery = {}

local function setProgress(p: number, text: string?)
	workspace:SetAttribute("TV_Progress", p)
	if text then
		workspace:SetAttribute("TV_LoadText", text)
	end
end

-- Canhoes expressos: biomas -> praca e praca -> biomas
local function expressCannons(folder: Folder)
	local hubY = Build.y(0, 0)
	local plazaTarget = Vector3.new(0, hubY + 4, 34)
	local list = {
		{ pos = Vector3.new(-410, 0, 60), label = "Fazenda ➜ Praça", target = plazaTarget },
		{ pos = Vector3.new(-30, 0, -340), label = "Montanha ➜ Praça", target = plazaTarget },
		{ pos = Vector3.new(400, 0, 10), label = "Vulcão ➜ Praça", target = plazaTarget },
		{ pos = Vector3.new(40, 0, 340), label = "Praia ➜ Praça", target = plazaTarget },
	}
	for _, c in list do
		Interactive.cannon(folder, c.pos, c.target, c.label, { angle = 50 })
	end
	-- da praca para os biomas (posicao do destino perto do centro de cada bioma)
	for key, b in Config.Biomes do
		if key ~= "Hub" then
			local dir = Vector3.new(b.center.X, 0, b.center.Y).Unit
			local cpos = dir * 92 + Vector3.new(-dir.Z * 20, 0, dir.X * 20)
			local tx = b.center.X * 0.72
			local tz = b.center.Y * 0.72
			local ty = Build.y(tx, tz) + 4
			Interactive.cannon(folder, cpos, Vector3.new(tx, ty, tz), "Praça ➜ " .. b.name, { angle = 52 })
		end
	end
end

-- Roda uma etapa protegida: se falhar, avisa no Output e o resto do mundo continua.
local function stage(name: string, fn: (...any) -> ...any, ...)
	local ok, err = xpcall(fn, debug.traceback, ...)
	if not ok then
		warn("[Mundo] etapa '" .. name .. "' falhou:\n" .. tostring(err))
	end
	return ok
end

function Scenery.build()
	setProgress(0, "Gerando terreno...")
	stage("terreno", WorldGen.build, function(p)
		setProgress(p * 0.55, "Gerando terreno...")
	end)

	Build.init()
	local rng = Random.new(Config.World.Seed)
	local addSlot = function(pos, biome)
		ToySpawner.addSlot(pos, biome)
	end

	setProgress(0.58, "Construindo a praça...")
	-- a Vila dos Jogadores (Activities/Plots) ocupa este raio: nada de arvores/pedras nascendo la
	Nature.reserve(Config.World.Village.X, Config.World.Village.Z, 120)
	stage("praca", Hub.build)
	task.wait()
	setProgress(0.64, "Plantando a fazenda...")
	stage("fazenda", Farm.build, rng, addSlot)
	task.wait()
	setProgress(0.70, "Cobrindo a montanha de neve...")
	stage("montanha", Snow.build, rng, addSlot)
	task.wait()
	setProgress(0.76, "Acendendo o vulcão...")
	stage("vulcao", Volcano.build, rng, addSlot)
	task.wait()
	setProgress(0.82, "Molhando a praia...")
	stage("praia", Beach.build, rng, addSlot)
	task.wait()
	setProgress(0.87, "Levantando as ilhas...")
	stage("ilhas", Sky.build, rng, addSlot)
	task.wait()
	setProgress(0.90, "Iluminando a caverna...")
	stage("caverna", Cave.build, rng, addSlot)

	stage("canhoes", expressCannons, Build.folder("Cannons"))

	-- brinquedos na praca (fora da zona segura) e moedas soltas
	local hubY = Build.y(0, 0)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2 + 0.2
		addSlot(Vector3.new(math.cos(a) * 80, hubY + 1, math.sin(a) * 80), "Hub")
	end
	local pickups = require(Server:WaitForChild("Pickups"))
	local coinRng = Random.new(Config.World.Seed + 9)
	local placed = 0
	local attempts = 0
	while placed < 90 and attempts < 900 do
		attempts += 1
		local a = coinRng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(coinRng:NextNumber()) * 640
		local pos, normal = Build.ground(math.cos(a) * r, math.sin(a) * r)
		if pos and normal.Y > 0.8 and pos.Y > 4 and Vector2.new(pos.X, pos.Z).Magnitude > 70 then
			pickups.placeStatic(pos + Vector3.new(0, 3, 0), 5, 75)
			placed += 1
		end
		if attempts % 60 == 0 then
			task.wait()
		end
	end

	setProgress(0.96, "Soltando os brinquedos...")
	Nature.reserve(0, 0, 0)
	task.wait()
	setProgress(1, "Pronto!")
	_ = Zones
	_ = Remotes
end

return Scenery
