-- Speech.lua - translates boss / NPC chat lines (say, yell, emote, raid-boss emote and warning)
-- Data: WPQ_DB.speech[english] = persian   (see tools/make_speech.py)
-- Commands: /wpqspeech on|off   /wpqchat on|off (use the Persian font in the chat windows)
local api = WPQ_API
if not api then return end

local function enabled()
  return WPQ_Settings and WPQ_Settings.speech ~= false and WPQ_DB and WPQ_DB.speech and true or false
end

-- same normalisation as tools/make_speech.py: strip |T..|t, colour codes, collapse spaces
local function norm(s)
  s = s:gsub("|T.-|t", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("%s+", " ")
  return api.trim(s)
end

local function plainReplace(s, find, repl)
  if not find or find == "" then return s end
  local out, pos = {}, 1
  while true do
    local i, j = s:find(find, pos, true)
    if not i then break end
    out[#out + 1] = s:sub(pos, i - 1)
    out[#out + 1] = repl
    pos = j + 1
  end
  out[#out + 1] = s:sub(pos)
  return table.concat(out)
end

local function translate(text, sender)
  if not enabled() or type(text) ~= "string" then return nil end
  local d = WPQ_DB
  local key = norm(text)
  -- the game has already put the player's name / class / race into the text: turn them back into $n/$c/$r
  local k = plainReplace(key, UnitName and UnitName("player"), "$n")
  local className = UnitClass and UnitClass("player")
  local raceName = UnitRace and UnitRace("player")
  local hit = d.speech[key] or d.speech[k]
  if not hit and className then
    local kc = plainReplace(k, className, "$c")
    hit = d.speech[kc] or (raceName and d.speech[plainReplace(kc, raceName, "$r")])
  end
  if not hit and sender and sender ~= "" then
    hit = d.speech[plainReplace(k, sender, "%s")]
  end
  if not hit and d.speechNames then
    for name in pairs(d.speechNames) do
      if k:sub(1, #name) == name then
        local alt = d.speech["%s" .. k:sub(#name + 1)]
        if alt then hit = alt sender = name break end
      end
    end
  end
  if not hit then return nil end
  return plainReplace(hit, "%s", sender or "")
end

local measureFS
local function shapeText(text, size, width)
  if type(WPQ_RTL) ~= "function" then return nil end
  if not measureFS then measureFS = UIParent:CreateFontString(nil, "OVERLAY") end
  measureFS:SetFont(api.fontPath(), size, "")
  local ok, res = pcall(WPQ_RTL, api.expand(text), measureFS, width)
  if ok and type(res) == "string" then return res end
end

-- chat windows -------------------------------------------------------------
local function filter(self, event, text, ...)
  local ok, p = pcall(translate, text, (...))
  if not ok or not p then return false end
  local size = 14
  if self and self.GetFont then local _, sz = self:GetFont() size = sz or size end
  local width = ((self and self.GetWidth and self:GetWidth()) or 420) - 40
  local shaped = shapeText(p, size, width)
  if not shaped then return false end
  return false, shaped, ...
end

local EVENTS = { "CHAT_MSG_MONSTER_SAY", "CHAT_MSG_MONSTER_YELL", "CHAT_MSG_MONSTER_EMOTE",
  "CHAT_MSG_MONSTER_WHISPER", "CHAT_MSG_MONSTER_PARTY", "CHAT_MSG_RAID_BOSS_WHISPER" }
if ChatFrame_AddMessageEventFilter then
  for _, ev in ipairs(EVENTS) do ChatFrame_AddMessageEventFilter(ev, filter) end
end

-- Persian glyphs need our font in the chat windows
local origFonts = {}
local function applyChatFont()
  if not NUM_CHAT_WINDOWS or not WPQ_Settings then return end
  local ours = api.fontPath()
  for i = 1, NUM_CHAT_WINDOWS do
    local f = _G["ChatFrame" .. i]
    if f and f.GetFont then
      local face, size, flags = f:GetFont()
      if WPQ_Settings.chatFont ~= false and enabled() then
        if face ~= ours then
          if not origFonts[i] then origFonts[i] = { face, size, flags or "" } end
          f:SetFont(ours, size, flags or "")
        end
      elseif origFonts[i] then
        f:SetFont(origFonts[i][1], origFonts[i][2], origFonts[i][3])
        origFonts[i] = nil
      end
    end
  end
end
if hooksecurefunc and FCF_SetChatWindowFontSize then
  hooksecurefunc("FCF_SetChatWindowFontSize", function() pcall(applyChatFont) end)
end

-- center-screen boss emotes / raid warnings ----------------------------------
if type(RaidNotice_AddMessage) == "function" then
  local orig = RaidNotice_AddMessage
  RaidNotice_AddMessage = function(frame, text, info, ...)
    if frame and (frame == RaidBossEmoteFrame or frame == RaidWarningFrame) and enabled() then
      local ok, p = pcall(translate, text)
      if ok and p then
        local size = 24
        local name = frame:GetName()
        for i = 1, 2 do
          local slot = name and _G[name .. "Slot" .. i]
          if slot and slot.GetFont then
            local _, sz, fl = slot:GetFont()
            size = sz or size
            slot:SetFont(api.fontPath(), size, fl or "")
          end
        end
        local shaped = shapeText(p, size, 600)
        if shaped then text = shaped end
      end
    end
    return orig(frame, text, info, ...)
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() pcall(applyChatFont) end)

local function toggle(key, arg, label)
  if arg == "on" then WPQ_Settings[key] = true elseif arg == "off" then WPQ_Settings[key] = false end
  api.msg(label .. ": " .. ((WPQ_Settings[key] ~= false) and "on" or "off"))
  pcall(applyChatFont)
end
SLASH_WPQSPEECH1 = "/wpqspeech"
SlashCmdList["WPQSPEECH"] = function(a) toggle("speech", (a or ""):lower(), "Boss/NPC speech translation") end
SLASH_WPQCHAT1 = "/wpqchat"
SlashCmdList["WPQCHAT"] = function(a) toggle("chatFont", (a or ""):lower(), "Persian font in chat windows") end
