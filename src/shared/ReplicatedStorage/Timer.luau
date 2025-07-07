local RS = game:GetService("RunService")
local Heartbeat = RS.Heartbeat

type DefaultProperties = {
	duration: number?,
	timerSpeed: number?,
	looped: boolean?
}

type state = "Running" | "Paused" | "Stopped" | "Completed" | "Destroyed"

export type Timer = {
	Started: RBXScriptSignal,
	Stopped: RBXScriptSignal,

	Paused: RBXScriptSignal,
	Resumed: RBXScriptSignal,

	Completed: RBXScriptSignal,
	Restarted: RBXScriptSignal,

	Tick: RBXScriptSignal,
	SecondPassed: RBXScriptSignal,

	Start: (self: Timer, dontFireEvent: boolean?) -> (),
	Stop: (self: Timer, dontFireEvent: boolean?) -> (),

	Pause: (self: Timer, dontFireEvent: boolean?) -> (),
	Resume: (self: Timer, dontFireEvent: boolean?) -> (),

	Restart: (self: Timer, dontFireEvent: boolean?) -> (),

	SetTimerSpeed: (self: Timer, speed: number) -> (),
	IncrementTimerSpeed: (self: Timer, amount: number) -> (),

	SetDuration: (self: Timer, duration: number) -> (),
	IncrementDuration: (self: Timer, amount: number) -> (),

	FastForward: (self: Timer, duration: number) -> (),
	Rewind: (self: Timer, duration: number) -> (),

	SetLooped: (self: Timer, looped: boolean) -> (),

	IsRunning: (self: Timer) -> boolean,

	GetState: (self: Timer) -> state,

	GetTimeLeft: (self: Timer) -> number,
	GetSecondsLeft: (self: Timer) -> number,
	GetMinutesLeft: (self: Timer) -> number,
	GetHoursLeft: (self: Timer) -> number,

	GetFormattedTimeLeft: (self: Timer, useMiliseconds: boolean?) -> string,

	Destroy: (self: Timer) -> (),

	new: (props:DefaultProperties?) -> Timer
}

type DevTimer = {
	_running: boolean,
	_state: state,

	_willResume: boolean,
	_localResumedEvent: BindableEvent,

	_duration: number,
	_timeLeft: number,
	_previousSecond: number,

	_timerSpeed: number,
	_looped: boolean,

	_timerCoroutine: typeof(coroutine.create(function() end)),

	_startedEvent: BindableEvent,
	_stoppedEvent: BindableEvent,

	_pausedEvent: BindableEvent,
	_resumedEvent: BindableEvent,

	_completedEvent: BindableEvent,
	_restartedEvent: BindableEvent,

	_tickEvent: BindableEvent,
	_secondPassed: BindableEvent,
	[any]: any
} & Timer

local DefaultProperties: DefaultProperties = {
	duration = 10,
	timerSpeed = 1,
	looped = false,
}

local Timer: DevTimer = {} :: DevTimer
Timer.__index = Timer

function Timer.new(props: DefaultProperties?): Timer
	local timer = setmetatable({}, Timer)

	----- Private Properties -----

	timer._startedEvent = Instance.new("BindableEvent")
	timer._stoppedEvent = Instance.new("BindableEvent")
	
	timer._pausedEvent = Instance.new("BindableEvent")
	timer._resumedEvent = Instance.new("BindableEvent")

	timer._localResumedEvent = Instance.new("BindableEvent") -- This is used interanlly for its :Wait() function
	
	timer._completedEvent = Instance.new("BindableEvent")
	timer._restartedEvent = Instance.new("BindableEvent")

	timer._tickEvent = Instance.new("BindableEvent")
	timer._secondPassedEvent = Instance.new("BindableEvent")

	timer._state = "Stopped" -- Running, Paused, Completed, Stopped, or Destroyed

	timer._willResume = false
	
	timer._duration = if props and props.duration then props.duration else DefaultProperties.duration -- Default duration of a Timer
	timer._timeLeft = if props and props.duration then props.duration else DefaultProperties.duration -- Timer remaining, can cout up or down
	timer._previousSecond = if props and props.duration then props.duration else DefaultProperties.duration -- Used for SecondPassed

	timer._timerSpeed = if props and props.timerSpeed then props.timerSpeed else DefaultProperties.timerSpeed -- Negative means counting up, Positive means counting down

	timer._looped = if props and props.looped ~= nil then props.looped else DefaultProperties.looped

	timer._timerCoroutine = nil

	----- Public Properties -----

	timer.Started = timer._startedEvent.Event
	timer.Stopped = timer._stoppedEvent.Event

	timer.Paused = timer._pausedEvent.Event
	timer.Resumed = timer._resumedEvent.Event

	timer.Completed = timer._completedEvent.Event
	timer.Restarted = timer._restartedEvent.Event

	timer.Tick = timer._tickEvent.Event
	timer.SecondPassed = timer._secondPassedEvent.Event

	timer.Completed:Connect(function()
		if timer._looped and timer._state == "Completed" then
			timer:Start()
		end
	end)

	return timer :: Timer
end

function Timer:Start(dontFireEvent: boolean?)
	if (self._state ~= "Destroyed") and (self._state == "Stopped" or self._state == "Completed") then -- The timer has either been forced to stop or has fully completed so we will create a new coroutine
		
		self._timerCoroutine = coroutine.create(function()
			
			self._state = "Running" -- Change state to Running

			-- Restore to default values
			self._timeLeft = self._duration
			self._previousSecond = self._duration

			-- Fire the tick event for the initial value to be delivered
			self._tickEvent:Fire()

			local previousTick = tick()

			-- While Running or Paused, and while there's time left or the timer is counting up
			while (self._state ~= "Destroyed" and self._state ~= "Stopped" and self._state ~= "Completed") and (self._timeLeft > 0 or self._timerSpeed < 0) do
				--local deltaTime: number
				local currentTick: number

				if self._state == "Paused" then -- Check if the timer is Paused
					if not self._willResume then -- Check if the timer wanted to resume in the same Heartbeat
						self._localResumedEvent.Event:Wait() -- Otherwise, wait for it to be resumed
						self._willResume = false
					end

					-- reset the previous tick
					previousTick = tick()
				end

				--***-- This is where the big magic happens --***--
				Heartbeat:Wait() --deltaTime = Heartbeat:Wait()
				
				currentTick = tick()

				if self._state == "Destroyed" or self._state == "Stopped" or self._state == "Completed" then -- Check if the timer state changed somehow
					break
				end
				--currentTick -= (previousTick + deltaTime) - currentTick -- Secret sauce to make the timer super accurate

				-- Reduce (or increase based on timerSpeed) the time left
				self._timeLeft -= (currentTick - previousTick) * self._timerSpeed
				self._tickEvent:Fire() -- Tell the whole world we ticking

				-- Check for when a second passes in either direction
				task.spawn(function()
					if self._timerSpeed < 0 then
						if math.floor(self._timeLeft) - self._previousSecond >= 1 then
							self._previousSecond = math.floor(self._timeLeft)
							self._secondPassedEvent:Fire(self._timeLeft)
						end
					elseif self._timerSpeed > 0 then -- Counting down
						if self._previousSecond - math.ceil(self._timeLeft) >= 1 then -- If the last checked number - ceil(current time left) >= 1
							self._previousSecond = math.ceil(self._timeLeft)
							self._secondPassedEvent:Fire(self._timeLeft)
						end
					end
				end)

				previousTick = tick()
			end

			if self._state == "Destroyed" then
				return
			end

			--***-- When the timer breaks out of the loop, usually when it is stopped or completes --***--
			if self._state ~= "Stopped" then -- Check if the timer was not stopped, which means it completed
				self._state = "Completed"
				self._completedEvent:Fire()
			end
		end)

		-- Start the timer coroutine and let the whole world know
		coroutine.resume(self._timerCoroutine)
		self._startedEvent:Fire()
	elseif self._state == "Paused" then
		self:Resume(dontFireEvent)
	else
		warn("Cannot start timer that is already running!!!")
	end
end

function Timer:Stop(dontFireEvent: boolean?)
	if self._state == "Stopped" or self._state == "Completed" then return end

	self._state = "Stopped"
	coroutine.close(self._timerCoroutine)

	if not dontFireEvent then
		self._stoppedEvent:Fire()
	end
end

function Timer:Restart(dontFireEvent: boolean?)
	self:Stop(true)
	self:Start(true)
	if not dontFireEvent then
		self._restartedEvent:Fire()
	end
end

function Timer:Pause(dontFireEvent: boolean?)
	self._state = "Paused"

	if not dontFireEvent then
		self._pausedEvent:Fire()
	end
end

function Timer:Resume(dontFireEvent: boolean?)
	if self._state ~= "Paused" then
		warn("Cannot Resume a timer that is " .. self._state)
		return
	end

	self._willResume = true
	self._state = "Running"
	self._localResumedEvent:Fire()

	if not dontFireEvent then
		self._resumedEvent:Fire()
	end
end

function Timer:SetTimerSpeed(speed: number)
	self._timerSpeed = speed
end

function Timer:IncrementTimerSpeed(amount: number)
	self._timerSpeed += amount
end

function Timer:SetDuration(duration: number)
	self._duration = duration
	self._timeLeft = duration
end

function Timer:IncrementDuration(amount: number)
	self._duration += amount
	self._timeLeft += amount
end

-- Moves the timer ahead by a specified duration
-- If timerSpeed is positive, will decrease the time left
-- If timerSpeed is negative, will increase the time left
function Timer:FastForward(duration: number)
	if self._timerSpeed > 0 then
		self._timeLeft -= duration
		self._previousSecond -= duration
	else
		self._timeLeft += duration
		self._previousSecond += duration
	end
end

-- Moves the timer ahead by a specified duration
-- If timerSpeed is positive, will increase the time left
-- If timerSpeed is negative, will decrease the time left
function Timer:Rewind(duration: number)
	if self._timerSpeed < 0 then
		self._timeLeft -= duration
		self._previousSecond -= duration
	else
		self._timeLeft += duration
		self._previousSecond += duration
	end
end

function Timer:SetLooped(looped: boolean)
	self._looped = looped
end

function Timer:IsRunning(): boolean
	return if (self._state == "Running" or self._state == "Paused") then true else false
end

function Timer:GetState(): state
	return self._state
end

function Timer:GetTimeLeft(): number
	return self._timeLeft
end

function Timer:GetSecondsLeft(): number
	if self._timerSpeed < 0 then
		if math.floor(self._timeLeft) - math.floor(self._timeLeft + 0.5) == 1 then
			-- >= .5
			return math.abs(math.ceil(self._timeLeft))
		else
			-- < .5
			return math.floor(self._timeLeft)
		end
	else
		if math.floor(self._timeLeft + 0.5) - math.floor(self._timeLeft) == 1 then
			-- >= .5
			return math.abs(math.ceil(self._timeLeft))
		else
			-- < .5
			return math.floor(self._timeLeft)
		end
	end
end

function Timer:GetMinutesLeft(): number
	return math.floor(self:GetTimeLeft() / 60)
end

function Timer:GetHoursLeft(): number
	return math.floor(self:GetTimeLeft() / 3600)
end

function Timer:GetFormattedTimeLeft(useMiliseconds: boolean?): string
	local seconds = self:GetTimeLeft()

	if seconds <= 0 then
		return "00:00:00"
	else
		local hours = self:GetHoursLeft()
		local hoursText: string = string.format("%02.f", hours)
		local minutes = math.floor(seconds / 60 - (hours * 60))
		local minutesText: string = string.format("%02.f", minutes)

		if useMiliseconds then
			local secs = math.floor(seconds - tonumber(hours):: number * 3600 - minutes * 60)
			local secsText: string =
				string.format("%02.f", secs)
			local milisecs: string = string.format(
				"%02.0f",
				((seconds - hours * 3600 - minutes * 60) - secs * 100)
			)
			return hoursText .. ":" .. minutesText .. ":" .. secsText .. "." .. milisecs
		else
			local secs: string = string.format(
				"%02.f",
				self._timerSpeed > 0 and math.ceil(seconds - hours * 3600 - minutes * 60)
					or math.floor(seconds - hours * 3600 - minutes * 60)
			)
			return hoursText .. ":" .. minutesText .. ":" .. secs
		end
	end
end

function Timer:Destroy()
	self._state = "Destroyed"

	task.cancel(self._timerCoroutine)

	self._tickEvent:Destroy()
	self._secondPassedEvent:Destroy()
	self._startedEvent:Destroy()
	self._pausedEvent:Destroy()
	self._completedEvent:Destroy()
	self._restartedEvent:Destroy()
	self._resumedEvent:Destroy()
	self._localResumedEvent:Destroy()
	self._stoppedEvent:Destroy()

	setmetatable(self, nil)
end

return Timer :: Timer