local ADDON_NAME, addon = ...

local module = addon:New('Roster', 'Roster View')

module.WeakAuras = {}
module.WeakAuraResponses = {}

local function waPush(channel, ...)
	local msg, sender = ...
	AstralRaidComms:DecodeChunkedAddonMessages(sender, msg, function(m)
		local player = Ambiguate(sender, 'short')
		module.WeakAuraResponses[player] = {}
		for wa, _ in pairs(AstralRaidSettings.wa.required) do
			module.WeakAuraResponses[player][wa] = true
		end
		for wa, url in string.gmatch(m, '"([^"]+)":"([^"]+)"') do
			module.WeakAuraResponses[player][wa] = url
		end
		module.UpdateRosterPage()
	end)
end

local function envPush(msg, sender)
	print(msg)
end

AstralRaidComms:RegisterPrefix('RAID', 'versionPush', envPush)
AstralRaidComms:RegisterPrefix('RAID', 'addonPush', envPush)
AstralRaidComms:RegisterPrefix('RAID', 'waPush', function(...) waPush('RAID', ...) end)

local function sendRequest(request, msg, channel)
	AstralRaidComms:SendChunkedAddonMessages(request, msg, channel)
	AstralRaidComms.versionPrint = true
	AstralRaidComms.delay = 0
	AstralRaidComms:Show()
end

function module.SendWeakAuraRequest()
	if not IsInRaid() then return end

	local req = ''
	for wa, val in pairs(AstralRaidSettings.wa.required) do
		if val then
			req = req .. string.format(' "%s":"%s"', wa, tostring(module.WeakAuras[wa].url))
		end
	end

	sendRequest('waRequest', req, 'RAID')
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

function module.options:Load()
	local LISTFRAME_WIDTH = 610
	local LISTFRAME_HEIGHT = 480
	local VERTICALNAME_WIDTH = 20
	local VERTICALNAME_COUNT = 24
	local LINE_HEIGHT, LINE_NAME_WIDTH = 16, 100

	local roster = AstralUI:ScrollFrame(self):Point(0, -80):Size(LISTFRAME_WIDTH, LISTFRAME_HEIGHT)
	self.updateButton = AstralUI:Button(self, UPDATE):Point('BOTTOMRIGHT', -75, 45):Size(130,20):OnClick(function()
		module.SendWeakAuraRequest()
	end)

	AstralUI:Border(roster, 0)
	roster.prevTopLine = 0
	roster.prevPlayerCol = 0
	roster.ScrollBar:ClickRange(32)

	local raidSlider = AstralUI:Slider(self, ''):Point("TOPLEFT", roster,"BOTTOMLEFT", LINE_NAME_WIDTH + 15,-3):Range(0,25):Size(VERTICALNAME_WIDTH*VERTICALNAME_COUNT):SetTo(0):OnChange(function(self, value)
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
		elseif type == 1 then -- x
			self:SetTexCoord(0.5,0.5625,0.5,0.625)
			self:SetVertexColor(.8,0,0,1)
		elseif type == 2 then -- green check
			self:SetTexCoord(0.5625,0.625,0.5,0.625)
			self:SetVertexColor(0,.8,0,1)
		elseif type == 3 then -- yellow check
			self:SetTexCoord(0.5625,0.625,0.5,0.625)
			self:SetVertexColor(.8,.8,0,1)
		elseif type == 4 then -- ellipsis
			self:SetTexCoord(0.875,0.9375,0.5,0.625)
			self:SetVertexColor(.8,.8,0,1)
		end
	end

	for i = 1, ceil(LISTFRAME_HEIGHT/LINE_HEIGHT) do
		local line = CreateFrame('FRAME', nil, roster.C)
		roster.lines[i] = line
		line:SetPoint("TOPLEFT",0,-(i-1)*LINE_HEIGHT)
		line:SetPoint("TOPRIGHT",0,-(i-1)*LINE_HEIGHT)
		line:SetSize(0,LINE_HEIGHT)
		line.name = AstralUI:Text(line):Size(LINE_NAME_WIDTH-LINE_HEIGHT/2,LINE_HEIGHT):Point('LEFT', 2, 0):Shadow():Tooltip("ANCHOR_LEFT",true)
		line.icons = {}
		local iconSize = min(VERTICALNAME_WIDTH,LINE_HEIGHT)
		for j=1,VERTICALNAME_COUNT do
			local icon = line:CreateTexture(nil,"ARTWORK")
			line.icons[j] = icon
			icon:SetPoint("CENTER",line,"LEFT",LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(j-1) + VERTICALNAME_WIDTH / 2,0)
			icon:SetSize(iconSize,iconSize)
			icon:SetTexture('Interface\\AddOns\\'.. ADDON_NAME ..'\\media\\DiesalGUIcons16x256x128')
			roster:SetIcon(icon,(i+j)%4)
		end
		line.t = line:CreateTexture(nil, 'BACKGROUND')
		line.t:SetAllPoints()
		line.t:SetColorTexture(1, 1, 1, .05)
		line:Hide()
	end

	local raidNames = CreateFrame('FRAME', nil, self)
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

		local list = self.list
		local lineCount = 1
		local backgroundLineStatus = (roster.prevTopLine % 2) == 1
		for i = start, #list do
			local data = list[i]
			local line = self.lines[lineCount]
			lineCount = lineCount + 1
			if not line then
				break
			end
			line.name:SetText(data)
			line.data = data
			line:Show()

			line.t:SetShown(backgroundLineStatus)
			for j = 1, VERTICALNAME_COUNT do
				local pname = namesList2[j] or "-"
				local d
				for name, dat in pairs(module.WeakAuraResponses) do
					if name == pname then
						d = dat
						break
					end
				end
				if not d then -- no data, no icon
					roster:SetIcon(line.icons[j], 0)
				elseif d[data] and d[data] == true then -- has WA
					roster:SetIcon(line.icons[j], 2)
				elseif type(d[data]) == 'string' then -- URL different
					roster:SetIcon(line.icons[j], 3)
				elseif d then
					roster:SetIcon(line.icons[j], 4)
				else
					roster:SetIcon(line.icons[j], 1)
				end
			end
		end
		for i=lineCount,#self.lines do
			self.lines[i]:Hide()
		end

		self:Height(LINE_HEIGHT * #list)
	end

	function module.options:OnShow()
		roster:Update()
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
end