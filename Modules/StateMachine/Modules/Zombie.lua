local zombie = {name="Zombie"}
local human=require(script.Parent)
local repStore=game:GetService("ReplicatedStorage")
local modules=repStore:WaitForChild("Modules")
local serverStor=game:GetService("ServerStorage")
local sModules=serverStor:WaitForChild("Modules")
local sUtility=require(sModules:WaitForChild("ServerUtility"))
local NPCs = workspace:WaitForChild("NPCs")

local colors = {"Earth green", "Slime green", "Grime", "Rust", "Reddish brown"}

local SHIRTS = {0}
local PANTS = {0}
local FACES = {"174393211","7074882"}

zombie.new = function(humanoid)
	local ai=human.new(humanoid)
	local character=humanoid.Parent
	local MoveState = ai.MoveState
	local AttackState = ai.AttackState
	local PatrolState = ai.PatrolState
	local IdleState = ai.IdleState

	local lastYell = time()
	local attackSounds = {"Attack1", "Attack2", "Attack3"
		, "Attack4", "Attack5"
	}
	local lastHurt = time()
	local hurtSounds = {"Hit1","Hit2","Hit3"
	}

	local function PlaySound(soundName)
		if (soundName == ai:GetGlobal("PlaySound")) then
			ai:SetGlobal("PlaySound", nil)
			wait()
		end
		ai:SetGlobal("PlaySound", soundName)
	end

	local function PlayActionAnim(animName)

	end

	ai:SetLongMem("ModelName", zombie.name)
	ai:SetGlobal("PlaySound", nil)

	IdleState.Starting = function()
		ai:SetLongMem("ActionAnim", nil)
		ai:SetGlobal("PathOffsetSide", math.random(-4,4))
		ai:SetLongMem("Team", "Zombie")
		ai:SwitchState(PatrolState)

	end
	IdleState.Stopping = function()

	end
	IdleState.Action = function()

	end

	AttackState.Action = function()
		if not character.PrimaryPart then
			return
		end
		ai:SetGlobal("ActionAnim", nil)
		local target = ai:GetShortMem("FollowTarget")
		if not target or not target.Parent or not target.Parent:FindFirstChild("Humanoid") or target.Parent.Humanoid.Health <= 0 then
			--			print("Getting Target")
			local targetNew, dist = sUtility.RequestTaskFromNearestClient(character.PrimaryPart.Position, "FindNearestNPCToPoint", {humanoid, character.PrimaryPart.Position, 1000}, character.PrimaryPart);
			if targetNew and targetNew.Parent and targetNew.PrimaryPart then
				ai:SetShortMem("FollowTarget", targetNew.PrimaryPart)
				target=targetNew.PrimaryPart
			else
				ai:SetShortMem("FollowTarget", nil)
				--if dist > 1000 then
				ai.SwitchState(PatrolState)
				return
			end
		end

		if not character.PrimaryPart then
			return
		end
		--ai:GetShortMem("DistanceFromTarget",10000)
		local distanceFrom = (target and target.Parent and (target.Position-character.PrimaryPart.Position).magnitude) or 100--ai:GetShortMem("DistanceFromTarget")
		if distanceFrom < 10 then
			ai:SetGlobal("ActionAnim", "Slash")
			if (time() - lastYell) > 2 then
				PlaySound(attackSounds[math.random(1,#attackSounds)])
				lastYell = time()
			end
		end
		if distanceFrom < 4 then
			if target and target.Parent and target.Parent:FindFirstChild("Humanoid") then
				ai:SetGlobal("ActionAnim", "Slash")
				target.Parent.Humanoid.Health = target.Parent.Humanoid.Health - (math.random(10,20)-distanceFrom)
				PlaySound(hurtSounds[math.random(1,#hurtSounds)])

			else
				ai:SetShortMem("FollowTarget",nil)
			end
		end

		if MoveState.Ready then
			MoveState.Ready=false
			MoveState.Action()
			MoveState.Ready=true
		end

	end

	AttackState.Starting = function()

	end

	--PATROL STATE
	PatrolState.Starting = function()

	end
	PatrolState.Stopping = function()

	end
	PatrolState.Action = function()

		if character.PrimaryPart.Velocity.magnitude < 5 then
			local r = ai.GetNearestRoad(character.PrimaryPart.Position, 50)
			if r then
				humanoid:MoveTo(r.Position + Vector3.new(0, r.Size.y/2 + 1, 0))
			end
		end
	end

	local function GotDamaged()
		if humanoid.Health < ai:GetShortMem("Health") then
			ai:SetShortMem("Health", humanoid.Health)

			if (time() - lastHurt) > 0.2 then
				PlaySound(hurtSounds[math.random(1,#hurtSounds)])
				lastHurt = time()
			end
			return true
		end
		ai:SetShortMem("Health", humanoid.Health)
		return false
	end

	ai.GotDamagedFunction = GotDamaged

	ai.Start = function()
		print("Loaded")
	end

	ai:SetGlobal("BodyColor", colors[math.random(1,#colors)])
	ai:SetGlobal("FaceId", FACES[math.random(1,#FACES)])
	ai:SetGlobal("ShirtId", SHIRTS[math.random(1,#SHIRTS)])
	ai:SetGlobal("PantsId", PANTS[math.random(1,#PANTS)])
	return ai
end

return zombie
