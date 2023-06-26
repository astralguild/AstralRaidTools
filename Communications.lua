local _, addon = ...

local SendAddonMessage, SendChatMessage = C_ChatInfo.SendAddonMessage, SendChatMessage
local LibDeflate = LibStub:GetLibrary("LibDeflate")

-- Protocol constants
local PREFIX = 'ASTRAL_RAID'
local SENDER_VERSION, DATA_VERSION = 1, 1

-- Interval times for syncing keys between clients
-- Two different time settings for in a raid or otherwise
-- Creates a random variance between +- [.001, .100] to help prevent
-- disconnects from too many addon messages
-- Borrowed from Astral Keys Communications.lua
local SEND_VARIANCE = ((-1)^math.random(1,2)) * math.random(1, 100)/ 10^3 -- random number to space out messages being sent between clients
local SEND_INTERVAL = {}
SEND_INTERVAL[1] = 0.2 + SEND_VARIANCE -- Normal operations
SEND_INTERVAL[2] = 1 + SEND_VARIANCE -- Used when in a non-raiding environment
SEND_INTERVAL[3] = 2 -- Used for version checks

-- Current setting to be used
-- Changes when player enters a raid instance or not
local SEND_INTERVAL_SETTING = 1 -- What intervel to use for sending normal information

local msgs, newMsg, delMsg

AstralRaidComms = CreateFrame('FRAME', 'AstralRaidComms')

function AstralRaidComms:Init()
	C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

	self:SetScript('OnEvent', self.OnEvent)
	self:SetScript('OnUpdate', self.OnUpdate)

	self.dtbl = {}
	self.queue = {}

	self:Hide()
	self.delay = 0
	self.loadDelay = 0
	self.versionPrint = false
	self.runningText = {}

	self:RegisterEvent('CHAT_MSG_ADDON')
end

function AstralRaidComms:RegisterPrefix(channel, prefix, f)
	channel = channel or 'RAID'

	if self:IsPrefixRegistered(channel, prefix) then return end -- Did we register something to the same channel with the same name?

	if not self.dtbl[channel] then self.dtbl[channel] = {} end

	local obj = {}
	obj.method = f
	obj.prefix = prefix

	table.insert(self.dtbl[channel], obj)
end

function AstralRaidComms:UnregisterPrefix(channel, prefix)
	local objs = self.dtbl[channel]
	if not objs then return end
	for id, obj in pairs(objs) do
		if obj.prefix == prefix then
			objs[id] = nil
			break
		end
	end
end

function AstralRaidComms:IsPrefixRegistered(channel, prefix)
	local objs = self.dtbl[channel]
	if not objs then return false end
	for _, obj in pairs(objs) do
		if obj.prefix == prefix then
			return true
		end
	end
	return false
end

function AstralRaidComms:OnEvent(event, prefix, msg, channel, sender)
	if event ~= 'CHAT_MSG_ADDON' then return end
	if prefix ~= PREFIX then return end
	print(prefix, msg, channel)
	local objs = self.dtbl[channel]
	if not objs then return end
	local arg, content = msg:match("^(%S*)%s*(.-)$")
	for _, obj in pairs(objs) do
		if obj.prefix == arg then
			obj.method(content, sender, msg)
		end
	end
end

function AstralRaidComms:OnUpdate(elapsed)
	self.delay = self.delay + elapsed
	if self.delay < SEND_INTERVAL[SEND_INTERVAL_SETTING] + self.loadDelay then
		return
	end
	self.loadDelay = 0

	if self.versionPrint then
		AstralRaidComms.loadDelay = 3
		if addon.InInstance and addon.InstanceType == 'raid' then
			SEND_INTERVAL_SETTING = 1
		else
			SEND_INTERVAL_SETTING = 2
		end
		self.versionPrint = false
		addon.PrintCheckResults()
	end

	self.delay = 0
	if #self.queue < 1 then -- Don't have any messages to send
		self:Hide()
		return
	end

	self:SendMessage()
end

function AstralRaidComms:NewMessage(prefix, text, channel, target)
	if channel == 'GUILD' then
		if not IsInGuild() then
			return
		end
	end

	if channel == 'RAID' then
		if not IsInRaid() then
			return
		end
	end

	local msg = newMsg()
	msg.method = SendAddonMessage
	msg[1] = prefix
	msg[2] = text
	msg[3] = channel
	msg[4] = channel == 'WHISPER' and target or ''

	--Let's add it to queue
	self.queue[#self.queue + 1] = msg

	if not self:IsShown() then
		self:Show()
	end
end

function AstralRaidComms:SendMessage()
	local msg = table.remove(self.queue, 1)
	if msg[3] == 'WHISPER' then
		if addon.IsFriendOnline(msg[4]) then -- Are they still logged into that toon
			msg.method(unpack(msg, 1, #msg))
		end
	else-- Guild/raid message, just send it
		msg.method(unpack(msg, 1, #msg))
		delMsg(msg)
	end
end

function AstralRaidComms:SendChunkedAddonMessages(prefix, prefix2, message, ...)
	local compressed = LibDeflate:CompressDeflate(message, {level = 9})
	local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
	encoded = encoded .. "##F##"
	local parts = ceil(#encoded / 240)
	for i = 1, parts do
		local msg = encoded:sub((i-1)*240+1 , i*240)
		SendAddonMessage(prefix, prefix2 .. ' ' .. msg, ...)
	end
end

function AstralRaidComms:DecodeChunkedAddonMessages(sender, message, func)
	if self.runningText[sender] and type(self.runningText[sender]) == 'string' then
		self.runningText[sender] = self.runningText[sender] .. message
	else
		self.runningText[sender] = message
	end

	if self.runningText[sender] and type(self.runningText[sender]) == 'string' and self.runningText[sender]:find("##F##$") then
		local str = self.runningText[sender]:sub(1,-6)
		local decoded = LibDeflate:DecodeForWoWAddonChannel(str)
		local decompressed = LibDeflate:DecompressDeflate(decoded)
		func(decompressed)
		self.runningText[sender] = nil
	end
end

-- Version/Addon/WA Checking

local function waRequest(channel, ...)
	local msg, sender = ...
	AstralRaidComms:DecodeChunkedAddonMessages(sender, string.sub(msg, 11), function(m)
		local resp = addon.PlayerClass

		addon.GetWeakAuras()
		for wa, url in string.gmatch(m, '"([^"]+)":"([^"]+)"') do
			if not addon.WeakAuraList[wa] or addon.WeakAuraList[wa] ~= url then
				local u = ''
				if addon.WeakAuraList[wa] then
					u = addon.WeakAuraList[wa]
				end
				resp = resp .. string.format(' "%s":"%s"', wa, u)
			end
		end
		AstralRaidComms:SendChunkedAddonMessages(PREFIX, 'waPush', resp, channel)
	end)
end

local function addonRequest(channel, ...)
	local msg, _ = ...

	local resp = 'addonPush ' .. addon.PlayerClass

	for a, v in string.gmatch(msg, '"([^"]+)":"([^"]+)"') do
		if not addon.AddonList[a] or addon.AddonList[a] ~= v then
			resp = resp .. string.format(' "%s":"%s"', a, addon.AddonList[a])
		end
	end

	AstralRaidComms:SendChunkedAddonMessages(PREFIX, 'addonPush', resp, channel)
end

local function versionRequest(channel, ...)
	local resp = 'versionPush ' .. string.format('%s:%s', addon.CLIENT_VERSION, addon.PlayerClass)
	SendAddonMessage(PREFIX, resp, channel)
end

AstralRaidComms:Init()
AstralRaidComms:RegisterPrefix('RAID', 'waRequest', function(...) waRequest('RAID', ...) end)
AstralRaidComms:RegisterPrefix('GUILD', 'waRequest', function(...) waRequest('GUILD', ...) end)
AstralRaidComms:RegisterPrefix('RAID', 'addonRequest', function(...) addonRequest('RAID', ...) end)
AstralRaidComms:RegisterPrefix('GUILD', 'addonRequest', function(...) addonRequest('GUILD', ...) end)
AstralRaidComms:RegisterPrefix('RAID', 'versionRequest', function(...) versionRequest('RAID', ...) end)
AstralRaidComms:RegisterPrefix('GUILD', 'versionRequest', function(...) versionRequest('GUILD', ...) end)

-- Message handling

msgs = setmetatable({}, {__mode='k'})

newMsg = function()
	local msg = next(msgs)
	if msg then
		msgs[msg] = nil
		return msg
	end
	return {}
end

delMsg = function(msg)
	msg[1] = nil
	msgs[msg] = true
end