----- GLOBALS -----

----- Libraries and Services -----

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerComm = require(ReplicatedStorage.Packages.Comm).ServerComm
local CommFolder = ReplicatedStorage.Comms

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicaServer = require(ServerScriptService.Libraries.ReplicaServer)

local UpgradeTypes = {
	_B = "_G", -- Base to Gold
	_G = "_D", -- Gold to Diamond
	_D = "_R", -- Diamond to Rainbow
	_R = "_V", -- Rainbow to Void
	_V = "None" -- Void has no upgrade
}

----- Variables -----

local COMM = ServerComm.new(CommFolder, "ItemService")

local QUANTITY_FOR_MERGE = 50

local ItemService = {
	Token = ReplicaServer.Token("ItemData"),

	PlayerReplicas = {},

	Client = {
		COMM = COMM
	}
}
ItemService.Client.Server = ItemService

----- Server Functions -----

function ItemService:AddItems(plr: Player, list: {string: number})
	local replica = self.PlayerReplicas[plr]
	if not replica then return end

	-- Loops through all the items that the player rolled and adds them to their item list
	for itemIndex, count in pairs(list) do
		print("Giving " .. plr.DisplayName .. " " .. count .. " " .. itemIndex)
		local old_value = replica.Data.Inventory[itemIndex] or 0
		replica:Set({"Inventory", itemIndex}, old_value + count)
	end
end

function ItemService:RemoveItems(plr: Player, list: {string: number})
	local replica = self.PlayerReplicas[plr]
	if not replica then return end

	-- Loops through all the items that the player rolled and removes the specified amount
	for itemIndex, count in pairs(list) do
		print("Taking away " .. count .. " " .. itemIndex .. " from " .. plr.DisplayName)
		local old_value = replica.Data.Inventory[itemIndex]
		replica:Set({"Inventory", itemIndex}, old_value - count)
	end
end

function ItemService:_AddPlayerReplica(plr: Player, replica)
	self.PlayerReplicas[plr] = replica
end

----- Client Functions -----

-- Give the Player an Upgraded version of an Item if they have enough if said Item in their inventory
function ItemService.Client:RequestMerge(plr: Player, itemIndex: string)
	assert(type(itemIndex) == "string", string.format("RequestMerge takes in a string, got: %s", type(itemIndex)))

	local fromType = string.match(itemIndex, "_[BGDRV]") -- Pattern Match if _B, _G, _D, _R, or _V are in the string
	local toType = UpgradeTypes[fromType] -- Set the upgraded pattern

	local replica = self.Server.PlayerReplicas[plr]
	local indexCount = replica.Data.Inventory[itemIndex]

	print("Attempting to merge " .. itemIndex .. " for " .. plr.DisplayName)

	-- Check if they have an indexCount for the item they are merging or enough of the item to merge
	if not indexCount or indexCount < QUANTITY_FOR_MERGE then return false end

	local mergeCount = 0 -- How many of the upgraded items will be given

	-- Merge as many times as you can
	while indexCount >= QUANTITY_FOR_MERGE do
		mergeCount += 1
		indexCount -= QUANTITY_FOR_MERGE
	end

	self.Server:RemoveItems(plr, {
		[itemIndex] = mergeCount * 50
	})

	---- Add the upgraded item

	-- Replace the fromType pattern with the upgraded toType pattern to get the upgraded version of the item
	local newItemIndex = string.gsub(itemIndex, fromType, toType)

	self.Server:AddItems(plr, {
		[newItemIndex] = mergeCount
	})

	return true
end

return ItemService