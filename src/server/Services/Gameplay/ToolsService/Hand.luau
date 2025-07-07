local Hand = {}
Hand.__index = Hand

function Hand.new()
	local newHand = setmetatable({}, Hand)

	newHand.Model = "" -- Location of the handmodel to clone


	return
end


function Hand:DoSomething()

end

return Hand