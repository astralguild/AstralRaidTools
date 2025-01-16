local _, addon = ...
local L = addon.L

-- Event Hooks --

AstralRaidEvents:Register('READY_CHECK', function()
	if InCombatLockdown() then
		return
	end
	
	if AstralRaidSettings.readycheck.severedstrands.enable then
		if IsInRaid() and IsInInstance() then
			local instanceName, instanceType, difficultyId, difficultyName, _, _, _, instanceId = GetInstanceInfo()
			if difficultyId == 16 and instanceId == 2657 then -- Mythic Nerubar Palace
				for i = 1, MAX_RAID_MEMBERS do
					local unit = format("%s%i", 'raid', i)
					if UnitExists(unit) then
						if UnitIsVisible(unit) then							
							local aura = C_UnitAuras.GetAuraDataBySpellName(unit, 'Severed Strands')
							if not aura then
								print(GetUnitName(unit) .. " is missing the Severed Strands raid buff")
							else
								local buffpercent = tonumber(aura.points[1])
								local numBuffStacks = floor(((buffpercent - 4.5) / 2.25) + 0.5)
								
								local secondsSinceFirstBuffWeek = GetServerTime() - 1730214000
								local weeksSinceFirstBuffWeek = floor(secondsSinceFirstBuffWeek / (60 * 60 * 24 * 7))
								local expectedNumBuffs = floor(weeksSinceFirstBuffWeek / 2)
								local expectedNumBuffs = min(6, expectedNumBuffs) -- Nerubar Finery buff caps at 6 (18%)
								
								if numBuffStacks ~= expectedNumBuffs then
									print(GetUnitName(unit) .. " has " .. (numBuffStacks+1) .. "/" .. (expectedNumBuffs+1) .. " stacks of Severed Strands.")
								end
							end
						else
							print(GetUnitName(unit, true) .. " is not in range for the Severed Strands check.")
						end
					end
				end
			end
		end
	end
end, 'ReadyCheck_ReadyCheck')

local module = addon:New("Ready Check", "Ready Check")

-- UI --

local severedStrandsCheckbox

function module.options:Load()
  local header = AstralUI:Text(self, "Ready Check Options")
	:Point('TOPLEFT', 0, 0)
	:Shadow()
  local headerDesc = AstralUI:Text(self, "Options for things to perform during ready checks.")
	:Point('TOPLEFT', header, 'BOTTOMLEFT', 0, -10)
	:FontSize(9)
	:Shadow()
  
  severedStrandsCheckbox = AstralUI:Check(self, "Check if everyone has max stacks of the Severed Strands buff")
	:Point('TOPLEFT', headerDesc, 'BOTTOMLEFT', 0, -30)
	:OnClick(function(self) 
		AstralRaidSettings.readycheck.severedstrands.enable = self:GetChecked()
	end)
end


function module.options:OnShow()
	severedStrandsCheckbox:SetChecked(AstralRaidSettings.readycheck.severedstrands.enable)
end