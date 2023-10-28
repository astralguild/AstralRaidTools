local _, addon = ...

local SendAddonMessage = C_ChatInfo.SendAddonMessage
local LibDeflate = LibStub:GetLibrary("LibDeflate")

-- Protocol constants
local PREFIX = 'ASTRAL_RAID'
local CHUNKED_EOL = '##F##$'

-- Interval times for syncing keys between clients
-- Two different time settings for in a raid or otherwise
-- Creates a random variance between +- [.001, .100] to help prevent
-- disconnects from too many addon messages
-- Borrowed from Astral Keys Communications.lua
local SEND_VARIANCE = ((-1)^math.random(1,2)) * math.random(1, 100)/ 10^3
local SEND_INTERVAL = 0.2 + SEND_VARIANCE

local msgs, newMsg, delMsg

AstralRaidComms = CreateFrame('FRAME', 'AstralRaidComms')
AstralRaidComms.PREFIX = PREFIX

function AstralRaidComms:Init()
  self.registered = C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

  self:SetScript('OnEvent', self.OnEvent)
  self:SetScript('OnUpdate', self.OnUpdate)

  self.dtbl = {}
  self.queue = {}

  self:Hide()
  self.delay = 0
  self.loadDelay = 0
  self.sendIndex = 0
  self.recIndex = {}
  self.runningText = {}

  self:RegisterEvent('CHAT_MSG_ADDON')
end

function AstralRaidComms:RegisterPrefix(channel, prefix, f)
  channel = channel or 'RAID'
  if self:IsPrefixRegistered(channel, prefix) then return end
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
  local objs = self.dtbl[channel]
  if not objs then return end
  local arg, _ = strsplit(' ', msg, 2)
  for _, obj in pairs(objs) do
    if obj.prefix == arg then
      obj.method(msg, sender)
    end
  end
end

function AstralRaidComms:OnUpdate(elapsed)
  self.delay = self.delay + elapsed
  if self.delay < SEND_INTERVAL + self.loadDelay then return end
  self.loadDelay = 0
  self.delay = 0
  if #self.queue < 1 then -- no messages to send
    self:Hide()
    return
  end
  self:SendMessage()
end

function AstralRaidComms:NewMessage(prefix, text, channel, target)
  if channel == 'GUILD' and not IsInGuild() then return end
  if channel == 'RAID' and not IsInRaid() then return end
  if channel == 'PARTY' and not IsInGroup() then return end

  local msg = newMsg()
  msg.method = SendAddonMessage
  msg[1] = prefix
  msg[2] = text
  msg[3] = channel
  msg[4] = channel == 'WHISPER' and target or ''

  --Let's add it to queue
  self.queue[#self.queue + 1] = msg

  if not self:IsShown() then self:Show() end
end

function AstralRaidComms:SendMessage()
  local msg = table.remove(self.queue, 1)
  if msg[3] == 'WHISPER' then
    if addon.IsFriendOnline(msg[4]) then
      msg.method(unpack(msg, 1, #msg))
    end
  else
    msg.method(unpack(msg, 1, #msg))
    delMsg(msg)
  end
end

function AstralRaidComms:SendChunkedAddonMessages(prefix2, message, ...)
  local compressed = LibDeflate:CompressDeflate(message, {level = 9})
  local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
  encoded = encoded .. "##F##"

  local index = 0
  while self.sendIndex ~= index do
    index = math.random(100, 999)
  end
  self.sendIndex = index

  local parts = ceil(#encoded / 240)
  for i = 1, parts do
    local msg = encoded:sub((i-1)*240+1, i*240)
    AstralRaidComms:NewMessage(PREFIX, string.format('%s %d %s', prefix2, index, msg), ...)
  end
end

function AstralRaidComms:DecodeChunkedAddonMessages(sender, message, func)
  if not self.runningText[sender] then
    self.runningText[sender] = {}
  end

  local prefix2, index, msg = strsplit(' ', message, 3)
  if self.runningText[sender][prefix2] and self.recIndex[prefix2] == index then
    self.runningText[sender][prefix2] = self.runningText[sender][prefix2] .. msg
  else
    self.runningText[sender][prefix2] = msg
  end
  self.recIndex[prefix2] = index

  if self.runningText[sender][prefix2] and self.runningText[sender][prefix2]:find(CHUNKED_EOL) then
    local decoded = LibDeflate:DecodeForWoWAddonChannel(self.runningText[sender][prefix2]:gsub(CHUNKED_EOL, ''))
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    self.runningText[sender][prefix2] = nil
    func(decompressed)
  end
end

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

-- Version/Addon/WA Checking

local function waRequest(channel, ...)
  local msg, sender = ...
  local weakAuras = addon.GetWeakAuras()
  AstralRaidComms:DecodeChunkedAddonMessages(sender, msg, function(m)
    addon.PrintDebug('waRequest', m)
    local first = true
    local resp = ''
    for wa, v in string.gmatch(m, '"([^"]+)":"([^"]+)"') do
      local validWa = weakAuras[wa] and tostring(weakAuras[wa].version) == v and not weakAuras[wa].load.use_never
      if not validWa then
        local d = ''
        if not weakAuras[wa] then
          d = 'MISSING'
        elseif weakAuras[wa].load.use_never then
          d = 'LOAD_NEVER'
        else
          d = tostring(weakAuras[wa].version)
        end
        -- Why does Lua not have a built-in string.trim
        if not first then
          resp = resp .. ' '
        end
        first = false
        resp = resp .. string.format('"%s":"%s"', wa, d)
      end
    end
    AstralRaidComms:SendChunkedAddonMessages('waPush', resp, channel)
    addon.PrintDebug('waPush', resp, channel)
  end)
end

local function addonRequest(channel, ...)
  local msg, sender = ...
  local addons = addon.GetAddons()
  AstralRaidComms:DecodeChunkedAddonMessages(sender, msg, function(m)
    addon.PrintDebug('addonRequest', m)
    local resp = addon.PlayerClass
    for a, v in string.gmatch(m, '"([^"]+)":"([^"]+)"') do
      if not addons[a] or addons[a].version ~= v then
        local d = ''
        if addons[a] then
          d = addons[a].version
        end
        resp = resp .. string.format(' "%s":"%s"', a, d)
      end
    end
    AstralRaidComms:SendChunkedAddonMessages('addonPush', resp, channel)
    addon.PrintDebug('addonPush', resp, channel)
  end)
end

local function versionRequest(channel, ...)
  SendAddonMessage(PREFIX, 'versionPush ' .. string.format('%s:%s', addon.CLIENT_VERSION, addon.PlayerClass), channel)
end

AstralRaidComms:Init()

AstralRaidComms:RegisterPrefix('RAID', 'waRequest', function(...) waRequest('RAID', ...) end)
AstralRaidComms:RegisterPrefix('PARTY', 'waRequest', function(...) waRequest('PARTY', ...) end)
AstralRaidComms:RegisterPrefix('GUILD', 'waRequest', function(...) waRequest('GUILD', ...) end)

AstralRaidComms:RegisterPrefix('RAID', 'addonRequest', function(...) addonRequest('RAID', ...) end)
AstralRaidComms:RegisterPrefix('PARTY', 'addonRequest', function(...) addonRequest('PARTY', ...) end)
AstralRaidComms:RegisterPrefix('GUILD', 'addonRequest', function(...) addonRequest('GUILD', ...) end)

AstralRaidComms:RegisterPrefix('RAID', 'versionRequest', function(...) versionRequest('RAID', ...) end)
AstralRaidComms:RegisterPrefix('PARTY', 'versionRequest', function(...) versionRequest('PARTY', ...) end)
AstralRaidComms:RegisterPrefix('GUILD', 'versionRequest', function(...) versionRequest('GUILD', ...) end)