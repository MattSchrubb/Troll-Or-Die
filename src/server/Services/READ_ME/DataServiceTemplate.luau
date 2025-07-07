----- GLOBALS -----

----- Libraries and Services -----

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicaServer = require(ServerScriptService.Libraries.ReplicaServer)
local Players = game:GetService("Players")

----- Variables -----

local SomethingData = {
	Token = ReplicaServer.Token("SomethingData"), -- Setting up a Token for this Data Service

	PlayerReplicas = {},

	Client = {}, -- A table used to store functions that Players can call. If not needed, then remove this line and the line below
}
SomethingData.Client.Server = SomethingData -- A way for a client function to access the server side functions and data

----- Server Functions -----

function SomethingData:_AddPlayerReplica(plr: Player, replica) -- Function used by ProfileService to add in each player's Replica
	self.PlayerReplicas[plr] = replica
end

function SomethingData:_CleanupPlayer(plr: Player) -- Function used by ProfileService or another module to cleanup and Player references
	self.PlayerReplicas[plr] = nil

	-- Any other cleanup that needs to happen
end

function SomethingData:DoSomething(name: string)
	print("Hello from " .. name) -- printed from the server
end

----- Client Functions -----

-- This section adds in functions that the client can call to perform actions on the server
-- REMEMBER!!!!! Do not trust ANYTHING from the client. The server should be doing all the checks

function SomethingData.Client:DoSomething(plr: Player) -- Called by the client
	if plr.Parent ~= Players then -- We check if the Player is actually in the game
		print("Player isn't in the game :|")
		return
	end

	-- If all our checks pass, we can finally do stuff - YIPEEE!!!

	self.Server:DoSomething(plr.Name) -- We access the Server variable in the Client table that links to the SomethingData Service
	-- And then we call the server function DoSomething
end

-----  Connections -----

return SomethingData
