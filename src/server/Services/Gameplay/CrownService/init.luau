--local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CROWN_MODEL = game.ReplicatedStorage:WaitForChild("Models"):WaitForChild("Crown")

local CrownService = {
	CrownList = {}
}

local Crown = {}
Crown.__index = Crown

function Crown.new(spawnPart: Part)
	local newCrown = setmetatable({}, Crown)

	newCrown.Model = CROWN_MODEL:Clone()
		newCrown.Model:PivotTo(CFrame.new(spawnPart.CFrame.Position))
		newCrown.Model.Parent = Workspace

	newCrown.PlayerWeld = Instance.new("WeldConstraint")
		newCrown.PlayerWeld.Parent = newCrown.Model.PrimaryPart
		newCrown.PlayerWeld.Part0 = newCrown.Model.PrimaryPart
		newCrown.Model.PrimaryPart:ApplyImpulse(Vector3.new())

	newCrown.AlignOrientation = newCrown.Model.PrimaryPart.StayVert :: AlignOrientation
	newCrown.Touched = newCrown.Model.PrimaryPart.Touched

	newCrown.PlayerHighlight = newCrown.Model.Highlight:Clone() :: Highlight

	newCrown.Owner = false
	newCrown.IsPickingUp = false
	newCrown.IsDropping = false

	table.insert(CrownService.CrownList, newCrown)
	return newCrown
end

-- Welds the crown to the 
function Crown:Pickup(chr: Model)
	-- If the crown is currently being picked up
	if self.IsPickingUp then
		return false
	end
	self.IsPickingUp = true

	-- If the crown already has an owner then -- If the character that is picking up the crown already has one -- If the crown is currently in launch
	if (self.Owner) or (CrownService.HasCrown(chr)) or (self.IsDropping) then 
		self.IsPickingUp = false
		return false
	end

	self.Owner = chr
	
	self.Owner.Humanoid.WalkSpeed = 32
	self.PlayerHighlight.Parent = chr

	local hrp = chr:WaitForChild("HumanoidRootPart") :: Part

	-- turn off the align orientation
	self.AlignOrientation.Enabled = false

	-- Move the crown to the current owner's head
	self.Model.PrimaryPart.CanCollide = false
	self.Model.PrimaryPart.Anchored = false
	self.Model.PrimaryPart.Massless = true

	self.Model:PivotTo(hrp.CFrame + Vector3.new(0, 4, 0))

	-- Weld the crown to the current owner
	self.PlayerWeld.Part1 = hrp

	self.IsPickingUp = false

	return true
end

function Crown:Drop()
	if self.IsDropping then
		return
	end
	self.IsDropping = true

	if (not self.Owner) or (self.IsPickingUp) then
		self.IsDropping = false
		return
	end

	self.Owner.Humanoid.WalkSpeed = 42
	self.PlayerHighlight.Parent = nil

	self.PlayerWeld.Part1 = nil

	self.Model.PrimaryPart.CanCollide = true
	self.Model.PrimaryPart.Massless = true
	self.AlignOrientation.Enabled = true

	local xDir = if math.random(1, 2) == 1 then 1 else -1
	local zDir = if math.random(1, 2) == 1 then 1 else -1
	local impulseVec = Vector3.new(math.random(50, 75)/100 * 6000 * xDir, 3500, math.random(50, 75)/100 * 6000 * zDir)
	self.Model.PrimaryPart:ApplyImpulse(impulseVec)

	self.Owner = false
	task.spawn(function()
		task.wait(1)
		self.IsDropping = false
	end)
end

function Crown:Destroy()
	if self.Owner then
		self.Owner.Humanoid.WalkSpeed = 42
	end
	self.Model:Destroy()
	self.PlayerHighlight:Destroy()
	self = nil
end



function CrownService.LoadCrowns(spawnFolder: Folder, spawnCount: number)
	local spawnLocations = spawnFolder:GetChildren()

	local randomizedLocations = {}
	for i = 1,spawnCount,1 do
		local selectedIndex = math.random(1, #spawnLocations)
		-- Add the selected spawn location to the randomLocations table
		table.insert(randomizedLocations, spawnLocations[selectedIndex])
		-- Remove the selected spawn location from the remaining locations available
		table.remove(spawnLocations, selectedIndex)
	end

	-- Setup the crowns at the randomized locations
	local crowns = {}
	for _,spawnPart in randomizedLocations do
		table.insert(crowns, Crown.new(spawnPart))
	end

	return crowns
end

function CrownService.CleanupCrowns()
	for _, crown in CrownService.CrownList do
		crown:Destroy()
	end
	
	CrownService.CrownList = {}
end

-- Returns the crown the character currently owns
function CrownService.HasCrown(chr)
	for _, crown in CrownService.CrownList do
		if crown.Owner == chr then return crown end
	end

	return false
end

return CrownService