local Players = game:GetService("Players")
local CrownService = require(script.Parent.Parent.CrownService)
local WeaponStorage = game:GetService("ReplicatedStorage"):WaitForChild("Weapons")

local TestMode = {
	InProgress = false,
	TimerConnection = nil,
	CompletedCallback = nil
}

local SPAWN_COUNTS = { -- Index refers to the number of players
	0, -- 1 Player
	1, -- 2 Players
	1, -- 3 Players
	1, -- 4 Players
	1, -- 5 Players
	2, -- 6 Players
	2, -- 7 Players
	2, -- 8 Players
	2, -- 9 Players
	2, -- 10 Players
	2, -- 11 Players
	3, -- 12 Players
	3, -- 13 Players
	3, -- 14 Players
	3, -- 15 Players
	3, -- 16 Players
	3, -- 17 Players
	4, -- 18 Players
	4, -- 19 Players
	4, -- 20 Players
}

local CurrentCrowns = {}
local CharactersInGame = {}
local PlayerList = {}
local PlayerWeapons = {}

function TestMode:SetupCrownFunctionality()
	for _, crown in CurrentCrowns do
		crown.Touched:Connect(function(part)
			local chr = part.Parent
			local plr = Players:GetPlayerFromCharacter(chr)

			if not plr then
				return
			end
			if not CharactersInGame[chr] then
				return
			end

			crown:Pickup(chr)
			
			-- task.wait(5) -- Test launching the crown
			-- self:HitPlayer(plr)
		end)
	end
end

function TestMode:HitPlayer(plr: Player)
	-- Check if the player is in game and has a crown
	local chr = plr.Character

	if not chr then
		return
	end
	if not CharactersInGame[chr] then
		return
	end

	local crown = CrownService.HasCrown(chr)
	if crown then
		crown:Drop()
	end
end


function TestMode:RemoveCharacter(chr)
	if not CharactersInGame[chr] then return end

	local crown = CrownService.HasCrown(chr)
	if crown then
		crown:Drop()
	end

	CharactersInGame[chr].HumDied:Disconnect()
	CharactersInGame[chr].ChrRemove:Disconnect()
	CharactersInGame[chr] = nil

	local count = 0
	local hasCrownCount = 0
	for _chr,_ in CharactersInGame do
		count += 1
		if CrownService.HasCrown(_chr) then
			hasCrownCount += 1
		end
	end
	-- Check if only one player remains
	if count < 2 then
		self.CompletedCallback()
		return
	end

	-- Check if the remaining players have crowns
	if hasCrownCount < count then
		return
	end
	self.CompletedCallback()
end


function TestMode:SpawnPlayers(playerList, _spawnsFolder)
	local spawns = _spawnsFolder:GetChildren()
	PlayerList = playerList
	
	for _, plr: Player in playerList do
		local chr = plr.Character
		if not chr then
			continue
		end

		local spawnPartIndex = math.random(1, #spawns)
		local currentSpawnPart: Part = spawns[spawnPartIndex]
		table.remove(spawns, spawnPartIndex)

		local hrp = chr:FindFirstChild("HumanoidRootPart")
		local hum = chr:FindFirstChild("Humanoid")
		hrp.Anchored = true
		chr:PivotTo(currentSpawnPart.CFrame)

		-- Setup character info for the players in game
		CharactersInGame[chr] = {
			HRP = hrp,
			Humanoid = hum,
			HumDied = hum.Died:Connect(function()
				self:RemoveCharacter(chr)
			end),

			Plr = plr,
			ChrRemove = plr.CharacterRemoving:Connect(function()
				self:RemoveCharacter(chr)
			end)
		}

		-- TESTING ONLY, FIX LATER
		local SmackWeapon = WeaponStorage:WaitForChild("Smack")
		local newWeapon = SmackWeapon:Clone()

		table.insert(PlayerWeapons, newWeapon)
		newWeapon.Parent = plr.Backpack
	end
end

function TestMode:DoDamage()
	for chr,chrInfo in CharactersInGame do
		if CrownService.HasCrown(chr) then continue end

		chrInfo.Humanoid:TakeDamage(2)
	end
end

function TestMode:StartRound(timer)
	-- Check if there's enough players still
	if #PlayerList < 2 then
		self.CompletedCallback()
		return
	end

	print(PlayerList)

	for _, info in CharactersInGame do
		info.HRP.Anchored = false
	end

	if not self.TimerConnection then
		self.TimerConnection = timer.SecondPassed:Connect(function()
			self:DoDamage()
		end) :: RBXScriptConnection
	end

	self.InProgress = true
end

function TestMode:Init(props)
	CurrentCrowns = CrownService.LoadCrowns(props.ModeFolder:WaitForChild("CrownSpawns"), SPAWN_COUNTS[if #props.PlayerList > 20 then 20 else #props.PlayerList])
	self:SetupCrownFunctionality()
	self.CompletedCallback = props.CompletedCallback

	self:SpawnPlayers(props.PlayerList, props.ModeFolder:WaitForChild("PlayerSpawns"))
end

function TestMode:Cleanup()
	self.InProgress = false
	if self.TimerConnection then
		self.TimerConnection:Disconnect()
		self.TimerConnection = nil
	end

	for _, crown in CurrentCrowns do
		--task.spawn(function()
		crown:Destroy()
		--end)
	end

	for _, weapon in PlayerWeapons do
		weapon:Destroy()
	end

	local Winners = {}

	for _, chrInfo in CharactersInGame do
		table.insert(Winners, chrInfo.Plr)

		chrInfo.HumDied:Disconnect()
		chrInfo.ChrRemove:Disconnect()
		chrInfo.Plr:LoadCharacter()
	end

	CurrentCrowns = {}
	CharactersInGame = {}
	PlayerList = {}

	return Winners
end

return TestMode
