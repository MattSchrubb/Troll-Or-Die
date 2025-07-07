--[[
	Handles setting up the current game mode
		swapping game modes
		cleaning up after a round
		moving players around

]]

----- GLOBALS -----



----- Libraries and Services -----

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerComm = require(ReplicatedStorage.Packages.Comm).ServerComm
local CommFolder = ReplicatedStorage.Comms

local Players = game:GetService("Players")

----- Variables -----

local ModesList = {
	TestMode = require(script.TestMode),
}

local MapsList = {
	Construction = game.Workspace:WaitForChild("ConstructionSite")
}

----- Service Declaration -----

local GameModeService = {
	CurrentMode = nil
}

----- Server Functions -----

--[[
	Choose the mode
	Choose the map
	Grab the mode folder from the map, and send it to the mode's module script
]]

function GameModeService:GetModes()
	return ModesList
end

function GameModeService:GetMaps()
	return MapsList
end


function GameModeService:InitRound(mapId, modeId, playerList, completedCallback)
	print("Loading Map: " .. mapId)
	local map = MapsList[mapId]
	-- Would place map into workspace here

	print("Loading Mode: " .. modeId)
	local modeFolder: Folder = map.GameModes[modeId]
	local mode = ModesList[modeId]
	mode:Init({
		ModeFolder = modeFolder,
		PlayerList = playerList,
		CompletedCallback = completedCallback
	})

	self.CurrentMode = mode
end

function GameModeService:StartRound(timer)
	self.CurrentMode:StartRound(timer)
end



function GameModeService:HitPlayer(plr: Player)
	if not self.CurrentMode then return end

	self.CurrentMode:HitPlayer(plr)
end



function GameModeService:Cleanup()
	return self.CurrentMode:Cleanup()
end


----- Client Functions -----



----- Connections -----

return GameModeService