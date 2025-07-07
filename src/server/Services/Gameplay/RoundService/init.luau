----- GLOBALS -----

--[[

Timer does countdown or sm
End round after Timer ends
Go to voting for new map and mode
Once voting time concludes, countdown until match starts

repeat
]]

----- Libraries and Services -----

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerComm = require(ReplicatedStorage.Packages.Comm).ServerComm
local CommFolder = ReplicatedStorage.Comms

local Libraries = game.ServerScriptService.Libraries
local ReplicaServer = require(Libraries.ReplicaServer)

local Players = game:GetService("Players")
local TimerModule = require(ReplicatedStorage.Timer)

local GameModeService = require(script.Parent:WaitForChild("GameModeService"))

----- Variables -----

local COMM = ServerComm.new(CommFolder, "RoundService")

local DEFAULT_TIMERS = {
	round = 5,--180, -- 3 minutes
	postRound = 5,--15,
	voting = 5,--25,
	preRound = 5,--10,
}

local VotingReplicaToken = ReplicaServer.Token("VotingReplica")
local VotingReplica = ReplicaServer.New({
	Token = VotingReplicaToken,
	Tags = {},
	Data = {
		Maps = {
			Options = {
				-- [1] = id1, [2] = id2, [3] = id3
			},
			PlayerChoices = {
				-- plr1 = 1, plr2 = 2, plr3 = 1 -- Value represents the index in the Options table
			}
		},

		Modes = {
			Options = {
				-- [1] = id1, [2] = id2, [3] = id3
			},
			PlayerChoices = {
				-- plr1 = 1, plr2 = 2, plr3 = 3 -- Value represents the index in the Options table
			}
		}
	},
})

VotingReplica:Replicate()

----- Service Declaration -----

local RoundService = {
	playersInQueue = {},
	playersInGame = {},

	state = "Awaiting", -- Awaiting | Voting | PreRound | InProgress | PostRound

	Timer = TimerModule.new({duration = DEFAULT_TIMERS.voting}),
	--inProgress = false,

	-- MapVotes = {},
	-- ModeVotes = {},

	Client = {
		COMM = COMM,

		-- RoundStarted = COMM:CreateSignal("RoundStarted"),
		-- RoundEnded = COMM:CreateSignal("RoundEnded"),
		-- VotingInfoMaps = COMM:CreateProperty("VotingInfoMaps", {
		-- 	--MapId1 = 0,
		-- 	--MapId2 = 0,
		-- 	--MapId3 = 0,
		-- }),
		-- VotingInfoModes = COMM:CreateProperty("VotingInfoModes", {
		-- 	--ModeId1 = 0,
		-- 	--ModeId2 = 0,
		-- 	--ModeId3 = 0
		-- }),

		State = COMM:CreateProperty("State", "Awaiting"),
		Timer = COMM:CreateProperty("Timer", "0"),

		Winners = COMM:CreateProperty("Winners", {})
	},
}
RoundService.Client.Server = RoundService

----- Server Functions -----

function RoundService:RoundCompletedCallback(info)
	self.Timer:SetDuration(0)
end

-- Changes State and updates it for the players
function RoundService:SetState(newState)
	self.state = newState
	self.Client.State:Set(newState)
end

-- Starts the voting phase
function RoundService:Voting()
	self:SetState("Voting")
	self.Timer:SetDuration(DEFAULT_TIMERS.voting)

	-- Grab 3 maps and 3 modes randomly and set them up in the voting info tables
	-- self.Client.VotingInfoMaps:Set({
	-- 	Construction = 0
	-- })
	-- self.Client.VotingInfoModes:Set({
	-- 	TestMode = 0
	-- })

	VotingReplica:Set({"Maps", "PlayerChoices"}, {})
	VotingReplica:Set({"Maps", "Options"}, {
		[1] = "Construction"
	})
	
	VotingReplica:Set({"Modes", "PlayerChoices"}, {})
	VotingReplica:Set({"Modes", "Options"}, {
		[1] = "TestMode"
	})



	print("starting voting period")
	self.Timer:Start()



	self.Timer.Completed:Wait()

	-- Check which map and mode were voted on most
	local winningMap = nil
	local winningMode = nil

	if #VotingReplica.Data.Maps.PlayerChoices < 1 then
		winningMap = 1 -- math.random(1, 3)
	else
		local mapVotes = { 0, 0, 0 }
		for _, v in VotingReplica.Data.Maps.PlayerChoices do
			mapVotes[v] += 1
		end

		for index,v in mapVotes do
			if not winningMap then
				winningMap = index
			else
				if v > mapVotes[winningMap] then
					winningMap = index
				elseif v == mapVotes[winningMap] then
					if math.random(1, 2) == 1 then
						winningMap = index
					end
				end
			end
		end
	end

	if #VotingReplica.Data.Modes.PlayerChoices < 1 then
		winningMode = 1 -- math.random(1, 3)
	else
		local modeVotes = { 0, 0, 0 }
		for _,v in VotingReplica.Data.Modes.PlayerChoices do
			modeVotes[v] += 1
		end

		for index,v in modeVotes do
			if not winningMode then
				winningMode = index
			else
				if v > modeVotes[winningMode] then
					winningMode = index
				elseif v == modeVotes[winningMode] then
					if math.random(1, 2) == 1 then
						winningMode = index
					end
				end
			end
		end
	end

	if #self.playersInQueue < 2 then
		self:SetState("Awaiting")
		return
	end




	-- Track the players in the game
	self.playersInGame = table.clone(self.playersInQueue)
	print("PLAYERS IN GAME:")
	print(self.playersInGame)

	-- Start round with winningMode and Map
	GameModeService:InitRound(VotingReplica.Data.Maps.Options[winningMap], VotingReplica.Data.Modes.Options[winningMode], self.playersInGame, function(info) self:RoundCompletedCallback(info) end)

	print("voting done")
	self:PreRound()
end

-- Loads players into the map and counts down until the round starts
function RoundService:PreRound()
	self.Timer:SetDuration(DEFAULT_TIMERS.preRound)

	self:SetState("PreRound")

	print("starting preround period")
	self.Timer:Start()
	self.Timer.Completed:Wait()
	print("preround done")

	self:Round()
end

-- Main Round
function RoundService:Round()
	self.Timer:SetDuration(DEFAULT_TIMERS.round)

	self:SetState("InProgress")

	print("Starting round period")
	GameModeService:StartRound(self.Timer)
	self.Timer:Start()

	-- Testing for premature round ending case
	-- task.spawn(function()
	-- 	task.wait(3)
	-- 	self.Timer:SetDuration(0)
	-- end)



	-- Use self.Timer:SetDuration(0) while it is running to fire the Completed early
	if not (self.Timer:GetState() == "Completed") then
		self.Timer.Completed:Wait()
	end

	print("round done")

	local Winners = GameModeService:Cleanup()
	print(Winners)
	self.Client.Winners:Set(Winners)
	-- for _, plr in Players:GetPlayers() do
	-- 	task.spawn(function()
	-- 		self.Client.Winners:Fire(plr, Winners)
	-- 	end)
	-- end
	

	self:PostRound()
end

-- After round conclues, sends players to lobby and shows rewards or and end round screen
function RoundService:PostRound()
	self.Timer:SetDuration(DEFAULT_TIMERS.postRound)

	self:SetState("PostRound")

	print("Starting postround period")
	self.Timer:Start()
	self.Timer.Completed:Wait()
	print("postround done")

	if #self.playersInQueue > 1 then
		task.spawn(function()
			self:Voting()
		end)
	else
		self:SetState("Awaiting")
	end
end


function RoundService:Init()
	print("INITIALIZING ROUND")
	self:Voting()
end


function RoundService:GetPlayersInQueue()
	return self.playersInQueue, #self.playersInQueue
end

----- Client Functions -----

--- Client Queue Code ---
function RoundService.Client:JoinQueue(plr: Player)
	if not self.Server.playersInQueue[plr] then
		table.insert(self.Server.playersInQueue, plr)
	end
	-- Check if the round is waiting for players
	if self.Server.state ~= "Awaiting" then return end
	-- Check if enough players are in the queue to start the round
	if #self.Server.playersInQueue > 1 then
		task.spawn(function()
			self.Server:Init()
		end)
	end
end

function RoundService.Client:LeaveQueue(plr: Player)
	local index = table.find(self.Server.playersInQueue, plr)
	if index then
		table.remove(self.Server.playersInQueue, index)
	end

	local index2 = table.find(self.Server.playersInGame, plr)
	if index2 then
		table.remove(self.Server.playersInGame, index)
	end
end



--- Client Voting Code ---

function RoundService.Client:VoteMap(plr: Player, mapId: string)
	-- DO SANITY CHECK FOR CLIENT INFO PASSED --


	if not (self.Server.state == "Voting") then return end
	--if not (self.Server.playersInQueue[plr]) then return end -- Check if the player is in queue, otherwise don't let them vote

	if self.Server.MapVotes[plr] and self.Server.MapVotes[plr] == mapId then return end -- If their vote didnt change
	self.Server.MapVotes[plr] = mapId

	local oldTbl = self.VotingInfoMaps:Get()
	local newTbl = {}
	for _,id in ipairs(oldTbl) do
		
	end
end

function RoundService.Client:VoteMode(plr: Player, modeId: string)
	if not (self.Server.state == "Voting") then return end

	
end

----- Connections -----

RoundService.Timer.Tick:Connect(function()
	--print(RoundService.Timer:GetSecondsLeft())

	-- Sets the amount of time left for all players to see
	RoundService.Client.Timer:Set(RoundService.Timer:GetTimeLeft())
end)

Players.PlayerRemoving:Connect(function(plr: Player)

	-- Remove player from queue and current round
	local index = table.find(RoundService.playersInQueue, plr)
	if index then
		table.remove(RoundService.playersInQueue, index)
	end
	local index2 = table.find(RoundService.playersInGame, plr)
	if index2 then
		table.remove(RoundService.playersInGame, index2)
	end
end)

return RoundService