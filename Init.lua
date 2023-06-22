local _, addon = ...

LibStub("AceAddon-3.0"):NewAddon(addon, "AstralRaid", "AceConsole-3.0")

-- local ldb = LibStub("LibDataBroker-1.1"):NewDataObject("AstralRaid", {
-- 	type = "data source",
-- 	text = "AstralRaid",
-- 	icon = "Interface\\AddOns\\AstralKeys\\Media\\Texture\\Logo@2x",
-- 	OnClick = function(_, button)
-- 		if button == 'LeftButton' then
-- 			addon.AstralToggle()
-- 		elseif button == 'RightButton' then
-- 			AstralOptionsFrame:SetShown( not AstralOptionsFrame:IsShown())
-- 		end
-- 	end,
-- 	OnTooltipShow = function(tooltip)
-- 		tooltip:AddLine("Astral Keys")
-- 		tooltip:AddLine('Left click to toggle main window')
-- 		tooltip:AddLine('Right Click to toggle options')
-- 	end,
-- })

AstralRaidEvents:Register('PLAYER_LOGIN', function()
  -- addon.GetAddons()
end, 'init')