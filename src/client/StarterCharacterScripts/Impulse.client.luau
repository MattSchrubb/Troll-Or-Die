local remote = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Impulse")
local chr = script.Parent
local hrp = chr:WaitForChild("HumanoidRootPart")

remote.OnClientEvent:Connect(function(dir: Vector3, ang: Vector3?)
	hrp:ApplyImpulse(dir)
	if ang then
		hrp:ApplyAngularImpulse(ang)
	end
end)