local _, addon = ...

local SharedMedia = LibStub("LibSharedMedia-3.0")

AstralRaidReminders = CreateFrame('FRAME', 'AstralRaidReminders', UIParent)
AstralRaidReminders:SetHeight(1)
AstralRaidReminders:SetWidth(1)
AstralRaidReminders:SetPoint('CENTER', UIParent, 'CENTER')
AstralRaidReminders:Hide()

local textReminders = {}
local displayed = {}

function addon.CreateReminder(name, text)
  if textReminders[name] then
    return textReminders[name]
  end

  local fontPath = SharedMedia:Fetch('font', 'PT Sans Narrow')

  textReminders[name] = AstralRaidReminders:CreateFontString(nil, 'OVERLAY', 'GameTooltipText')
  textReminders[name]:SetPoint('CENTER', 0, 400)
  textReminders[name]:SetFont(fontPath, 72, 'OUTLINE')
  textReminders[name]:SetText(text)
  textReminders[name]:Hide()

  textReminders[name]:SetScript('OnShow', function(self)
    if #displayed > 0 then
      self:SetPoint('CENTER', displayed[#displayed], 'BOTTOM', 0, -20)
    else
      self:SetPoint('CENTER', 0, 400)
    end
    displayed[#displayed+1] = self
  end)

  textReminders[name]:SetScript('OnHide', function(self)
    local i = 0
    for j = 1, #displayed do
      if displayed[j] == self then
        i = j
      end
    end
    table.remove(displayed, i)
    for j = 1, #displayed do
      if j == 1 then
        displayed[j]:SetPoint('CENTER', 0, 400)
      else
        displayed[j]:SetPoint('CENTER', displayed[j-1], 'BOTTOM', 0, -30)
      end
    end
  end)

  return textReminders[name]
end