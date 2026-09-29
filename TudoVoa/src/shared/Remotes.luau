--!nonstrict
--[[
	Remotes: o servidor cria os RemoteEvents/RemoteFunctions em ReplicatedStorage.TV_Remotes,
	o cliente espera por eles. Todos os nomes ficam listados aqui.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

Remotes.Events = {
	-- cliente -> servidor
	"Release", -- (root)
	"Throw", -- (root, direcao, carga 0..1)
	"Struggle", -- () quem esta sendo segurado espernea
	"UseAbility", -- (id, dados)
	"SpawnToy", -- (toyId)
	"DespawnToys", -- ()
	"SetSetting", -- (chave, valor)
	"BuyUpgrade", -- (id)
	"ClientReady", -- ()
	"RequestGetUp", -- ()
	"ActivityAction", -- (atividade, acao, dados)
	-- servidor -> cliente
	"DataSync", -- (snapshot)
	"DataChanged", -- (chave, valor)
	"ForceRelease", -- (root, motivo)
	"RagdollState", -- (ligado, duracao)
	"Fx", -- (tipo, posicao, forca, extra)
	"Notify", -- (texto, tipo)
	"Announce", -- (titulo, subtitulo, duracao, cor)
	"BossState", -- (tabela)
	"EventState", -- (tabela)
	"WorldReady", -- ()
	"ThrowResult", -- (distancia, moedas, xp, recorde)
	"HoldedBy", -- (nomeDoSegurador | nil, progresso)
	"ArenaState", -- (tabela)
	"AbilityFx", -- (id, jogador, posicao, extra)
	"ScorePopup", -- (posicao, texto, cor)
	"Launch", -- (velocidade) o cliente dono do personagem aplica a velocidade
	"Zone", -- (nomeDaZona, icone)
	"Struck", -- (forca, direcao) tremor de camera no cliente atingido
}

Remotes.Functions = {
	"Grab", -- (root, pontoDeMira) -> ok, info
	"Shop", -- (acao, id) -> ok, mensagem
	"GetBoard", -- () -> lista de recordes
}

local FOLDER_NAME = "TV_Remotes"
local cache = {}

local function getFolder()
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if folder then
		return folder
	end
	if RunService:IsServer() then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

-- Servidor: cria tudo. Cliente: nao precisa chamar.
function Remotes.init()
	assert(RunService:IsServer(), "Remotes.init so no servidor")
	local folder = getFolder()
	for _, name in Remotes.Events do
		if not folder:FindFirstChild(name) then
			local ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = folder
		end
	end
	for _, name in Remotes.Functions do
		if not folder:FindFirstChild(name) then
			local fn = Instance.new("RemoteFunction")
			fn.Name = name
			fn.Parent = folder
		end
	end
end

function Remotes.get(name: string): any
	local c = cache[name]
	if c then
		return c
	end
	local folder = getFolder()
	local inst = folder:FindFirstChild(name)
	if not inst then
		if RunService:IsServer() then
			error("Remote inexistente: " .. name)
		end
		inst = folder:WaitForChild(name, 30)
	end
	assert(inst, "Remote nao encontrado: " .. name)
	cache[name] = inst
	return inst
end

return Remotes
