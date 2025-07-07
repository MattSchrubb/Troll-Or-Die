local Players = game:GetService("Players")
local LOCAL_PLAYER = Players.LocalPlayer
local RoundGui = LOCAL_PLAYER.PlayerGui:WaitForChild("RoundGui")
local roundTextLabel = RoundGui.TimerContainer.RoundText :: TextLabel
local timerTextLabel = RoundGui.TimerContainer.Timer :: TextLabel


local GetService = require(game.ReplicatedStorage.GetService)
local RoundService = GetService("RoundService")


local Timer = RoundService.Timer
local State = RoundService.State

-- Awaiting | Voting | PreRound | InProgress | PostRound
local RoundStates = {
	["Awaiting"] = "Waiting For Players",
	["Voting"] = "PLACE YOUR BETS!!",
	["PreRound"] = "Round Starts In:",
	["InProgress"] = "TROLL OR DIE!!!!!",
	["PostRound"] = "STOP FIGHTING!!!!!!!!"
}


Timer:Observe(function(newValue)
	timerTextLabel.Text = math.abs(math.ceil(newValue))
end)

State:Observe(function(newValue)
	roundTextLabel.Text = RoundStates[newValue]
end)

RoundService:JoinQueue()

local WinnerMenu = RoundGui:WaitForChild("WinnerMenu")
local ScrollingFrame = WinnerMenu:WaitForChild("ScrollingFrame")
local PlayercardTemplate = ScrollingFrame:WaitForChild("Player")



RoundService.Winners:Observe(function(winnersList)
	if not winnersList or #winnersList < 1 then return end

	task.spawn(function()
		print(winnersList)
		local cards = {}

		for index, plr: Player in winnersList do
			local newCard = PlayercardTemplate:Clone()
			newCard.PlayerName.Text = plr.DisplayName
			newCard.Place.Text = index
			newCard.PlayerImg.Image =
				Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

			newCard.Parent = ScrollingFrame
			newCard.Visible = true
			table.insert(cards, newCard)
		end

		WinnerMenu.Visible = true
		task.wait(5)
		WinnerMenu.Visible = false
	
		for _, card in cards do
			card:Destroy()
		end
	end)
end)

return {}