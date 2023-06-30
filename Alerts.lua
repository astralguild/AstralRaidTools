local _, addon = ...

local SendAddonMessage = C_ChatInfo.SendAddonMessage

local alert

function addon.InitAlerts()
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