local ADDON_NAME, addon = ...
local L = addon.L

function addon.ClassColorName(unit)
  if unit and UnitExists(unit) then
    local name = UnitName(unit)
    local _, class = UnitClass(unit)
    if not class then
      return name
    else
      local classData = RAID_CLASS_COLORS[class]
      local coloredName = ('|c%s%s|r'):format(classData.colorStr, name)
      return coloredName
    end
  else
    return ''
  end
end

local function delUnitNameServer(unitName)
  unitName = strsplit("-", unitName)
  return unitName
end

local module = addon:New(L['ROSTER'], L['ROSTER_VIEW'], true, true)

local statusIcons = {
  [1] = 'Interface\\RaidFrame\\ReadyCheck-Waiting',
  [2] = 'Interface\\RaidFrame\\ReadyCheck-Ready',
  [3] = 'Interface\\RaidFrame\\ReadyCheck-NotReady',
  [4] = 'Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\dash.png',
  [5] = 'Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\ReadyCheck-NotReady-Grey.png',
}
local notInGroupText, roster, raidSlider, raidNames, updateButton
local cdRequest = 5
local lastRequest = nil

local allWeakaurasCache, allAddonsCache

local function checkButtonCooldown(self)
  if (GetTime() - lastRequest) >= cdRequest then
    self:SetText(UPDATE)
    self:Enable()
  else
    self:SetText(UPDATE .. ' (' .. cdRequest - floor(GetTime() - lastRequest) .. ')')
    C_Timer.After(1, function()
      checkButtonCooldown(self)
    end)
  end
end

function module.options:Load()
  local LISTFRAME_WIDTH = 760
  local LISTFRAME_HEIGHT = 455
  local LINE_HEIGHT, LINE_NAME_WIDTH = 18, 225
  local VERTICALNAME_WIDTH = 24
  local VERTICALNAME_COUNT = 20

  roster = AstralUI:ScrollFrame(self):Point(0, -80):Size(LISTFRAME_WIDTH, LISTFRAME_HEIGHT)
  updateButton = AstralUI:Button(self, UPDATE):Point('BOTTOMRIGHT', -15, 15):Size(130, 20):OnClick(function(self)
    addon.AddonResponses = {}
    addon.WeakAuraResponses = {}
    addon.SendWeakAuraRequest()
    addon.SendAddonsRequest()

    lastRequest = GetTime()
    self:Disable()
    checkButtonCooldown(self)
  end)

  AstralUI:Border(roster, 0)
  roster.prevTopLine = 0
  roster.prevPlayerCol = 0
  roster.ScrollBar:ClickRange(32)

  raidSlider = AstralUI:Slider(self, ''):Point('TOPLEFT', roster, 'BOTTOMLEFT', LINE_NAME_WIDTH + 15, -3):Range(0, 25):Size(VERTICALNAME_WIDTH*VERTICALNAME_COUNT):SetTo(0):OnChange(function(self, value)
    local currPlayerCol = floor(value)
    if currPlayerCol ~= roster.prevPlayerCol then
      roster.prevPlayerCol = currPlayerCol
      roster:Update()
    end
  end)

  raidSlider.Low:Hide()
  raidSlider.High:Hide()
  raidSlider.text:Hide()
  raidSlider.Low.Show = raidSlider.Low.Hide
  raidSlider.High.Show = raidSlider.High.Hide

  roster.lines = {}
  roster.list = {}

  function roster:SetIcon(self, type)
    if not type or type == 0 then -- no icon
      self:SetAlpha(0)
    elseif type == 1 then
      self:SetTexture(statusIcons[3]) -- not ready
      self:SetVertexColor(1, 1, 1, 1)
    elseif type == 2 then
      self:SetTexture(statusIcons[2]) -- ready
      self:SetVertexColor(1, 1, 1, 1)
    elseif type == 3 then
      self:SetTexture(statusIcons[1]) -- question mark
      self:SetVertexColor(1, 1, 1, 1)
    elseif type == 4 then
      self:SetTexture(statusIcons[4]) -- dash
      self:SetVertexColor(0.6, 0.6, 0.6, 1)
    elseif type == 5 then
      self:SetTexture(statusIcons[5])
      self:SetVertexColor(1, 1, 1, 1)
    end
  end

  for i = 1, ceil(LISTFRAME_HEIGHT/LINE_HEIGHT) do
    local line = CreateFrame('FRAME', nil, roster.C)
    roster.lines[i] = line
    line:SetPoint('TOPLEFT', 0, -(i-1) * LINE_HEIGHT)
    line:SetPoint('TOPRIGHT', 0, -(i-1) * LINE_HEIGHT)
    line:SetSize(0,LINE_HEIGHT)
    line.name = AstralUI:Text(line):Size(LINE_NAME_WIDTH-LINE_HEIGHT/2, LINE_HEIGHT, 9):Point('LEFT', 2, 0):Shadow():Tooltip('ANCHOR_LEFT', true)
    line.icons = {}
    local iconSize = min(VERTICALNAME_WIDTH, LINE_HEIGHT)
    for j = 1, VERTICALNAME_COUNT do
      local icon = line:CreateTexture(nil, 'ARTWORK')
      line.icons[j] = icon
      icon:SetPoint('CENTER', line, 'LEFT', LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(j-1) + VERTICALNAME_WIDTH / 2, 0)
      icon:SetSize(iconSize, iconSize)
      roster:SetIcon(icon, (i+j)%4)

      local f = CreateFrame('FRAME', nil, line)
      f:SetPoint('TOPLEFT', icon, 'TOPLEFT', 0, 0)
      f:SetSize(iconSize,iconSize)
      f:SetScript('OnEnter', function(self)
        if self.icon.t and self.icon.t ~= '' then
          AstralUI.Tooltip.Show(self, 'ANCHOR_LEFT', self.icon.t)
        end
      end)
      f:SetScript('OnLeave', AstralUI.Tooltip.Hide)
      f.icon = icon
    end
    line.t = line:CreateTexture(nil, 'BACKGROUND')
    line.t:SetAllPoints()
    line.t:SetColorTexture(1, 1, 1, .05)
    line:Hide()
  end

  raidNames = CreateFrame('FRAME', nil, self)
  for i = 1,VERTICALNAME_COUNT do
    raidNames[i] = AstralUI:Text(raidNames, 'raid'..i, 11):Point('BOTTOMLEFT', roster, 'TOPLEFT', LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(i-1), 0):Color(1, 1, 1)
    local f = CreateFrame('FRAME', nil, self)
    f:SetPoint('BOTTOMLEFT', roster, 'TOPLEFT', LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(i-1), 0)
    f:SetSize(VERTICALNAME_WIDTH, 80)
    f:SetScript('OnEnter', function(self)
      local t = self.t:GetText()
      if t ~= '' then
        AstralUI.Tooltip.Show(self, 'ANCHOR_LEFT', t)
      end
    end)
    f:SetScript('OnLeave', AstralUI.Tooltip.Hide)
    f.t = raidNames[i]

    local t = roster:CreateTexture(nil, 'BACKGROUND')
    raidNames[i].t = t
    t:SetPoint('TOPLEFT', LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(i-1), 0)
    t:SetSize(VERTICALNAME_WIDTH, LISTFRAME_HEIGHT)
    if i % 2 == 1 then
      t:SetColorTexture(.5,.5,1,.07)
      t.Vis = true
    end
  end
  local rosterRotation = raidNames:CreateAnimationGroup()
  rosterRotation:SetScript('OnFinished', function() rosterRotation:Play() end)
  local rotation = rosterRotation:CreateAnimation('Rotation')
  rotation:SetDuration(0.000001)
  rotation:SetEndDelay(2147483647)
  rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
  rotation:SetDegrees(65)
  rosterRotation:Play()

  local function sortByName(a,b)
    if a and b and a.name and b.name then
      return a.name < b.name
    end
  end

  function roster:Update()
    local l = {}
    for a, data in addon.PairsByKeys(AstralRaidSettings.addons.required) do
      if allAddonsCache and not allAddonsCache[a] then
        AstralRaidSettings.addons.required[a] = nil
      elseif data then
        l[#l+1] = {a, 'A'}
      end
    end
    for wa, data in addon.PairsByKeys(AstralRaidSettings.wa.required) do
      if allWeakaurasCache and not allWeakaurasCache[wa] then
        AstralRaidSettings.wa.required[wa] = nil
      elseif data then
        l[#l+1] = {wa, 'W'}
      end
    end
    roster.list = l

    local scroll = self.ScrollBar:GetValue()
    self:SetVerticalScroll(scroll % LINE_HEIGHT)
    local start = floor(scroll / LINE_HEIGHT) + 1

    local namesList, namesList2 = {},{}
    for _, name, class, _, _, _, _, _, _, nameWithRealm in addon.IterateRoster do

      -- Display the realm if different
      local overrideName = nil
      local shortName, realmName = strsplit('-', nameWithRealm)
      if realmName ~= nil and realmName ~= addon.GetNormalizedRealmName() then
        overrideName = nameWithRealm
      end


      namesList[#namesList + 1] = {
        name = name,
        class = class,
        overrideName = overrideName,
      }
    end
    sort(namesList, sortByName)
    if #namesList <= VERTICALNAME_COUNT then
      raidSlider:Hide()
      roster.prevPlayerCol = 0
    else
      raidSlider:Show()
      raidSlider:Range(0, #namesList - VERTICALNAME_COUNT)
    end
    local raidNamesUsed = 0
    for i = 1 + roster.prevPlayerCol, #namesList do
      raidNamesUsed = raidNamesUsed + 1
      if not raidNames[raidNamesUsed] then
        break
      end
      local overrideName = namesList[i].overrideName
      local name = delUnitNameServer(namesList[i].name)
      raidNames[raidNamesUsed]:SetText(overrideName or name)
      raidNames[raidNamesUsed]:SetTextColor(addon.ClassColorNum(namesList[i].class))
      namesList2[raidNamesUsed] = name
      if raidNames[raidNamesUsed].Vis then
        raidNames[raidNamesUsed]:SetAlpha(.05)
      end
    end
    for i = raidNamesUsed + 1, #raidNames do
      raidNames[i]:SetText('')
      raidNames[i].t:SetAlpha(0)
    end

    local weakAuras = addon.GetWeakAuras()
    local addons = addon.GetAddons()

    local list = self.list
    local lineCount = 1
    local backgroundLineStatus = (roster.prevTopLine % 2) == 1
    for i = start, #list do
      local data, t = unpack(list[i])
      local name = string.format('|cfff5e4a8%s|r ', t) .. data
      local line = self.lines[lineCount]
      lineCount = lineCount + 1
      if not line then
        break
      end
      line.name:SetText(name)
      line.data = data
      line:Show()

      line.t:SetShown(backgroundLineStatus)
      local ll, yy
      if t == 'W' then
        ll = addon.WeakAuraResponses
        yy = weakAuras
      else
        ll = addon.AddonResponses
        yy = addons
      end
      for j = 1, VERTICALNAME_COUNT do
        local pname = namesList2[j]
        if lastRequest and (not pname) then
          roster:SetIcon(line.icons[j], 0)
          line.icons[j].t = ''
        else
          local d = ll[pname]
          if lastRequest and (not d) then
            roster:SetIcon(line.icons[j], 4)
            line.icons[j].t = L['NO_RESPONSE']
          elseif not d then
            roster:SetIcon(line.icons[j], 0)
            line.icons[j].t = ''
          elseif d[data] and d[data] == true then -- has WA/Addon
            roster:SetIcon(line.icons[j], 2)
            line.icons[j].t = ''
          elseif type(d[data]) == 'string' then -- data different
            if d[data] == 'MISSING' or d[data] == 'NOT_INSTALLED' then
              roster:SetIcon(line.icons[j], 1)
              line.icons[j].t = 'Not installed'
            elseif d[data] == 'DISABLED' then
              roster:SetIcon(line.icons[j], 5)
              line.icons[j].t = 'Disabled'
            elseif d[data] == 'LOAD_NEVER' then
              roster:SetIcon(line.icons[j], 5)
              line.icons[j].t = 'Set to never load'
            else
              roster:SetIcon(line.icons[j], 3)
              line.icons[j].t = string.format('%s: %s\n%s: %s', L['YOUR_VERSION'], tostring(yy[data].version), L['THEIR_VERSION'], d[data])
            end
          elseif d and not d[data] then
            roster:SetIcon(line.icons[j], 4)
            line.icons[j].t = ''
          end
        end
      end
    end
    for i=lineCount,#self.lines do
      self.lines[i]:Hide()
    end

    self:Height(LINE_HEIGHT * #list)
  end

  roster.ScrollBar.slider:SetScript('OnValueChanged', function(self, value)
    local parent = self:GetParent():GetParent()
    parent:SetVerticalScroll(value % LINE_HEIGHT)
    local currTopLine = floor(value / LINE_HEIGHT)
    if currTopLine ~= self.prevTopLine then
      self.prevTopLine = currTopLine
      roster:Update()
    end
    self:UpdateButtons()
  end)

  notInGroupText = self:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
  notInGroupText:SetText(L['ROSTER_MUST_BE_IN_GROUP'])
  notInGroupText:SetPoint('CENTER', -50, 100)
  notInGroupText:Hide()
end

function module.options:OnShow()
  if not (IsInRaid() or IsInGroup()) then
    roster:Hide()
    raidSlider:Hide()
    raidNames:Hide()
    updateButton:Hide()
    notInGroupText:Show()
  else
    roster:Show()
    raidSlider:Show()
    raidNames:Show()
    updateButton:Show()
    notInGroupText:Hide()
    roster:Update()

    allWeakaurasCache = addon.GetWeakAuras()
    allAddonsCache = addon.GetAddons()
  end
end

function addon.UpdateRosterPage()
  if roster and roster:IsShown() then
    roster:Update()
  end
end