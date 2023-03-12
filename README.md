# Developer Guide for State-Machine-NPC-Module
---
## Overview:

### The State Machine NPC module is a Lua module that handles all state machine-related tasks and logic for NPC AI. This module can be used to create new state machine objects, manage working memory, manage long-term memory, switch between states, add tasks, and add events. This guide will provide a step-by-step approach to using the module.

## Creating a new State Machine Object:
### Import the State-Machine-NPC-Module into your script using require().
* Create a humanoid object that the state machine will control.
* Call the new() method of the machine table and pass in the humanoid object as a parameter.
* Example Code:
```
local machine = require(path.to.state.machine)
local humanoid = -- the humanoid object
local stateMachine = machine.new(humanoid)
```
## Creating States:

### Call the NewState() method of the stateMachine object to create a new state.
Add conditions to the state by calling its AddCondition() method and passing in a condition object.
Example Code:
```
local state = stateMachine.NewState(name)
local condition = stateMachine.NewCondition()
condition.Name = "Example Condition"
condition.Evaluate = function() return true end
condition.TransitionState = stateMachine.GetState("Idle")
state:AddCondition(condition)
```
## Working Memory:

### Use the stateMachine object's GetShortMem(key) and SetShortMem(key, value) methods to store and retrieve key-value pairs for the duration of the state machine's execution.
Use the GetLongMem(key) and SetLongMem(key, value) methods to store and retrieve key-value pairs that persist across state machine executions.
Example Code:
```
stateMachine:SetShortMem("example_key", "example_value")
local exampleValue = stateMachine:GetShortMem("example_key")
stateMachine:SetLongMem("example_key", "example_value")
local exampleValue = stateMachine:GetLongMem("example_key")
```
## Switching States:

### Use the stateMachine object's SwitchState(state) method to switch to a new state.
This method will call the Stop() method of the current state (if there is one), set the current state to the new state, and call the Start() method of the new state.
Example Code:
```
stateMachine:SwitchState(state)
```
## Adding Events:

### Use the stateMachine object's AddEvent(event) method to add events to its event list.
Events are Roblox events that can be listened for during the state machine's execution.
Example Code:
```
stateMachine:AddEvent(humanoid.Died:Connect(function() stateMachine:SetActive(false) end))
```
Setting Active:

Use the stateMachine object's SetActive(bool) method to set the state machine's active state.
* If bool is true, the state machine is active and will execute its states.
* If bool is false, the state machine is not active and will stop executing its states.
Example Code:
```
stateMachine:SetActive(true)
```
Additional Notes:

* The state machine object has a TickDelay property that determines how often the state machine will execute its states.
* The module contains a main update thread that handles state machine execution.
* The module compares the server's average frame rate to a control group of recent performance and throttles down requests accordingly to avoid overloading the server.
