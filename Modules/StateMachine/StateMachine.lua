--zacharie410
--State Machine
--21-09-05
--last edit 21-09-05
--[[
this module is for managine all state machine related tasks and logic
other AI modules will be descendants of this class
]]


local runService=game:GetService("RunService")
local repStore=game:GetService("ReplicatedStorage")
local modules=repStore:WaitForChild("Modules")
local serverStor=game:GetService("ServerStorage")
local sModules=serverStor:WaitForChild("Modules")
local sUtility=require(sModules:WaitForChild("ServerUtility"))

local machine = {
	machines={},
	states={}
}

machine.new = function(humanoid)
	local stateMachine={
		Class="Machine",
		TickDelay=0.5,
		running=false,
		lastTick=0,
		currentState=nil,
		shortMemory={},
		longMemory={},
		tasks={},
		spawnState=nil,
		events = {};--create list of states. Most will have idle, search, attack states, etc... the machine will handle these sub states
	}
	
	stateMachine.humanoid=humanoid
	stateMachine.states = {}
	
	
	--AI WORKING MEMORY
	--this is for stuff like the current combat target or what the NPC health state last was etc...
	--probably will use attributes for this eventually so that NPC control can be passed from server to client and vice versa
	
	
	function stateMachine:GetShortMem(key)
		return self.shortMemory[key]
	end
	function stateMachine:SetShortMem(key, value)
		self.shortMemory[key]=value
	end
	--LONG TERM MEMORY
	--this will be used to store stuff like identity, team, etc...
	--REMEMBER TO USE THESE GETTERS AND SETTERS TO SET ATTRIBUTES SO THAT NPCS CAN READ EACHOTHER BETTER
	--ONLY LONG TERM MEMORY WILL BE AN ATTRIBUTE
	function stateMachine:GetLongMem(key)
		return self.longMemory[key]
	end
	function stateMachine:SetLongMem(key, value)
		self.humanoid:SetAttribute(key, value)
		self.longMemory[key]=value
	end
	--CROSS SERVER-CLIENT BOUNDARY
	function stateMachine:SetGlobal(key, value)
		self.humanoid:SetAttribute(key, value)
	end
	function stateMachine:GetGlobal(key)
		self.humanoid:GetAttribute(key)
	end
	--
	function stateMachine:AddTask(key, taskF)
		self.tasks[key]=taskF
	end
	function stateMachine:AddEvent(event)
		table.insert(self.events, event)
	end
	
	function stateMachine:SetActive(bool)
		if bool == true then
			stateMachine.running=true
			stateMachine:SwitchState(stateMachine.spawnState)
		else
			self.currentState=nil
			stateMachine.running=false
		end
	end
	
	function stateMachine:SwitchState(state)
		if stateMachine.running then
			if self.currentState then
				self.currentState.Stop()
			end
			self.currentState=state
			if state then
				state.Start()
			end
		else
			
			self.currentState=state
		end
	end
	
	
	function stateMachine.NewState(name)--this is what is used to create new states such as Search or Attack or MoveToLocation
		local state = {}
		state.name = name
		state.Conditions = {}
		state.Active = false
		state.Ready = true--ready by default as the tick is not executing on start
		
		state.Action = function() end--user config, this is what executes when all the state conditions are met (Like to attack must see a target or have aggroed etc..)
		state.Starting = function() end--user config. this is what executes when the state machine switches to this state
		state.Stopping = function() end--user config. this is what executes when the state machine switches FROM this state
				
		state.Tick = function()--this will execute at a configurable rate so long as the thread is ready
			state.Ready=false--lock this thread so multiple instances don't spawn
			for _, condition in pairs(state.Conditions) do
				if stateMachine.running and condition.Evaluate() then
					state.Ready=true
					stateMachine:SwitchState(condition.TransitionState)--if we haven't met the state conditions, react and switch to appropriate state for the situation
					--make sure that the state is readied since the Action has been cancelled
					return--end this thread
				end
			end
			
			if stateMachine.running then
				state.Action()--if conditions are met, perform state action
			end
			--ready the state for another thread
			state.Ready=true
		end
		
		
		state.Start = function()
			state.Starting()
			state.Active=true
		end
		state.Stop = function()
			state.Stopping()
			state.Active=false
		end
		
		function state:BindFunction(name, fun)
			self[name]=fun--function type
		end
		
		function state:AddCondition(condition)
			table.insert(self.Conditions,condition)--add a condition object to the list of conditions (see StateMachine.NewCondition)
		end
		
		table.insert(stateMachine.states,state)
		return state
	end
	
	function stateMachine.GetState(name)
		for _, s in pairs(stateMachine.states) do
			if string.lower(s.name) == string.lower(name) then
				return s
			end
		end
	end
	
	stateMachine.NewCondition = function()
		local condition = {}
		condition.Name = ""
		condition.Evaluate = function()--return TRUE if conditions are not met
			print("Default Condition") 
			return false
		end
		condition.TransitionState = nil--stateType. eg states.Attack or states.Chase etc...
		return condition
	end
	
	stateMachine:AddEvent(humanoid.Died:Connect(function()
		stateMachine:SetActive(false)
		for index, m in pairs(machine.machines) do
			if m == stateMachine then
				table.remove(machine.machines, index)
				break
			end
		end
		
		wait(5)
		
		humanoid.Parent:Destroy()
		workspace.Debugger:SetAttribute("NPCs", workspace.Debugger:GetAttribute("NPCs") - 1)
	end))
	
	table.insert(machine.machines, stateMachine)
	
	return stateMachine
end

local control=0
local average=0
local count=0

local updateThread = coroutine.create(function()
	
	runService.Heartbeat:Connect(function(deltaTime)
		
		count = count + deltaTime
		control = control + 1
		
		average = count / control
		
		if control == 1000 then
			average=deltaTime
			count=deltaTime
			control=1
		end
		--this check ensures the server is not overloaded by comparing its average framerate to a control group of recent performance and throttles down requests accordingly
		if deltaTime < (average + 0.01) then
		
			for _, stateMachine in pairs(machine.machines) do--search through all the existing machines
				if (time()-stateMachine.lastTick) > stateMachine.TickDelay and stateMachine.running and stateMachine.currentState and stateMachine.currentState.Ready then
					--^make sure enough time has passed, make sure the machine is running, make sure the currentState is declared
					--also make sure that the existing state thread has completed execution and is ready
					stateMachine.lastTick=time()--set last execution time
					coroutine.resume(coroutine.create(function()--create and resume a separate thread
						stateMachine.currentState.Tick()--execute Tick function for this state
					end))
				end
			end
			
		end
	end)
	
end)

coroutine.resume(updateThread)

return machine
