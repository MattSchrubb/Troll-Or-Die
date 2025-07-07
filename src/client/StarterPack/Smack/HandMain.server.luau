local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local GameModeService = require(ServerScriptService.Services.Gameplay.GameModeService)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitboxClass = require(ReplicatedStorage.HitboxClass)
local HitboxTypes = require(ReplicatedStorage.HitboxClass.Types)

local ImpulseRemote = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Impulse")

local RagdollModule = require(game.ReplicatedStorage.RagdollModule)

local tool = script.Parent
local HitVFX: Attachment = tool:WaitForChild("HitVFX")

local COOLDOWN = .25
local RAGDOLL_DURATION = 1.5
local HITBOX_LIFETIME = 0.25

local activatedTick = tick() - COOLDOWN

local LocalPlayer
local hitboxParams
local currentCharacter
local currentHRP
local currentHum
local currentAnimator
local currentTrack

local swingAnim = Instance.new("Animation")
swingAnim.AnimationId = "rbxassetid://75181931062567"

local DongPlayer: AudioPlayer = tool.AudioPlayer
local WooshPlayer: AudioPlayer = tool.Woosh

local function doHit(chr)
	local _ = RagdollModule.Ragdoll(chr, RAGDOLL_DURATION)

	local LookVector = currentHRP.CFrame.LookVector
	local impulseVec = Vector3.new(LookVector.X * 1500, 1000, LookVector.Z * 1500)

	local plr = Players:GetPlayerFromCharacter(chr)
	if not plr then -- If it's an NPC
		local hrp = chr:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		
		local CounterEvent: BindableEvent = chr.SmackCounter.CounterEvent
		CounterEvent:Fire()

		hrp:ApplyImpulse(impulseVec)
		hrp:ApplyAngularImpulse(Vector3.new(math.random(50, 100), math.random(50, 100), math.random(50, 100)))
	else
		task.spawn(function()
			GameModeService:HitPlayer(plr)
		end)

		ImpulseRemote:FireClient(
			plr,
			impulseVec,
			Vector3.new(math.random(50, 100), math.random(50, 100), math.random(50, 100))
		)
	end

	local newAudio = DongPlayer:Clone()
	newAudio.Parent = tool
	newAudio.Ended:Connect(function()
		newAudio:Destroy()
	end)
	newAudio.PlaybackSpeed = math.random(475, 500)/100
	newAudio:Play()

	task.spawn(function()
		local vfx = HitVFX:Clone()
		vfx.Parent = chr:WaitForChild("HumanoidRootPart")
		for _, emitter in vfx:GetChildren() do
			emitter:Emit(2)
		end

		task.wait(.3)
		vfx:Destroy()
	end)
end

-- task.spawn(function()
-- 	task.wait(5)
-- 	doHit(tool.Parent)
-- end)

tool.Equipped:Connect(function()
	currentCharacter = tool.Parent
	LocalPlayer = Players:GetPlayerFromCharacter(currentCharacter)

	currentHum = currentCharacter:WaitForChild("Humanoid")
	currentAnimator = currentHum:WaitForChild("Animator")
	currentTrack = currentAnimator:LoadAnimation(swingAnim)

	currentHRP = currentCharacter:WaitForChild("HumanoidRootPart")

	hitboxParams = {
		SizeOrPart = Vector3.new(7, 10, 7),
		DebounceTime = 1.1,
		Blacklist = { currentCharacter },
		Debug = false,
		--UseClient = Players:GetPlayerFromCharacter(tool.Parent),
	} :: HitboxTypes.HitboxParams
end)

tool.Activated:Connect(function()
	if not LocalPlayer then
		return
	end

	if tick() - activatedTick < COOLDOWN then
		return
	end

	activatedTick = tick()

	local newAudio = WooshPlayer:Clone()
	newAudio.Parent = tool
	newAudio.Ended:Connect(function()
		newAudio:Destroy()
	end)
	newAudio:Play()

	task.spawn(function()
		local hitbox = HitboxClass.new(hitboxParams)

		hitbox.HitSomeone:Connect(function(hits)
			--print(hits)
			for _, hitChar in ipairs(hits) do
				task.spawn(function()
					doHit(hitChar)
				end)
			end
		end)
		hitbox:WeldTo(currentHRP, CFrame.new(Vector3.new(1, 0, -5)))
		hitbox:Start()

		task.wait(HITBOX_LIFETIME)

		hitbox:Stop()
	end)
	currentTrack:Play()
	--activateRemote:FireClient(LocalPlayer)
end)

-- local activationDebounce = false

-- tool.Activated:Connect(function()
-- 	if (not currentCharacter) or (not currentHRP) then return end

-- 	if activationDebounce then return end

-- 	hitbox:WeldTo(currentHRP, CFrame.new(Vector3.new(1, 0, -5)))

-- 	activationDebounce = true
-- 	hitbox:Start()

-- 	task.wait(.25)

-- 	hitbox:Stop()
-- 	activationDebounce = false
-- end)
