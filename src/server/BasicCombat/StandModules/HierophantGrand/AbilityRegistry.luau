local HierophantGrand = require(script.Parent:WaitForChild("HierophantGrand"))
local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))

local AbilityRegistry = {

	------------------------------------------------------------------------
	-- Ability 1
	------------------------------------------------------------------------
	[1] = {
		Name = "PuppetMaster",
		Cooldown = 10,
		Execute = function(standModel, player)
			HierophantGrand.PuppetMaster(standModel)
		end,
	},

	------------------------------------------------------------------------
	-- Ability 2: Emerald Splash (TOGGLE)
	------------------------------------------------------------------------
	[2] = {
		Name = "EmeraldSplash",
		Cooldown = 0, -- cooldown handled INSIDE StopSplash()
		Execute = function(standModel, player)
			local character = standModel.Parent
			if not character then
				return
			end

			-- Access Hierophant's internal active flag
			local isSplashing = HierophantGrand.IsSplashActive(character)

			-- If already splashing -> STOP it
			if isSplashing then
				HierophantGrand.StopSplash(character)
				return
			end

			-- Otherwise -> try to START it
			-- respect stun or action lock BEFORE calling your module
			local actionFlag = CombatUtils.GetActionInProgress(character)
			if actionFlag and actionFlag.Value then
				return
			end
			if CombatUtils.GetStun(character) then
				return
			end

			HierophantGrand.StartSplash(character)
		end,
	},

	------------------------------------------------------------------------
	-- Ability 3
	------------------------------------------------------------------------
	[3] = {
		Name = "EmeraldBarrier",
		Cooldown = 12,
		Execute = function(standModel, player)
			local character = standModel.Parent
			if character then
				HierophantGrand.ActivateBarrier(standModel)
			end
		end,
	},

	------------------------------------------------------------------------
	-- Ability 4
	------------------------------------------------------------------------
	[4] = {
		Name = "TwentyMeterBarrier",
		Cooldown = 40,
		Execute = function(standModel, player)
			HierophantGrand.TwentyMeterBarrier(standModel)
		end,
	},
}

return AbilityRegistry
