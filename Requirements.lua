local _, addon = ...

local waModule = addon:New('WA Requirements', 'WeakAuras', true)
local addonModule = addon:New('Addon Requirements', 'Addons', true)

addon.WeakAuraResponses = {}
addon.AddonResponses = {}

local function waPush(channel, ...)
	local msg, sender = ...
	AstralRaidComms:DecodeChunkedAddonMessages(sender, msg, function(m)
		local player = Ambiguate(sender, 'short')
    if not addon.WeakAuraResponses[player] then
      addon.WeakAuraResponses[player] = {}
    end
		for wa, _ in pairs(AstralRaidSettings.wa.required) do
			addon.WeakAuraResponses[player][wa] = true
		end
		for wa, url in string.gmatch(m, '"([^"]+)":"([^"]+)"') do
			addon.WeakAuraResponses[player][wa] = url
		end
		addon.UpdateRosterPage()
	end)
end

local function addonPush(channel, ...)
	local msg, sender = ...
	AstralRaidComms:DecodeChunkedAddonMessages(sender, msg, function(m)
		local player = Ambiguate(sender, 'short')
    if not addon.AddonResponses[player] then
      addon.AddonResponses[player] = {}
    end
		for a, _ in pairs(AstralRaidSettings.addons.required) do
			addon.AddonResponses[player][a] = true
		end
		for a, ver in string.gmatch(m, '"([^"]+)":"([^"]+)"') do
			addon.AddonResponses[player][a] = ver
		end
		addon.UpdateRosterPage()
	end)
end

local function envPush(msg, sender)
	print(msg)
end

AstralRaidComms:RegisterPrefix('RAID', 'versionPush', envPush)
AstralRaidComms:RegisterPrefix('RAID', 'addonPush', function(...) addonPush('RAID', ...) end)
AstralRaidComms:RegisterPrefix('RAID', 'waPush', function(...) waPush('RAID', ...) end)

function addon.SendWeakAuraRequest()
	if not IsInRaid() then return end

	local req = ''
  local weakAuras = addon.GetWeakAuras()
	for wa, val in pairs(AstralRaidSettings.wa.required) do
		if val and weakAuras[wa] then
			req = req .. string.format(' "%s":"%s"', wa, tostring(weakAuras[wa].version))
		end
	end

	AstralRaidComms:SendChunkedAddonMessages('waRequest', req, 'RAID')
end

function addon.SendAddonsRequest()
	if not IsInRaid() then return end

	local req = ''
  local addons = addon.GetAddons()
	for a, val in pairs(AstralRaidSettings.addons.required) do
		if val and addons[a] then
			req = req .. string.format(' "%s":"%s"', a, addons[a].version)
		end
	end

	AstralRaidComms:SendChunkedAddonMessages('addonRequest', req, 'RAID')
end

function addon.IterateRoster(maxGroup, index)
	index = (index or 0) + 1
	maxGroup = maxGroup or 8

	if IsInRaid() then
		if index > GetNumGroupMembers() then
			return
		end
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(index)
		if subgroup > maxGroup then
			return addon.IterateRoster(maxGroup,index)
		end
		local guid = UnitGUID(name or ("raid"..index))
		name = name or ""
		return index, name, subgroup, fileName, guid, rank, level, online, isDead, combatRole
	else
		local name, rank, subgroup, level, class, fileName, online, isDead, combatRole, _
		local unit = index == 1 and "player" or "party"..(index-1)
		local guid = UnitGUID(unit)
		if not guid then
			return
		end
		subgroup = 1
		name, _ = UnitName(unit)
		name = name or ""
		if _ then
			name = name .. "-" .. _
		end
		class, fileName = UnitClass(unit)
		if UnitIsGroupLeader(unit) then
			rank = 2
		else
			rank = 1
		end
		level = UnitLevel(unit)
		if UnitIsConnected(unit) then
			online = true
		end
		if UnitIsDeadOrGhost(unit) then
			isDead = true
		end
		combatRole = UnitGroupRolesAssigned(unit)
		return index, name, subgroup, fileName, guid, rank, level, online, isDead, combatRole
	end
end

function addon.DelUnitNameServer(unitName)
	unitName = strsplit("-", unitName)
	return unitName
end

local waHeader, waList, noWAs, addonHeader, addonList

local function updateWeakAuraList()
  local weakAuras = addon.GetWeakAuras()
  local list = {}
  for wa, data in pairs(weakAuras) do
    if not data.parent then
      list[#list+1] = wa
    end
  end
  waList.list = list
end

local function updateAddonList()
  local addons = addon.GetAddons()
  local list = {}
  for _, data in pairs(addons) do
    list[#list+1] = data
  end
  addonList.list = list
end

function waModule.options:Load()
  waHeader = AstralUI:Text(self, 'Required Raider WeakAuras'):Point('TOPLEFT', 0, 0):Shadow()
  waList = AstralUI:ScrollFrame(self):Point('TOPLEFT', waHeader, 'BOTTOMLEFT', 0, -10):Size(AstralRaidOptionsFrame.ContentWidth - 30, AstralRaidOptionsFrame.Height - 100)

	noWAs = self:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
	noWAs:SetText('WeakAuras was not found.')
	noWAs:SetPoint('CENTER', -50, 100)
	noWAs:Hide()

  AstralUI:Border(waList,2,.24,.25,.30,1)
  waList.mouseWheelRange = 50

  local function waOnClick(self)
    if self.disabled then
      AstralRaidSettings.wa.required[self:GetParent().data] = nil
      if self:GetChecked() then
        self:SetChecked(false)
      end
    elseif self:GetChecked() then
      AstralRaidSettings.wa.required[self:GetParent().data] = true
    else
      AstralRaidSettings.wa.required[self:GetParent().data] = nil
    end
  end

  waList.lines = {}
  waList.list = {}
  for i = 1, ceil(589/32) do
    local line = CreateFrame('FRAME', nil, waList.C)
    waList.lines[i] = line
    line:SetPoint("TOPLEFT",0,-(i-1)*32)
    line:SetPoint("RIGHT",0,0)
    line:SetHeight(32)
    line.chk = AstralUI:Check(line):Point("LEFT",10,0):OnClick(waOnClick)
    line.chk.CheckedTexture:SetVertexColor(0.2,1,0.2,1)
    line.waName = AstralUI:Text(line):Size(AstralRaidOptionsFrame.ContentWidth - 10, 10):FontSize(10):Point("LEFT",line.chk,"RIGHT",5,0):Shadow()
    line:Hide()
  end

  function waList:Update()
    updateWeakAuraList()

    local scroll = self.ScrollBar:GetValue()
    self:SetVerticalScroll(scroll % 32)
    local start = floor(scroll / 32) + 1

    local list = self.list
    local lineCount = 1
    for i = start, #list do
      local data = list[i]
      local line = self.lines[lineCount]
      lineCount = lineCount + 1
      if not line then
        break
      end
      line.waName:SetText(data)
      line.chk:SetChecked(AstralRaidSettings.wa.required[data])
      line.data = data
      line:Show()
    end
    for i=lineCount,#self.lines do
      self.lines[i]:Hide()
    end
    self:Height(32 * #list)
  end

  waList:SetScript('OnShow', function()
    waList:Update()
  end)

  waList.ScrollBar.slider:SetScript("OnValueChanged", function(self)
    self:GetParent():GetParent():Update()
    self:UpdateButtons()
  end)

  waList:Update()
end

function waModule.options:OnShow()
  if WeakAurasSaved then
    addon.GetWeakAuras()
    waHeader:Show()
    waList:Show()
    noWAs:Hide()
  else
    waHeader:Hide()
    waList:Hide()
    noWAs:Show()
    return
  end
end

function addonModule.options:Load()
  addonHeader = AstralUI:Text(self, 'Required Raider Addons'):Point('TOPLEFT', 0, 0):Shadow()
  addonList = AstralUI:ScrollFrame(self):Point('TOPLEFT', addonHeader, 'BOTTOMLEFT', 0, -10):Size(AstralRaidOptionsFrame.ContentWidth - 30, AstralRaidOptionsFrame.Height - 100)

  AstralUI:Border(addonList,2,.24,.25,.30,1)
  addonList.mouseWheelRange = 50

  local function addonOnClick(self)
    if self.disabled then
      AstralRaidSettings.addons.required[self:GetParent().data.name] = nil
      if self:GetChecked() then
        self:SetChecked(false)
      end
    elseif self:GetChecked() then
      AstralRaidSettings.addons.required[self:GetParent().data.name] = true
    else
      AstralRaidSettings.addons.required[self:GetParent().data.name] = nil
    end
  end

  addonList.lines = {}
  addonList.list = {}
  for i = 1, ceil(589/32) do
    local line = CreateFrame('FRAME', nil, addonList.C)
    addonList.lines[i] = line
    line:SetPoint("TOPLEFT",0,-(i-1)*32)
    line:SetPoint("RIGHT",0,0)
    line:SetHeight(32)
    line.chk = AstralUI:Check(line):Point("LEFT",10,0):OnClick(addonOnClick)
    line.chk.CheckedTexture:SetVertexColor(0.2,1,0.2,1)
    line.addonName = AstralUI:Text(line):Size(AstralRaidOptionsFrame.ContentWidth - 10, 10):FontSize(10):Point("LEFT",line.chk,"RIGHT",5,0):Shadow()
    line:Hide()
  end

  function addonList:Update()
    updateAddonList()

    local scroll = self.ScrollBar:GetValue()
    self:SetVerticalScroll(scroll % 32)
    local start = floor(scroll / 32) + 1

    local list = self.list
    local lineCount = 1
    for i = start, #list do
      local data = list[i]
      local line = self.lines[lineCount]
      lineCount = lineCount + 1
      if not line or not data then
        break
      end
      line.addonName:SetText(data.title or data.name)
      line.chk:SetChecked(AstralRaidSettings.addons.required[data.name])
      line.data = data
      line:Show()
    end
    for i=lineCount,#self.lines do
      self.lines[i]:Hide()
    end
    self:Height(32 * #list)
  end

  addonList:SetScript('OnShow', function()
    addonList:Update()
  end)

  addonList.ScrollBar.slider:SetScript("OnValueChanged", function(self)
    self:GetParent():GetParent():Update()
    self:UpdateButtons()
  end)

  addonList:Update()
end

function addonModule.options:OnShow()
  addon.GetAddons()
end