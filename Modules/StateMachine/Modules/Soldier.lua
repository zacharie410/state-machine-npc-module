local soldier = {name="Soldier"}
local human=require(script.Parent)
local repStore=game:GetService("ReplicatedStorage")
local modules=repStore:WaitForChild("Modules")
local serverStor=game:GetService("ServerStorage")
local sModules=serverStor:WaitForChild("Modules")
local sUtility=require(sModules:WaitForChild("ServerUtility"))
local NPCs = workspace:WaitForChild("NPCs")

local AIUtilities = require(script:WaitForChild("AIUtilities"))

local colors = {"Pastel brown", "Brown"}

local SHIRTS = {179301177}
local PANTS = {179743304}
local FACES = {"5184141048", "7069755984"}

local tasks = require(workspace.YT_PLACE_IN_WORKSPACE.Tasks)

local function Task(taskName, ...)
	tasks[taskName](...)
end

soldier.new = function(humanoid)
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
	local shootSounds = {"Shot1", "Shot2", "Shot3", "Shot4"

	}
	local shotID = 1--for weird glitch thing

	local function PlaySound(soundName)
		if (soundName == ai:GetGlobal("PlaySound")) then
			ai:SetGlobal("PlaySound", "")
			wait()
		end
		ai:SetGlobal("PlaySound", soundName)
	end

	local function PlayActionAnim(animName)
		ai:SetGlobal("ActionAnim", animName)
	end

	ai:SetLongMem("ModelName", soldier.name)
	ai:SetGlobal("PlaySound", "")

	local ignoreList = {character}


	IdleState.Starting = function()
		--local offsets={-4,-2,0,1,2}
		ai:SetLongMem("ActionAnim", nil)
		ai:SetGlobal("PathOffsetSide", math.random(-4,4))

		ai:SetLongMem("Team", "Soldier")
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
		local target = ai:GetShortMem("FollowTarget")
		if not target or not target.Parent or not target.Parent:FindFirstChild("Humanoid") or target.Parent.Humanoid.Health<= 0 then
			--			print("Getting Target")
			local targetNew, dist = sUtility.RequestTaskFromNearestClient(character.PrimaryPart.Position, "FindNearestNPCToPoint", {humanoid, character.PrimaryPart.Position, 1000}, character.PrimaryPart);
			if targetNew and targetNew.Parent then
				ai:SetShortMem("FollowTarget", targetNew.PrimaryPart)
				target=targetNew.PrimaryPart
			else
				ai:SetShortMem("FollowTarget",nil)

				ai.SwitchState(PatrolState)
				return
			end
		end
		if not character.PrimaryPart then
			return
		end

        local distanceFrom = (target and target.Parent and (target.Position-character.PrimaryPart.Position).magnitude) or 1000--ai:GetShortMem("DistanceFromTarget")

		if distanceFrom < 200 then
			PlayActionAnim("Aim")
			if target and target.Parent and target.Parent:FindFirstChild("Humanoid") then

				shotID += 1
				if shotID > #shootSounds then
					shotID = 1
				end
				PlaySound(shootSounds[shotID])

				local toTarget = target.Position - character.PrimaryPart.Position

				local range=toTarget.magnitude
				if range < 50 or math.random()*3 < (-range)/100 + 1 then
					--local mainRay = Ray.new()
					local part, position = AIUtilities:RayCast(character.PrimaryPart.Position, toTarget.unit * 1000,ignoreList)--game.Workspace:FindPartOnRayWithIgnoreList(mainRay, ignoreList)
					toTarget=position-character.PrimaryPart.Position
					if part then
						Task("BulletImpact", part, position, 5, false, math.random(30,50))
						if part and part.Parent and part.Parent:FindFirstChild("Humanoid") and 
							part.Parent.Humanoid:GetAttribute("Team") ~= ai:GetLongMem("Team")
						then
							local ply=game.Players:GetPlayerFromCharacter(part.Parent)

							local otherHumanoid = part.Parent:FindFirstChild("Humanoid")
							otherHumanoid.Health = otherHumanoid.Health - (math.random(30,50))--distanceFrom)

						end
					end
				else
					-- missed!
					local hOffset = toTarget:Cross(Vector3.new(0,1,0)).unit * math.random(5,10) * math.random(-1, 1)
					toTarget = toTarget + hOffset

					local part, position = AIUtilities:RayCast(character.PrimaryPart.Position, toTarget.unit * 1000, ignoreList)--game.Workspace:FindPartOnRayWithIgnoreList(missRay, ignoreList)
					toTarget=position-character.PrimaryPart.Position
					if part then
						Task("BulletImpact", part, position, 5, false, math.random(30,50))
						if part and part.Parent and part.Parent:FindFirstChild("Humanoid") and 
							part.Parent.Humanoid:GetAttribute("Team") ~= ai:GetLongMem("Team")
						then
							local ply=game.Players:GetPlayerFromCharacter(part.Parent)

							local otherHumanoid = part.Parent:FindFirstChild("Humanoid")
							otherHumanoid.Health = otherHumanoid.Health - math.random(30,50)
						end
					end
				end	

			else
				ai:SetShortMem("FollowTarget",nil)
			end
		else
			PlayActionAnim("")
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

return soldier
