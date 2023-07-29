local _, addon = ...

local SendAddonMessage = C_ChatInfo.SendAddonMessage

local alert

local function initAlerts()
  alert = addon.CreateText('alertPrimary', 'LOREM IPSUM', 'ALERT')
end

local function showAlert(channel, ...)
  local msg, _ = ...

	local resp = 'alertShowAck ' .. string.format('%s:%s', addon.CLIENT_VERSION, addon.PlayerClass)

	for name, text in string.gmatch(msg, '"([^"]+)":"([^"]+)"') do
		if name == addon.PlayerNameRealm or name == UnitName('player') then
      alert:SetText(text)
      addon.ShowText('alertPrimary')
      SendAddonMessage(AstralRaidComms.PREFIX, resp, channel)
      return
		end
	end

end

local function hideAlert(channel, ...)
  local msg, _ = ...

	local resp = 'alertHideAck ' .. string.format('%s:%s', addon.CLIENT_VERSION, addon.PlayerClass)

	for name, text in string.gmatch(msg, '"([^"]+)":"([^"]+)"') do
		if name == addon.PlayerNameRealm or name == UnitName('player') then
      alert:SetText(text)
      addon.HideText('alertPrimary')
      SendAddonMessage(AstralRaidComms.PREFIX, resp, channel)
      return
		end
	end
end

AstralRaidComms:RegisterPrefix('RAID', 'alertShow', function(...) showAlert('RAID', ...) end)
AstralRaidComms:RegisterPrefix('RAID', 'alertHide', function(...) hideAlert('RAID', ...) end)

AstralRaidEvents:Register('PLAYER_LOGIN', initAlerts, 'InitAlerts')

-- Library Hooks

function AstralRaidLibrary:ShowAlert(text, time)
  alert:SetText(text)
  addon.ShowText('alertPrimary')
  if time then C_Timer.After(time, function() addon.HideText('alertPrimary') end) end
end

function AstralRaidLibrary:HideAlert()
  addon.HideText('alertPrimary')
end