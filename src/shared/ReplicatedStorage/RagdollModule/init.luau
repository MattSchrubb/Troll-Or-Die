local module = {}


local TimerModule = require(game.ReplicatedStorage.Timer)


local Players = game:GetService("Players")

local remote = script:WaitForChild("Ragdoll")


local CurrentRagdolls = {} -- {timer = Timer.new, ...}

-- Pass duration if you want the module to unragdoll after the duration passes
function module.Ragdoll(char: Model, duration: number?)
	if CurrentRagdolls[char] then
		if CurrentRagdolls[char].timer then
			CurrentRagdolls[char].timer:Restart()
		end

		return
	end

	CurrentRagdolls[char] = {}

	-- Check if a duration was specified and setup a timer
	if duration then
		local timer = TimerModule.new({
			duration = duration
		})

		timer.SecondPassed:Connect(function()
			print(timer:GetSecondsLeft())
		end)
		timer.Started:Connect(function()
			print(timer:GetSecondsLeft())
		end)

		timer.Completed:Connect(function()
			module.Unragdoll(char)
		end)

		CurrentRagdolls[char].timer = timer

		timer:Start()
		
	end

	-- Check if the character is destroyed before the timer finishes
	char.Destroying:Connect(function()
		if CurrentRagdolls[char].timer then
			CurrentRagdolls[char].timer:Destroy()
		end
		CurrentRagdolls[char] = nil
	end)

	local plr = Players:GetPlayerFromCharacter(char)
	if plr then
		remote:FireClient(plr, nil, "manualM")
	else
		local humanoid: Humanoid = char:WaitForChild("Humanoid") :: Humanoid
		humanoid.BreakJointsOnDeath = false
		humanoid.PlatformStand = true
	end

	

	for index, joint in pairs(char:GetDescendants()) do
		if joint:IsA("Motor6D") then
			if joint:FindFirstAncestorOfClass("Tool") then -- Make sure not to unweld the tool
				continue
			end

			local socket = Instance.new("BallSocketConstraint")
			local a1 = Instance.new("Attachment")
			local a2 = Instance.new("Attachment")
			a1.Parent = joint.Part0
			a2.Parent = joint.Part1
			socket.Parent = joint.Parent
			
			socket.Attachment0 = a1
			socket.Attachment1 = a2
			a1.CFrame = joint.C0
			a2.CFrame = joint.C1
			socket.LimitsEnabled = true
			
			if joint.Name == "Root" then
				socket:Destroy()
				local hinge = Instance.new("HingeConstraint")
				hinge.Parent = joint.Parent
				hinge.Attachment0 = a1
				hinge.Attachment1 = a2
				hinge.LimitsEnabled = true
			end

			if joint.Name == "Neck" then
				socket:Destroy()
				local hinge = Instance.new("HingeConstraint")
				hinge.Parent = joint.Parent
				hinge.Attachment0 = a1
				hinge.Attachment1 = a2
				hinge.LimitsEnabled = true
			end
			socket.TwistLimitsEnabled = true
			joint.Enabled = false
		end
	end

	return CurrentRagdolls[char]
end

function module.Unragdoll(char: Model) -- again, the character
	if CurrentRagdolls[char].timer then
		CurrentRagdolls[char].timer:Destroy()
	end
	CurrentRagdolls[char] = nil

	for index, joint in pairs(char:GetDescendants()) do
		if joint:IsA("Motor6D") then
			if joint:FindFirstAncestorOfClass("Tool") then 	
				continue
			end

			local socket = joint.Parent:FindFirstChild("BallSocketConstraint")
				or joint.Parent:FindFirstChild("HingeConstraint")
			local a1 = joint.Part0:FindFirstChild("Attachment")
			local a2 = joint.Part1:FindFirstChild("Attachment")
			socket:Destroy()
			a1:Destroy()
			a2:Destroy()
			joint.Enabled = true
		end
	end

	local plr = Players:GetPlayerFromCharacter(char)
	if plr then
		remote:FireClient(plr, nil, "manualD")
	else
		local humanoid: Humanoid = char and char:WaitForChild("Humanoid") :: Humanoid
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

return module
-- fr fr, forum: "https://devforum.roblox.com/t/emilios-ragdoll-module-easy-ahh-ragdolls-r15-and-r6/2865426"
