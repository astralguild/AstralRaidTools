local ADDON_NAME, addon = ...

function addon.TextureToText(textureName, widthInText, heightInText, textureWidth, textureHeight, l, r, t, b)
  return '|T' .. textureName .. ':' .. (widthInText or 0) .. ':' .. (heightInText or 0) .. ':0:0:' .. textureWidth .. ':' .. textureHeight .. ':' ..
    format('%d', l*textureWidth) .. ':' ..format('%d', r*textureWidth) .. ':' .. format ('%d',t*textureHeight) .. ':' .. format('%d', b*textureHeight) .. '|t'
end

function addon.GetRaidTargetText(icon, size)
  size = size or 0
  return addon.TextureToText([[Interface\TargetingFrame\UI-RaidTargetingIcons]], size, size, 256, 256, ((icon-1)%4)/4, ((icon-1)%4+1)/4, floor((icon-1)/4)/4, (floor((icon-1)/4)+1)/4)
end

function addon.LinkItem(itemID, itemLink)
  if not itemLink then
    if not itemID then
      return
    end
    itemLink = select(2, GetItemInfo(itemID))
  end
  if not itemLink then
    return
  end
  if IsModifiedClick('DRESSUP') then
    return DressUpItemLink(itemLink)
  else
    if ChatEdit_GetActiveWindow() then
      ChatEdit_InsertLink(itemLink)
    else
      ChatFrame_OpenChat(itemLink)
    end
  end
end

-- Large amount of code copied and modified from ExRT Functions, Library

AstralUI = {}
local templates = {}

function AstralUI:Template(name, parent)
  if not templates[name] then
    return
  end
  return templates[name](nil, parent)
end

local Mod = nil
do
  local function Widget_SetPoint(self, arg1, arg2, arg3, arg4, arg5)
    if arg1 == 'x' then arg1 = self:GetParent() end
    if arg2 == 'x' then arg2 = self:GetParent() end
    if type(arg1) == 'number' and type(arg2) == 'number' then
      arg1, arg2, arg3 = 'TOPLEFT', arg1, arg2
    end
    if type(arg1) == 'table' and not arg2 then
      self:SetAllPoints(arg1)
      return self
    end
    if arg5 then
      self:SetPoint(arg1, arg2, arg3, arg4, arg5)
    elseif arg4 then
      self:SetPoint(arg1, arg2, arg3, arg4)
    elseif arg3 then
      self:SetPoint(arg1, arg2, arg3)
    elseif arg2 then
      self:SetPoint(arg1, arg2)
    else
      self:SetPoint(arg1)
    end
    return self
  end
  local function Widget_SetSize(self, ...)
    self:SetSize(...)
    return self
  end
  local function Widget_SetNewPoint(self, ...)
    self:ClearAllPoints()
    self:Point(...)
    return self
  end
  local function Widget_SetScale(self, ...)
    self:SetScale(...)
    return self
  end
  local function Widget_OnClick(self, func)
    self:SetScript('OnClick', func)
    return self
  end
  local function Widget_OnShow(self, func, disableFirstRun)
    if not func then
      self:SetScript('OnShow', nil)
      return self
    end
    self:SetScript('OnShow', func)
    if not disableFirstRun then
      func(self)
    end
    return self
  end
  local function Widget_Run(self, func, ...)
    func(self, ...)
    return self
  end
  local function Widget_Shown(self, bool)
    if bool then self:Show() else self:Hide() end
    return self
  end
  local function Widget_OnEnter(self, func)
    self:SetScript('OnEnter', func)
    return self
  end
  local function Widget_OnLeave(self, func)
    self:SetScript('OnLeave', func)
    return self
  end
  function Mod(self,...)
    self.Point = Widget_SetPoint
    self.Size = Widget_SetSize
    self.NewPoint = Widget_SetNewPoint
    self.Scale = Widget_SetScale
    self.OnClick = Widget_OnClick
    self.OnShow = Widget_OnShow
    self.Run = Widget_Run
    self.Shown = Widget_Shown
    self.OnEnter = Widget_OnEnter
    self.OnLeave = Widget_OnLeave
    for i = 1, select('#', ...) do
      if i % 2 == 1 then
        local funcName, func = select(i, ...)
        self[funcName] = func
      end
    end
  end
  AstralUI.ModObjFuncs = Mod
end

do
  local function close(self)
    self:GetParent():Hide()
  end
  function templates:AstralOptionsFrame(parent, logoPath)
    local self = CreateFrame('FRAME', nil, parent, BackdropTemplateMixin and 'BackdropTemplate')

    self:SetSize(850, 650)
    self:SetFrameStrata('HIGH')
    self:SetToplevel(true)
    self:EnableMouse(true)
    self:SetPoint('CENTER')

    self.Width = 850
    self.Height = 650
    self.ListWidth = 165
    self.MenuBarWidth = 50
    self.ContentWidth = self.Width - self.ListWidth - self.MenuBarWidth

    self.HeaderText = self:CreateFontString(nil, 'ARTWORK', 'InterUIBold_Normal')
    self.HeaderText:SetPoint('TOP', 0, -14)
    self.HeaderText:SetTextColor(1, 1, 1, 1)

    self.background = self:CreateTexture(nil, 'BACKGROUND')
    self.background:SetAllPoints(self)
    self.background:SetColorTexture(33/255, 33/255, 33/255, 0.5)

    local menuBar = CreateFrame('FRAME', nil, self)
    menuBar:SetWidth(self.MenuBarWidth)
    menuBar:SetHeight(self.Height)
    menuBar:SetPoint('TOPLEFT', self, 'TOPLEFT')
    menuBar.texture = menuBar:CreateTexture(nil, 'BACKGROUND')
    menuBar.texture:SetAllPoints(menuBar)
    menuBar.texture:SetColorTexture(33/255, 33/255, 33/255, 0.8)
    self.MenuBar = menuBar

    local icon = menuBar:CreateTexture(nil, 'ARTWORK')
    icon:SetAlpha(0.8)
    icon:SetSize(24, 24)
    icon:SetPoint('TOPLEFT', menuBar, 'TOPLEFT', 13, -10)
    menuBar.Icon = icon

    local logo = CreateFrame('BUTTON', nil, menuBar)
    logo:SetSize(32, 32)
    logo:SetPoint('BOTTOMLEFT', menuBar, 'BOTTOMLEFT', 10, 10)
    logo:SetAlpha(0.8)
    logo:SetNormalTexture(logoPath or ('Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\logo.png'))
    logo:SetScript('OnClick', function()
      self.GuildInfo:SetShown(not self.GuildInfo:IsShown())
    end)
    logo:SetScript('OnEnter', function(self)
      self:SetAlpha(1)
      end)
    logo:SetScript('OnLeave', function(self)
      self:SetAlpha(0.8)
    end)
    self.Logo = logo

    local closeButton = CreateFrame('BUTTON', nil, self)
    closeButton:SetNormalTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\baseline-close-24px@2x.tga')
    closeButton:SetSize(12, 12)
    closeButton:GetNormalTexture():SetVertexColor(.8, .8, .8, 0.8)
    closeButton:SetScript('OnClick', close)
    closeButton:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -14, -14)
    closeButton:SetScript('OnEnter', function(self) self:GetNormalTexture():SetVertexColor(126/255, 126/255, 126/255, 0.8) end)
    closeButton:SetScript('OnLeave', function(self) self:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8) end)

    self.GuildInfo, self.GuildText = AstralUI:GuildInfo(self)
    return self
  end
end

function templates:AstralButtonTransparentTemplate(parent,isSecure)
  local self = isSecure and CreateFrame('Button', nil, parent, isSecure) or CreateFrame('Button', nil, parent)
  self:SetSize(40, 18)

  self.HighlightTexture = self:CreateTexture()
  self.HighlightTexture:SetColorTexture(1, 1, 1, .1)
  self.HighlightTexture:SetPoint('TOPLEFT')
  self.HighlightTexture:SetPoint('BOTTOMRIGHT')
  self:SetHighlightTexture(self.HighlightTexture)

  self.PushedTexture = self:CreateTexture()
  self.PushedTexture:SetColorTexture(.9, .8, .1, .3)
  self.PushedTexture:SetPoint('TOPLEFT')
  self.PushedTexture:SetPoint('BOTTOMRIGHT')
  self:SetPushedTexture(self.PushedTexture)

  self:SetNormalFontObject('GameFontNormal')
  self:SetHighlightFontObject('GameFontHighlight')
  self:SetDisabledFontObject('GameFontDisable')
  return self
end

function templates:AstralButtonModernTemplate(parent, isSecure)
  local self = templates:AstralButtonTransparentTemplate(parent, isSecure)
  templates:Border(self, 0, 0, 0, 1, 1)
  self.Texture = self:CreateTexture(nil, 'BACKGROUND')
  self.Texture:SetColorTexture(1, 1, 1, .3)
  self.Texture:SetPoint('TOPLEFT')
  self.Texture:SetPoint('BOTTOMRIGHT')
  self.DisabledTexture = self:CreateTexture()
  self.DisabledTexture:SetColorTexture(0.20, 0.21, 0.25, 0.5)
  self.DisabledTexture:SetPoint('TOPLEFT')
  self.DisabledTexture:SetPoint('BOTTOMRIGHT')
  self:SetDisabledTexture(self.DisabledTexture)
  return self
end

function templates:AstralDialogTemplate(parent)
  local self = CreateFrame('FRAME', nil, parent)

  self.TopLeft = self:CreateTexture(nil, 'OVERLAY')
  self.TopLeft:SetPoint('TOPLEFT')
  self.TopLeft:SetTexture('Interface\\PaperDollInfoFrame\\UI-GearManager-Border')
  self.TopLeft:SetSize(64, 64)
  self.TopLeft:SetTexCoord(0.501953125, 0.625, 0, 1)

  self.TopRight = self:CreateTexture(nil, 'OVERLAY')
  self.TopRight:SetPoint('TOPRIGHT')
  self.TopRight:SetTexture('Interface\\PaperDollInfoFrame\\UI-GearManager-Border')
  self.TopRight:SetSize(64, 64)
  self.TopRight:SetTexCoord(0.625, 0.75, 0, 1)

  self.Top = self:CreateTexture(nil, 'OVERLAY')
  self.Top:SetPoint('TOPLEFT', self.TopLeft, 'TOPRIGHT')
  self.Top:SetPoint('TOPRIGHT', self.TopRight, 'TOPLEFT')
  self.Top:SetTexture('Interface\\PaperDollInfoFrame\\UI-GearManager-Border')
  self.Top:SetSize(0, 64)
  self.Top:SetTexCoord(0.25, 0.369140625, 0, 1)

  self.BottomLeft = self:CreateTexture(nil, 'OVERLAY')
  self.BottomLeft:SetPoint('BOTTOMLEFT')
  self.BottomLeft:SetTexture('Interface\\PaperDollInfoFrame\\UI-GearManager-Border')
  self.BottomLeft:SetSize(64, 64)
  self.BottomLeft:SetTexCoord(0.751953125, 0.875, 0, 1)

  self.BottomRight = self:CreateTexture(nil, 'OVERLAY')
  self.BottomRight:SetPoint('BOTTOMRIGHT')
  self.BottomRight:SetTexture('Interface\\PaperDollInfoFrame\\UI-GearManager-Border')
  self.BottomRight:SetSize(64, 64)
  self.BottomRight:SetTexCoord(0.875, 1, 0, 1)

  self.Bottom = self:CreateTexture(nil, 'OVERLAY')
  self.Bottom:SetPoint('BOTTOMLEFT', self.BottomLeft, 'BOTTOMRIGHT')
  self.Bottom:SetPoint('BOTTOMRIGHT', self.BottomRight, 'BOTTOMLEFT')
  self.Bottom:SetTexture('Interface\\PaperDollInfoFrame\\UI-GearManager-Border')
  self.Bottom:SetSize(0, 64)
  self.Bottom:SetTexCoord(0.376953125, 0.498046875, 0, 1)

  self.Left = self:CreateTexture(nil, 'OVERLAY')
  self.Left:SetPoint('TOPLEFT', self.TopLeft, 'BOTTOMLEFT')
  self.Left:SetPoint('BOTTOMLEFT', self.BottomLeft, 'TOPLEFT')
  self.Left:SetTexture('Interface\\PaperDollInfoFrame\\UI-GearManager-Border')
  self.Left:SetSize(64, 0)
  self.Left:SetTexCoord(0.001953125, 0.125, 0, 1)

  self.Right = self:CreateTexture(nil, 'OVERLAY')
  self.Right:SetPoint('TOPRIGHT', self.TopRight, 'BOTTOMRIGHT')
  self.Right:SetPoint('BOTTOMRIGHT', self.BottomRight, 'TOPRIGHT')
  self.Right:SetTexture('Interface\\PaperDollInfoFrame\\UI-GearManager-Border')
  self.Right:SetSize(64, 0)
  self.Right:SetTexCoord(0.1171875, 0.2421875, 0, 1)

  self.TitleBG = self:CreateTexture(nil, 'BACKGROUND')
  self.TitleBG:SetPoint('TOPLEFT', 8, -7)
  self.TitleBG:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', -8, -24)
  self.TitleBG:SetTexture('Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background')

  self.DialogBG = self:CreateTexture(nil, 'BACKGROUND')
  self.DialogBG:SetPoint('TOPLEFT', 8, -24)
  self.DialogBG:SetPoint('BOTTOMRIGHT', -6, 8)
  self.DialogBG:SetTexture('Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-L1')
  self.DialogBG:SetTexCoord(0.255, 1, 0.29, 1)

  self.title = self:CreateFontString(nil, 'OVERLAY', 'InterUIBold_Normal')
  self.title:SetPoint('TOPLEFT', 12, -8)
  self.title:SetPoint('TOPRIGHT', -32, -24)

  self.Close = CreateFrame('Button', nil, self, 'UIPanelCloseButton')
  self.Close:SetPoint('TOPRIGHT', 2, 1)
  return self
end

do
  local function HideBorders(self)
    self.BorderTop:Hide()
    self.BorderLeft:Hide()
    self.BorderBottom:Hide()
    self.BorderRight:Hide()
  end
  function templates:Border(self, cR, cG, cB, cA, size, offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    self.BorderTop = self.BorderTop or self:CreateTexture(nil, 'BACKGROUND')
    self.BorderTop:SetColorTexture(cR, cG, cB, cA)
    self.BorderTop:SetPoint('TOPLEFT', -size-offsetX, size+offsetY)
    self.BorderTop:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', size+offsetX, offsetY)

    self.BorderLeft = self.BorderLeft or self:CreateTexture(nil, 'BACKGROUND')
    self.BorderLeft:SetColorTexture(cR, cG, cB, cA)
    self.BorderLeft:SetPoint('TOPLEFT', -size-offsetX, offsetY)
    self.BorderLeft:SetPoint('BOTTOMRIGHT', self, 'BOTTOMLEFT', -offsetX, -offsetY)

    self.BorderBottom = self.BorderBottom or self:CreateTexture(nil, 'BACKGROUND')
    self.BorderBottom:SetColorTexture(cR, cG, cB, cA)
    self.BorderBottom:SetPoint('BOTTOMLEFT', -size-offsetX, -size-offsetY)
    self.BorderBottom:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', size+offsetX, -offsetY)

    self.BorderRight = self.BorderRight or self:CreateTexture(nil, 'BACKGROUND')
    self.BorderRight:SetColorTexture(cR, cG, cB, cA)
    self.BorderRight:SetPoint('BOTTOMRIGHT', size+offsetX, offsetY)
    self.BorderRight:SetPoint('TOPLEFT', self, 'TOPRIGHT', offsetX, -offsetY)

    self.HideBorders = HideBorders
  end
  AstralUI.Templates_Border = templates.Border
end

function templates:AstralCheckButtonTemplate(parent)
  local self = CreateFrame('CheckButton', nil, parent)
  self:SetSize(20, 20)
  templates:Border(self, 0.24, 0.25, 0.3, 1, 1)

  self.Texture = self:CreateTexture(nil, 'BACKGROUND')
  self.Texture:SetColorTexture(0, 0, 0, .3)
  self.Texture:SetPoint('TOPLEFT')
  self.Texture:SetPoint('BOTTOMRIGHT')

  self.CheckedTexture = self:CreateTexture()
  self.CheckedTexture:SetTexture('Interface\\Buttons\\UI-CheckBox-Check')
  self.CheckedTexture:SetPoint('TOPLEFT', -4, 4)
  self.CheckedTexture:SetPoint('BOTTOMRIGHT', 4, -4)
  self:SetCheckedTexture(self.CheckedTexture)

  self.PushedTexture = self:CreateTexture()
  self.PushedTexture:SetTexture('Interface\\Buttons\\UI-CheckBox-Check')
  self.PushedTexture:SetPoint('TOPLEFT', -4, 4)
  self.PushedTexture:SetPoint('BOTTOMRIGHT', 4, -4)
  self.PushedTexture:SetVertexColor(0.8, 0.8, 0.8, 0.5)
  self.PushedTexture:SetDesaturated(true)
  self:SetPushedTexture(self.PushedTexture)

  self.DisabledTexture = self:CreateTexture()
  self.DisabledTexture:SetTexture('Interface\\Buttons\\UI-CheckBox-Check-Disabled')
  self.DisabledTexture:SetPoint('TOPLEFT', -4, 4)
  self.DisabledTexture:SetPoint('BOTTOMRIGHT', 4, -4)
  self:SetDisabledTexture(self.DisabledTexture)

  self.HighlightTexture = self:CreateTexture()
  self.HighlightTexture:SetColorTexture(1, 1, 1, .3)
  self.HighlightTexture:SetPoint('TOPLEFT')
  self.HighlightTexture:SetPoint('BOTTOMRIGHT')
  self:SetHighlightTexture(self.HighlightTexture)
  return self
end

do
  local function OnEnter(self)
    if (self:IsEnabled()) then
      if (self.tooltipText) then
        GameTooltip:SetOwner(self, self.tooltipOwnerPoint or 'ANCHOR_RIGHT')
        GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
      end
      if (self.tooltipRequirement) then
        GameTooltip:AddLine(self.tooltipRequirement, 1.0, 1.0, 1.0, 1.0)
        GameTooltip:Show()
      end
    end
  end
  local function OnLeave(self)
    GameTooltip:Hide()
  end
  function templates:AstralSliderTemplate(parent)
    local self = CreateFrame('Slider', nil, parent, BackdropTemplateMixin and 'BackdropTemplate')
    self:SetOrientation('HORIZONTAL')
    self:SetSize(144, 17)
    self:SetHitRectInsets(0, 0, -10, -10)
    self:SetBackdrop({
      bgFile='Interface\\Buttons\\UI-SliderBar-Background',
      edgeFile='Interface\\Buttons\\UI-SliderBar-Border',
      tile = true,
      insets = {left = 3, right = 3, top = 6,	bottom = 6},
      tileSize = 8,
      edgeSize = 8,
    })

    self.Text = self:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    self.Text:SetPoint('BOTTOM', self, 'TOP')

    self.Low = self:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
    self.Low:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', -4, 3)
    self.High = self:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
    self.High:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 4, 3)

    self.Thumb = self:CreateTexture()
    self.Thumb:SetTexture('Interface\\Buttons\\UI-SliderBar-Button-Horizontal')
    self.Thumb:SetSize(32, 32)
    self:SetThumbTexture(self.Thumb)

    self:SetScript('OnEnter', OnEnter)
    self:SetScript('OnLeave', OnLeave)
    return self
  end
  function templates:AstralSliderModernTemplate(parent)
    local self = CreateFrame('Slider', nil, parent)
    self:SetOrientation('HORIZONTAL')
    self:SetSize(144, 10)

    self.Text = self:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    self.Text:SetPoint('BOTTOM', self, 'TOP', 0, 1)

    self.Low = self:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
    self.Low:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -1)
    self.High = self:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
    self.High:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -1)

    templates:Border(self, 0.24, 0.25, 0.3, 1, 1, 1, 0)

    self.Thumb = self:CreateTexture()
    self.Thumb:SetColorTexture(1, 206/255, 0, 0.7)
    self.Thumb:SetSize(16, 8)
    self:SetThumbTexture(self.Thumb)

    self:SetScript('OnEnter', OnEnter)
    self:SetScript('OnLeave', OnLeave)
    return self
  end
  function templates:AstralSliderModernVerticalTemplate(parent)
    local self = CreateFrame('Slider', nil, parent)
    self:SetOrientation('VERTICAL')
    self:SetSize(10, 144)

    self.Text = self:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    self.Text:SetPoint('BOTTOM', self, 'TOP', 0, 1)

    self.Low = self:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
    self.Low:SetPoint('TOPLEFT', self, 'TOPRIGHT', 1, -1)
    self.High = self:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
    self.High:SetPoint('BOTTOMLEFT', self, 'BOTTOMRIGHT', 1, 1)

    templates:Border(self, 0.24, 0.25, 0.3, 1, 1, 0, 1)

    self.Thumb = self:CreateTexture()
    self.Thumb:SetColorTexture(0.44, 0.45, 0.50, 0.7)
    self.Thumb:SetSize(8, 16)
    self:SetThumbTexture(self.Thumb)

    self:SetScript('OnEnter', OnEnter)
    self:SetScript('OnLeave', OnLeave)
    return self
  end
end

do
  local function OnClick(self)
    self:Hide()
  end
  local function OnShow(self)
    self:SetFrameLevel(1000)
    if self.OnShow then
      self:OnShow()
    end
  end
  local function OnUpdate(self, elapsed)
    AstralUI.ScrollDropDown.Update(self, elapsed)
  end
  function templates:AstralDropDownListTemplate(parent)
    local self = CreateFrame('Button', nil, parent)
    self:SetFrameStrata('TOOLTIP')
    self:EnableMouse(true)
    self:Hide()
    self.Backdrop = CreateFrame('FRAME', nil, self, BackdropTemplateMixin and 'BackdropTemplate')
    self.Backdrop:SetAllPoints()
    self.Backdrop:SetBackdrop({
      bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
      edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
      tile = true,
      insets = {
        left = 11,
        right = 12,
        top = 11,
        bottom = 9,
      },
      tileSize = 32,
      edgeSize = 32,
    })
    self:SetScript('OnClick', OnClick)
    self:SetScript('OnShow', OnShow)
    self:SetScript('OnUpdate', OnUpdate)
    return self
  end
  function templates:AstralDropDownListModernTemplate(parent)
    local self = CreateFrame('Button', nil, parent)
    self:SetFrameStrata('TOOLTIP')
    self:EnableMouse(true)
    self:Hide()
    templates:Border(self, 0, 0, 0, 1, 1)
    self.Background = self:CreateTexture(nil, 'BACKGROUND')
    self.Background:SetColorTexture(0, 0, 0, .9)
    self.Background:SetPoint('TOPLEFT')
    self.Background:SetPoint('BOTTOMRIGHT')
    self:SetScript('OnClick', OnClick)
    self:SetScript('OnShow', OnShow)
    self:SetScript('OnUpdate', OnUpdate)
    return self
  end
end

do
  local function OnEnter(self)
    local parent = self:GetParent()
    local s = parent:GetScript('OnEnter')
    if s then s(parent) end
  end
  local function OnLeave(self)
    local parent = self:GetParent()
    local s = parent:GetScript('OnLeave')
    if s then s(parent) end
  end
  local function OnClick(self)
    ToggleDropDownMenu(nil, nil, self:GetParent())
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  end
  function templates:AstralUIChatDownButtonTemplate(parent)
    local self = CreateFrame('Button', nil, parent)
    self:SetSize(24, 24)

    self.NormalTexture = self:CreateTexture()
    self.NormalTexture:SetTexture('Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up')
    self.NormalTexture:SetSize(24, 24)
    self.NormalTexture:SetPoint('RIGHT')
    self:SetNormalTexture(self.NormalTexture)

    self.PushedTexture = self:CreateTexture()
    self.PushedTexture:SetTexture('Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down')
    self.PushedTexture:SetSize(24, 24)
    self.PushedTexture:SetPoint('RIGHT')
    self:SetPushedTexture(self.PushedTexture)

    self.DisabledTexture = self:CreateTexture()
    self.DisabledTexture:SetTexture('Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled')
    self.DisabledTexture:SetSize(24, 24)
    self.DisabledTexture:SetPoint('RIGHT')
    self:SetDisabledTexture(self.DisabledTexture)

    self.HighlightTexture = self:CreateTexture()
    self.HighlightTexture:SetTexture('Interface\\Buttons\\UI-Common-MouseHilight')
    self.HighlightTexture:SetSize(24, 24)
    self.HighlightTexture:SetPoint('RIGHT')
    self:SetHighlightTexture(self.HighlightTexture, 'ADD')

    self:SetScript('OnEnter', OnEnter)
    self:SetScript('OnLeave', OnLeave)
    self:SetScript('OnClick', OnClick)
    return self
  end
end

do
  local function OnHide(self)
    CloseDropDownMenus()
  end
  function templates:AstralDropDownMenuTemplate(parent)
    local self = CreateFrame('FRAME', nil, parent)
    self:SetSize(40, 32)

    self.Left = self:CreateTexture(nil, 'ARTWORK')
    self.Left:SetPoint('TOPLEFT', 0, 17)
    self.Left:SetTexture('Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame')
    self.Left:SetSize(25, 64)
    self.Left:SetTexCoord(0, 0.1953125, 0, 1)
    self.Middle = self:CreateTexture(nil, 'ARTWORK')
    self.Middle:SetPoint('LEFT', self.Left, 'RIGHT')
    self.Middle:SetTexture('Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame')
    self.Middle:SetSize(115, 64)
    self.Middle:SetTexCoord(0.1953125, 0.8046875, 0, 1)
    self.Right = self:CreateTexture(nil, 'ARTWORK')
    self.Right:SetPoint('LEFT', self.Middle, 'RIGHT')
    self.Right:SetTexture('Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame')
    self.Right:SetSize(25, 64)
    self.Right:SetTexCoord(0.8046875, 1, 0, 1)

    self.Text = self:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
    self.Text:SetWordWrap(false)
    self.Text:SetJustifyH('RIGHT')
    self.Text:SetSize(0, 10)
    self.Text:SetPoint('RIGHT', self.Right, -43, 2)

    self.Icon = self:CreateTexture(nil, 'OVERLAY')
    self.Icon:Hide()
    self.Icon:SetPoint('LEFT', 30, 2)
    self.Icon:SetSize(16, 16)

    self.Button = AstralUI:Template('AstralUIChatDownButtonTemplate', self)
    self.Button:SetPoint('TOPRIGHT', self.Right, -16, -18)
    self.Button:SetMotionScriptsWhileDisabled(true)

    self:SetScript('OnHide', OnHide)
    return self
  end
  function templates:AstralDropDownButtonModernTemplate(parent)
    local self = AstralUI:Template('AstralUIChatDownButtonTemplate', parent)
    self:SetSize(16, 16)
    self:SetMotionScriptsWhileDisabled(true)

    self.NormalTexture:SetTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\media\\DiesalGUIcons16x256x128')
    self.NormalTexture:SetTexCoord(0.25, 0.3125, 0.5, 0.625)
    self.NormalTexture:SetVertexColor(1, 1, 1, .7)
    self.NormalTexture:SetSize(0, 0)
    self.NormalTexture:ClearAllPoints()
    self.NormalTexture:SetPoint('TOPLEFT', -5, 2)
    self.NormalTexture:SetPoint('BOTTOMRIGHT', 5, -2)

    self.PushedTexture:SetTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\media\\DiesalGUIcons16x256x128')
    self.PushedTexture:SetTexCoord(0.25, 0.3125, 0.5, 0.625)
    self.PushedTexture:SetVertexColor(1, 1, 1, 1)
    self.PushedTexture:SetSize(0, 0)
    self.PushedTexture:ClearAllPoints()
    self.PushedTexture:SetPoint('TOPLEFT', -5, 1)
    self.PushedTexture:SetPoint('BOTTOMRIGHT', 5, -3)

    self.DisabledTexture:SetTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\media\\DiesalGUIcons16x256x128')
    self.DisabledTexture:SetTexCoord(0.25, 0.3125, 0.5, 0.625)
    self.DisabledTexture:SetVertexColor(.4, .4, .4, 1)
    self.DisabledTexture:SetSize(0, 0)
    self.DisabledTexture:ClearAllPoints()
    self.DisabledTexture:SetPoint('TOPLEFT', -5, 2)
    self.DisabledTexture:SetPoint('BOTTOMRIGHT', 5, -2)

    self.HighlightTexture:SetColorTexture(1, 1, 1, .3)
    self.HighlightTexture:SetSize(0, 0)
    self.HighlightTexture:ClearAllPoints()
    self.HighlightTexture:SetPoint('TOPLEFT')
    self.HighlightTexture:SetPoint('BOTTOMRIGHT')
    self:SetHighlightTexture(self.HighlightTexture)

    templates:Border(self,0.24,0.25,0.30,1,1)

    self.Background = self:CreateTexture(nil,'BACKGROUND')
    self.Background:SetColorTexture(0,0,0,.3)
    self.Background:SetPoint('TOPLEFT')
    self.Background:SetPoint('BOTTOMRIGHT')
    return self
  end
  function templates:AstralDropDownMenuModernTemplate(parent)
    local self = CreateFrame('FRAME', nil, parent)
    self:SetSize(40, 20)

    self.Text = self:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
    self.Text:SetWordWrap(false)
    self.Text:SetJustifyH('RIGHT')
    self.Text:SetJustifyV('MIDDLE')
    self.Text:SetSize(0,20)
    self.Text:SetPoint('RIGHT', -24, 0)
    self.Text:SetPoint('LEFT', 4, 0)

    templates:Border(self, 0.24, 0.25, 0.30, 1, 1)

    self.Background = self:CreateTexture(nil,'BACKGROUND')
    self.Background:SetColorTexture(0, 0, 0, .3)
    self.Background:SetPoint('TOPLEFT')
    self.Background:SetPoint('BOTTOMRIGHT')

    self.Button = AstralUI:Template('AstralDropDownButtonModernTemplate', self)
    self.Button:SetPoint('RIGHT', -2, 0)

    self:SetScript('OnHide', OnHide)
    return self
  end
end

do
  local function OnEnter(self)
    self.Highlight:Show()
    if (self.tooltipTitle) then
      if (self.tooltipOnButton) then
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:AddLine(self.tooltipTitle, 1.0, 1.0, 1.0)
        GameTooltip:AddLine(self.tooltipText)
        GameTooltip:Show()
      else
        GameTooltip_AddNewbieTip(self, self.tooltipTitle, 1.0, 1.0, 1.0, self.tooltipText, true)
      end
    end
    if (self.NormalText:IsTruncated()) then
      GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
      GameTooltip:AddLine(self.NormalText:GetText())
      GameTooltip:Show()
    end
    AstralUI.ScrollDropDown.OnButtonEnter(self)
  end
  local function OnLeave(self)
    self.Highlight:Hide()
    GameTooltip:Hide()
    AstralUI.ScrollDropDown.OnButtonLeave(self)
  end
  local function OnClick(self, button, down)
    AstralUI.ScrollDropDown.OnClick(self, button, down)
  end
  local function OnLoad(self)
    self:SetFrameLevel(self:GetParent():GetFrameLevel()+2)
  end
  function templates:AstralDropDownMenuButtonTemplate(parent)
    local self = CreateFrame('Button', nil, parent)
    self:SetSize(100, 16)

    self.Highlight = self:CreateTexture(nil, 'BACKGROUND')
    self.Highlight:SetTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight')
    self.Highlight:SetAllPoints()
    self.Highlight:SetBlendMode('ADD')
    self.Highlight:Hide()

    self.Texture = self:CreateTexture(nil, 'BACKGROUND', nil, -8)
    self.Texture:Hide()
    self.Texture:SetAllPoints()

    self.Icon = self:CreateTexture(nil, 'ARTWORK')
    self.Icon:SetSize(16, 16)
    self.Icon:SetPoint('LEFT')
    self.Icon:Hide()

    self.Arrow = self:CreateTexture(nil,'ARTWORK')
    self.Arrow:SetTexture('Interface\\ChatFrame\\ChatFrameExpandArrow')
    self.Arrow:SetSize(16, 16)
    self.Arrow:SetPoint('RIGHT')
    self.Arrow:Hide()

    self.NormalText = self:CreateFontString()
    self.NormalText:SetPoint('LEFT')

    self:SetFontString(self.NormalText)

    self:SetNormalFontObject('GameFontHighlightSmallLeft')
    self:SetHighlightFontObject('GameFontHighlightSmallLeft')
    self:SetDisabledFontObject('GameFontDisableSmallLeft')

    self:SetPushedTextOffset(1, -1)

    self:SetScript('OnEnter', OnEnter)
    self:SetScript('OnLeave', OnLeave)
    self:SetScript('OnClick', OnClick)
    self:SetScript('OnLoad', OnLoad)
    return self
  end
end

function templates:AstralRadioButtonModernTemplate(parent)
  local self = CreateFrame('CheckButton', nil, parent)
  self:SetSize(16,16)

  self.text = self:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmall')
  self.text:SetPoint('LEFT', self, 'RIGHT', 5, 0)
  self:SetFontString(self.text)

  self.NormalTexture = self:CreateTexture()
  self.NormalTexture:SetTexture('Interface\\Addons\\' ..ADDON_NAME.. '\\Media\\radioModern')
  self.NormalTexture:SetAllPoints()
  self.NormalTexture:SetTexCoord(0, 0.25, 0, 1)
  self:SetNormalTexture(self.NormalTexture)

  self.HighlightTexture = self:CreateTexture()
  self.HighlightTexture:SetTexture('Interface\\Addons\\' ..ADDON_NAME.. '\\Media\\radioModern')
  self.HighlightTexture:SetAllPoints()
  self.HighlightTexture:SetTexCoord(0.5, 0.75, 0, 1)
  self:SetHighlightTexture(self.HighlightTexture)

  self.CheckedTexture = self:CreateTexture()
  self.CheckedTexture:SetTexture('Interface\\Addons\\'..ADDON_NAME..'\\Media\\radioModern')
  self.CheckedTexture:SetAllPoints()
  self.CheckedTexture:SetTexCoord(0.25, 0.5, 0, 1)
  self:SetCheckedTexture(self.CheckedTexture)
  return self
end

do
  local function OnMouseDown(self)
    local parent = self:GetParent()
    parent.Icon:SetPoint('TOPLEFT', parent, 'TOPLEFT', 8, -8)
    parent.IconOverlay:Show()
  end
  local function OnMouseUp(self)
    local parent = self:GetParent()
    parent.Icon:SetPoint('TOPLEFT', parent, 'TOPLEFT', 6, -6)
    parent.IconOverlay:Hide()
  end
  function templates:AstralTrackingButtonModernTemplate(parent)
    local self = CreateFrame('FRAME', nil, parent)
    self:SetSize(32, 32)
    self:SetHitRectInsets(0, 0, -10, -10)

    self.Icon = self:CreateTexture(nil, 'ARTWORK')
    self.Icon:SetPoint('TOPLEFT', 6, -6)
    self.Icon:SetTexture('Interface\\Minimap\\Tracking\\None')
    self.Icon:SetSize(20, 20)

    self.IconOverlay = self:CreateTexture(nil, 'ARTWORK')
    self.IconOverlay:SetPoint('TOPLEFT', self.Icon)
    self.IconOverlay:SetPoint('BOTTOMRIGHT', self.Icon)
    self.IconOverlay:SetColorTexture(0, 0, 0, 0.5)

    self.Button = CreateFrame('Button', nil, self)
    self.Button:SetSize(32, 32)
    self.Button:SetPoint('TOPLEFT')

    self.Button.Border = self.Button:CreateTexture(nil, 'BORDER')
    self.Button.Border:SetPoint('TOPLEFT')
    self.Button.Border:SetTexture('Interface\\Addons\\' .. ADDON_NAME .. '\\media\\radioModern')
    self.Button.Border:SetSize(32, 32)
    self.Button.Border:SetTexCoord(0, 0.25, 0, 1)

    self.Button.Shine = self.Button:CreateTexture(nil, 'OVERLAY')
    self.Button.Shine:SetPoint('TOPLEFT', 2, -2)
    self.Button.Shine:SetTexture('Interface\\ComboFrame\\ComboPoint')
    self.Button.Shine:SetBlendMode('ADD')
    self.Button.Shine:Hide()
    self.Button.Shine:SetSize(27, 27)
    self.Button.Shine:SetTexCoord(0.5625, 1, 0, 1)

    self.Button:SetScript('OnMouseDown', OnMouseDown)
    self.Button:SetScript('OnMouseUp', OnMouseUp)

    self.Button:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight', 'ADD')
    return self
  end
end

function templates:AstralCheckButtonModernTemplate(parent)
  local self = CreateFrame('CheckButton', nil, parent)
  self:SetSize(20, 20)

  self.text = self:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
  self.text:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
  self.text:SetPoint('BOTTOMLEFT', self, 'BOTTOMRIGHT', 4, 0)
  self.text:SetJustifyV('MIDDLE')
  self:SetFontString(self.text)

  templates:Border(self, 0.24, 0.25, 0.3, 1, 1)

  self.Texture = self:CreateTexture(nil, 'BACKGROUND')
  self.Texture:SetColorTexture(0, 0, 0, .3)
  self.Texture:SetPoint('TOPLEFT')
  self.Texture:SetPoint('BOTTOMRIGHT')

  self.CheckedTexture = self:CreateTexture()
  self.CheckedTexture:SetTexture('Interface\\Buttons\\UI-CheckBox-Check')
  self.CheckedTexture:SetPoint('TOPLEFT', -4, 4)
  self.CheckedTexture:SetPoint('BOTTOMRIGHT', 4, -4)
  self:SetCheckedTexture(self.CheckedTexture)

  self.PushedTexture = self:CreateTexture()
  self.PushedTexture:SetTexture('Interface\\Buttons\\UI-CheckBox-Check')
  self.PushedTexture:SetPoint('TOPLEFT', -4, 4)
  self.PushedTexture:SetPoint('BOTTOMRIGHT', 4, -4)
  self.PushedTexture:SetVertexColor(0.8, 0.8, 0.8, 0.5)
  self.PushedTexture:SetDesaturated(true)
  self:SetPushedTexture(self.PushedTexture)

  self.DisabledTexture = self:CreateTexture()
  self.DisabledTexture:SetTexture('Interface\\Buttons\\UI-CheckBox-Check-Disabled')
  self.DisabledTexture:SetPoint('TOPLEFT', -4, 4)
  self.DisabledTexture:SetPoint('BOTTOMRIGHT', 4, -4)
  self:SetDisabledTexture(self.DisabledTexture)

  self.HighlightTexture = self:CreateTexture()
  self.HighlightTexture:SetColorTexture(1, 1, 1, .3)
  self.HighlightTexture:SetPoint('TOPLEFT')
  self.HighlightTexture:SetPoint('BOTTOMRIGHT')
  self:SetHighlightTexture(self.HighlightTexture)

  return self
end

do
  local function Widget_Icon(self,texture,cG,cB,cA)
    if cG then
      self.texture:SetColorTexture(texture,cG,cB,cA)
    else
      self.texture:SetTexture(texture)
    end
    return self
  end
  local function Widget_Tooltip(self, text)
    self:SetScript('OnEnter', AstralUI.Tooltip.Std)
    self:SetScript('OnLeave', AstralUI.Tooltip.Hide)
    self.tooltipText = text
    return self
  end
  function AstralUI:Icon(parent, textureIcon, size, isButton)
    local self = CreateFrame(isButton and 'Button' or 'Frame', nil, parent)
    self:SetSize(size,size)
    self.texture = self:CreateTexture(nil, "BACKGROUND")
    self.texture:SetAllPoints()
    self.texture:SetTexture(textureIcon or 'Interface\\Icons\\INV_MISC_QUESTIONMARK')
    if isButton then
       self:EnableMouse(true)
      self:RegisterForClicks('LeftButtonDown')
    end
    Mod(self,
      'Icon', Widget_Icon,
      'Tooltip', Widget_Tooltip
    )
    return self
  end
end

do
  function AstralUI:Shadow(parent,size,edgeSize)
    local self = CreateFrame('FRAME', nil, parent, BackdropTemplateMixin and 'BackdropTemplate')
    self:SetPoint('LEFT', -size, 0)
    self:SetPoint('RIGHT', size, 0)
    self:SetPoint('TOP', 0, size)
    self:SetPoint('BOTTOM', 0, -size)
    self:SetBackdrop({edgeFile='Interface/AddOns/' .. ADDON_NAME .. '/media/shadow', edgeSize = edgeSize or 28, insets={left=size, right=size, top=size, bottom=size}})
    self:SetBackdropBorderColor(0, 0, 0, .45)
    return self
  end
end

do
  local function SliderOnMouseWheel(self,delta)
    if tonumber(self:GetValue()) == nil then
      return
    end
    if self.isVertical then
      delta = -delta
    end
    self:SetValue(tonumber(self:GetValue()) + delta)
  end
  local function SliderTooltipShow(self)
    local text = self.text:GetText()
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    GameTooltip:SetText(self.tooltipText or '')
    GameTooltip:AddLine(text or '', 1, 1, 1)
    GameTooltip:Show()
  end
  local function SliderTooltipReload(self)
    if GameTooltip:IsVisible() then
      self:tooltipHide()
      self:tooltipShow()
    end
  end
  local function Widget_Range(self,minVal,maxVal,hideRange)
    self.Low:SetText(minVal)
    self.High:SetText(maxVal)
    self:SetMinMaxValues(minVal, maxVal)
    if not self.isVertical then
      self.Low:SetShown(not hideRange)
      self.High:SetShown(not hideRange)
    end
    return self
  end
  local function Widget_Size(self,size)
    if self:GetOrientation() == 'VERTICAL' then
      self:SetHeight(size)
    else
      self:SetWidth(size)
    end
    return self
  end
  local function Widget_SetTo(self,value)
    if not value then
      local _, max = self:GetMinMaxValues()
      value = max
    end
    self.tooltipText = value
    self:SetValue(value)
    return self
  end
  local function Widget_OnChange(self, func)
    self:SetScript('OnValueChanged', func)
    return self
  end
  local function Widget_SetTooltip(self, tooltipText)
    self.tooltipText = tooltipText
    return self
  end
  local function Widget_SetObey(self, bool)
    self:SetObeyStepOnDrag(bool)
    return self
  end

  function AstralUI:Slider(parent,text,isVertical,template)
    if template == 0 then
      template = 'AstralSliderTemplate'
    elseif not template then
      template = isVertical and 'AstralSliderModernVerticalTemplate' or 'AstralSliderModernTemplate'
    end
    local self = AstralUI:Template(template, parent) or CreateFrame('Slider', nil, parent, template)
    self.text = self.Text
    self.text:SetText(text or '')
    if isVertical then
      self.Low:Hide()
      self.High:Hide()
      self.text:Hide()
      self.isVertical = true
    end
    self:SetOrientation(isVertical and 'VERTICAL' or 'HORIZONTAL')
    self:SetValueStep(1)
    self.isVertical = isVertical
    self:SetScript('OnMouseWheel', SliderOnMouseWheel)
    self.tooltipShow = SliderTooltipShow
    self.tooltipHide = GameTooltip_Hide
    self.tooltipReload = SliderTooltipReload
    self:SetScript('OnEnter', self.tooltipShow)
    self:SetScript('OnLeave', self.tooltipHide)

    Mod(self)
    self.Range = Widget_Range
    self.SetTo = Widget_SetTo
    self.OnChange = Widget_OnChange
    self.Tooltip = Widget_SetTooltip
    self.SetObey = Widget_SetObey

    if template and template:find('^AstralSliderModern') then
      self._Size = self.Size
      self.Size = Widget_Size
      self.text:SetFont(self.text:GetFont(), 10, '')
      self.Low:SetFont(self.Low:GetFont(), 10, '')
      self.High:SetFont(self.High:GetFont(), 10, '')
    end
    return self
  end
  function AstralUI.CreateSlider(parent, width, height, x, y, minVal, maxVal, text, defVal, relativePoint, isVertical, isModern)
    return AstralUI:Slider(parent, text, isVertical, (not isModern) and 0):Size(width, height):Point(relativePoint or 'TOPLEFT', x, y):Range(minVal, maxVal):SetTo(defVal or maxVal)
  end
end

do
  local function DropDown_OnEnter(self)
    if self.tooltip then
      AstralUI.Tooltip.Show(self, nil, self.tooltip, self.Text:IsTruncated() and self.Text:GetText())
    elseif self.Text:IsTruncated() then
      AstralUI.Tooltip.Show(self, nil, self.Text:GetText())
    end
  end
  local function DropDown_OnLeave(self)
    GameTooltip_Hide()
  end
  local function ScrollDropDownOnHide(self)
    AstralUI:DropDownClose()
  end
  local function Widget_SetSize(self, width)
    if self.Middle then
      self.Middle:SetWidth(width)
      local defaultPadding = 25
      self:_SetWidth(width + defaultPadding + defaultPadding)
      self.Text:SetWidth(width - defaultPadding)
    else
      self:_SetWidth(width)
    end
    self.noResize = true
    return self
  end
  local function Widget_SetText(self,text)
    self.Text:SetText(text)
    return self
  end
  local function Widget_SetTooltip(self,text)
    self.tooltip = text
    self:SetScript('OnEnter', DropDown_OnEnter)
    self:SetScript('OnLeave', DropDown_OnLeave)
    return self
  end
  local function Widget_AddText(self, text, size, extra_func)
    self.labelText = AstralUI:Text(self, text, size or 10):Point('LEFT', self, 'LEFT', 5, 0):Center():Middle():Color():Shadow()
    if type(extra_func) == 'function' then
      self.labelText:Run(extra_func)
    end
    return self
  end
  local function Widget_Disable(self)
    self.Button:Disable()
    return self
  end
  local function Widget_Enable(self)
    self.Button:Enable()
    return self
  end
  local function DropDown_OnClick(self, ...)
    local parent = self:GetParent()
    if parent.PreUpdate then
      parent.PreUpdate(parent)
    end
    AstralUI.ScrollDropDown.ClickButton(self, ...)
  end

  local function Widget_ColorBorder(self, cR, cG, cB, cA)
    if type(cR) == 'number' then
      AstralUI:Templates_Border(self, cR, cG, cB, cA, 1)
    elseif cR then
      AstralUI:Templates_Border(self, 0.74, 0.25, 0.3, 1, 1)
    else
      AstralUI:Templates_Border(self, 0.24, 0.25, 0.3, 1, 1)
    end
    return self
  end

  function AstralUI:DropDown(parent,width,lines,template)
    template = template == 0 and 'AstralDropDownMenuTemplate' or template or 'AstralDropDownMenuModernTemplate'
    local self = AstralUI:Template(template, parent) or CreateFrame('FRAME', nil, parent, template)

    self.Button:SetScript('OnClick', DropDown_OnClick)
    self:SetScript('OnHide', ScrollDropDownOnHide)

    self.List = {}
    self.Width = width
    self.Lines = lines or 10
    if lines == -1 then
      self.Lines = nil
    end
    if template == 'AstralDropDownMenuModernTemplate' then
      self.isModern = true
    end
    self.relativeTo = self.Left

    Mod(self,
      'SetText', Widget_SetText,
      'Tooltip', Widget_SetTooltip,
      'AddText', Widget_AddText,
      'Disable', Widget_Disable,
      'Enable', Widget_Enable,
      'ColorBorder', Widget_ColorBorder
    )
    self._Size = self.Size
    self.Size = Widget_SetSize
    self._SetWidth = self.SetWidth
    self.SetWidth = Widget_SetSize
    return self
  end

  function AstralUI:DropDownButton(parent,defText,dropDownWidth,lines,template)
    local self = AstralUI:Button(parent,defText,template)

    self:SetScript('OnClick', AstralUI.ScrollDropDown.ClickButton)
    self:SetScript('OnHide', ScrollDropDownOnHide)

    self.List = {}
    self.Width = dropDownWidth
    self.Lines = lines or 10

    self.isButton = true
    return self
  end
end

AstralUI.ScrollDropDown = {}
AstralUI.ScrollDropDown.List = {}
local ScrollDropDown_Blizzard, ScrollDropDown_Modern = {},{}

for i = 1, 2 do
  ScrollDropDown_Modern[i] = AstralUI:Template('AstralDropDownListModernTemplate', UIParent)
  _G[ADDON_NAME .. 'DropDownListModern' .. i] = ScrollDropDown_Modern[i]
  ScrollDropDown_Modern[i]:SetClampedToScreen(true)
  ScrollDropDown_Modern[i].border = AstralUI:Shadow(ScrollDropDown_Modern[i], 20)
  ScrollDropDown_Modern[i].Buttons = {}
  ScrollDropDown_Modern[i].MaxLines = 0
  ScrollDropDown_Modern[i].isModern = true
  do
    ScrollDropDown_Modern[i].Animation = CreateFrame('FRAME', nil, ScrollDropDown_Modern[i])
    ScrollDropDown_Modern[i].Animation:SetSize(1, 1)
    ScrollDropDown_Modern[i].Animation:SetPoint('CENTER')
    ScrollDropDown_Modern[i].Animation.P = 0
    ScrollDropDown_Modern[i].Animation.parent = ScrollDropDown_Modern[i]
    ScrollDropDown_Modern[i].Animation:SetScript('OnUpdate', function(self,elapsed)
      self.P = self.P + elapsed
      local P = self.P
      if P > 2.5 then
        P = P % 2.5
        self.P = P
      end
      local color = P <= 1 and P / 2 or P <= 1.5 and 0.5 or (2.5 - P)/2
      local parent = self.parent
      parent.BorderTop:SetColorTexture(color, color, color, 1)
      parent.BorderLeft:SetColorTexture(color, color, color, 1)
      parent.BorderBottom:SetColorTexture(color, color, color, 1)
      parent.BorderRight:SetColorTexture(color, color, color, 1)
    end)
  end

  ScrollDropDown_Modern[i].Slider = AstralUI.CreateSlider(ScrollDropDown_Modern[i], 10, 170, -8, -8, 1, 10, 'Text', 1, 'TOPRIGHT', true, true)
  ScrollDropDown_Modern[i].Slider:SetScript('OnValueChanged', function (self, value)
    value = Round(value)
    self:GetParent().Position = value
    AstralUI.ScrollDropDown:Reload()
  end)

  ScrollDropDown_Modern[i]:SetScript('OnMouseWheel', function (self, delta)
    local min, max = self.Slider:GetMinMaxValues()
    local val = self.Slider:GetValue()
    if (val - delta) < min then
      self.Slider:SetValue(min)
    elseif (val - delta) > max then
      self.Slider:SetValue(max)
    else
      self.Slider:SetValue(val - delta)
    end
  end)
end

for i = 1, 2 do
  ScrollDropDown_Blizzard[i] = AstralUI:Template('AstralDropDownListTemplate', UIParent)
  _G[ADDON_NAME .. 'DropDownList'..i] = ScrollDropDown_Blizzard[i]
  ScrollDropDown_Blizzard[i].Buttons = {}
  ScrollDropDown_Blizzard[i].MaxLines = 0
  ScrollDropDown_Blizzard[i].Slider = AstralUI.CreateSlider(ScrollDropDown_Blizzard[i], 10, 170, -15, -11, 1, 10, 'Text', 1, 'TOPRIGHT', true)
  ScrollDropDown_Blizzard[i].Slider:SetScript('OnValueChanged', function (self, value)
    value = Round(value)
    self:GetParent().Position = value
    AstralUI.ScrollDropDown:Reload()
  end)

  ScrollDropDown_Blizzard[i]:SetScript('OnMouseWheel', function (self, delta)
    local min,max = self.Slider:GetMinMaxValues()
    local val = self.Slider:GetValue()
    if (val - delta) < min then
      self.Slider:SetValue(min)
    elseif (val - delta) > max then
      self.Slider:SetValue(max)
    else
      self.Slider:SetValue(val - delta)
    end
  end)
end

AstralUI.ScrollDropDown.DropDownList = ScrollDropDown_Blizzard

do
  local function CheckButtonClick(self)
    local parent = self:GetParent()
    self:GetParent():GetParent().List[parent.id].checkState = self:GetChecked()
    if parent.checkFunc then
      parent.checkFunc(parent, self:GetChecked())
    end
  end
  function AstralUI.ScrollDropDown.CreateButton(i, level)
    level = level or 1
    local dropDown = AstralUI.ScrollDropDown.DropDownList[level]
    if dropDown.Buttons[i] then
      return
    end
    dropDown.Buttons[i] = AstralUI:Template('AstralDropDownMenuButtonTemplate', dropDown)
    if dropDown.isModern then
      dropDown.Buttons[i]:SetPoint('TOPLEFT', 8, -8 - (i-1) * 16)
    else
      dropDown.Buttons[i]:SetPoint('TOPLEFT', 18, -16 - (i-1) * 16)
    end
    dropDown.Buttons[i].NormalText:SetMaxLines(1)
    if dropDown.isModern then
      dropDown.Buttons[i].checkButton = AstralUI:Template('AstralCheckButtonModernTemplate', dropDown.Buttons[i])
      dropDown.Buttons[i].checkButton:SetPoint('LEFT', 1, 0)
      dropDown.Buttons[i].checkButton:SetSize(12, 12)

      dropDown.Buttons[i].radioButton = AstralUI:Template('AstralRadioButtonModernTemplate', dropDown.Buttons[i])
      dropDown.Buttons[i].radioButton:SetPoint('LEFT', 1, 0)
      dropDown.Buttons[i].radioButton:SetSize(12, 12)
      dropDown.Buttons[i].radioButton:EnableMouse(false)
    else
      dropDown.Buttons[i].checkButton = CreateFrame('CheckButton', nil, dropDown.Buttons[i], 'UICheckButtonTemplate')
      dropDown.Buttons[i].checkButton:SetPoint('LEFT', -7, 0)
      dropDown.Buttons[i].checkButton:SetScale(.6)
      dropDown.Buttons[i].radioButton = CreateFrame('CheckButton', nil, dropDown.Buttons[i])	-- Do not used in blizzard style
    end
    dropDown.Buttons[i].checkButton:SetScript('OnClick', CheckButtonClick)
    dropDown.Buttons[i].checkButton:Hide()
    dropDown.Buttons[i].radioButton:Hide()
    dropDown.Buttons[i].Level = level
  end
end

local function ScrollDropDown_DefaultCheckFunc(self)
  self:Click()
end

local IsDropDownCustom

function AstralUI.ScrollDropDown.ClickButton(self)
  if AstralUI.ScrollDropDown.DropDownList[1]:IsShown() then
    AstralUI:DropDownClose()
    return
  end
  local dropDown = nil
  if self.isButton then
    dropDown = self
  else
    dropDown = self:GetParent()
  end
  IsDropDownCustom = nil
  AstralUI.ScrollDropDown.ToggleDropDownMenu(dropDown)
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

function AstralUI.ScrollDropDown:Reload(level)
  for j = 1, #AstralUI.ScrollDropDown.DropDownList do
    if AstralUI.ScrollDropDown.DropDownList[j]:IsShown() or level == j then
      local val = AstralUI.ScrollDropDown.DropDownList[j].Position
      local count = #AstralUI.ScrollDropDown.DropDownList[j].List
      local now = 0
      for i = val, count do
        local data = AstralUI.ScrollDropDown.DropDownList[j].List[i]
        if not data.isHidden then
          now = now + 1
          local button = AstralUI.ScrollDropDown.DropDownList[j].Buttons[now]
          local text = button.NormalText
          local icon = button.Icon
          local paddingLeft = data.padding or 0
          if data.icon then
            icon:SetTexture(data.icon)
            paddingLeft = paddingLeft + 18
            if data.iconcoord then
              icon:SetTexCoord(unpack(data.iconcoord))
              icon.customcoord = true
            elseif icon.customcoord then
              icon:SetTexCoord(0, 1, 0, 1)
              icon.customcoord = false
            end
            icon:Show()
          else
            icon:Hide()
          end
          if data.font then
            local font = _G[ADDON_NAME..'DropDownListFont'..now]
            if not font then
              font = CreateFont(ADDON_NAME..'DropDownListFont'..now)
            end
            font:SetFont(data.font, 12, '')
            font:SetShadowOffset(1, -1)
            font:SetShadowColor(0, 0, 0)
            button:SetNormalFontObject(font)
            button:SetHighlightFontObject(font)
          else
            button:SetNormalFontObject(GameFontHighlightSmallLeft)
            button:SetHighlightFontObject(GameFontHighlightSmallLeft)
          end
          if data.colorCode then
            text:SetText(data.colorCode .. (data.text or '') .. '|r')
          else
            text:SetText(data.text or '')
          end
          text:ClearAllPoints()
          if data.checkable or data.radio then
            text:SetPoint('LEFT', paddingLeft + 16, 0)
          else
            text:SetPoint('LEFT', paddingLeft, 0)
          end
          text:SetPoint('RIGHT', button, 'RIGHT', 0, 0)
          text:SetJustifyH(data.justifyH or 'LEFT')
          if data.checkable then
            button.checkButton:SetChecked(data.checkState)
            button.checkButton:Show()
          else
            button.checkButton:Hide()
          end
          if data.radio then
            button.radioButton:SetChecked(data.checkState)
            button.radioButton:Show()
          else
            button.radioButton:Hide()
          end
          local texture = button.Texture
          if data.texture then
            texture:SetTexture(data.texture)
            texture:Show()
          else
            texture:Hide()
          end
          if data.subMenu then
            button.Arrow:Show()
          else
            button.Arrow:Hide()
          end
          if data.isTitle then
            button:SetEnabled(false)
          else
            button:SetEnabled(true)
          end
          button.id = i
          button.arg1 = data.arg1
          button.arg2 = data.arg2
          button.arg3 = data.arg3
          button.arg4 = data.arg4
          button.func = data.func
          button.hoverFunc = data.hoverFunc
          button.leaveFunc = data.leaveFunc
          button.hoverArg = data.hoverArg
          button.checkFunc = data.checkFunc
          button.tooltip = data.tooltip
          if not data.checkFunc then
            button.checkFunc = ScrollDropDown_DefaultCheckFunc
          end
          button.subMenu = data.subMenu
          button.Lines = data.Lines --Max lines for second level
          button.data = data
          button:Show()
          if now >= AstralUI.ScrollDropDown.DropDownList[j].LinesNow then
            break
          end
        end
      end
      for i = (now+1), AstralUI.ScrollDropDown.DropDownList[j].MaxLines do
        AstralUI.ScrollDropDown.DropDownList[j].Buttons[i]:Hide()
      end
    end
  end
end

function AstralUI.ScrollDropDown.UpdateChecks()
  local parent = AstralUI.ScrollDropDown.DropDownList[1].parent
  if parent.additionalToggle then
    parent.additionalToggle(parent)
  end
  for j = 1, #AstralUI.ScrollDropDown.DropDownList do
    for i = 1, #AstralUI.ScrollDropDown.DropDownList[j].Buttons do
      local button = AstralUI.ScrollDropDown.DropDownList[j].Buttons[i]
      if button:IsShown() and button.data then
        button.checkButton:SetChecked(button.data.checkState)
      end
    end
  end
end

function AstralUI.ScrollDropDown.Update(self, elapsed)
  if (not self.showTimer or not self.isCounting) then
    return
  elseif (self.showTimer < 0) then
    self:Hide()
    self.showTimer = nil
    self.isCounting = nil
  else
    self.showTimer = self.showTimer - elapsed
  end
end

function AstralUI.ScrollDropDown.OnClick(self, button, down)
  local func = self.func
  if func then
    func(self, self.arg1, self.arg2, self.arg3, self.arg4)
  end
end
function AstralUI.ScrollDropDown.OnButtonEnter(self)
  local func = self.hoverFunc
  if func then
    func(self, self.hoverArg)
  end
  if self.tooltip then
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    GameTooltip:AddLine(self.tooltip)
    GameTooltip:Show()
  end
  AstralUI.ScrollDropDown:CloseSecondLevel(self.Level)
  if self.subMenu then
    if IsDropDownCustom then
      AstralUI.ScrollDropDown.ToggleDropDownMenu(self, 2, self.subMenu, IsDropDownCustom)
    else
      AstralUI.ScrollDropDown.ToggleDropDownMenu(self, 2)
    end
  end
end
function AstralUI.ScrollDropDown.OnButtonLeave(self)
  local func = self.leaveFunc
  if func then
    func(self)
  end
  if self.tooltip then
    GameTooltip_Hide()
  end
end

function AstralUI.ScrollDropDown.EasyMenu(self, list, customWidth)
  IsDropDownCustom = customWidth or 200
  AstralUI.ScrollDropDown.ToggleDropDownMenu(self, nil, list, customWidth)
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

function AstralUI.ScrollDropDown.ToggleDropDownMenu(self, level, customList, customWidth)
  level = level or 1
  if self.ToggleUpadte then
    self:ToggleUpadte()
  end

  if level == 1 then
    if self.isModern or customList then
      AstralUI.ScrollDropDown.DropDownList = ScrollDropDown_Modern
    else
      AstralUI.ScrollDropDown.DropDownList = ScrollDropDown_Blizzard
    end
  end
  for i = level+1, #AstralUI.ScrollDropDown.DropDownList do
    AstralUI.ScrollDropDown.DropDownList[i]:Hide()
  end
  local dropDown = AstralUI.ScrollDropDown.DropDownList[level]

  local dropDownWidth = customWidth or (type(self.Width) == 'number' and self.Width) or (customList and 200) or IsDropDownCustom or 200
  local isModern = self.isModern or (customList and true)
  if level > 1 then
    local parent = AstralUI.ScrollDropDown.DropDownList[1].parent
    dropDownWidth = (type(parent.Width) == 'number' and parent.Width) or IsDropDownCustom or 200
    isModern = parent.isModern or (customList and true)
  end

  dropDown.List = customList or self.subMenu or self.List
  local count = #dropDown.List
  local maxLinesNow = self.Lines or count

  for i = (dropDown.MaxLines + 1), maxLinesNow do
    AstralUI.ScrollDropDown.CreateButton(i, level)
  end
  dropDown.MaxLines = max(dropDown.MaxLines, maxLinesNow)

  local isSliderHidden = max(count-maxLinesNow+1, 1) == 1
  if isModern then
    for i = 1, maxLinesNow do
      dropDown.Buttons[i]:SetSize(dropDownWidth - 16 - (isSliderHidden and 0 or 12), 16)
    end
  else
    for i = 1, maxLinesNow do
      dropDown.Buttons[i]:SetSize(dropDownWidth - 22 + (isSliderHidden and 16 or 0), 16)
    end
  end
  dropDown.Position = 1
  dropDown.LinesNow = maxLinesNow
  dropDown.Slider:SetValue(1)
  if self.additionalToggle then
    self.additionalToggle(self)
  end
  dropDown:ClearAllPoints()
  dropDown:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', -16, 0)
  dropDown.Slider:SetMinMaxValues(1, max(count-maxLinesNow+1, 1))
  if isModern then
    dropDown:SetSize(dropDownWidth,16 + 16 * maxLinesNow)
    dropDown.Slider:SetHeight(maxLinesNow * 16)
  else
    dropDown:SetSize(dropDownWidth + 32,32 + 16 * maxLinesNow)
    dropDown.Slider:SetHeight(maxLinesNow * 16 + 10)
  end
  if isSliderHidden then
    dropDown.Slider:Hide()
  else
    dropDown.Slider:Show()
  end
  dropDown:ClearAllPoints()
  if level > 1 then
    if dropDownWidth and dropDownWidth + AstralUI.ScrollDropDown.DropDownList[level-1]:GetRight() > GetScreenWidth() then
      dropDown:SetPoint('TOP', self, 'TOP', 0, 8)
      dropDown:SetPoint('RIGHT', AstralUI.ScrollDropDown.DropDownList[level-1], 'LEFT', -5, 0)
    else
      dropDown:SetPoint('TOPLEFT', self, 'TOPRIGHT', level > 1 and AstralUI.ScrollDropDown.DropDownList[level-1].Slider:IsShown() and 24 or 12, isModern and 8 or 16)
    end
  else
    local toggleX = self.toggleX or -16
    local toggleY = self.toggleY or 0
    dropDown:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', toggleX, toggleY)
  end

  dropDown.parent = self
  dropDown:Show()
  dropDown:SetFrameLevel(0)
  AstralUI.ScrollDropDown:Reload()
end

function AstralUI.ScrollDropDown.CreateInfo(self, info)
  if info then
    self.List[#self.List + 1] = info
  end
  self.List[#self.List + 1] = {}
  return self.List[#self.List]
end

function AstralUI.ScrollDropDown.ClearData(self)
  table.wipe(self.List)
  return self.List
end

function AstralUI.ScrollDropDown.Close()
  AstralUI.ScrollDropDown.DropDownList[1]:Hide()
  AstralUI.ScrollDropDown:CloseSecondLevel()
end
function AstralUI.ScrollDropDown:CloseSecondLevel(level)
  level = level or 1
  for i = (level+1), #AstralUI.ScrollDropDown.DropDownList do
    AstralUI.ScrollDropDown.DropDownList[i]:Hide()
  end
end
AstralUI.DropDownClose = AstralUI.ScrollDropDown.Close

do
  local function CheckBoxOnEnter(self)
    local tooltipTitle = self.text:GetText()
    local tooltipText = self.tooltipText
    if tooltipTitle == '' or not tooltipTitle then
      tooltipTitle = tooltipText
      tooltipText = nil
    end
    AstralUI.Tooltip.Show(self, 'ANCHOR_TOP', tooltipTitle, {tooltipText, 1, 1, 1, true})
  end
  local function Widget_Tooltip(self, text)
    self.tooltipText = text
    return self
  end
  local function Widget_Left(self,relativeX)
    self.text:ClearAllPoints()
    self.text:SetPoint('RIGHT', self, 'LEFT', relativeX and relativeX*(-1) or -2, 0)
    return self
  end
  local function Widget_TextSize(self,size)
    self.text:SetFont(self.text:GetFont(), size)
    return self
  end

  local function Widget_ColorState(self,isBorderInsteadText)
    if isBorderInsteadText then
      local cR, cG, cB
      if self.disabled or not self:IsEnabled() then
        cR, cG, cB = .5, .5, .5
      elseif self:GetChecked() then
        cR, cG, cB = .2, .8, .2
      else
        cR, cG, cB = .8, .2, .2
      end
      self.BorderTop:SetColorTexture(cR, cG, cB, 1)
      self.BorderLeft:SetColorTexture(cR, cG, cB, 1)
      self.BorderBottom:SetColorTexture(cR, cG, cB, 1)
      self.BorderRight:SetColorTexture(cR, cG, cB, 1)
    elseif self.disabled or not self:IsEnabled() then
      self.text:SetTextColor(.5, .5, .5, 1)
    elseif self:GetChecked() then
      self.text:SetTextColor(.3, 1, .3, 1)
    else
      self.text:SetTextColor(1, .4, .4, 1)
    end
    return self
  end

  local function Widget_ColorState_SetCheckedHandler(self, ...)
    self:_SetChecked(...)
    self:ColorState(self.colorStateIsBorderInsteadText)
  end
  local function Widget_PostClickHandler(self)
    self:ColorState(self.colorStateIsBorderInsteadText)
  end
  local function Widget_AddColorState(self, isBorderInsteadText)
    self.colorStateIsBorderInsteadText = isBorderInsteadText
    self:SetScript('PostClick', Widget_PostClickHandler)
    self:ColorState(isBorderInsteadText)
    self._SetChecked = self.SetChecked
    self.SetChecked = Widget_ColorState_SetCheckedHandler
    return self
  end

  function AstralUI:Check(parent,text,state,template)
    if template == 0 then
      template = 'UICheckButtonTemplate'
    elseif not template then
      template = 'AstralCheckButtonTemplate'
    end
    local self = AstralUI:Template(template, parent) or CreateFrame('CheckButton', nil, parent, template)
    self.text = AstralUI:Text(self):FontSize(10):Point('LEFT', self, 'RIGHT', 5, 0):Shadow()
    self.text:SetText(text)
    self:SetChecked(state and true or false)
    self:SetScript('OnEnter', CheckBoxOnEnter)
    self:SetScript('OnLeave', AstralUI.Tooltip.Hide)
    self.defSetSize = self.SetSize

    Mod(self)
    self.Tooltip = Widget_Tooltip
    self.Left = Widget_Left
    self.TextSize = Widget_TextSize
    self.ColorState = Widget_ColorState
    self.AddColorState = Widget_AddColorState
    return self
  end
end

function AstralUI:GuildInfo(frame)
  local astralGuildInfo
  local guildVersionString = CreateFrame('BUTTON', nil, frame)
  guildVersionString:SetNormalFontObject('InterUIRegular_Small')
  guildVersionString:SetSize(110, 20)
  guildVersionString:SetPoint('BOTTOM', frame, 'BOTTOM', 0, 10)
  guildVersionString:SetAlpha(0.65)

  guildVersionString:SetScript('OnEnter', function(self) self:SetAlpha(1) end)
  guildVersionString:SetScript('OnLeave', function(self) self:SetAlpha(0.65) end)
  guildVersionString:SetScript('OnClick', function()
    astralGuildInfo:SetShown(not astralGuildInfo:IsShown())
  end)

  astralGuildInfo = CreateFrame('FRAME', nil, frame, BackdropTemplateMixin and 'BackdropTemplate')
  astralGuildInfo:Hide()
  astralGuildInfo:SetFrameLevel(8)
  astralGuildInfo:SetSize(300, 150)
  astralGuildInfo:EnableKeyboard(true)
  astralGuildInfo:SetPoint('BOTTOM', UIParent, 'TOP', 0, -300)

  astralGuildInfo.background = astralGuildInfo:CreateTexture(nil, 'BACKGROUND')
  astralGuildInfo.background:SetAllPoints(astralGuildInfo)
  astralGuildInfo.background:SetColorTexture(33/255, 33/255, 33/255, 0.8)

  astralGuildInfo.title = astralGuildInfo:CreateFontString(nil, 'OVERLAY', 'InterUIBold_Normal')
  astralGuildInfo.title:SetPoint('TOP', astralGuildInfo, 'TOP', 0, -10)
  astralGuildInfo.title:SetText(ADDON_NAME)

  astralGuildInfo.author = astralGuildInfo:CreateFontString(nil, 'OVERLAY', 'InterUIRegular_Normal')
  astralGuildInfo.author:SetPoint('TOP', astralGuildInfo.title, 'BOTTOM', 0, -20)
  astralGuildInfo.author:SetText('Made by Luna <Astral> @ Area 52')

  astralGuildInfo.visit = astralGuildInfo:CreateFontString(nil, 'OVERLAY', 'InterUIRegular_Normal')
  astralGuildInfo.visit:SetPoint('TOP', astralGuildInfo.author, 'BOTTOM', 0, -20)
  astralGuildInfo.visit:SetText('Visit <Astral> at')

  astralGuildInfo.editBox = CreateFrame('EditBox', nil, astralGuildInfo, 'BackdropTemplate')
  astralGuildInfo.editBox:SetSize(125, 20)
  astralGuildInfo.editBox:SetPoint('TOP', astralGuildInfo.visit, 'BOTTOM', 0, -20)

  astralGuildInfo.logo = astralGuildInfo:CreateTexture(nil, 'ARTWORK')
  astralGuildInfo.logo:SetSize(32, 32)
  astralGuildInfo.logo:SetTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\logo.png')
  astralGuildInfo.logo:SetPoint('TOPLEFT', astralGuildInfo, 'TOPLEFT', 14, -10)

  astralGuildInfo.editBox:SetFontObject(InterUIRegular_Normal)
  astralGuildInfo.editBox:SetText('www.astralguild.com')
  astralGuildInfo.editBox:HighlightText()
  astralGuildInfo.editBox:SetScript('OnChar', function(self)
    self:SetText('www.astralguild.com')
    self:HighlightText()
  end)
  astralGuildInfo.editBox:SetScript('OnEscapePressed', function()
    astralGuildInfo:Hide()
  end)
  astralGuildInfo.editBox:SetScript('OnEditFocusLost', function(self)
    self:SetText('www.astralguild.com')
    self:HighlightText()
  end)

  local closeButton = CreateFrame('BUTTON', nil, astralGuildInfo)
  closeButton:SetNormalTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\baseline-close-24px@2x.tga')
  closeButton:SetSize(12, 12)
  closeButton:GetNormalTexture():SetVertexColor(.8, .8, .8, 0.8)
  closeButton:SetPoint('TOPRIGHT', astralGuildInfo, 'TOPRIGHT', -14, -10)
  closeButton:SetScript('OnClick', function() astralGuildInfo:Hide() end)
  closeButton:SetScript('OnEnter', function(self) self:GetNormalTexture():SetVertexColor(126/255, 126/255, 126/255, 0.8) end)
  closeButton:SetScript('OnLeave', function(self) self:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 0.8) end)
  return astralGuildInfo, guildVersionString
end

do
  local function SetBorderColor(self,colorR,colorG,colorB,colorA,layerCounter)
    layerCounter = layerCounter or ''
    self['border_top' .. layerCounter]:SetColorTexture(colorR,colorG,colorB,colorA)
    self['border_bottom' .. layerCounter]:SetColorTexture(colorR,colorG,colorB,colorA)
    self['border_left' .. layerCounter]:SetColorTexture(colorR,colorG,colorB,colorA)
    self['border_right' .. layerCounter]:SetColorTexture(colorR,colorG,colorB,colorA)
  end
  function AstralUI:Border(parent,size,colorR,colorG,colorB,colorA,outside,layerCounter)
    outside = outside or 0
    layerCounter = layerCounter or ''
    if size == 0 then
      if parent['border_top' .. layerCounter] then
        parent['border_top' .. layerCounter]:Hide()
        parent['border_bottom' .. layerCounter]:Hide()
        parent['border_left' .. layerCounter]:Hide()
        parent['border_right' .. layerCounter]:Hide()
      end
      return
    end

    local textureOwner = parent.CreateTexture and parent or parent:GetParent()

    local top = parent['border_top' .. layerCounter] or textureOwner:CreateTexture(nil, 'BORDER')
    local bottom = parent['border_bottom' .. layerCounter] or textureOwner:CreateTexture(nil, 'BORDER')
    local left = parent['border_left' .. layerCounter] or textureOwner:CreateTexture(nil, 'BORDER')
    local right = parent['border_right' .. layerCounter] or textureOwner:CreateTexture(nil, 'BORDER')

    parent['border_top' .. layerCounter] = top
    parent['border_bottom' .. layerCounter] = bottom
    parent['border_left' .. layerCounter] = left
    parent['border_right' .. layerCounter] = right

    top:ClearAllPoints()
    bottom:ClearAllPoints()
    left:ClearAllPoints()
    right:ClearAllPoints()

    top:SetPoint('TOPLEFT', parent, 'TOPLEFT', -size-outside, size+outside)
    top:SetPoint('BOTTOMRIGHT', parent, 'TOPRIGHT', size+outside, outside)
    bottom:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', -size-outside, -size-outside)
    bottom:SetPoint('TOPRIGHT', parent, 'BOTTOMRIGHT', size+outside, -outside)
    left:SetPoint('TOPLEFT', parent, 'TOPLEFT', -size-outside, outside)
    left:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMLEFT', -outside, -outside)
    right:SetPoint('TOPLEFT', parent, 'TOPRIGHT', outside, outside)
    right:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', size+outside, -outside)

    top:SetColorTexture(colorR, colorG, colorB, colorA)
    bottom:SetColorTexture(colorR, colorG, colorB, colorA)
    left:SetColorTexture(colorR, colorG, colorB, colorA)
    right:SetColorTexture(colorR, colorG, colorB, colorA)

    parent.SetBorderColor = SetBorderColor

    top:Show()
    bottom:Show()
    left:Show()
    right:Show()
  end
end

do
  local function Widget_SetFont(self, ...)
    self:SetFont(...)
    return self
  end
  local function Widget_Color(self, colR, colG, colB)
    self:SetTextColor(colR or 1, colG or 1, colB or 1, 1)
    return self
  end
  local function Widget_Left(self) self:SetJustifyH('LEFT') return self end
  local function Widget_Center(self) self:SetJustifyH('CENTER') return self end
  local function Widget_Right(self) self:SetJustifyH('RIGHT') return self end
  local function Widget_Top(self) self:SetJustifyV('TOP') return self end
  local function Widget_Middle(self) self:SetJustifyV('MIDDLE') return self end
  local function Widget_Bottom(self) self:SetJustifyV('BOTTOM') return self end
  local function Widget_Shadow(self, disable)
    self:SetShadowColor(0, 0, 0, disable and 0 or 1)
    self:SetShadowOffset(1, -1)
    return self
  end
  local function Widget_Outline(self, disable)
    local filename,fontSize = self:GetFont()
    self:SetFont(filename, fontSize, (not disable) and 'OUTLINE')
    return self
  end
  local function Widget_FontSize(self, size)
    local filename, _, fontParam1, fontParam2, fontParam3 = self:GetFont()
    self:SetFont(filename, size, fontParam1, fontParam2, fontParam3)
    return self
  end
  local function OnTooltipEnter(self)
    local text = self.t
    if text.TooltipOverwrite then
      AstralUI.Tooltip.Show(self, self.a, text.TooltipOverwrite)
      return
    end
    if not text:IsTruncated() and not text.alwaysTooltip then
      return
    end
    AstralUI.Tooltip.Show(self, self.a, text:GetText())
  end
  local function OnTooltipLeave(self)
    AstralUI.Tooltip.Hide()
  end
  local function Widget_Tooltip(self,anchor,isButton)
    local f = CreateFrame(isButton and 'BUTTON' or 'FRAME', nil, self:GetParent())
    f:SetAllPoints(self)
    f.t = self
    f.a = anchor or 'ANCHOR_RIGHT'
    f:SetScript('OnEnter', OnTooltipEnter)
    f:SetScript('OnLeave', OnTooltipLeave)
    self.TooltipFrame = f
    return self
  end
  local function Widget_MaxLines(self, num)
    self:SetMaxLines(num)
    return self
  end

  function AstralUI:Text(parent, text, size, template)
    if template == 0 then
      template = nil
    elseif not template then
      template = 'InterUIBold_Normal'
    end
    local self = parent:CreateFontString(nil, 'ARTWORK', template)
    if template and size then
      local filename = self:GetFont()
      if filename then
        self:SetFont(filename, size)
      end
    end
    self:SetJustifyH('LEFT')
    self:SetJustifyV('MIDDLE')
    if template then
      self:SetText(text or '')
    end
    Mod(self,
      'Font', Widget_SetFont,
      'Color', Widget_Color,
      'Left', Widget_Left,
      'Center', Widget_Center,
      'Right', Widget_Right,
      'Top', Widget_Top,
      'Middle', Widget_Middle,
      'Bottom', Widget_Bottom,
      'Shadow', Widget_Shadow,
      'Outline', Widget_Outline,
      'FontSize', Widget_FontSize,
      'Tooltip', Widget_Tooltip,
      'MaxLines', Widget_MaxLines
    )
    return self
  end
end

do
  local function PopupFrameShow(self, anchor, notResetPosIfShown)
    if self:IsShown() and notResetPosIfShown then
      return
    end
    local x, y = GetCursorPosition()
    local Es = self:GetEffectiveScale()
    x, y = x/Es, y/Es
    self:ClearAllPoints()
    self:SetPoint(anchor or self.anchor or 'BOTTOMLEFT', UIParent, 'BOTTOMLEFT', x, y)
    self:Show()
  end
  local function PopupFrameOnShow(self)
    local strata = InterfaceOptionsFrame:GetFrameStrata()
    if strata == 'FULLSCREEN' or strata == 'FULLSCREEN_DIALOG' or strata == 'TOOLTIP' then
      self:SetFrameStrata(strata)
    end
    self:SetFrameLevel(120)
    if self.OnShow then self:OnShow() end
  end
  local function buttonCloseOnClick(self)
    local parent = self:GetParent()
    if parent.CloseClick then parent:CloseClick() else parent:Hide() end
  end

  function AstralUI:Popup(title, template)
    if template == 0 or not template then
      template = 'AstralDialogTemplate'
    end
    local self = AstralUI:Template(template, UIParent) or CreateFrame('FRAME', nil, UIParent, template)
    self:SetPoint('CENTER')
    self:SetFrameStrata('DIALOG')
    self:SetClampedToScreen(true)
    self:EnableMouse(true)
    self:SetMovable(true)
    self:RegisterForDrag('LeftButton')
    self:SetDontSavePosition(true)
    self:SetScript('OnDragStart', function(self)
      self:StartMoving()
    end)
    self:SetScript('OnDragStop', function(self)
      self:StopMovingOrSizing()
    end)
    self:Hide()
    self:SetScript('OnShow', PopupFrameOnShow)
    self.ShowClick = PopupFrameShow
    self.title:SetTextColor(1, 1, 1, 1)
    self.title:SetText(title or '')
    self.Close:SetScript('OnClick', buttonCloseOnClick)
    Mod(self)
    return self
  end
end

do
  local function ScrollBarButtonUpClick(self)
    local scrollBar = self:GetParent()
    if not scrollBar.GetMinMaxValues then scrollBar = scrollBar.slider end
    local min, _ = scrollBar:GetMinMaxValues()
    local val = scrollBar:GetValue()
    local clickRange = self:GetParent().clickRange
    if (val - clickRange) < min then
      scrollBar:SetValue(min)
    else
      scrollBar:SetValue(val - clickRange)
    end
  end
  local function ScrollBarButtonDownClick(self)
    local scrollBar = self:GetParent()
    if not scrollBar.GetMinMaxValues then scrollBar = scrollBar.slider end
    local _, max = scrollBar:GetMinMaxValues()
    local val = scrollBar:GetValue()
    local clickRange = self:GetParent().clickRange
    if (val + clickRange) > max then
      scrollBar:SetValue(max)
    else
      scrollBar:SetValue(val + clickRange)
    end
  end
  local function ScrollBarButtonUpMouseHoldDown(self)
    local counter = 0
    self.ticker = C_Timer.NewTicker(.03, function()
      counter = counter + 1
      if counter > 10 then
        ScrollBarButtonUpClick(self)
      end
    end)
  end
  local function ScrollBarButtonUpMouseHoldUp(self)
     if self.ticker then
       self.ticker:Cancel()
     end
  end
  local function ScrollBarButtonDownMouseHoldDown(self)
    local counter = 0
    self.ticker = C_Timer.NewTicker(.03, function()
      counter = counter + 1
      if counter > 10 then
        ScrollBarButtonDownClick(self)
      end
    end)
  end
  local function ScrollBarButtonDownMouseHoldUp(self)
     if self.ticker then
       self.ticker:Cancel()
     end
  end

  local function Widget_Size(self, width, height)
    self:SetSize(width, height)
    if self.isHorizontal then
      self.thumb:SetHeight(height - 2)
      self.thumb:SetSize(width + 10,width + 10)
      self.slider:SetPoint('TOPLEFT', height + 2, 0)
      self.slider:SetPoint('BOTTOMRIGHT', -height-2, 0)
      self.buttonUP:SetSize(height,height)
      self.buttonDown:SetSize(height,height)
    else
      self.thumb:SetWidth(width - 2)
      self.thumb:SetSize(width + 10, width + 10)
      self.slider:SetPoint('TOPLEFT', 0, -width-2)
      self.slider:SetPoint('BOTTOMRIGHT', 0, width+2)
      self.buttonUP:SetSize(width,width)
      self.buttonDown:SetSize(width,width)
    end
    return self
  end
  local function Widget_Range(self, minVal, maxVal, clickRange, unchangedValue)
    self.slider:SetMinMaxValues(minVal,  maxVal)
    self.clickRange = clickRange or self.clickRange or 1
    if not unchangedValue then
      self.slider:SetValue(minVal)
    end
    return self
  end
  local function Widget_SetValue(self, value)
    self.slider:SetValue(value)
    self:UpdateButtons()
    return self
  end
  local function Widget_GetValue(self)
    return self.slider:GetValue()
  end
  local function Widget_GetMinMaxValues(self)
    return self.slider:GetMinMaxValues()
  end
  local function Widget_SetMinMaxValues(self, ...)
    self.slider:SetMinMaxValues(...)
    self:UpdateButtons()
    return self
  end
  local function Widget_SetScript(self, ...)
    self.slider:SetScript(...)
    return self
  end
  local function Widget_OnChange(self, func)
    self.slider:SetScript('OnValueChanged', func)
    return self
  end
  local function Widget_UpdateButtons(self)
    local slider = self.slider
    local value = Round(slider:GetValue())
    local min,max = slider:GetMinMaxValues()
    if max == min then
      self.buttonUP:SetEnabled(false)	self.buttonDown:SetEnabled(false)
    elseif value <= min then
      self.buttonUP:SetEnabled(false)	self.buttonDown:SetEnabled(true)
    elseif value >= max then
      self.buttonUP:SetEnabled(true) self.buttonDown:SetEnabled(false)
    else
      self.buttonUP:SetEnabled(true) self.buttonDown:SetEnabled(true)
    end
    return self
  end
  local function Widget_Slider_UpdateButtons(self)
    self:GetParent():UpdateButtons()
    return self
  end
  local function Widget_ClickRange(self, value)
    self.clickRange = value or 1
    return self
  end

  local function Widget_SetObey(self, bool)
    self.slider:SetObeyStepOnDrag(bool)
    return self
  end

  local function Widget_SetHorizontal(self)
    self.slider:SetOrientation('HORIZONTAL')
    self.buttonUP:ClearAllPoints()
    self.buttonUP:SetPoint('LEFT', 0, 0)
    self.buttonUP.NormalTexture:SetTexCoord(0.4375, 0.5, 0.5, 0.625)
    self.buttonUP.HighlightTexture:SetTexCoord(0.4375, 0.5, 0.5, 0.625)
    self.buttonUP.PushedTexture:SetTexCoord(0.4375, 0.5, 0.5, 0.625)
    self.buttonUP.DisabledTexture:SetTexCoord(0.4375, 0.5, 0.5, 0.625)

    self.buttonDown:ClearAllPoints()
    self.buttonDown:SetPoint('RIGHT', 0, 0)
    self.buttonDown.NormalTexture:SetTexCoord(0.375, 0.4375, 0.5, 0.625)
    self.buttonDown.HighlightTexture:SetTexCoord(0.375, 0.4375, 0.5, 0.625)
    self.buttonDown.PushedTexture:SetTexCoord(0.375, 0.4375, 0.5, 0.625)
    self.buttonDown.DisabledTexture:SetTexCoord(0.375, 0.4375, 0.5, 0.625)

    self.thumb:SetSize(30, 14)

    self.slider:SetPoint('TOPLEFT', 18, 0)
    self.slider:SetPoint('BOTTOMRIGHT', -18, 0)

    self.borderLeft:ClearAllPoints()
    self.borderLeft:SetSize(0, 1)
    self.borderLeft:SetPoint('BOTTOMLEFT', self.slider, 'TOPLEFT', -1, 0)
    self.borderLeft:SetPoint('BOTTOMRIGHT', self.slider, 'TOPRIGHT', 1, 0)
    self.borderRight:ClearAllPoints()
    self.borderRight:SetSize(0, 1)
    self.borderRight:SetPoint('TOPLEFT', self.slider, 'BOTTOMLEFT', -1, 0)
    self.borderRight:SetPoint('TOPRIGHT', self.slider, 'BOTTOMRIGHT', 1, 0)
    self.isHorizontal = true
     return self
  end

  function AstralUI:ScrollBar(parent)
    local self = CreateFrame('FRAME', nil, parent)

    self.slider = CreateFrame('Slider', nil, self)
    self.slider:SetPoint('TOPLEFT',0,-18)
    self.slider:SetPoint('BOTTOMRIGHT',0,18)

    self.bg = self.slider:CreateTexture(nil, 'BACKGROUND')
    self.bg:SetPoint('TOPLEFT',0,1)
    self.bg:SetPoint('BOTTOMRIGHT',0,-1)
    self.bg:SetColorTexture(0, 0, 0, 0.3)

    self.thumb = self.slider:CreateTexture(nil, 'OVERLAY')
    self.thumb:SetTexture('Interface\\Buttons\\UI-ScrollBar-Knob')
    self.thumb:SetSize(25, 25)
    self.slider:SetThumbTexture(self.thumb)
    self.slider:SetOrientation('VERTICAL')
    self.slider:SetValue(2)

    self.buttonUP = AstralUI:Template('UIPanelScrollUPButtonTemplate', self) or CreateFrame('Button', nil, self, 'UIPanelScrollUPButtonTemplate')
    self.buttonUP:SetSize(16,16)
    self.buttonUP:SetPoint('TOP', 0, 0)
    self.buttonUP:SetScript('OnClick',ScrollBarButtonUpClick)
    self.buttonUP:SetScript('OnMouseDown',ScrollBarButtonUpMouseHoldDown)
    self.buttonUP:SetScript('OnMouseUp',ScrollBarButtonUpMouseHoldUp)

    self.buttonDown = AstralUI:Template('UIPanelScrollDownButtonTemplate', self) or CreateFrame('Button', nil, self, 'UIPanelScrollDownButtonTemplate')
    self.buttonDown:SetPoint('BOTTOM', 0, 0)
    self.buttonDown:SetSize(16, 16)
    self.buttonDown:SetScript('OnClick', ScrollBarButtonDownClick)
    self.buttonDown:SetScript('OnMouseDown', ScrollBarButtonDownMouseHoldDown)
    self.buttonDown:SetScript('OnMouseUp', ScrollBarButtonDownMouseHoldUp)

    self.clickRange = 1

    self._SetScript = self.SetScript
    Mod(self,
      'Range', Widget_Range,
      'SetValue', Widget_SetValue,
      'SetTo', Widget_SetValue,
      'GetValue', Widget_GetValue,
      'GetMinMaxValues', Widget_GetMinMaxValues,
      'SetMinMaxValues', Widget_SetMinMaxValues,
      'SetScript', Widget_SetScript,
      'OnChange', Widget_OnChange,
      'UpdateButtons', Widget_UpdateButtons,
      'ClickRange', Widget_ClickRange,
      'SetHorizontal', Widget_SetHorizontal,
      'SetObey', Widget_SetObey
    )
    self.Size = Widget_Size
    self.slider.UpdateButtons = Widget_Slider_UpdateButtons
    return self
  end
  function AstralUI:CreateScrollBar(parent, width, height, x, y, minVal, maxVal, relativePoint, clickRange)
    return AstralUI:ScrollBar(parent):Size(width, height):Point(relativePoint or 'TOPLEFT', x, y):Range(minVal, maxVal):ClickRange(clickRange)
  end
end

do
  local function Widget_SetSize(self, width, height)
    self:SetSize(width,height)
    self.content:SetWidth(width-12)
    if height < 65 then
      self.ScrollBar.IsThumbSmalled = true
      self.ScrollBar.thumb:SetHeight(5)
    elseif self.ScrollBar.IsThumbSmalled then
      self.ScrollBar.IsThumbSmalled = nil
      self.ScrollBar.thumb:SetHeight(30)
    end
    return self
  end
  local function ScrollFrameMouseWheel(self,delta)
    delta = delta * (self.mouseWheelRange or 20)
    local min,max = self.ScrollBar.slider:GetMinMaxValues()
    local val = self.ScrollBar:GetValue()
    if (val - delta) < min then
      self.ScrollBar:SetValue(min)
    elseif (val - delta) > max then
      self.ScrollBar:SetValue(max)
    else
      self.ScrollBar:SetValue(val - delta)
    end
  end
  local function CheckHideScroll(self)
    if not self.HideOnNoScroll then
      return
    end
    if not self.buttonUP:IsEnabled() and not self.buttonDown:IsEnabled() then
      self:Hide()
    else
      self:Show()
    end
  end
  local function ScrollFrameScrollBarValueChanged(self,value)
    local parent = self:GetParent():GetParent()
    parent:SetVerticalScroll(value)
    self:UpdateButtons()
    CheckHideScroll(self)
  end
  local function ScrollFrameScrollBarValueChangedH(self,value)
    local parent = self:GetParent():GetParent()
    parent:SetHorizontalScroll(value)
    self:UpdateButtons()
  end
  local function ScrollFrameChangeHeight(self,newHeight)
    self.content:SetHeight(newHeight)
    self.ScrollBar:Range(0,max(newHeight-self:GetHeight(),0),nil,true)
    self.ScrollBar:UpdateButtons()
    CheckHideScroll(self.ScrollBar)

    return self
  end
  local function ScrollFrameChangeWidth(self,newWidth)
    self.content:SetWidth(newWidth)
    self.ScrollBarHorizontal:Range(0,max(newWidth-self:GetWidth(),0),nil,true)
    self.ScrollBarHorizontal:UpdateButtons()

    return self
  end
  local function Widget_AddHorizontal(self,outside)
    self.ScrollBarHorizontal = AstralUI:ScrollBar(self):SetHorizontal():Size(0,16):Point('BOTTOMLEFT', 3, 3-(outside and 18 or 0)):Point('BOTTOMRIGHT', -3-18, 3-(outside and 18 or 0)):Range(0, 1):SetTo(0):ClickRange(20)
    self.ScrollBarHorizontal.slider:SetScript('OnValueChanged', ScrollFrameScrollBarValueChangedH)
    self.ScrollBarHorizontal:UpdateButtons()

    self.ScrollBar:Point('BOTTOMRIGHT', -3, 3+(outside and 0 or 18))

    self.SetNewWidth = ScrollFrameChangeWidth
    self.Width = ScrollFrameChangeWidth

    return self
  end
  local function Widget_HideScrollOnNoScroll(self)
    self.ScrollBar.HideOnNoScroll = true
    self.ScrollBar:UpdateButtons()
    CheckHideScroll(self.ScrollBar)
    return self
  end

  function AstralUI:ScrollFrame(parent)
    local self = CreateFrame('ScrollFrame', nil, parent)
    AstralUI:Border(self, 2, .24, .25, .30, 1)
    self.content = CreateFrame('FRAME', nil, self)
    self:SetScrollChild(self.content)

    self.C = self.content
    self.ScrollBar = AstralUI:ScrollBar(self):Size(16,0):Point('TOPRIGHT', -3, -3):Point('BOTTOMRIGHT', -3, 3):Range(0, 1):SetTo(0):ClickRange(20)
    self.ScrollBar.slider:SetScript('OnValueChanged', ScrollFrameScrollBarValueChanged)
    self.ScrollBar:UpdateButtons()

    self:SetScript('OnMouseWheel', ScrollFrameMouseWheel)

    self.SetNewHeight = ScrollFrameChangeHeight
    self.Height = ScrollFrameChangeHeight

    self.AddHorizontal = Widget_AddHorizontal
    self.HideScrollOnNoScroll = Widget_HideScrollOnNoScroll

    Mod(self)
    self._Size = self.Size
    self.Size = Widget_SetSize
    return self
  end
end

do
  local Tooltip = {}
  AstralUI.Tooltip = Tooltip
  function Tooltip:Hide()
    GameTooltip_Hide()
  end
  function Tooltip:Std(anchorUser)
    GameTooltip:SetOwner(self,anchorUser or 'ANCHOR_RIGHT')
    GameTooltip:SetText(self.tooltipText or '')
    GameTooltip:Show()
  end
  function Tooltip:Link(data, ...)
    if not data then return end
    local x = self:GetRight()
    if x >= ( GetScreenWidth() / 2 ) then
      GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
    else
      GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    end
    GameTooltip:SetHyperlink(data, ...)
    GameTooltip:Show()
  end
  function Tooltip:Show(anchorUser,title,...)
    if not title then return end
    local x,y = 0,0
    if type(anchorUser) == 'table' then
      x = anchorUser[2]
      y = anchorUser[3]
      anchorUser = anchorUser[1] or 'ANCHOR_RIGHT'
    elseif not anchorUser then
      anchorUser = 'ANCHOR_RIGHT'
    end
    GameTooltip:SetOwner(self,anchorUser or 'ANCHOR_RIGHT',x,y)
    GameTooltip:SetText(title)
    for i=1,select('#', ...) do
      local line = select(i, ...)
      if type(line) == 'table' then
        if not line.right then
          if line[1] then
            GameTooltip:AddLine(unpack(line))
          end
        else
          GameTooltip:AddDoubleLine(line[1], line.right, line[2],line[3],line[4], line[2],line[3],line[4])
        end
      else
        GameTooltip:AddLine(line)
      end
    end
    GameTooltip:Show()
  end
  function Tooltip:Edit_Show(linkData, link)
    GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')
    GameTooltip:SetHyperlink(linkData)
    GameTooltip:Show()
  end
  function Tooltip:Edit_Click(linkData, link, button)
    AstralUI:LinkItem(nil, link)
  end

  local additionalTooltips = {}
  local additionalTooltipBackdrop = {bgFile='Interface/Buttons/WHITE8X8', edgeFile='Interface/Tooltips/UI-Tooltip-Border', tile=false, edgeSize=14, insets={left=2.5,right=2.5,top=2.5,bottom=2.5}}
  local function CreateAdditionalTooltip()
    local new = #additionalTooltips + 1
    local tip = CreateFrame('GameTooltip', ADDON_NAME ..'LibAdditionalTooltip'..new, UIParent, 'GameTooltipTemplate'..(BackdropTemplateMixin and ',BackdropTemplate' or ''))
    additionalTooltips[new] = tip

    tip:SetScript('OnLoad', nil)
    tip:SetScript('OnHide', nil)

    tip:SetBackdrop(additionalTooltipBackdrop)
    tip:SetBackdropColor(0, 0, 0, 1)
    tip:SetBackdropBorderColor(0.3, 0.3, 0.4, 1)

    tip.gradientTexture = tip:CreateTexture()
    tip.gradientTexture:SetColorTexture(1,1,1,1)
    tip.gradientTexture:SetGradientAlpha('VERTICAL', 0, 0, 0, 0, .8, .8, .8, .2)
    tip.gradientTexture:SetPoint('TOPLEFT', 2.5, -2.5)
    tip.gradientTexture:SetPoint('BOTTOMRIGHT', -2.5, 2.5)

    tip:Hide()
    return new
  end
  function Tooltip:Add(link,data,enableMultiline,disableTitle)
    local tooltipID = nil
    for i=1,#additionalTooltips do
      if not additionalTooltips[i]:IsShown() then
        tooltipID = i
        break
      end
    end
    if not tooltipID then
      tooltipID = CreateAdditionalTooltip()
    end
    local tooltip = additionalTooltips[tooltipID]
    local owner = nil
    if tooltipID == 1 then
      owner = GameTooltip
    else
      owner = additionalTooltips[tooltipID - 1]
    end
    tooltip:SetOwner(owner, 'ANCHOR_NONE')
    if link then
      tooltip:SetHyperlink(link)
    else
      for i=1,#data do
        tooltip:AddLine(data[i], nil, nil, nil, enableMultiline and true)
      end
    end
    if disableTitle then
      local textObj = _G[tooltip:GetName()..'TextLeft1']
      local arg1, arg2, arg3, arg4, arg5 = textObj:GetFont()
      textObj:SetFont(arg1, select(2, _G[tooltip:GetName()..'TextLeft2']:GetFont()), arg3, arg4, arg5)
      tooltip.titleDisabled = tooltip.titleDisabled or arg2
    elseif tooltip.titleDisabled then
      local textObj = _G[tooltip:GetName()..'TextLeft1']
      local arg1, arg2, arg3, arg4, arg5 = textObj:GetFont()
      textObj:SetFont(arg1, tooltip.titleDisabled, arg3, arg4, arg5)
      tooltip.titleDisabled = nil
    end
    tooltip:ClearAllPoints()
    local isTop = false
    if tooltipID > 1 then
      local ownerPoint = owner:GetPoint()
      if ownerPoint == 'BOTTOMRIGHT' then
        isTop = true
      end
    end
    if not isTop then
      tooltip:SetPoint('TOPRIGHT', owner, 'BOTTOMRIGHT', 0, 0)
    else
      tooltip:SetPoint('BOTTOMRIGHT', owner, 'TOPRIGHT', 0, 0)
    end
    tooltip:Show()
    if not isTop and (tooltip:GetBottom() or 0) < 1 then
      owner = nil
      for i = 1, (tooltipID-1) do
        local point = additionalTooltips[i]:GetPoint()
        if point ~= 'TOPRIGHT' then
          owner = additionalTooltips[i]
        end
      end
      owner = owner or GameTooltip
      tooltip:ClearAllPoints()
      tooltip:SetPoint('BOTTOMRIGHT', owner, 'TOPRIGHT', 0, 0)
    end
  end
  function Tooltip:HideAdd()
    for i=1,#additionalTooltips do
      additionalTooltips[i]:Hide()
      additionalTooltips[i]:ClearLines()
    end
  end
end

do
  local function MultilineEditBoxOnTextChanged(self, ...)
    local parent = self.Parent
    local height = self:GetHeight()
    local _, prevMax = parent.ScrollBar:GetMinMaxValues()
    local changeToMax = parent.ScrollBar:GetValue() >= prevMax

    parent:SetNewHeight(max(height, parent:GetHeight()))
    if changeToMax then
      local _, max = parent.ScrollBar:GetMinMaxValues()
      parent.ScrollBar:SetValue(max)
    end
    if parent.OnTextChanged then
      parent.OnTextChanged(self, ...)
    elseif self.OnTextChanged then
      self:OnTextChanged(...)
    end

    if parent.SyntaxOnEdit then
      parent:SyntaxOnEdit()
    end
  end
  local function MultilineEditBoxGetTextHighlight(self)
    local text,cursor = self:GetText(),self:GetCursorPfosition()
    self:Insert('')
    local textNew, cursorNew = self:GetText(), self:GetCursorPosition()
    self:SetText(text)
    self:SetCursorPosition(cursor)
    local Start, End = cursorNew, #text - (#textNew - cursorNew)
    self:HighlightText(Start, End)
    return Start, End
  end
  local function MultilineEditBoxOnFrameClick(self)
    self:GetParent().EditBox:SetFocus()
  end
  local function Widget_Font(self, font, size, ...)
    if font == 'x' then
      font = self.EditBox:GetFont()
    end
    self.EditBox:SetFont(font, size, ...)
    if self.EditBox.ColoredText then
      self.EditBox.ColoredText:SetFont(font, size, ...)
    end
    return self
  end
  local function Widget_OnChange(self, func)
    self.EditBox.OnTextChanged = func
    return self
  end
  local function Widget_Hyperlinks(self)
    self.EditBox:SetHyperlinksEnabled(true)
    self.EditBox:SetScript('OnHyperlinkEnter', AstralUI.Tooltip.Edit_Show)
    self.EditBox:SetScript('OnHyperlinkLeave', AstralUI.Tooltip.Hide)
    self.EditBox:SetScript('OnHyperlinkClick', AstralUI.Tooltip.Edit_Click)
    return self
  end
  local function Widget_MouseWheel(self,delta)
    local min,max = self.ScrollBar:GetMinMaxValues()
    delta = delta * (self.wheelRange or 20)
    local val = self.ScrollBar:GetValue()
    if (val - delta) < min then
      self.ScrollBar:SetValue(min)
    elseif (val - delta) > max then
      self.ScrollBar:SetValue(max)
    else
      self.ScrollBar:SetValue(val - delta)
    end
  end
  local function Widget_ToTop(self)
    self.EditBox:SetCursorPosition(0)
    return self
  end
  local function Widget_SetText(self,text)
    self.EditBox:SetText(text)
    return self
  end
  local function Widget_GetTextHighlight(self)
    return MultilineEditBoxGetTextHighlight(self.EditBox)
  end

  local function MultilineEditBox_OnCursorChanged(self, x, y, width, height)
    local parent = self.Parent
    y = abs(y)
    local scrollNow = parent:GetVerticalScroll()
    local heightNow = parent:GetHeight()
    if y < scrollNow then
      parent.ScrollBar:SetValue(max(floor(y),0))
    elseif (y + height) > (scrollNow + heightNow) then
      local _, scrollMax = parent.ScrollBar:GetMinMaxValues()
      parent.ScrollBar:SetValue(min(ceil(y + height - heightNow), scrollMax))
    end

    if parent.Cursor730fix then
      parent:Cursor730fix(height, y)
    end

    if parent.OnCursorChanged then
      local _, obj = self:GetRegions()
      parent.OnCursorChanged(self, obj, x, y)
    end

    if parent.OnPosText then
      parent:OnPosText()
    end
  end
  local function Widget_GetText(self)
    return self.EditBox:GetText()
  end

  local Widget_AddSyntax
  do
    local LUA_COLOR1 = 'f92672' --lua
    local LUA_COLOR2 = 'e6db74' --string
    local LUA_COLOR3 = '75715e' --comment
    local LUA_COLOR4 = '5dffed' -- ()=.
    local LUA_COLOR5 = 'ae81ff' --numbers

    local lua_str = {
      ['function'] = true,
      ['end'] = true,
      ['if'] = true,
      ['elseif'] = true,
      ['else'] = true,
      ['then'] = true,
      ['false'] = true,
      ['do'] = true,
      ['and'] = true,
      ['break'] = true,
      ['for'] = true,
      ['local'] = true,
      ['nil'] = true,
      ['not'] = true,
      ['or'] = true,
      ['return'] = true,
      ['while'] = true,
      ['until'] = true,
      ['repeat'] = true,
    }

    local function LUA_ReplaceLua1(pre,str,fin)
      if lua_str[str] then
        return pre..'|cff'..LUA_COLOR1..str..'|r'..fin
      end
    end
    local function LUA_ReplaceLua2(str,fin)
      if lua_str[str] then
        return '|cff'..LUA_COLOR1..str..'|r'..fin
      end
    end
    local function LUA_ReplaceLua3(pre,str)
      if lua_str[str] then
        return pre..'|cff'..LUA_COLOR1..str..'|r'
      end
    end
    local function LUA_ReplaceLua4(str)
      if lua_str[str] then
        return '|cff'..LUA_COLOR1..str..'|r'
      end
    end
    local function LUA_ReplaceString(str)
      str = str:gsub('|c........', ''):gsub('|r', '')
      return '|cff'..LUA_COLOR2..str..'|r'
    end
    local function LUA_ReplaceComment(str)
      str = str:gsub('|c........', ''):gsub('|r', '')
      return '|cff'..LUA_COLOR3..str..'|r'
    end

    local function LUA_ModdedSetText(self)
      if not self.EditBox.ColoredText:IsShown() then
        return
      end

      local textObj = self.EditBox:GetRegions()

      local left,top = textObj:GetLeft(),textObj:GetTop()
      if not top then return end
      local x = textObj:FindCharacterIndexAtCoordinate(left,top-self:GetVerticalScroll())
      if not x then return end
      local xMax = textObj:FindCharacterIndexAtCoordinate(left,top-self:GetVerticalScroll()-self:GetHeight()-40)
      local res = textObj:GetParent():GetDisplayText()

      local newStrPos = x
      for i=x,1,-1 do
        if res:sub(i,i) == '\n' then
          newStrPos = i + 1
          break
        end
      end

      local text = res:sub(newStrPos or x,xMax)

      text = text
        :gsub("||c","||с")
        :gsub("(%A)([%d]+)","%1|cff"..LUA_COLOR5.."%2|r")
        :gsub("(%A?)(%l+)(%A)",LUA_ReplaceLua1):gsub("^(%l+)(%A)",LUA_ReplaceLua2):gsub("(%A)(%l+)$",LUA_ReplaceLua3):gsub("^(%l+)$",LUA_ReplaceLua4)
        :gsub("[\\/]+","|cff"..LUA_COLOR1.."%1|r")
        :gsub("([%(%)%.=,%[%]<>%+{}#]+)","|cff"..LUA_COLOR4.."%1|r")
        :gsub('("[^"]*")',LUA_ReplaceString)
        :gsub('(%-%-[^\n]*)',LUA_ReplaceComment)
      res = res:sub(1,newStrPos):gsub("[^\n]*",self.EditBox.repFunc)..text

      self.EditBox.ColoredText:SetText(res)
    end

    function Widget_AddSyntax(self,syntax)
      syntax = syntax:lower()
      if syntax == "lua" then
        self.SyntaxLUA = true
      else
        self.SyntaxLUA = nil
      end

      local textObj = self.EditBox:GetRegions()
      self.EditBox.textObj = textObj

      local coloredText = self.EditBox:CreateFontString(nil, 'ARTWORK')
      self.EditBox.ColoredText = coloredText
      coloredText:SetFont(textObj:GetFont())
      coloredText:SetAllPoints(textObj)
      coloredText:SetJustifyH('LEFT')
      coloredText:SetJustifyV('TOP')
      coloredText:SetMaxLines(0)
      coloredText:SetNonSpaceWrap(false)
      coloredText:SetWordWrap(true)

      textObj:SetAlpha(0.2)

      if syntax == 'lua' then
        self.SyntaxOnEdit = LUA_ModdedSetText
      end
      local specialCheck = self.EditBox:CreateFontString(nil, 'ARTWORK')
      specialCheck:SetFont(textObj:GetFont())
      specialCheck:SetAllPoints(textObj)
      specialCheck:SetJustifyH('LEFT')
      specialCheck:SetJustifyV('TOP')
      specialCheck:SetMaxLines(0)
      specialCheck:SetNonSpaceWrap(false)
      specialCheck:SetWordWrap(true)
      specialCheck:SetAlpha(0)

      self.EditBox.repFunc = function(a)
        specialCheck:SetText(a)
        if specialCheck:GetNumLines() > 1 then
          return a
        else
          return ''
        end
      end

      self.specialCheckObj = specialCheck

      self:SetScript('OnVerticalScroll', function(self, offset) LUA_ModdedSetText(self) end)
      return self
    end
  end

  local function Widget_OnCursorChanged(self, func)
    self.OnCursorChanged = func

    return self
  end
  local function Widget_AddPosText(self)
    self.posText = self.posText or self:CreateFontString(nil, 'ARTWORK', 'GameFontWhite')
    self.posText:SetJustifyH('RIGHT')
    self.posText:SetJustifyV('BOTTOM')
    self.posText:SetPoint('BOTTOMRIGHT', -22, 2)
    self.posText:SetFont(self.posText:GetFont(),8)
    self.posText:SetAlpha(0.4)

    self.OnPosText = function(self)
      local cursor = self.EditBox:GetCursorPosition()
      local text = self.EditBox:GetText():sub(1,cursor)
      local line = 1
      for w in string.gmatch(text, '\n') do
        line = line + 1
      end
      local len = #(text:match('[^\n]*$') or '') + 1
      self.posText:SetText(line .. ':' .. len)
    end

    return self
  end

  function AstralUI:MultiEdit(parent)
    local self = AstralUI:ScrollFrame(parent)

    self.EditBox = AstralUI:Edit(self.C, nil, nil, 1):Point('TOPLEFT', self.C, 0, 0):Point('TOPRIGHT', self.C, 0, 0):OnChange(MultilineEditBoxOnTextChanged)
    self.EditBox.Parent = self
    self.EditBox:SetMultiLine(true)
    self.EditBox:SetBackdropColor(0, 0, 0, 0)
    self.EditBox:SetBackdropBorderColor(0, 0, 0, 0)
    self.EditBox:SetTextInsets(5, 5, 2, 2)
    self.EditBox:SetScript('OnCursorChanged', MultilineEditBox_OnCursorChanged)

    self.C:SetScript('OnMouseDown', MultilineEditBoxOnFrameClick)
    self:SetScript('OnMouseWheel', Widget_MouseWheel)

    self.EditBox.GetTextHighlight = MultilineEditBoxGetTextHighlight

    self.Font = Widget_Font
    self.OnChange = Widget_OnChange
    self.Hyperlinks = Widget_Hyperlinks
    self.ToTop = Widget_ToTop
    self.SetText = Widget_SetText
    self.GetTextHighlight = Widget_GetTextHighlight
    self.GetText = Widget_GetText
    self.SetSyntax = Widget_AddSyntax
    self.OnCursorChanged = Widget_OnCursorChanged
    self.AddPosText = Widget_AddPosText

    return self
  end
end

do
  local function ButtonOnEnter(self)
    AstralUI.Tooltip.Show(self, 'ANCHOR_TOP', self.tooltip, {type(self.tooltipText) == 'function' and self.tooltipText(self) or self.tooltipText,1,1,1,true})
  end
  local function Widget_Tooltip(self, text)
    self.tooltip = self:GetText()
    if self.tooltip == '' or not self.tooltip then
      self.tooltip = text
    else
      self.tooltipText = text
    end
    self:SetScript('OnEnter', ButtonOnEnter)
    self:SetScript('OnLeave', AstralUI.Tooltip.Hide)
    return self
  end
  local function Widget_Disable(self)
    self:_Disable()
    return self
  end
  local function Widget_Enable(self)
    self:_Enable()
    return self
  end
  local function Widget_GetTextObj(self)
    for i=1,self:GetNumRegions() do
      local obj = select(i,self:GetRegions())
      if obj.GetText and obj:GetText() == self:GetText() then
        return obj
      end
    end
  end
  local function Widget_SetFontSize(self,size)
    local obj = self:GetFontString()
    obj:SetFont(obj:GetFont(),size,"")

    return self
  end
  local function Widget_SetVertical(self)
    self.Texture:SetGradientAlpha('HORIZONTAL', 0.20, 0.21, 0.25, 1, 0.05, 0.06, 0.09, 1)
    self.TextObj = self:GetTextObj()
    self.TextObj:SetPoint('CENTER', -5, 0)
    local group = self:CreateAnimationGroup()
    group:SetScript('OnFinished', function() group:Play() end)
    local rotation = group:CreateAnimation('Rotation')
    rotation:SetDuration(0.000001)
    rotation:SetEndDelay(2147483647)
    rotation:SetChildKey('TextObj')
    rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
    rotation:SetDegrees(90)
    group:Play()

    return self
  end

  function AstralUI:Button(parent,text,template)
    if template == 0 then
      template = 'UIPanelButtonTemplate'
    elseif template == 1 then
      template = nil
    elseif not template then
      template = 'AstralButtonModernTemplate'
    end
    local self = AstralUI:Template(template,parent) or CreateFrame('Button', nil, parent, template)
    self:SetText(text)

    Mod(self,
      'Tooltip',Widget_Tooltip
    )
    self._Disable = self.Disable
    self.Disable = Widget_Disable
    self._Enable = self.Enable
    self.Enable = Widget_Enable
    self.GetTextObj = Widget_GetTextObj
    self.FontSize = Widget_SetFontSize
    self.SetVertical = Widget_SetVertical

    return self
  end
end

do
  local function ScrollListLineEnter(self)
    local mainFrame = self.mainFrame
    if mainFrame.HoverListValue then
      mainFrame:HoverListValue(true, self.index, self)
      mainFrame.HoveredLine = self
    end
    if mainFrame.EnableHoverAnimation then
      if not self.anim then
        self.anim = self:CreateAnimationGroup()
        self.anim:SetLooping('NONE')
        self.anim.timer = self.anim:CreateAnimation()
        self.anim.timer:SetDuration(.25)
        self.anim.timer.line = self
        self.anim.timer.main = mainFrame
        self.anim.timer:SetScript('OnUpdate', function(self,elapsed)
          local p = self:GetProgress()
          local cR,cG,cB,cA = self.fR + (self.tR - self.fR) * p, self.fG + (self.tG - self.fG) * p, self.fB + (self.tB - self.fB)* p, self.fA + (self.tA - self.fA) * p
          self.cR, self.cG, self.cB, self.cA = cR,cG,cB,cA
          self.line.AnimTexture:SetColorTexture(cR,cG,cB,cA)
        end)
        self.HighlightTexture:SetVertexColor(0,0,0,0)
        self.anim.timer.cR, self.anim.timer.cG, self.anim.timer.cB, self.anim.timer.cA = .5, .5, .5, .2
        self.anim:SetScript('OnFinished', function(self, requested)
          if self.timer.HideOnEnd then
            local t = self:GetParent().AnimTexture
            t:Hide()
            t:SetColorTexture(.5, .5, .5, .2)
            self.timer.cR, self.timer.cG, self.timer.cB, self.timer.cA = .5, .5, .5, .2
          end
        end)

        self.AnimTexture = self:CreateTexture()
        self.AnimTexture:SetPoint('LEFT', 0, 0)
        self.AnimTexture:SetPoint('RIGHT', 0, 0)
        self.AnimTexture:SetHeight(mainFrame.LINE_TEXTURE_HEIGHT or 15)
        self.AnimTexture:SetColorTexture(self.anim.timer.cR, self.anim.timer.cG, self.anim.timer.cB, self.anim.timer.cA)
      end
      if self.anim:IsPlaying() then
        self.anim:Stop()
      end
      local t = self.anim.timer
      t.fR, t.fG, t.fB, t.fA = t.cR, t.cG, t.cB, t.cA
      if mainFrame.LINE_TEXTURE_COLOR_HL then
        t.tR, t.tG, t.tB, t.tA = unpack(mainFrame.LINE_TEXTURE_COLOR_HL)
      else
        t.tR, t.tG, t.tB, t.tA = 1, 1, 1, 1
      end
      t.HideOnEnd = false
      self.anim:Play()
      self.AnimTexture:Show()
    end
  end
  local function ScrollListLineLeave(self)
    local mainFrame = self.mainFrame
    if mainFrame.HoverListValue then
      mainFrame:HoverListValue(false,self.index,self)
    end
    mainFrame.HoveredLine = nil

    if mainFrame.EnableHoverAnimation then
      if self.anim:IsPlaying() then
        self.anim:Stop()
      end
      local t = self.anim.timer
      t.fR, t.fG, t.fB, t.fA = t.cR, t.cG, t.cB, t.cA
      t.tR, t.tG, t.tB, t.tA = .5, .5, .5, 0
      t.HideOnEnd = true
      self.anim:Play()
    end
  end
  local function ScrollListLineOnDragStart(self)
    if self:IsMovable() then
      if self.ignoreDrag then
        return
      end
      self.poins = {}
      for i=1, self:GetNumPoints() do
        self.poins[i] = {self:GetPoint()}
      end
      GameTooltip_Hide()
      self:StartMoving()
    end
  end
  local function ScrollListLineOnDragStop(self)
    self:StopMovingOrSizing()
    if not self.poins then
      return
    end
    local mainFrame = self.mainFrame
    if mainFrame.OnDragFunction then
      local swapLine
      for i=1, #mainFrame.List do
        local line = mainFrame.List[i]
        if line ~= self and line:IsShown() and MouseIsOver(line) then
          swapLine = line
          break
        end
      end
      if swapLine then mainFrame:OnDragFunction(self, swapLine) end
    end
    self:ClearAllPoints()
    for i=1, #self.poins do
      self:SetPoint(unpack(self.poins[i]))
    end
    self.poins = nil
  end
  local function ScrollListMouseWheel(self,delta)
    if delta > 0 then
      self.Frame.ScrollBar.buttonUP:Click('LeftButton')
    else
      self.Frame.ScrollBar.buttonDown:Click('LeftButton')
    end
  end
  local function ScrollListListMultitableEnter(self)
    local mainFrame = self:GetParent().mainFrame
    if mainFrame.HoverMultitableListValue then
      mainFrame:HoverMultitableListValue(true, self.index, self)
    end
  end
  local function ScrollListListMultitableLeave(self)
    local mainFrame = self:GetParent().mainFrame
    if mainFrame.HoverMultitableListValue then
      mainFrame:HoverMultitableListValue(false, self.index, self)
    end
  end
  local function ScrollListListMultitableClick(self)
    local mainFrame = self:GetParent().mainFrame
    if mainFrame.ClickMultitableListValue then
      mainFrame:ClickMultitableListValue(self.index, self)
    end
  end

  local function ScrollList_Line_Click(self, button, ...)
    local parent = self.mainFrame
    if not parent.isCheckList then
      parent.selected = self.index
    else
      if button ~= "RightButton" then
        parent.C[self.index] = not parent.C[self.index]
      end
    end
    parent:Update()
    if parent.SetListValue then
      parent:SetListValue(self.index, button, ...)
    end
    if parent.isCheckList and parent.ValueChanged then
      parent:ValueChanged()
    end
    if parent.AdditionalLineClick then
      parent.AdditionalLineClick(self, button, ...)
    end
  end
  local function ScrollList_Check_Click(self, ...)
    local listParent = self:GetParent()
    local parent = listParent.mainFrame
    if self:GetChecked() then
      parent.C[listParent.index] = true
    else
      parent.C[listParent.index] = nil
    end
    parent:Update()
    if parent.SetListValue then
      parent:SetListValue(listParent.index, ...)
    end
    if parent.isCheckList and parent.ValueChanged then
      parent:ValueChanged()
    end
  end
  local function ScrollList_AddLine(self, i)
    local line = CreateFrame('Button', nil, self.Frame.C)
    self.List[i] = line
    line:SetPoint('TOPLEFT', 0, -(i-1)*(self.LINE_HEIGHT or 16))
    line:SetPoint('BOTTOMRIGHT', self.Frame.C, 'TOPRIGHT', 0, -i*(self.LINE_HEIGHT or 16))

    if not self.T then
      line.text = AstralUI:Text(line, 'List'..tostring(i)):Point('LEFT', (self.isCheckList and 24 or 3)+(self.LINE_PADDING_LEFT or 0),0):Point('RIGHT', -3, 0):Size(0, self.LINE_HEIGHT or 16):Color():Shadow()
      if self.fontName then line.text:Font(self.fontName,self.fontSize or 12) end
      line:SetFontString(line.text)
      line:SetPushedTextOffset(2, -1)
    else
      local zeroWidth = nil
      for j=1,#self.T do
        local width = self.T[j]
        local textObj = AstralUI:Text(line, 'List', self.fontSize or 12):Size(width, self.LINE_HEIGHT or 16):Color():Shadow():Left()
        if self.fontName then
          textObj:Font(self.fontName, self.fontSize or 12)
        end
        line['text'..j] = textObj
        if width == 0 then
          zeroWidth = j
        end
        if self.additionalLineFunctions then
          local hoverFrame = CreateFrame('Button', nil, line)
          hoverFrame:SetScript('OnEnter', ScrollListListMultitableEnter)
          hoverFrame:SetScript('OnLeave', ScrollListListMultitableLeave)
          hoverFrame:SetScript('OnClick', ScrollListListMultitableClick)
          hoverFrame:SetAllPoints(textObj)
          hoverFrame.index = j
          hoverFrame.parent = textObj
        end
      end
      for j = 1, #self.T do
        local text = line['text' .. j]
        if j == 1 then
          text:Point('LEFT', 3, 0)
        elseif j < zeroWidth then
          text:Point('LEFT', line['text'..(j-1)], 'RIGHT', 0, 0)
        elseif j == #self.T and j == zeroWidth then
          text:Point('LEFT', line['text'..(j-1)], 'RIGHT', 0, 0):Point('RIGHT', -3, 0)
        elseif j == #self.T then
          text:Point('RIGHT', -3, 0)
        elseif j == zeroWidth then
          text:Point('LEFT', line['text'..(j-1)], 'RIGHT', 0, 0):Point('RIGHT', line['text'..(j+1)], 'LEFT', 0, 0)
        else
          text:Point('RIGHT', line['text'..(j+1)], 'LEFT', 0, 0)
        end
      end
    end

    line.background = line:CreateTexture(nil, 'BACKGROUND')
    line.background:SetPoint('TOPLEFT')
    line.background:SetPoint('BOTTOMRIGHT')

    line.HighlightTexture = line:CreateTexture()
    line.HighlightTexture:SetTexture(self.LINE_TEXTURE or 'Interface\\QuestFrame\\UI-QuestLogTitleHighlight')
    if not self.LINE_TEXTURE_IGNOREBLEND then
      line.HighlightTexture:SetBlendMode('ADD')
    end
    line.HighlightTexture:SetPoint('LEFT', 0, 0)
    line.HighlightTexture:SetPoint('RIGHT', 0, 0)
    line.HighlightTexture:SetHeight(self.LINE_TEXTURE_HEIGHT or 15)
    if self.LINE_TEXTURE_COLOR_HL then
      line.HighlightTexture:SetVertexColor(unpack(self.LINE_TEXTURE_COLOR_HL))
    else
      line.HighlightTexture:SetVertexColor(1, 1, 1, 1)
    end
    line:SetHighlightTexture(line.HighlightTexture)

    line.PushedTexture = line:CreateTexture()
    line.PushedTexture:SetTexture(self.LINE_TEXTURE or 'Interface\\QuestFrame\\UI-QuestLogTitleHighlight')
    if not self.LINE_TEXTURE_IGNOREBLEND then
      line.PushedTexture:SetBlendMode('ADD')
    end
    line.PushedTexture:SetPoint('LEFT', 0, 0)
    line.PushedTexture:SetPoint('RIGHT', 0, 0)
    line.PushedTexture:SetHeight(self.LINE_TEXTURE_HEIGHT or 15)
    if self.LINE_TEXTURE_COLOR_P then
      line.PushedTexture:SetVertexColor(unpack(self.LINE_TEXTURE_COLOR_P))
    else
      line.PushedTexture:SetVertexColor(1, 1, 0, 1)
    end
    line:SetDisabledTexture(line.PushedTexture)

    line.iconRight = line:CreateTexture()
    line.iconRight:SetPoint('RIGHT', -3, 0)
    line.iconRight:SetSize(self.LINE_HEIGHT or 16, self.LINE_HEIGHT or 16)

    if self.isCheckList then
      line.chk = AstralUI:Template('AstralCheckButtonTemplate', line)
      line.chk:SetSize(14,14)
      line.chk:SetPoint('LEFT',4,0)
      line.chk:SetScript('OnClick', ScrollList_Check_Click)
    end

    line.mainFrame = self
    line.id = i
    line:SetScript('OnClick', ScrollList_Line_Click)
    line:SetScript('OnEnter', ScrollListLineEnter)
    line:SetScript('OnLeave', ScrollListLineLeave)
    line:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    line:SetScript('OnDragStart', ScrollListLineOnDragStart)
    line:SetScript('OnDragStop', ScrollListLineOnDragStop)
    if self.dragAdded then
      line:SetMovable(true)
      line:RegisterForDrag('LeftButton')
    end

    return line
  end

  local function ScrollList_ScrollBar_OnValueChanged(self,value)
    local parent = self:GetParent():GetParent()
    parent:SetVerticalScroll(value % (parent:GetParent().LINE_HEIGHT or 16))
    self:UpdateButtons()
    parent:GetParent():Update()
  end

  local function Widget_Update(self)
    local val = floor(self.Frame.ScrollBar:GetValue() / (self.LINE_HEIGHT or 16)) + 1
    local j = 0
    for i = val, #self.L do
      j = j + 1
      local line = self.List[j]
      if not line then
        line = ScrollList_AddLine(self, j)
      end
      if not self.T then
        if type(self.L[i]) == 'table' then
          line:SetText(self.L[i][1])
        else
          line:SetText(self.L[i])
        end
      else
        for k=1,#self.T do
          line['text'..k]:SetText(self.L[i][k] or '')
        end
      end
      if self.isCheckList then
        line.chk:SetChecked(self.C[i])
      elseif not self.T then
        if not self.dontDisable then
          if i ~= self.selected then
            line:SetEnabled(true)
            line.ignoreDrag = false
          else
            line:SetEnabled(nil)
            line.ignoreDrag = true
          end
        end
        if self.LDisabled then
          if self.LDisabled[i] then
            line:SetEnabled(false)
            line.ignoreDrag = true
            line.text:Color(.5, .5, .5, 1)
            line.PushedTexture:SetAlpha(0)
          else
            line.text:Color()
            line.PushedTexture:SetAlpha(1)
          end
        end
      end
      if self.IconsRight then
        local icon = self.IconsRight[j]
        if type(icon)=='table' then
          line.iconRight:SetTexture(icon[1])
          line.iconRight:SetSize(icon[2], icon[2])
        elseif icon then
          line.iconRight:SetTexture(icon)
          line.iconRight:SetSize(self.LINE_HEIGHT or 16, self.LINE_HEIGHT or 16)
        else
          line.iconRight:SetTexture('')
        end
      end
      if self.colors then
        if self.colors[i] then
          line.background:SetColorTexture(unpack(self.colors[i]))
        else
          line.background:SetColorTexture(0, 0, 0, 0)
        end
      end
      line:Show()
      line.index = i
      line.table = self.L[i]
      if (j >= #self.L) or (j >= self.linesPerPage) then
        break
      end
    end
    for i = (j+1), #self.List do
      self.List[i]:Hide()
    end
    self.Frame.ScrollBar:Range(0, max(0, #self.L * (self.LINE_HEIGHT or 16) - 1 - self:GetHeight()), self.LINE_HEIGHT or 16, true):UpdateButtons()

    if (self:GetHeight() / (self.LINE_HEIGHT or 16) - #self.L) > 0 then
      self.Frame.ScrollBar:Hide()
      self.Frame.C:SetWidth(self.Frame:GetWidth())
    else
      self.Frame.ScrollBar:Show()
      self.Frame.C:SetWidth(self.Frame:GetWidth() - (self.SCROLL_WIDTH or 16))
    end

    if self.UpdateAdditional then
      self.UpdateAdditional(self, val)
    end

    if self.HoveredLine then
      local hovered = self.HoveredLine
      ScrollListLineLeave(hovered)
      ScrollListLineEnter(hovered)
    end

    return self
  end
  local function Widget_SetSize(self, width, height)
    self:_Size(width, height)
    self.Frame:Size(width, height):Height(height + (self.LINE_HEIGHT or 16))
    self.linesPerPage = height / (self.LINE_HEIGHT or 16) + 1
    self.Frame.ScrollBar:Range(0, max(0, #self.L * (self.LINE_HEIGHT or 16) - 1 - height)):UpdateButtons()
    self:Update()
    return self
  end
  local function Widget_FontSize(self, size)
    self.fontSize = size
    if not self.T then
      for i = 1, #self.List do
        self.List[i].text:SetFont(self.List[i].text:GetFont(), size)
      end
    else
      for i = 1, #self.List do
        for j = 1, #self.T do
          self.List[i]['text' .. j]:SetFont(self.List[i]['text' .. j]:GetFont(), size)
        end
      end
    end
    return self
  end
  local function Widget_Font(self, fontName, fontSize)
    self.fontSize = fontSize
    self.fontName = fontName
    if not self.T then
      for i = 1, #self.List do
        self.List[i].text:SetFont(fontName, fontSize)
      end
    else
      for i = 1, #self.List do
        for j = 1, #self.T do
          self.List[i]['text'..j]:SetFont(fontName, fontSize)
        end
      end
    end
    return self
  end
  local function Widget_SetLineHeight(self, height)
    self.LINE_HEIGHT = height
    return self
  end
  local function Widget_AddDrag(self)
    self.dragAdded = true
    for i = 1, #self.List do
      local line = self.List[i]
      line:SetMovable(true)
      line:RegisterForDrag('LeftButton')
    end

    return self
  end
  local function Widget_HideBorders(self)
    AstralUI:Border(self.Frame, 0)
    AstralUI:Border(self, 0)
    AstralUI:Border(self, 0, nil, nil, nil, nil, nil, 1)
    return self
  end
  local function Widget_SetTo(self, index)
    self.selected = index
    self:Update()
    if self.SetListValue then
      self:SetListValue(index)
    end
    if self.AdditionalLineClick then
      self.AdditionalLineClick(self)
    end
    return self
  end

  local function CreateScrollList(parent, list)
    local self = CreateFrame('FRAME', nil, parent)
    self.Frame = AstralUI:ScrollFrame(self):Point(0, 0)

    AstralUI:Border(self, 2, .24, .25, .30, 1)
    AstralUI:Border(self, 1, 0, 0, 0, 1, 2, 1)

    self.linesPerPage = 1
    self.List = {}
    self.L = list or {}

    Mod(self,
      'Update',Widget_Update,
      'FontSize',Widget_FontSize,
      'Font',Widget_Font,
      'LineHeight',Widget_SetLineHeight,
      'AddDrag',Widget_AddDrag,
      'HideBorders',Widget_HideBorders,
      'SetTo',Widget_SetTo
    )
    self._Size = self.Size
    self.Size = Widget_SetSize

    self.Frame.ScrollBar:SetScript('OnValueChanged', ScrollList_ScrollBar_OnValueChanged)
    self:SetScript('OnShow', self.Update)
    self:SetScript('OnMouseWheel', ScrollListMouseWheel)

    return self
  end
  function AstralUI:ScrollList(parent, list)
    local self = CreateScrollList(parent, list)
    self:Update()
    return self
  end
  function AstralUI:ScrollTableList(parent, ...)
    local self = CreateScrollList(parent)
    self.T = {}
    for i=1,select('#', ...) do
      self.T[i] = select(i, ...)
    end
    self:Update()
    return self
  end
  function AstralUI:ScrollCheckList(parent, list)
    local self = CreateScrollList(parent, list)
    self.C = {}
    self.isCheckList = true
    self:Update()
    return self
  end
end

do
  local exportWindow
  function AstralUI:Export(str, hideTextInfo, name, func)
    if not exportWindow then
      exportWindow = AstralUI:Popup('Export'):Size(650, 600)
      exportWindow.Edit = AstralUI:MultiEdit(exportWindow):Point('TOP', 0, -20):Size(640, 560)
      exportWindow.TextInfo = AstralUI:Text(exportWindow, 'Export Info', 11):Color():Point('BOTTOM', 0, 3):Size(640, 15):Bottom():Left()
      exportWindow:SetScript('OnHide', function(self) self.Edit:SetText('') end)
      exportWindow.Next = AstralUI:Button(exportWindow, '>>>'):Size(100, 16):Point('BOTTOMRIGHT', 0, 0):OnClick(function(self)
        self.now = self.now + 1
        self:SetText('>>> ' .. self.now .. '/' .. #exportWindow.hugeText)
        exportWindow.Edit:SetText(exportWindow.hugeText[self.now])
        exportWindow.Edit.EditBox:HighlightText()
        exportWindow.Edit.EditBox:SetFocus()
        if self.now == #exportWindow.hugeText then
          self:Hide()
        end
      end)
    end
    exportWindow.title:SetText(name or 'Export')
    exportWindow.Edit.OnTextChanged = func
    exportWindow:NewPoint('CENTER', UIParent, 0, 0)
    exportWindow.TextInfo:SetShown(not hideTextInfo)
    exportWindow:Show()
    if #str > 200000 then
      exportWindow.hugeText = {}
      while str and str ~= '' do
        local newText = str:sub(1, 200000)..strsplit('\n', str:sub(200001))
        exportWindow.hugeText[#exportWindow.hugeText+1] = newText
        str = select(2, strsplit('\n', str:sub(200001), 2))
      end
      exportWindow.Next.now = 0
      exportWindow.Next:Show()
      exportWindow.Next:Click()
    else
      exportWindow.hugeText = nil
      exportWindow.Next:Hide()
      exportWindow.Edit:SetText(str)
      exportWindow.Edit.EditBox:HighlightText()
      exportWindow.Edit.EditBox:SetFocus()
    end
  end
end

do
  local choiceWindow -- TODO
  function AstralUI:Choices(str, name, func)
    if not choiceWindow then
      choiceWindow = AstralUI:Popup('Choices'):Size(650, 600)
      choiceWindow.Edit = AstralUI:MultiEdit(choiceWindow):Point('TOP', 0, -20):Size(640, 560)
      choiceWindow.TextInfo = AstralUI:Text(choiceWindow, 'Export Info', 11):Color():Point('BOTTOM', 0, 3):Size(640, 15):Bottom():Left()
      choiceWindow:SetScript('OnHide', function(self) self.Edit:SetText('') end)
      choiceWindow.Next = AstralUI:Button(choiceWindow, '>>>'):Size(100, 16):Point('BOTTOMRIGHT', 0, 0):OnClick(function(self)
        self.now = self.now + 1
        self:SetText('>>> ' .. self.now .. '/' .. #choiceWindow.hugeText)
        choiceWindow.Edit:SetText(choiceWindow.hugeText[self.now])
        choiceWindow.Edit.EditBox:HighlightText()
        choiceWindow.Edit.EditBox:SetFocus()
        if self.now == #choiceWindow.hugeText then
          self:Hide()
        end
      end)
    end
    choiceWindow.title:SetText(name or 'Export')
    choiceWindow.Edit.OnTextChanged = func
    choiceWindow:NewPoint('CENTER', UIParent, 0, 0)
    choiceWindow:Show()
    if #str > 200000 then
      choiceWindow.hugeText = {}
      while str and str ~= "" do
        local newText = str:sub(1, 200000)..strsplit("\n",str:sub(200001))
        choiceWindow.hugeText[#choiceWindow.hugeText+1] = newText
        str = select(2,strsplit("\n",str:sub(200001), 2))
      end
      choiceWindow.Next.now = 0
      choiceWindow.Next:Show()
      choiceWindow.Next:Click()
    else
      choiceWindow.hugeText = nil
      choiceWindow.Next:Hide()
      choiceWindow.Edit:SetText(str)
      choiceWindow.Edit.EditBox:HighlightText()
      choiceWindow.Edit.EditBox:SetFocus()
    end
  end
end

function AstralUI:UpdateScrollList(self, lineHeight, initFunc, lineFunc)
  initFunc(self)
  local scroll = self.ScrollBar:GetValue()
  self:SetVerticalScroll(scroll % lineHeight)
  local start = floor(scroll / lineHeight) + 1
  local list = self.list
  local lineCount = 1
  for i = start, #list do
    local data = list[i]
    local line = self.lines[lineCount]
    lineCount = lineCount + 1
    if not line then
      break
    end
    lineFunc(line, data)
    line.data = data
    line:Show()
  end
  for i = lineCount, #self.lines do
    self.lines[i]:Hide()
  end
  self:Height(lineHeight * #list)
end

-- Dialogs

StaticPopupDialogs['WANT_TO_RELEASE_ASTRAL'] = {
  text = 'Do you want to release your spirit?',
  button1 = 'Ok',
  OnAccept = function()
    StaticPopup1Button1:Show()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = false,
  preferredIndex = 3
}