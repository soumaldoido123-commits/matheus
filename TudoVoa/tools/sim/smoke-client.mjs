// Teste de fumaca do CLIENTE: inicia toda a interface e os sistemas locais no mock,
// simula dados, quadros de render, agarrar/arremessar, menu e efeitos.
//   node sim/smoke-client.mjs
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

-- os remotes sao criados "pelo servidor", depois viramos cliente
try("remotes + jogador local", function()
	R("Remotes").init()
	__IS_CLIENT = true
	local Players = game:GetService("Players")
	local lp = Instance.new("Player")
	lp.Name = "Local"
	lp.DisplayName = "Local"
	lp.UserId = 7
	local gui = Instance.new("PlayerGui")
	gui.Name = "PlayerGui"
	gui.Parent = lp
	local char = Instance.new("Model")
	char.Name = "Local"
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Position = Vector3.new(0, 30, 0)
	hrp.Parent = char
	local torso = Instance.new("Part")
	torso.Name = "UpperTorso"
	torso.Parent = char
	local hum = Instance.new("Humanoid")
	hum.Health = 100
	hum.Parent = char
	char.Parent = workspace
	lp.Character = char
	Players.LocalPlayer = lp
	Players.GetPlayers = function() return { lp } end
end)

try("client/init (todos os modulos)", function()
	R("client")
end)

try("Store recebe dados", function()
	local Remotes = R("Remotes")
	Remotes.get("DataSync").OnClientEvent:Fire({
		Coins = 1234, XP = 50, XPNeeded = 200, Level = 12, SkillPoints = 3, BestThrow = 250,
		Upgrades = { Power = 2, Range = 1 }, Toys = { foguete = true },
		OwnedTethers = { Roxo = true, Ciano = true, Ouro = true }, OwnedTrails = { Nenhum = true },
		Tether = "Ouro", Trail = "Nenhum", Settings = { Peaceful = false, Music = true, Sfx = true, Shake = true, Tutorial = true },
	})
	local Store = R("Store")
	assert(Store.get("Level") == 12)
	assert(Store.ownsToy("caixa"))
	assert(Store.ownsToy("foguete"))
	assert(not Store.ownsToy("piano"))
end)

try("quadros de render/heartbeat", function()
	local rs = game:GetService("RunService")
	for _ = 1, 5 do
		rs.RenderStepped:Fire(0.016)
		rs.Heartbeat:Fire(0.016)
		for _, fn in __RENDER or {} do
			fn(0.016)
		end
	end
end)

try("HUD: toast, anuncio, zona, resultado, espernear", function()
	local HUD = R("HUD")
	HUD.toast("teste", "coin")
	HUD.announce("NIVEL 5!", "sub", 2, nil)
	HUD.setZone("Praça", "🌀")
	HUD.showThrowResult(250, 30, 12, true, 3, "Cristal!")
	HUD.setStruggle("Fulano", 0.4)
	HUD.setStruggle(nil)
	HUD.setCharge(0.5)
	HUD.setCharge(nil)
	HUD.setHint("Caixote", true)
	HUD.setHint(nil)
end)

try("Menu: todas as abas", function()
	local Menu = R("Menu")
	for _, tab in { "shop", "toys", "skills", "tether", "board", "settings", "help" } do
		Menu.open(tab)
		Menu.refresh()
	end
	Menu.close()
end)

try("Fx: todos os efeitos", function()
	local Fx = R("Fx")
	local pos = Vector3.new(0, 20, 0)
	for kind, h in Fx.handlers do
		h(pos, 1, { color = Color3.new(1, 0, 0), mat = "Metal", dir = Vector3.yAxis })
	end
	Fx.popup(pos, "TESTE", nil)
	Fx.screenFlash()
	Fx.shake(1)
end)

try("agarrar -> carregar -> arremessar", function()
	local ToysMod = R("Toys")
	local Config = R("Config")
	local CS = game:GetService("CollectionService")
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Position = Vector3.new(0, 30, -10)
	body:SetAttribute("Behavior", "glide")
	body:SetAttribute("AlignMode", "look")
	body:SetAttribute("ToyId", "aviao")
	body.Parent = workspace
	CS:AddTag(body, Config.Tags.Grabbable)
	workspace.Spherecast = function()
		return { Instance = body, Position = body.Position, Normal = Vector3.yAxis }
	end
	-- resposta do servidor ao agarrar
	local remotes = R("Remotes")
	remotes.get("Grab").OnClientInvoke = nil
	local grabFn = remotes.get("Grab")
	grabFn.InvokeServer = function()
		return true, { kind = "object", key = body, model = nil, mass = 5 }
	end
	local rs = game:GetService("RunService")
	rs.RenderStepped:Fire(0.016)
	for _, fn in __RENDER or {} do fn(0.016) end
	local uis = game:GetService("UserInputService")
	uis.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, KeyCode = Enum.KeyCode.Unknown }, false)
	local GC = R("GrabController")
	assert(GC.holdCount == 1, "nao agarrou (holdCount=" .. tostring(GC.holdCount) .. ")")
	-- quadros segurando
	for _ = 1, 3 do
		for _, fn in __RENDER or {} do fn(0.016) end
	end
	-- carregar
	uis.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton2, KeyCode = Enum.KeyCode.Unknown }, false)
	assert(GC.charging, "nao comecou a carregar")
	for _ = 1, 20 do
		for _, fn in __RENDER or {} do fn(0.05) end
	end
	assert(GC.charge > 0.5, "carga nao subiu: " .. tostring(GC.charge))
	uis.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton2, KeyCode = Enum.KeyCode.Unknown }, false)
	assert(GC.holdCount == 0, "nao arremessou")
	_ = ToysMod
end)

try("AbilityBar: ativar habilidades", function()
	local AB = R("AbilityBar")
	local defs = R("AbilityDefs")
	for _, def in defs.List do
		AB.activate(def)
	end
end)

try("Movement/ToyPhysics/DecorAnim frames", function()
	local rs = game:GetService("RunService")
	for _ = 1, 10 do
		rs.Heartbeat:Fire(0.016)
		rs.RenderStepped:Fire(0.016)
	end
end)

return failures, table.concat(results, "\\\\n")
`);
console.log(res[1]);
console.log("\nfalhas:", res[0]);
process.exit(res[0] ? 1 : 0);
