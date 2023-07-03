local ADDON_NAME, addon = ...

local module = addon:New('Roster', 'Roster View', true)

local statusIcons = {
	[1] = "Interface\\RaidFrame\\ReadyCheck-Waiting",
	[2] = "Interface\\RaidFrame\\ReadyCheck-Ready",
	[3] = "Interface\\RaidFrame\\ReadyCheck-NotReady",
	[4] = 'Interface\\AddOns\\' .. ADDON_NAME .. '\\Media\\dash.png',
}

local notInRaidText, roster, raidSlider, raidNames, updateButton
local cdRequest = 5
local lastRequest = nil

local function checkButtonCooldown(self)
	if (GetTime() - lastRequest) >= cdRequest then
		self:SetText('Update')
		self:Enable()
	else
		self:SetText('Update (' .. cdRequest - floor(GetTime() - lastRequest) .. ')')
		C_Timer.After(1, function()
			checkButtonCooldown(self)
		end)
	end
end

function module.options:Load()
	local LISTFRAME_WIDTH = 610
	local LISTFRAME_HEIGHT = 400
	local VERTICALNAME_WIDTH = 20
	local VERTICALNAME_COUNT = 24
	local LINE_HEIGHT, LINE_NAME_WIDTH = 16, 150

	roster = AstralUI:ScrollFrame(self):Point(0, -80):Size(LISTFRAME_WIDTH, LISTFRAME_HEIGHT)
	updateButton = AstralUI:Button(self, UPDATE):Point('BOTTOMRIGHT', -75, 45):Size(130,20):OnClick(function(self)
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

	raidSlider = AstralUI:Slider(self, ''):Point("TOPLEFT", roster,"BOTTOMLEFT", LINE_NAME_WIDTH + 15,-3):Range(0,25):Size(VERTICALNAME_WIDTH*VERTICALNAME_COUNT):SetTo(0):OnChange(function(self, value)
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
		if not type or type == 0 then
			self:SetAlpha(0)
		elseif type == 1 then
			self:SetTexture(statusIcons[3])
			self:SetVertexColor(1,1,1,1)
		elseif type == 2 then
			self:SetTexture(statusIcons[2])
			self:SetVertexColor(1,1,1,1)
		elseif type == 3 then
			self:SetTexture(statusIcons[1])
			self:SetVertexColor(1,1,1,1)
		elseif type == 4 then
			self:SetTexture(statusIcons[4])
			self:SetVertexColor(0.6,0.6,0.6,1)
		end
	end

	for i = 1, ceil(LISTFRAME_HEIGHT/LINE_HEIGHT) do
		local line = CreateFrame('FRAME', nil, roster.C)
		roster.lines[i] = line
		line:SetPoint("TOPLEFT",0,-(i-1)*LINE_HEIGHT)
		line:SetPoint("TOPRIGHT",0,-(i-1)*LINE_HEIGHT)
		line:SetSize(0,LINE_HEIGHT)
		line.name = AstralUI:Text(line):Size(LINE_NAME_WIDTH-LINE_HEIGHT/2,LINE_HEIGHT):Point('LEFT', 2, 0):Shadow():Tooltip("ANCHOR_LEFT",true):FontSize(9)
		line.icons = {}
		local iconSize = min(VERTICALNAME_WIDTH,LINE_HEIGHT)
		for j=1,VERTICALNAME_COUNT do
			local icon = line:CreateTexture(nil,"ARTWORK")
			line.icons[j] = icon
			icon:SetPoint("CENTER",line,"LEFT",LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(j-1) + VERTICALNAME_WIDTH / 2,0)
			icon:SetSize(iconSize,iconSize)
			roster:SetIcon(icon,(i+j)%4)

			local f = CreateFrame('FRAME', nil, line)
			f:SetPoint('TOPLEFT', icon, 'TOPLEFT', 0, 0)
			f:SetSize(iconSize,iconSize)
			f:SetScript("OnEnter", function(self)
				if self.icon.t and self.icon.t ~= "" then
					AstralUI.Tooltip.Show(self, "ANCHOR_LEFT", self.icon.t)
				end
			end)
			f:SetScript("OnLeave", AstralUI.Tooltip.Hide)
			f.icon = icon
		end
		line.t = line:CreateTexture(nil, 'BACKGROUND')
		line.t:SetAllPoints()
		line.t:SetColorTexture(1, 1, 1, .05)
		line:Hide()
	end

	raidNames = CreateFrame('FRAME', nil, self)
	for i=1,VERTICALNAME_COUNT do
		raidNames[i] = AstralUI:Text(raidNames,'raid'..i,10):Point('BOTTOMLEFT', roster,'TOPLEFT', LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(i-1),0):Color(1,1,1)
		local f = CreateFrame('FRAME', nil, self)
		f:SetPoint('BOTTOMLEFT',roster,"TOPLEFT",LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(i-1),0)
		f:SetSize(VERTICALNAME_WIDTH,80)
		f:SetScript("OnEnter", function(self)
			local t = self.t:GetText()
			if t ~= "" then
				AstralUI.Tooltip.Show(self,"ANCHOR_LEFT",t)
			end
		end)
		f:SetScript("OnLeave", AstralUI.Tooltip.Hide)
		f.t = raidNames[i]

		local t = roster:CreateTexture(nil, "BACKGROUND")
		raidNames[i].t = t
		t:SetPoint("TOPLEFT",LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(i-1),0)
		t:SetSize(VERTICALNAME_WIDTH, LISTFRAME_HEIGHT)
		if i % 2 == 1 then
			t:SetColorTexture(.5,.5,1,.05)
			t.Vis = true
		end
	end
	local rosterRotation = raidNames:CreateAnimationGroup()
	rosterRotation:SetScript('OnFinished', function() rosterRotation:Play() end)
	local rotation = rosterRotation:CreateAnimation('Rotation')
	rotation:SetDuration(0.000001)
	rotation:SetEndDelay(2147483647)
	rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
	rotation:SetDegrees(60)
	rosterRotation:Play()

	local function sortByName(a,b)
		if a and b and a.name and b.name then
			return a.name < b.name
		end
	end

	function roster:Update()
		local l = {}
		for wa, data in pairs(AstralRaidSettings.wa.required) do
			if data then
				l[#l+1] = {wa, 'WeakAura'}
			end
		end
		for a, data in pairs(AstralRaidSettings.addons.required) do
			if data then
				l[#l+1] = {a, 'Addon'}
			end
		end
		roster.list = l

		local scroll = self.ScrollBar:GetValue()
		self:SetVerticalScroll(scroll % LINE_HEIGHT)
		local start = floor(scroll / LINE_HEIGHT) + 1

		local namesList, namesList2 = {},{}
		for _, name, _, class in addon.IterateRoster do
			namesList[#namesList + 1] = {
				name = name,
				class = class,
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
			local name = addon.DelUnitNameServer(namesList[i].name)
			raidNames[raidNamesUsed]:SetText(name)
			raidNames[raidNamesUsed]:SetTextColor(addon.ClassColorNum(namesList[i].class))
			namesList2[raidNamesUsed] = name
			if raidNames[raidNamesUsed].Vis then
				raidNames[raidNamesUsed]:SetAlpha(.05)
			end
		end
		for i = raidNamesUsed + 1, #raidNames do
			raidNames[i]:SetText("")
			raidNames[i].t:SetAlpha(0)
		end

		local weakAuras = addon.GetWeakAuras()
		local addons = addon.GetAddons()

		local list = self.list
		local lineCount = 1
		local backgroundLineStatus = (roster.prevTopLine % 2) == 1
		for i = start, #list do
			local data, t = unpack(list[i])
			local name = data .. string.format(' (|cfff5e4a8%s|r)', t)
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
			if t == 'WeakAura' then
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
						line.icons[j].t = 'No Response'
					elseif not d then
						roster:SetIcon(line.icons[j], 0)
						line.icons[j].t = ''
					elseif d[data] and d[data] == true then -- has WA/Addon
						roster:SetIcon(line.icons[j], 2)
						line.icons[j].t = ''
					elseif type(d[data]) == 'string' then -- data different
						roster:SetIcon(line.icons[j], 3)
						line.icons[j].t = string.format('Your Version: %s\nTheir Version: %s', tostring(yy[data].version), d[data])
					elseif d and not d[data] then
						roster:SetIcon(line.icons[j], 4)
						line.icons[j].t = ''
					else
						roster:SetIcon(line.icons[j], 1)
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

	roster.ScrollBar.slider:SetScript("OnValueChanged", function(self, value)
		local parent = self:GetParent():GetParent()
		parent:SetVerticalScroll(value % LINE_HEIGHT)
		local currTopLine = floor(value / LINE_HEIGHT)
		if currTopLine ~= self.prevTopLine then
			self.prevTopLine = currTopLine
			roster:Update()
		end
		self:UpdateButtons()
	end)

	notInRaidText = self:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
	notInRaidText:SetText('You must be in a raid group to inspect the raid roster.')
	notInRaidText:SetPoint('CENTER', -50, 100)
	notInRaidText:Hide()
end

function module.options:OnShow()
	if not IsInRaid() then
		roster:Hide()
		raidSlider:Hide()
		raidNames:Hide()
		updateButton:Hide()
		notInRaidText:Show()
	else
		roster:Show()
		raidSlider:Show()
		raidNames:Show()
		updateButton:Show()
		notInRaidText:Hide()
		roster:Update()
	end
end

function addon.UpdateRosterPage()
	roster:Update()
end