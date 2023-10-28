local ADDON_NAME, addon = ...

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
  addon.PrintDebug(msg, sender)
end

AstralRaidComms:RegisterPrefix('RAID', 'versionPush', envPush)
AstralRaidComms:RegisterPrefix('RAID', 'addonPush', function(...) addonPush('RAID', ...) end)
AstralRaidComms:RegisterPrefix('PARTY', 'addonPush', function(...) addonPush('PARTY', ...) end)
AstralRaidComms:RegisterPrefix('RAID', 'waPush', function(...) waPush('RAID', ...) end)
AstralRaidComms:RegisterPrefix('PARTY', 'waPush', function(...) waPush('PARTY', ...) end)

function addon.SendWeakAuraRequest()
  if not (IsInRaid() or IsInGroup()) then return end
  local channel = addon.GetInstanceChannel()

  local req = ''
  local weakAuras = addon.GetWeakAuras()
  for wa, val in pairs(AstralRaidSettings.wa.required) do
    if val and weakAuras[wa] then
      req = req .. string.format(' "%s":"%s"', wa, tostring(weakAuras[wa].version))
    end
  end

  AstralRaidComms:SendChunkedAddonMessages('waRequest', req, channel)
end

function addon.SendAddonsRequest()
  if not (IsInRaid() or IsInGroup()) then return end
  local channel = addon.GetInstanceChannel()

  local req = ''
  local addons = addon.GetAddons()
  for a, val in pairs(AstralRaidSettings.addons.required) do
    if val and addons[a] then
      req = req .. string.format(' "%s":"%s"', a, addons[a].version)
    end
  end

  AstralRaidComms:SendChunkedAddonMessages('addonRequest', req, channel)
end

local waHeader, waList, noWAs, addonHeader, addonList
local allWAs = nil
local childrenWAs = {}
local expandedWAs = {}
local parentWAs = {}

local function getChildrenWeakAuras(weakAuras, parent)
  local children = {}
  for wa, data in pairs(weakAuras) do
    if data.parent == parent then
      children[#children+1] = wa
      parentWAs[wa] = parent
    end
  end
  return children
end

local function updateWeakAuraList()
  local weakAuras = allWAs or addon.GetWeakAuras()
  local list = {}

  local function recurseChildren(name)
    if expandedWAs[name] then
      for _, child in pairs(childrenWAs[name]) do
        list[#list+1] = child
        recurseChildren(child)
      end
    end
  end

  for wa, data in addon.PairsByKeys(weakAuras) do
    if not childrenWAs[wa] then
      childrenWAs[wa] = getChildrenWeakAuras(weakAuras, wa)
    end
    if not data.parent then
      list[#list+1] = wa
    end
    recurseChildren(wa)
  end
  allWAs = weakAuras
  waList.list = list
end

local function updateAddonList()
  local addons = addon.GetAddons()
  local list = {}
  for _, data in addon.PairsByKeys(addons) do
    list[#list+1] = data
  end
  addonList.list = list
end

local function getChildLevel(wa)
  local level = 0
  local parent = parentWAs[wa]
  while parent do
    level = level + 1
    parent = parentWAs[parent]
  end
  return level
end

function waModule.options:Load()
  waHeader = AstralUI:Text(self, 'Required Raider WeakAuras'):Point('TOPLEFT', 0, 0):Shadow()
  waList = AstralUI:ScrollFrame(self):Point('TOPLEFT', waHeader, 'BOTTOMLEFT', 0, -10):Size(AstralRaidOptionsFrame.ContentWidth - 30, AstralRaidOptionsFrame.Height - 100)

  AstralUI:Button(self, REFRESH):Point('LEFT', waHeader, 'RIGHT', 10, 0):Size(100,15):OnClick(function(self)
    allWAs = nil
    expandedWAs = {}
    waList:Update()
  end)

  noWAs = self:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
  noWAs:SetText('WeakAuras addon was not found.')
  noWAs:SetPoint('CENTER', -50, 100)
  noWAs:Hide()

  AstralUI:Border(waList, 2, .24, .25, .30, 1)
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

  local function waOnExpand(self)
    if expandedWAs[self:GetParent().data] then
      expandedWAs[self:GetParent().data] = nil
      self.texture:SetTexCoord(0.25,0.3125,0.5,0.625)
    else
      expandedWAs[self:GetParent().data] = true
      self.texture:SetTexCoord(0.375,0.4375,0.5,0.625)
    end
    waList:Update()
  end

  waList.lines = {}
  waList.list = {}
  for i = 1, ceil(589/32) do
    local line = CreateFrame('FRAME', nil, waList.C)
    waList.lines[i] = line
    line:SetPoint('TOPLEFT',0, -(i-1)*32)
    line:SetPoint('RIGHT', 0, 0)
    line:SetHeight(32)
    line.expand = AstralUI:Icon(line, 'Interface\\AddOns\\'.. ADDON_NAME ..'\\media\\DiesalGUIcons16x256x128', 18, true):Point('LEFT', 10, 0):OnClick(waOnExpand)
    line.chk = AstralUI:Check(line):Point('LEFT', line.expand, 'RIGHT', 5, 0):OnClick(waOnClick)
    line.chk.CheckedTexture:SetVertexColor(0.2, 1, 0.2, 1)
    line.waName = AstralUI:Text(line):Size(AstralRaidOptionsFrame.ContentWidth - 10, 10):FontSize(10):Point('LEFT',line.chk,'RIGHT',5,0):Shadow()
    line.y = -(i-1)*32
    line:Hide()
  end

  function waList:Update()
    AstralUI:UpdateScrollList(self, 32, updateWeakAuraList, function(line, data)
      line.waName:SetText(data)
      local children = childrenWAs[data]
      if #children == 0 then line.expand:Hide() else line.expand:Show() end
      if expandedWAs[data] then
        line.expand.texture:SetTexCoord(0.25, 0.3125, 0.5, 0.625)
      else
        line.expand.texture:SetTexCoord(0.375, 0.4375, 0.5, 0.625)
      end
      line:SetPoint('TOPLEFT', math.min(getChildLevel(data)*10, AstralRaidOptionsFrame.ContentWidth - 40), line.y)
      line:SetPoint('RIGHT', 0, 0)
      line.chk:SetChecked(AstralRaidSettings.wa.required[data])
    end)
  end

  waList:SetScript('OnShow', function()
    waList:Update()
  end)

  waList.ScrollBar.slider:SetScript('OnValueChanged', function(self)
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

  AstralUI:Border(addonList, 2, .24, .25, .30, 1)
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
    line:SetPoint('TOPLEFT',0,-(i-1)*32)
    line:SetPoint('RIGHT',0,0)
    line:SetHeight(32)
    line.chk = AstralUI:Check(line):Point('LEFT', 10, 0):OnClick(addonOnClick)
    line.chk.CheckedTexture:SetVertexColor(0.2, 1, 0.2, 1)
    line.addonName = AstralUI:Text(line):Size(AstralRaidOptionsFrame.ContentWidth - 10, 10):FontSize(10):Point('LEFT', line.chk, 'RIGHT', 5, 0):Shadow()
    line:Hide()
  end

  function addonList:Update()
    AstralUI:UpdateScrollList(self, 32, updateAddonList, function(line, data)
      line.addonName:SetText(data.title or data.name)
      line.chk:SetChecked(AstralRaidSettings.addons.required[data.name])
    end)
  end

  addonList:SetScript('OnShow', function()
    addonList:Update()
  end)

  addonList.ScrollBar.slider:SetScript('OnValueChanged', function(self)
    self:GetParent():GetParent():Update()
    self:UpdateButtons()
  end)

  addonList:Update()
end

function addonModule.options:OnShow()
  addon.GetAddons()
end