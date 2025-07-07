local camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local char = plr.Character
local head: Part = char:WaitForChild("Head")
local hum: Humanoid = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

local noCamShake = true -- R6 specifik!!
local antiMove = true -- enable this if ragdoll is weird

-- put me in StarterPlayer.StarterCharacterScripts

local remote = game.ReplicatedStorage.RagdollModule.Ragdoll

local function focus(arg)
	if arg == "Focus" then
		if noCamShake then
			camera.CameraSubject = head
			hrp.CanCollide = false
		end
	elseif arg == "Unfocus" then
		if noCamShake then
			camera.CameraSubject = hum
			hrp.CanCollide = true
		end
	end
end
local function noMove(arg)
	if arg == "Stop" then
		if antiMove then
			hum.WalkSpeed = 0
			hum.PlatformStand = true
		end
	elseif arg == "Aan" then
		if antiMove then
			hum.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed
			hum.JumpHeight = game.StarterPlayer.CharacterJumpHeight
			hum.JumpPower = game.StarterPlayer.CharacterJumpPower
			hum.PlatformStand = false
		end
	end
end

remote.OnClientEvent:Connect(function(arg, sec)
	if hum then
		if arg == "Make" then
			print("RAGDOLLING")
			hum:ChangeState(Enum.HumanoidStateType.Physics) -- in ragdoll
			focus("Focus")
			noMove("Stop")
		elseif arg == "Destroy" then
			print("getting UP")
			hum:ChangeState(Enum.HumanoidStateType.GettingUp) -- out of ragdoll
			focus("Unfocus")
			noMove("Aan")
		end
		if arg == nil then
			if sec == "manualM" then
				print("ragdolling")
				hum:ChangeState(Enum.HumanoidStateType.Physics) -- in ragdoll
				focus("Focus")
				noMove("Stop")
			end
		end
		if arg == nil then
			if sec == "manualD" then
				print("Getting up")
				hum:ChangeState(Enum.HumanoidStateType.GettingUp) -- out of ragdoll
				focus("Unfocus")
				noMove("Aan")
			end
		end
	end
end)
