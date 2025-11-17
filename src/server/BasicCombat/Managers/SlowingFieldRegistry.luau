-- SlowingFieldRegistry.lua
-- Global registry for all movement slows applied to characters

local SlowingFieldRegistry = {}

-- Format:
-- SlowingFieldRegistry.Active[character] = {
--      SlowingField = 0.5,       -- field slow multiplier
--      Stun = 0.16,              -- stun slow multiplier
--      Block = 0.75,             -- block slow multiplier
--      CustomDebuff = 0.4        -- anything else
-- }
SlowingFieldRegistry.Active = {}

-- Utility to ensure character table exists
function SlowingFieldRegistry.GetCharTable(character)
    local active = SlowingFieldRegistry.Active
    active[character] = active[character] or {}
    return active[character]
end

-- Add or override a slow effect
function SlowingFieldRegistry.SetSlow(character, sourceKey, multiplier)
	-- multiplier MUST be 0 < x ≤ 1
    local charTable = SlowingFieldRegistry.GetCharTable(character)
    charTable[sourceKey] = multiplier
end

-- Remove a slow effect
function SlowingFieldRegistry.ClearSlow(character, sourceKey)
    local charTable = SlowingFieldRegistry.Active[character]
    if not charTable then return end

    charTable[sourceKey] = nil

    -- remove empty entries
    if next(charTable) == nil then
        SlowingFieldRegistry.Active[character] = nil
    end
end

-- Calculate final multiplier
function SlowingFieldRegistry.GetFinalMultiplier(character)
    local charTable = SlowingFieldRegistry.Active[character]
    if not charTable then return 1 end

    local final = 1
    for _, mult in pairs(charTable) do
        final *= mult
    end

    return final
end

return SlowingFieldRegistry
