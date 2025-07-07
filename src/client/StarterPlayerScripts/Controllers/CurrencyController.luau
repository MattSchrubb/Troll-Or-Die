local GetService = require(game.ReplicatedStorage.GetService)
local CurrencyService = GetService("CurrencyService")

local ReplicaClient = require(game.ReplicatedStorage.ReplicaClient)

ReplicaClient.OnNew("CurrencyData", function(replica)
	print(replica.Data)

	replica:OnSet({"Tix"}, function(new_val, old_val)
		print("Tix: " .. old_val .. " -> " .. new_val)
	end)
end)


--print(CurrencyService.Property1:Get())


CurrencyService:DoSomething() -- Returns whatever

return {}