-- Changing Stuff
local snakeMode = 1

addHook("NetVars", function(net)
	snakeMode = net(snakeMode)
end)

local function KL_SnakingUpdate(var)
	if var.value ~= snakeMode
		if var.value == 0
			print("Snaking will be turned ".."\x82".."off".."\x80".." starting next round.") 
		elseif var.value == 1 
			print("Snaking Mode will be set to ".."\x82".."Mario Kart DS".."\x80".." mode starting next round!")
		elseif var.value == 2
			print("Snaking Mode will be set to ".."\x82".."Mario Kart Double Dash".."\x80".." mode starting next round!")
		end
	else
		if var.value == 0
			print("Snaking was set back to ".."\x82".."off".."\x80"..".") 
		elseif var.value == 1 
			print("Snaking Mode was set back to ".."\x82".."Mario Kart DS".."\x80".." mode.")
		elseif var.value == 2
			print("Snaking Mode was set back to ".."\x82".."Mario Kart Double Dash".."\x80".." mode.")
		end
	end
end

local cv_snaking = CV_RegisterVar({
  name = "kartsnaking",
  defaultvalue = 1,
  flags = CV_CALL|CV_NOINIT|CV_NETVAR,
  PossibleValue = {MIN = 0, MAX = 2},
  func = KL_SnakingUpdate,
})

addHook("MapLoad", function()
	if cv_snaking.value ~= snakeMode
		snakeMode = cv_snaking.value
		if snakeMode == 0
			print("Snaking has been ".."\x82".."disabled".."\x80"..".") 
		elseif snakeMode == 1
			print("Snaking Mode has been set to ".."\x82".."Mario Kart DS".."\x80".." mode.")
		elseif snakeMode == 2
			print("Snaking Mode has been set to ".."\x82".."Mario Kart Double Dash".."\x80".." mode.")
		end
	end
end)

-- Functions that simplify stuff because I'm a lazy cunt
local function KL_PlaySnakeDriftsparkSound(p)
	if snakeMode == 2 and p.snakecharge == 500 then S_StartSoundAtVolume(p.mo, sfx_s251, 192) end
	if p.snakecharge == 1000
	or p.snakecharge == 2000
	or p.snakecharge == 4000
		S_StartSoundAtVolume(p.mo, sfx_s3ka2, 192)
	end
end

local function KL_AddSnakeCharge(p)
	if snakeMode
		if snakeMode == 1 -- MKDS Mode
			p.snakecharge = $ + (p.snakecharge >= 2000 and 500 or 1000)
		elseif snakeMode == 2 -- MKDD Mode
			if p.snakecharge < 1000 then p.snakecharge = $ + 500
			elseif p.snakecharge == 1000 then p.snakecharge = $ + 1 
			end
		end
	end
end

local function KL_SpawnDriftSparks(p, clr, scl)
	if not P_IsObjectOnGround(p.mo) then return end
	if leveltime%2 == 1 then return end
	
	local travelangle = p.mo.angle-(ANGLE_45/5)*p.kartstuff[k_drift]
	
	for i = 0, 2
		local nx = p.mo.x + P_ReturnThrustX(p.mo, travelangle+((i&1) and -1 or 1)*ANGLE_135, FixedMul(32*FRACUNIT, p.mo.scale))
		local ny = p.mo.y + P_ReturnThrustY(p.mo, travelangle+((i&1) and -1 or 1)*ANGLE_135, FixedMul(32*FRACUNIT, p.mo.scale))
		
		local spark = P_SpawnMobj(nx, ny, p.mo.z, MT_DRIFTSPARK)
		spark.momx = p.mo.momx/2
		spark.momy = p.mo.momy/2
		spark.target = p.mo
		spark.angle = travelangle-(ANGLE_45/5)*p.kartstuff[k_drift]
		spark.color = clr
		spark.scale = scl
		-- Inwards Drift
		if p.kartstuff[k_drift] > 0 and p.cmd.driftturn > 0
		or p.kartstuff[k_drift] < 0 and p.cmd.driftturn < 0
			if p.kartstuff[k_drift] < 0 and (i&1)
			or p.kartstuff[k_drift] > 0 and not (i&1)
				spark.state = S_DRIFTSPARK_A1
			elseif p.kartstuff[k_drift] < 0 and not (i&1)
			or p.kartstuff[k_drift] > 0 and (i&1)
				spark.state = S_DRIFTSPARK_C1
			end
		end
		-- Outwards Drift
		if p.kartstuff[k_drift] > 0 and p.cmd.driftturn < 0
		or p.kartstuff[k_drift] < 0 and p.cmd.driftturn > 0
			if p.kartstuff[k_drift] < 0 and (i&1)
			or p.kartstuff[k_drift] > 0 and not (i&1)
				spark.state = S_DRIFTSPARK_C1
			elseif p.kartstuff[k_drift] < 0 and not (i&1)
			or p.kartstuff[k_drift] > 0 and (i&1)
				spark.state = S_DRIFTSPARK_A1
			end
		end
	end
end
			

addHook("ThinkFrame", do
	for p in players.iterate
		if not snakeMode then return end -- Has to be turned on, dingus
		
		if not (p and p.mo) continue end
		-- Setup Snaking variables
		p.snakecharge = $ == nil and 0 or $ -- Alternate charge to apply to p.kartstuff[k_driftcharge]
		p.snaketics = $ == nil and 0 or $ -- Tics you have to do a successful snaking Miniturbo
		p.snakecooldown = $ == nil and 0 or $ -- Tics you have to wait to Snake again
		
		-- Snaking Thinker
		if p.snakecooldown then p.snakecooldown = $-1 end
		
		if p.kartstuff[k_driftboost] -- Let's fucking SAVE THE BALANCE OF THE GAME
			if not p.extendboost -- Make sure you dont get more than you need
				p.extendboost = true
				
				p.kartstuff[k_driftboost] = $ - (1*p.kartweight) -- Let's add weight support because we dont want it to be moot now do we.
				if snakeMode == 2 then p.kartstuff[k_driftboost] = $ + 6 end -- (Also while we're at it lets quickly buff Double Dash Mode because it fucking sucks)
			end
		else
			p.extendboost = nil
		end
		
		if p.kartstuff[k_drift] -- Are you Drifting?
		and not p.kartstuff[k_driftend] -- And the Drift isnt ending...
			if P_IsObjectOnGround(p.mo) -- Uf you're on the ground.
				if p.snaketics then p.snaketics = $-1 end
				p.kartstuff[k_driftcharge] = p.snakecharge+169
				
				if p.kartstuff[k_drift] > 0 -- Left Drift
					if not p.snakecooldown
						if p.cmd.driftturn < 0 then p.snaketics = 6 end
						if p.cmd.driftturn > 0 and p.snaketics
							p.snaketics = 0
							p.snakecooldown = 12 - (p.kartweight/2) -- Weight reduces the cooldown > faster charging
							KL_AddSnakeCharge(p) -- Increase Charge
							KL_PlaySnakeDriftsparkSound(p) -- Play SFX
						end
					end
				elseif p.kartstuff[k_drift] < 0 -- Right Drift
					if not p.snakecooldown
						if p.cmd.driftturn > 0 then p.snaketics = 6 end
						if p.cmd.driftturn < 0 and p.snaketics
							p.snaketics = 0
							p.snakecooldown = 12 - (p.kartweight/2) -- Weight reduces the cooldown > faster charging
							KL_AddSnakeCharge(p) -- Increase Charge
							KL_PlaySnakeDriftsparkSound(p) -- Play SFX
						end
					end
				end
				if snakeMode == 2 -- Custom MKDD Thinker!
					if p.snakecharge < 1000
						KL_SpawnDriftSparks(p, (p.snakecharge<500 and 20 or 17), p.mo.scale-(p.mo.scale/3))
					end
				end
			end
		else
			p.snakecharge = 0
			p.snaketics = 0
		end
	end
end)