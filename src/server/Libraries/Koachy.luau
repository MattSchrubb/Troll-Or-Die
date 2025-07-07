local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ServerScriptService.Services
local ServerComm = require(ReplicatedStorage.Packages.Comm).ServerComm

local commFolder = ReplicatedStorage.Comms

local Koachy = {
	ServiceComms = {}
}

type SIGNAL = {type: "Signal"}
local SIGNAL_TYPE: SIGNAL = {type = "Signal"}

type PROPERTY = typeof(ServerComm:CreateProperty())


function Koachy.CreateService(serviceTbl)
	if serviceTbl.Client ~= nil then
		
	end

	return serviceTbl
end

function Koachy.CreateSignal()
	return SIGNAL_TYPE
end

function Koachy.CreateProperty(val)
	return {type = "Property", value = val}:: PROPERTY
end



function Koachy.Init()
	for _,group in ipairs(Services:GetChildren()) do
		if group.Name == "READ_ME" then continue end
		print("**-**" .. group.Name .. "**-**")
		for _,module in ipairs(group:GetChildren()) do
			if not module:IsA("ModuleScript") then continue end
			local service = require(module)
			print(module.Name)
			if not service.Client then continue end
	
			-- Wrap .Client functions so Players can call them
			local Comm = ServerComm.new(commFolder, module.Name)
			for name,var in pairs(service.Client) do
				if type(var) == "function" then
					Comm:WrapMethod(service.Client, name)
				elseif true then
				end
			end
	
			service.Client.Comm = Comm
		end
	end
end

return Koachy