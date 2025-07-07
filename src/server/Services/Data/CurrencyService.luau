----- GLOBALS -----

----- Libraries and Services -----

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerComm = require(ReplicatedStorage.Packages.Comm).ServerComm
local CommFolder = ReplicatedStorage.Comms

local ServerScriptService = game:GetService("ServerScriptService")
local Libraries = ServerScriptService.Libraries

local ReplicaServer = require(Libraries.ReplicaServer)
--local Players = game:GetService("Players")

----- Variables -----

local COMM = ServerComm.new(CommFolder, "CurrencyService")

local CurrencyService = {
	Token = ReplicaServer.Token("CurrencyData"),

	PlayerReplicas = {},

	Client = {
		COMM = COMM,

		Signal1 = COMM:CreateSignal("Signal1"),
		Property1 = COMM:CreateProperty(5),
	}
}
CurrencyService.Client.Server = CurrencyService

----- Server Functions -----

function CurrencyService:_AddPlayerReplica(plr: Player, replica)
	self.PlayerReplicas[plr] = replica
	
	-- task.spawn(function()
	-- 	task.wait(5)
	-- 	replica:Set({"Tix"}, 5)
	-- end)
end

----- Client Functions -----

function CurrencyService.Client:DoSomething(plr: Player)
	--print("DOING SOMETHING ON THE SERVER")
end

----- 

return CurrencyService