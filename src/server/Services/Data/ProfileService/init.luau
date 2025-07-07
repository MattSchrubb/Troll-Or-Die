----- GLOBALS -----

----- Libraries and Services -----

--local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ProfileStore = require(ServerScriptService.Libraries.ProfileStore)
local ReplicaServer = require(ServerScriptService.Libraries.ReplicaServer)

----- Variables -----

local ProfileTemplate = require(script:WaitForChild("ProfileTemplate"))
local DataServices = script.Parent:GetChildren()

local PlayerStore: ProfileStore.ProfileStore<ProfileTemplate.ProfileTemplate> =
	ProfileStore.New("PlayerStore", ProfileTemplate)
if RunService:IsStudio() == true then
	PlayerStore = PlayerStore.Mock :: ProfileStore.ProfileStore<ProfileTemplate.ProfileTemplate>
end

----- Service Declaration -----

local ProfileService = {
	DataServices = {},
	Profiles = {} :: { [Player]: {} }, -- PlayerProfile
	Replicas = {} :: { [Player]: { [string]: ReplicaServer.Replica } },
}

-- Initialize each data service
for _, dataService in ipairs(DataServices) do
	if dataService == script then
		continue
	end
	if dataService:IsA("ModuleScript") then
		ProfileService.DataServices[dataService.Name] = require(dataService)
	end
end

----- Private Functions -----

function ProfileService:_SetupReplicas(plr: Player, profile)
	if self.Replicas[plr] == nil then
		self.Replicas[plr] = {}
	end

	for serviceId, dataService in pairs(self.DataServices) do
		local replica = ReplicaServer.New({
			Token = dataService.Token,
			Tags = {},
			Data = profile.Data[dataService.Token.Name],
		})

		self.Replicas[plr][dataService.Token.Name] = replica
		dataService:_AddPlayerReplica(plr, replica)
	end
end

function ProfileService:_CleanupReplicas(plr: Player)
	for dataGroup, replica in pairs(self.Replicas[plr]) do
		replica:Destroy()
		self.Replicas[plr][dataGroup] = nil
		--self.DataServices[dataGroup]:_CleanupPlayerReplica(plr)
	end
	self.Replicas[plr] = nil
end

function ProfileService:_SetupProfile(plr: Player)
	-- Start a profile session for this player's data:
	local profile = PlayerStore:StartSessionAsync(tostring(plr.UserId), {
		Cancel = function()
			return plr.Parent ~= Players
		end,
	}) --:: PlayerProfile

	-- Handling new profile session or failure to start it:

	if profile ~= nil then
		profile:AddUserId(plr.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		print(profile.Data)
		profile.OnSessionEnd:Connect(function()
			self.Profiles[plr] = nil
			self:_CleanupReplicas(plr)
			plr:Kick()
		end)

		if plr.Parent == Players then
			-- A profile has been successfully loaded:
			self.Profiles[plr] = profile
			self:_SetupReplicas(plr, profile)
		else
			-- Player left before the profile loaded:
			profile:EndSession()
		end
	else
		-- The profile couldn't be loaded possibly due to other
		--    Roblox servers trying to load this profile at the same time:
		plr:Kick("Profile load failed - Plaese rejoin")
	end
end

function ProfileService:_DisconnectProfile(plr: Player)
	local profile = self.Profiles[plr]
	if profile ~= nil then
		profile:EndSession()
	end
end

function ProfileService:_Start() end

----- Public Functions -----

function ProfileService:GetProfile(plr: Player)
	-- Returns the profile for the given player. The calling function must handle edge cases
	return self.Profiles[plr]
end

----- Connections and Type Exports -----

for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(ProfileService._SetupProfile, ProfileService, plr)
end
Players.PlayerAdded:Connect(function(plr: Player)
	ProfileService:_SetupProfile(plr)
end)
Players.PlayerRemoving:Connect(function(plr: Player)
	ProfileService:_DisconnectProfile(plr)
end)

ReplicaServer.NewReadyPlayer:Connect(function(plr)
	local replicaTbl = ProfileService.Replicas[plr]

	for _, replica in pairs(replicaTbl) do
		replica:Subscribe(plr)
	end
end)


export type ProfileService = typeof(ProfileService)
--export type PlayerProfile = ProfileStore.Profile<ProfileTemplate.ProfileTemplate>

return ProfileService :: ProfileService