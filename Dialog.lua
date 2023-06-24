local reallyRelease

StaticPopupDialogs["WANT_TO_RELEASE"] = {
  text = 'Do you want to release your spirit?',
  button1 = 'Ok',
  OnAccept = function()
      reallyRelease()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = false,
  preferredIndex = 3
}

reallyRelease = function()
  if StaticPopup1:IsShown() and StaticPopup1Button1:GetButtonState() == 'NORMAL' then
    StaticPopup1Button1:Enable()
  end
end