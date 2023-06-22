local _, addon = ...

local AstralRaidOptionsFrame = CreateFrame('FRAME', 'AstralRaidOptionsFrame', UIParent)
AstralRaidOptionsFrame:SetFrameStrata('DIALOG')
AstralRaidOptionsFrame:SetFrameLevel(5)
AstralRaidOptionsFrame:SetHeight(455)
AstralRaidOptionsFrame:SetWidth(650)
AstralRaidOptionsFrame:SetPoint('CENTER', UIParent, 'CENTER')
AstralRaidOptionsFrame:SetMovable(true)
AstralRaidOptionsFrame:EnableMouse(true)
AstralRaidOptionsFrame:RegisterForDrag('LeftButton')
AstralRaidOptionsFrame:EnableKeyboard(true)
AstralRaidOptionsFrame:SetPropagateKeyboardInput(true)
AstralRaidOptionsFrame:SetClampedToScreen(true)
AstralRaidOptionsFrame.background = AstralRaidOptionsFrame:CreateTexture(nil, 'BACKGROUND')
AstralRaidOptionsFrame.background:SetAllPoints(AstralRaidOptionsFrame)
AstralRaidOptionsFrame.background:SetColorTexture(0, 0, 0, 0.0)
AstralRaidOptionsFrame:Hide()

function addon.InitializeOptionSettings()
  -- set all widgets
end

AstralRaidEvents:Register('PLAYER_LOGIN', addon.InitializeOptionSettings, 'astralRaidInitOptions')

AstralRaidOptionsFrame:SetScript('OnKeyDown', function (self, key)
  if key == 'ESCAPE' then
    self:SetPropagateKeyboardInput(false)
    AstralRaidOptionsFrame:Hide()
  end
end)

AstralRaidOptionsFrame:SetScript('OnShow', function(self)
  self:SetPropagateKeyboardInput(true)
  addon.InitializeOptionSettings()
end)