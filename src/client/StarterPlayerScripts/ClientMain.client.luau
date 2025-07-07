-- Load Controllers
local ReplicaClient = require(game.ReplicatedStorage.ReplicaClient)
local Controllers = script.Parent:WaitForChild("Controllers")

for _, module in ipairs(Controllers:GetChildren()) do
	print(module.Name)
	require(module)
end

print("HERE")
ReplicaClient.RequestData()
print("Here")