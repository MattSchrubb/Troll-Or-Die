local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local CROWN_SPAWN_TAG = "CrownSpawn"
local PLAYER_SPAWN_TAG = "PlayerSpawn"

local Services = ServerScriptService.Services

do -- Player Collision Groups and Spawn Part Visibility
	local Players = game:GetService("Players")
	local CollisionGroupName = "PlayerCharacter"

	local function setCollisionGroup(model)
		-- Apply collision group to all existing parts in the model
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CollisionGroup = CollisionGroupName
			end
		end
	end

	Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function(chr)
			chr.Parent = game.Workspace:WaitForChild("AliveCharacters")
			setCollisionGroup(chr)
			chr:WaitForChild("Head").CanCollide = false
			chr:WaitForChild("Humanoid").RequiresNeck = false
		end)

		if plr.Character then
			setCollisionGroup(plr.Character)
			plr.Character:WaitForChild("Humanoid").RequiresNeck = false
		end
	end)

	task.spawn(function()
		for _, v in CollectionService:GetTagged(CROWN_SPAWN_TAG) do
			v.Transparency = 1
		end

		for _, v in CollectionService:GetTagged(PLAYER_SPAWN_TAG) do
			v.Transparency = 1
		end
	end)
end

for _,group in ipairs(Services:GetChildren()) do
	if group.Name == "READ_ME" then continue end
	print("**-**" .. group.Name .. "**-**")

	for _,module in ipairs(group:GetChildren()) do
		if not module:IsA("ModuleScript") then continue end
		local service = require(module)
		print(module.Name)
		if not service.Client then continue end

		-- Wrap .Client functions so Players can call them
		local COMM = service.Client.COMM
		for name,var in pairs(service.Client) do
			if type(var) == "function" then
				COMM:WrapMethod(service.Client, name)
			end
		end

		-- if module.Name == "RoundService" then
		-- 	task.spawn(function()
		-- 		service:Init()
		-- 	end)
		-- end
	end
end

--------------- FOR TESTING ----------------

-- local ItemService = require(ServerScriptService.Services.Data.ItemService)

-- task.wait(3)

-- for plr,replica in pairs(ItemService.PlayerReplicas) do
-- 	ItemService:AddItems(plr, {
-- 		["Hammer_B"] = 50
-- 	})
-- 	ItemService.Client:RequestMerge(plr, "Hammer_B")
-- 	print(replica.Data)
-- 	ItemService:AddItems(plr, {
-- 		["Hammer_B"] = 49,
-- 	})
-- 	ItemService.Client:RequestMerge(plr, "Hammer_B")
-- 	print(replica.Data)
-- end