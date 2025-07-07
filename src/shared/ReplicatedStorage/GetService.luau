local Packages = script.Parent.Packages
local ClientComm = require(Packages.Comm).ClientComm

local commFolder = script.Parent.Comms

local cachedServices = {}

-- Function that creates a new ClientComm object that connects to the specified Service
-- Allows Client modules to access Client functions and data from Server Services
return function(serviceName: string)
	if cachedServices[serviceName] then return cachedServices[serviceName] end

	local clientComm = ClientComm.new(commFolder, false, serviceName)

	local service = clientComm:BuildObject()
	cachedServices[serviceName] = service

	return service
end