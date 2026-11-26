local addonName = ...
local VERSION = "2.5.0"
local frame = CreateFrame("Frame")
WPQ_Settings = WPQ_Settings or { enabled = true, debug = false }

-- Fonts live in Interface\AddOns\WotLK_Persian_Quest\Fonts\
-- Put your own .ttf there and run: /wpq font YourFont.ttf
local FONT_DIR = "Interface\\AddOns\\WotLK_Persian_Quest\\Fonts\\"
local DEFAULT_FONT = "Vazirmatn-Regular.ttf"
local FALLBACK_FONT = "NotoSansArabic.ttf"
local DEFAULT_PADDING = 16  -- right-side padding in px (/wpq pad N)
local DEFAULT_TOP = 22      -- extra space above the quest title in px (/wpq top N)
local SETTINGS_VERSION = 4
local WRAP_MARGIN = 4       -- safety margin so WoW never re-wraps our lines
local DEFAULT_WIDTH = 280   -- used only when a panel width cannot be read

local state = setmetatable({}, { __mode = "k" })     -- per-FontString bookkeeping
local misc = {}                                      -- hook flags, test FontString
local btnFonts = setmetatable({}, { __mode = "k" })  -- per-Button font objects
local allBtnFonts = {}                               -- font object -> size
local fontCounter = 0
local fontOK = {}
local lastError
local titleIndex, lineIndex, titleCands

------------------------------------------------------------------ helpers
local function initSettings()
  if type(WPQ_Settings) ~= "table" then WPQ_Settings = {} end
  if WPQ_Settings.enabled == nil then WPQ_Settings.enabled = true end
  if WPQ_Settings.debug == nil then WPQ_Settings.debug = false end
  if WPQ_Settings.lamAlef == nil then WPQ_Settings.lamAlef = true end
  if type(WPQ_Settings.font) ~= "string" or WPQ_Settings.font == "" then WPQ_Settings.font = DEFAULT_FONT end
  if type(WPQ_Settings.padding) ~= "number" then WPQ_Settings.padding = DEFAULT_PADDING end
  if type(WPQ_Settings.topPadding) ~= "number" then WPQ_Settings.topPadding = DEFAULT_TOP end
  if WPQ_Settings.speech == nil then WPQ_Settings.speech = true end
  if WPQ_Settings.chatFont == nil then WPQ_Settings.chatFont = true end
  if WPQ_Settings.achievements == nil then WPQ_Settings.achievements = true end
  -- migrate: the old default (8 px) was too tight, move it to the new default once
  if (WPQ_Settings.settingsVersion or 0) < SETTINGS_VERSION then
    if WPQ_Settings.padding == 8 then WPQ_Settings.padding = DEFAULT_PADDING end
    -- 2.4.1: the old top default (10 px) was too tight, move it once to the new default
    if (WPQ_Settings.settingsVersion or 0) < 4 and WPQ_Settings.topPadding == 10 then
      WPQ_Settings.topPadding = DEFAULT_TOP
    end
    WPQ_Settings.settingsVersion = SETTINGS_VERSION
  end
end

local function msg(s)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffd7b56d[WPQ]|r " .. tostring(s))
  end
end

local function dbg(s)
  if WPQ_Settings and WPQ_Settings.debug then msg(s) end
end

-- run fn protected; errors are remembered (/wpq errors) and shown in debug mode
local function safe(label, fn, ...)
  local ok, a, b, c = pcall(fn, ...)
  if not ok then
    lastError = label .. ": " .. tostring(a)
    dbg("|cffff5555ERROR|r " .. lastError)
    return false
  end
  return true, a, b, c
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function clean(s)
  if type(s) ~= "string" then return nil end
  s = s:gsub("|", ""):gsub("[%z\1-\8\11\12\14-\31]", "")
  return trim(s)
end

-- $b line breaks, $g male:female; $n name, $c class, $r race
local function expand(s)
  if type(s) ~= "string" then return s end
  s = s:gsub("%$[bB]", "\n")
  s = s:gsub("%$[gG]([^:;]*):([^;]*);", function(male, female)
    local sex = UnitSex and UnitSex("player") or 2
    if sex == 3 then return female end
    return male
  end)
  s = s:gsub("%$[nN]", function() return (UnitName and UnitName("player")) or "" end)
  s = s:gsub("%$[cC]", function()
    local name, token = UnitClass("player")
    return (WPQ_UI and WPQ_UI.classes and WPQ_UI.classes[token]) or name or ""
  end)
  s = s:gsub("%$[rR]", function()
    local name, token = UnitRace("player")
    return (WPQ_UI and WPQ_UI.races and WPQ_UI.races[token]) or name or ""
  end)
  return s
end

local function descendantOf(obj, root)
  if not obj or not root then return false end
  local p = obj
  for _ = 1, 25 do
    if p == root then return true end
    if not p.GetParent then return false end
    p = p:GetParent()
    if not p then return false end
  end
  return false
end

------------------------------------------------------------------ data lookup
-- player faction as "A" / "H" (quests with the same English title can differ per faction)
local function factionCode()
  local g = UnitFactionGroup and UnitFactionGroup("player")
  if g == "Alliance" then return "A" elseif g == "Horde" then return "H" end
end

local function pickByFaction(list)
  if not list then return nil end
  if #list == 1 then return list[1] end
  local fc = factionCode()
  for _, e in ipairs(list) do if e.f == fc then return e end end
  for _, e in ipairs(list) do if not e.f then return e end end
  return list[1]
end

local function buildIndex()
  titleIndex, lineIndex, titleCands = {}, {}, {}
  local db = WPQ_DB
  if type(db) ~= "table" then return end
  local function add(titleEn, e)
    if type(e) ~= "table" then return end
    if titleEn then
      local c = titleCands[titleEn]
      if not c then c = {} titleCands[titleEn] = c end
      c[#c + 1] = e
      if not titleIndex[titleEn] then titleIndex[titleEn] = e end
    end
    if type(e.lines) == "table" then
      for k, v in pairs(e.lines) do lineIndex[k] = v end
    end
  end
  for titleEn, e in pairs(db.questTitles or {}) do add(titleEn, e) end
  for _, e in pairs(db.quests or {}) do add(e.titleEn, e) end
end

local function getEntry(title, questID)
  local db = WPQ_DB
  if type(db) ~= "table" then return nil end
  if questID and questID > 0 and db.quests and db.quests[questID] then return db.quests[questID] end
  if title and titleCands and titleCands[title] then return pickByFaction(titleCands[title]) end
  if title and db.questTitles then return db.questTitles[title] end
end

local function logContext()
  if not (QuestLogFrame and QuestLogFrame:IsShown()) then return nil end
  if type(GetQuestLogSelection) ~= "function" or type(GetQuestLogTitle) ~= "function" then return nil end
  local idx = GetQuestLogSelection()
  if not idx or idx <= 0 then return nil end
  local title, _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(idx)
  if isHeader then return nil end
  return clean(title), questID
end

local function npcContext()
  if not (QuestFrame and QuestFrame:IsShown()) then return nil end
  if type(GetTitleText) ~= "function" then return nil end
  local t = clean(GetTitleText())
  if t and t ~= "" then return t end
end

------------------------------------------------------------------ fonts
local function testFS()
  if not misc.testFS then
    misc.testFS = UIParent:CreateFontString(nil, "OVERLAY")
  end
  return misc.testFS
end

local function fontPath()
  local name = WPQ_Settings.font or DEFAULT_FONT
  if fontOK[name] == nil then
    local fs = testFS()
    local ok, res = pcall(fs.SetFont, fs, FONT_DIR .. name, 12, "")
    fontOK[name] = (ok and res) and true or false
    if not fontOK[name] then
      msg("Font '" .. name .. "' could not be loaded; using " .. FALLBACK_FONT .. " instead.")
    end
  end
  if fontOK[name] then return FONT_DIR .. name end
  return FONT_DIR .. FALLBACK_FONT
end

local function getState(fs)
  local st = state[fs]
  if not st then st = {} state[fs] = st end
  return st
end

local function snapshot(fs, st)
  if st.snap then return end
  local font, size, flags = fs:GetFont()
  st.snap = {
    font = font, size = size, flags = flags,
    jh = fs.GetJustifyH and fs:GetJustifyH() or nil,
    jv = fs.GetJustifyV and fs:GetJustifyV() or nil,
    spacing = fs.GetSpacing and fs:GetSpacing() or nil,
  }
end

local function applyFont(fs)
  local _, size, flags = fs:GetFont()
  fs:SetFont(fontPath(), size or 12, flags or "")
  if fs.SetSpacing then fs:SetSpacing(2) end
end

-- put the FontString back to how Blizzard had it (used for untranslated quests)
local function restore(fs)
  local st = state[fs]
  if not st or not st.touched or not st.snap then return end
  local s = st.snap
  if s.font then fs:SetFont(s.font, s.size or 12, s.flags or "") end
  if fs.SetSpacing and s.spacing then fs:SetSpacing(s.spacing) end
  if fs.SetJustifyH and s.jh then fs:SetJustifyH(s.jh) end
  if fs.SetJustifyV and s.jv then fs:SetJustifyV(s.jv) end
  if st.set and st.orig then
    local w = fs:GetWidth()
    if w and math.abs(w - st.set) < 0.5 then fs:SetWidth(st.orig) end
  end
  if st.topSet and st.topOrig and fs.ClearAllPoints and fs.SetPoint then
    local o = st.topOrig
    fs:ClearAllPoints()
    fs:SetPoint(o[1], o[2], o[3], o[4], o[5])
  end
  st.topSet, st.topOrig, st.topApplied = nil, nil, nil
  if st.hSet and fs.SetHeight then fs:SetHeight(0) end
  st.hSet = nil
  st.touched = false
  st.set, st.orig = nil, nil
end

-- push a title down by the top padding (everything anchored below it follows)
local function applyTop(fs, st)
  local top = WPQ_Settings.topPadding or DEFAULT_TOP
  if not (fs.GetNumPoints and fs.GetPoint and fs.SetPoint and fs.ClearAllPoints) then return end
  if fs:GetNumPoints() ~= 1 then return end
  local p, rel, rp, x, y = fs:GetPoint(1)
  x, y = x or 0, y or 0
  local a = st.topApplied
  -- if the anchor is not the one we set, Blizzard re-anchored it: take the current one as original
  if not (a and a[1] == p and math.abs(a[2] - x) < 0.5 and math.abs(a[3] - y) < 0.5) then
    st.topOrig = { p, rel, rp, x, y }
  end
  local o = st.topOrig
  if top == 0 then
    if st.topSet then
      fs:ClearAllPoints()
      fs:SetPoint(o[1], o[2], o[3], o[4], o[5])
    end
    st.topSet, st.topApplied = nil, nil
    return
  end
  local ny = o[5] - top
  if not (a and a[1] == p and math.abs(a[2] - x) < 0.5 and math.abs(a[3] - y) < 0.5 and math.abs(a[3] - ny) < 0.5) then
    fs:ClearAllPoints()
    fs:SetPoint(o[1], o[2], o[3], o[4], ny)
  end
  st.topSet = true
  st.topApplied = { o[1], o[4], ny }
end

-- shrink width by the padding; returns the width available for wrapping
local function applyWidth(fs, st, refWidth)
  local pad = WPQ_Settings.padding or DEFAULT_PADDING
  if pad < 0 then pad = 0 end
  local w = fs:GetWidth() or 0
  local base = w
  if st.set and st.orig and math.abs(w - st.set) < 0.5 then base = st.orig end
  if refWidth then base = refWidth end
  if base < 50 then
    dbg("width unknown for " .. tostring(fs:GetName() or "?") .. ", using " .. DEFAULT_WIDTH)
    return DEFAULT_WIDTH - pad
  end
  if pad > base - 50 then pad = 0 end
  if not refWidth then st.orig = base end
  st.set = base - pad
  fs:SetWidth(base - pad)
  return base - pad
end

local function shape(fs, text, width)
  text = clean(expand(text))
  if not text or text == "" then return nil end
  if type(WPQ_RTL) ~= "function" then return nil end
  local ok, res = safe("shape", WPQ_RTL, text, fs, width)
  if ok and type(res) == "string" then return res end
end

-- Long text blocks: make the FontString exactly as tall as its lines need.
-- WoW's automatic height can come out too small for our manually wrapped, line-spaced
-- Persian text, so the rewards/objectives anchored below it overlap the last lines.
local LONG_TEXT = {
  QuestInfoDescriptionText = true, QuestInfoObjectivesText = true, QuestInfoRewardText = true,
  QuestProgressText = true, QuestLogQuestDescription = true, QuestLogObjectivesText = true,
}

local function fitHeight(fs, st, shaped)
  if not (fs.SetHeight and fs.GetHeight) then return end
  local _, nl = shaped:gsub("\n", "")
  local lines = nl + 1
  if lines < 2 then
    if st.hSet then fs:SetHeight(0) st.hSet = nil end
    return
  end
  if not misc.heightFS then
    misc.heightFS = UIParent:CreateFontString(nil, "OVERLAY")
    misc.heightFS:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, 0)
    misc.heightFS:SetAlpha(0)
  end
  local h = misc.heightFS
  local font, size, flags = fs:GetFont()
  h:SetFont(font, size or 12, flags or "")
  h:SetText(shaped:match("[^\n]+") or "x")
  local lineH = h:GetStringHeight() or 0
  local spacing = fs.GetSpacing and fs:GetSpacing() or 0
  local mine = lines * (lineH + spacing) + 2
  fs:SetHeight(0)  -- back to automatic, then see what WoW thinks
  local auto = math.max(fs:GetHeight() or 0, fs.GetStringHeight and fs:GetStringHeight() or 0)
  fs:SetHeight(math.max(auto, mine))
  st.hSet = true
end

-- full layout: our font, right padding, right-aligned, manual wrapping
local TITLES = { QuestLogQuestTitle = true, QuestInfoTitleHeader = true, QuestProgressTitleText = true }

local function putBody(fs, text, refWidth)
  if not fs or not fs.SetText or type(text) ~= "string" or text == "" then return end
  local st = getState(fs)
  snapshot(fs, st)
  local nm = fs.GetName and fs:GetName()
  if nm and TITLES[nm] then safe("top", applyTop, fs, st) end
  applyFont(fs)
  local width = applyWidth(fs, st, refWidth)
  local shaped = shape(fs, text, width - WRAP_MARGIN)
  if not shaped then restore(fs) return end
  if fs:GetText() ~= shaped then fs:SetText(shaped) end
  if fs.SetJustifyH then fs:SetJustifyH("RIGHT") end
  if fs.SetJustifyV then fs:SetJustifyV("TOP") end
  if nm and LONG_TEXT[nm] then safe("height", fitHeight, fs, st, shaped) end
  st.touched = true
end

-- font + text only (tracker lines, list entries): keeps Blizzard's layout
local function putInline(fs, text)
  if not fs or not fs.SetText or type(text) ~= "string" or text == "" then return end
  local st = getState(fs)
  snapshot(fs, st)
  applyFont(fs)
  local w = fs:GetWidth() or 0
  local shaped = shape(fs, text, w >= 50 and (w - WRAP_MARGIN) or 0)
  if not shaped then return end
  if fs:GetText() ~= shaped then fs:SetText(shaped) end
  st.touched = true
end

local function bodyWidth(preferLog)
  local names = preferLog and { "QuestLogQuestDescription", "QuestInfoDescriptionText", "QuestProgressText" }
                          or { "QuestInfoDescriptionText", "QuestProgressText", "QuestLogQuestDescription" }
  for _, n in ipairs(names) do
    local fs = _G[n]
    if fs and fs.GetWidth then
      local st = state[fs]
      local w = (st and st.orig) or fs:GetWidth()
      if w and w >= 50 then return w end
    end
  end
  return DEFAULT_WIDTH
end

local WIDE_LABELS = {
  QuestInfoDescriptionHeader = true, QuestInfoObjectivesHeader = true, QuestInfoRewardsHeader = true,
  QuestInfoItemChooseText = true, QuestInfoItemReceiveText = true, QuestInfoSpellLearnText = true,
  QuestLogDescriptionTitle = true, QuestLogRewardTitleText = true, QuestLogItemChooseText = true,
  QuestLogItemReceiveText = true, QuestLogSpellLearnText = true, QuestProgressRequiredItemsText = true,
  QuestProgressRequiredMoneyText = true, AvailableQuestsText = true, CurrentQuestsText = true,
}

local function putLabel(fs, text)
  local name = fs:GetName()
  if name and WIDE_LABELS[name] then
    local isLog = QuestLogFrame and descendantOf(fs, QuestLogFrame)
    putBody(fs, text, bodyWidth(isLog))
  else
    putInline(fs, text)
  end
end

------------------------------------------------------------------ buttons
local KINDS = { "Normal", "Highlight", "Disabled" }

local function setButtonFonts(btn, fs)
  local rec = btnFonts[btn]
  if not rec then rec = {} btnFonts[btn] = rec end
  for _, kind in ipairs(KINDS) do
    local getter, setter = btn["Get" .. kind .. "FontObject"], btn["Set" .. kind .. "FontObject"]
    if getter and setter then
      local old = getter(btn)
      local mine = rec[kind]
      if old ~= mine and (old or kind == "Normal") then
        local src = old or fs
        if not mine then
          fontCounter = fontCounter + 1
          mine = CreateFont("WPQ_BtnFont" .. fontCounter)
          rec[kind] = mine
        end
        local _, size, flags = src:GetFont()
        size = size or 12
        mine:SetFont(fontPath(), size, flags or "")
        allBtnFonts[mine] = size
        if src.GetTextColor then
          local r, g, b, a = src:GetTextColor()
          if r then mine:SetTextColor(r, g, b, a or 1) end
        end
        if src.GetShadowColor then
          local r, g, b, a = src:GetShadowColor()
          if r then mine:SetShadowColor(r, g, b, a or 1) end
        end
        if src.GetShadowOffset then
          local x, y = src:GetShadowOffset()
          if x then mine:SetShadowOffset(x, y) end
        end
        setter(btn, mine)
      end
    end
  end
end

-- "(Complete)" / "(Failed)" at the end of an objective line or quest title
local function splitStatus(text)
  local base, word = text:match("^(.-)%s*%((%a+)%)$")
  local fa = word and WPQ_UI and WPQ_UI.status and WPQ_UI.status[word]
  if base and base ~= "" and fa then return base, "(" .. fa .. ")" end
  return text, nil
end

-- quest title inside a button/line: handles "|cffxxxxxx[80] Title|r" style texts
local function titleForText(text)
  if not titleIndex then return nil end
  local prefix = text:match("^(|c%x%x%x%x%x%x%x%x)") or ""
  local body = text:gsub("|c%x%x%x%x%x%x%x%x", "")
  body = trim(body:gsub("|r", ""))
  local statusFa
  body, statusFa = splitStatus(body)
  local lvl, name = body:match("^(%[[^%]]*%]%s*)(.+)$")
  local entry = titleIndex[name or body]
  if not entry and name then entry = titleIndex[body] lvl, name = nil, nil end
  if entry and entry.title then
    return prefix, (lvl or "") .. entry.title .. (statusFa and (" " .. statusFa) or "")
  end
  if statusFa then  -- quest not in the database: keep its name, translate only the tag
    return prefix, body .. " " .. statusFa
  end
end

local function translateButton(btn)
  local fs = btn.GetFontString and btn:GetFontString()
  if not fs or not btn.GetText then return end
  local text = btn:GetText()
  if type(text) ~= "string" or text == "" then return end
  local persian = WPQ_UI and WPQ_UI.labels and WPQ_UI.labels[trim(text)]
  if not persian and WPQ_DB and WPQ_DB.options then
    local plain = trim((text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")))
    persian = WPQ_DB.options[plain]
  end
  local prefix = ""
  if not persian then
    prefix, persian = titleForText(text)
    if not persian then return end
  end
  setButtonFonts(btn, fs)
  local shaped = shape(fs, persian, 0)
  if not shaped then return end
  if prefix ~= "" then shaped = prefix .. shaped .. "|r" end
  if btn:GetText() ~= shaped then btn:SetText(shaped) end
end

------------------------------------------------------------------ objective lines
local function matchLine(text)
  if not lineIndex then return nil end
  local base, suffix = splitStatus(text)
  local res
  if lineIndex[base] then
    res = lineIndex[base]
  else
    local name, cur, max = base:match("^(.-):%s*(%d+)/(%d+)$")
    if name and lineIndex[name] then
      res = lineIndex[name] .. ": " .. cur .. "/" .. max
    end
  end
  if not res and suffix then res = base end  -- objective not translated: still translate the tag
  if res and suffix then res = res .. " " .. suffix end
  return res
end

-- objective lines ("Discover the ... mystery") get the same right alignment + padding as the body
local function isObjectiveLine(fs)
  local n = fs.GetName and fs:GetName()
  return n and (n:match("^QuestLogObjective%d+$") or n:match("^QuestInfoObjective%d+$")) and true or false
end

local function putLine(fs, text)
  if isObjectiveLine(fs) then
    local isLog = QuestLogFrame and descendantOf(fs, QuestLogFrame)
    putBody(fs, text, bodyWidth(isLog))
  else
    putInline(fs, text)
  end
end

local function handleFontString(fs)
  local text = fs:GetText()
  if type(text) ~= "string" or text == "" then return end
  local key = trim(text)
  local label = WPQ_UI and WPQ_UI.labels and WPQ_UI.labels[key]
  if label then safe("label", putLabel, fs, label) return end
  local gossip = WPQ_DB and WPQ_DB.gossip and WPQ_DB.gossip[key]
  if gossip then
    local w = fs.GetWidth and fs:GetWidth() or 0
    safe("gossip", putBody, fs, gossip, w > 0 and w or nil)
    return
  end
  local entry = titleIndex and titleIndex[key]
  if entry and entry.title then safe("title", putInline, fs, entry.title) return end
  local line = matchLine(key)
  if line then safe("line", putLine, fs, line) end
end

------------------------------------------------------------------ scanning
local function scanFrame(f, depth)
  if not f or depth > 9 then return end
  local ot = f.GetObjectType and f:GetObjectType()
  local bfs
  if ot == "Button" or ot == "CheckButton" then
    bfs = f.GetFontString and f:GetFontString()
    safe("button", translateButton, f)
  end
  if f.GetRegions then
    local regs = { f:GetRegions() }
    for i = 1, #regs do
      local r = regs[i]
      if r ~= bfs and r.GetObjectType and r:GetObjectType() == "FontString" then
        handleFontString(r)
      end
    end
  end
  if f.GetChildren then
    local kids = { f:GetChildren() }
    for i = 1, #kids do scanFrame(kids[i], depth + 1) end
  end
end

local function scanRoot(name)
  local f = _G[name]
  if f and f.IsVisible and f:IsVisible() then scanFrame(f, 0) end
end

------------------------------------------------------------------ main apply
local BODY = {
  -- { fontstring, context ("info" = decided by parent, "log", "npc"), field, fallback field }
  { "QuestInfoTitleHeader",    "info", "title" },
  { "QuestInfoDescriptionText", "info", "description" },
  { "QuestInfoObjectivesText",  "info", "objectives" },
  { "QuestInfoRewardText",      "info", "completion" },
  { "QuestProgressTitleText",   "npc",  "title" },
  { "QuestProgressText",        "npc",  "progress" },
  { "QuestLogQuestTitle",       "log",  "title" },
  { "QuestLogQuestDescription", "log",  "description" },
  { "QuestLogObjectivesText",   "log",  "logObjectives", "objectives" },
}

local SCROLLS = { "QuestLogDetailScrollFrame", "QuestDetailScrollFrame", "QuestProgressScrollFrame",
                  "QuestRewardScrollFrame", "QuestGreetingScrollFrame", "GossipGreetingScrollFrame" }

local applying = false
local lastDbg

local function doApply()
  if not titleIndex then buildIndex() end

  local logTitle, logId = logContext()
  local npcTitle = npcContext()
  local logEntry = logTitle and getEntry(logTitle, logId) or nil
  local npcEntry = npcTitle and getEntry(npcTitle) or nil

  if WPQ_Settings.debug then
    local d = "log=" .. tostring(logTitle) .. (logEntry and "(ok)" or "") ..
              " npc=" .. tostring(npcTitle) .. (npcEntry and "(ok)" or "")
    if d ~= lastDbg then lastDbg = d msg(d) end
  end

  for _, row in ipairs(BODY) do
    local fs = _G[row[1]]
    if fs and fs.SetText then
      local ctx = row[2]
      if ctx == "info" then
        ctx = (QuestLogFrame and QuestLogFrame:IsShown() and descendantOf(fs, QuestLogFrame)) and "log" or "npc"
      end
      local entry = (ctx == "log") and logEntry or npcEntry
      local text = entry and (entry[row[3]] or (row[4] and entry[row[4]]))
      if text then
        safe("put " .. row[1], putBody, fs, text)
      else
        safe("restore " .. row[1], restore, fs)
      end
    end
  end

  scanRoot("QuestFrame")
  scanRoot("QuestInfoFrame")
  scanRoot("QuestLogFrame")
  scanRoot("GossipFrame")

  for _, n in ipairs(SCROLLS) do
    local sf = _G[n]
    if sf and sf.UpdateScrollChildRect then pcall(sf.UpdateScrollChildRect, sf) end
  end
end

local function apply()
  if applying or not WPQ_Settings or not WPQ_Settings.enabled or not WPQ_DB then return end
  applying = true
  safe("apply", doApply)
  applying = false
end

local pending = false
local function schedule()
  if pending then return end
  pending = true
  frame:SetScript("OnUpdate", function(self)
    self:SetScript("OnUpdate", nil)
    pending = false
    apply()
  end)
end

local function applyTracker()
  if applying or not WPQ_Settings or not WPQ_Settings.enabled or not WPQ_DB then return end
  applying = true
  safe("tracker", function()
    if not titleIndex then buildIndex() end
    scanRoot("WatchFrame")
  end)
  applying = false
end

------------------------------------------------------------------ achievements
-- Only the DESCRIPTION text is translated (names stay English). Data: WPQ_DB.achievements[id].
-- Blizzard_AchievementUI loads on demand, so the hook is installed when it loads.
-- AchievementButton_DisplayAchievement is wrapped: while it runs, GetAchievementInfo returns
-- our shaped, manually wrapped text, so Blizzard computes the button height from the Persian text.
local achInstalled = false

local function installAchievements()
  if achInstalled then return end
  if type(AchievementButton_DisplayAchievement) ~= "function" or type(GetAchievementInfo) ~= "function" then return end
  achInstalled = true
  local origDisplay = AchievementButton_DisplayAchievement
  local realGAI = GetAchievementInfo

  local function achFont(fs)
    local _, size, flags = fs:GetFont()
    fs:SetFont(fontPath(), size or 12, flags or "")
  end

  AchievementButton_DisplayAchievement = function(button, category, achievement, ...)
    local on = WPQ_Settings and WPQ_Settings.enabled and WPQ_Settings.achievements ~= false
    local db = WPQ_DB and WPQ_DB.achievements
    local desc, hidden = button and button.description, button and button.hiddenDescription
    local id = (on and db and desc and desc.SetFont) and realGAI(category, achievement) or nil
    local fa = id and db[id]
    if not fa then
      -- untranslated achievement: give the FontStrings back to Blizzard's font
      if desc then safe("ach restore", restore, desc) end
      if hidden then safe("ach restore", restore, hidden) end
      return origDisplay(button, category, achievement, ...)
    end

    local width = desc.GetWidth and desc:GetWidth() or 0
    if not width or width < 50 then width = ((button.GetWidth and button:GetWidth()) or 505) - 140 end
    local okShape, shaped = safe("ach shape", function()
      for _, fs in ipairs({ desc, hidden }) do
        if fs and fs.SetFont then
          local st = getState(fs)
          snapshot(fs, st)
          achFont(fs)
          st.touched = true
        end
      end
      return shape(desc, fa, width - WRAP_MARGIN)
    end)
    if not (okShape and shaped) then
      return origDisplay(button, category, achievement, ...)
    end

    GetAchievementInfo = function(a, b)
      local r = { realGAI(a, b) }
      if r[1] == id then r[8] = shaped end
      return unpack(r, 1, 14)
    end
    local ok, err = pcall(origDisplay, button, category, achievement, ...)
    GetAchievementInfo = realGAI
    if not ok then
      lastError = "achievement: " .. tostring(err)
      dbg("|cffff5555ERROR|r " .. lastError)
    end
  end
end

------------------------------------------------------------------ hooks
local function hookFrame(name)
  local f = _G[name]
  if f and f.HookScript and not misc["hook_" .. name] then
    misc["hook_" .. name] = true
    pcall(f.HookScript, f, "OnShow", function() apply() end)
  end
end

local function hookFunction(name, fn)
  if type(_G[name]) == "function" and type(hooksecurefunc) == "function" and not misc["fn_" .. name] then
    if pcall(hooksecurefunc, name, fn) then misc["fn_" .. name] = true end
  end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("QUEST_DETAIL")
frame:RegisterEvent("QUEST_PROGRESS")
frame:RegisterEvent("QUEST_COMPLETE")
frame:RegisterEvent("QUEST_GREETING")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_WATCH_UPDATE")
frame:RegisterEvent("GOSSIP_SHOW")
frame:SetScript("OnEvent", function(self, event, loaded)
  if event == "ADDON_LOADED" then
    if loaded == "Blizzard_AchievementUI" then
      if WPQ_Settings then safe("achievements", installAchievements) end
      return
    end
    if loaded ~= addonName then return end
    initSettings()
    safe("achievements", installAchievements)  -- when the achievement UI is already loaded
    for _, n in ipairs({ "QuestFrame", "QuestFrameDetailPanel", "QuestFrameProgressPanel",
                         "QuestFrameRewardPanel", "QuestFrameGreetingPanel", "QuestInfoFrame",
                         "QuestLogFrame", "GossipFrame" }) do
      hookFrame(n)
    end
    for _, n in ipairs({ "QuestInfo_Display", "QuestLog_UpdateQuestDetails", "QuestLog_Update",
                         "GossipFrameUpdate", "GossipFrame_Update" }) do
      hookFunction(n, apply)
    end
    hookFunction("WatchFrame_Update", applyTracker)
    msg("loaded v" .. VERSION .. " - /wpq for help")
  elseif event == "QUEST_WATCH_UPDATE" then
    applyTracker()
  else
    schedule()
  end
end)

------------------------------------------------------------------ slash commands
local function restoreAll()
  for fs, st in pairs(state) do
    if st.touched then pcall(restore, fs) end
  end
end

local function dump()
  local count = 0
  local function out(f, depth)
    if not f or depth > 9 or count >= 60 then return end
    if f.GetRegions then
      local regs = { f:GetRegions() }
      for i = 1, #regs do
        local r = regs[i]
        if r.GetObjectType and r:GetObjectType() == "FontString" and count < 60 then
          local t = r:GetText()
          if t and t ~= "" then
            count = count + 1
            local shown = t:gsub("|", "!")
            if #shown > 40 then shown = shown:sub(1, 40):gsub("[\192-\255][\128-\191]*$", "") end
            msg(tostring(r:GetName() or "<anon>") .. " w=" .. math.floor(r:GetWidth() or 0) .. " : " .. shown)
          end
        end
      end
    end
    if f.GetChildren then
      local kids = { f:GetChildren() }
      for i = 1, #kids do out(kids[i], depth + 1) end
    end
  end
  for _, n in ipairs({ "QuestFrame", "QuestInfoFrame", "QuestLogFrame" }) do
    local f = _G[n]
    if f and f:IsVisible() then out(f, 0) end
  end
  msg("dump: " .. count .. " lines (max 60)")
end

SLASH_WPQ1 = "/wpq"
SlashCmdList.WPQ = function(input)
  input = (input or ""):match("^%s*(.-)%s*$")
  local cmd, arg = input:match("^(%S*)%s*(.-)$")
  cmd = (cmd or ""):lower()
  if cmd == "on" then
    WPQ_Settings.enabled = true
    msg("Persian text enabled.")
    apply()
  elseif cmd == "off" then
    WPQ_Settings.enabled = false
    restoreAll()
    msg("Persian text disabled. Use /reload to restore all English labels.")
  elseif cmd == "debug" then
    WPQ_Settings.debug = not WPQ_Settings.debug
    msg("Debug: " .. (WPQ_Settings.debug and "ON" or "OFF"))
  elseif cmd == "font" then
    if arg ~= "" then
      WPQ_Settings.font = arg
      fontOK[arg] = nil
      for fo, size in pairs(allBtnFonts) do pcall(fo.SetFont, fo, fontPath(), size, "") end
      msg("Font set to " .. arg .. ". Reopen the quest window.")
      apply()
    else
      msg("Font: " .. tostring(WPQ_Settings.font) .. "  (usage: /wpq font File.ttf)")
    end
  elseif cmd == "pad" then
    local n = tonumber(arg)
    if n then
      WPQ_Settings.padding = n
      msg("Right padding: " .. n .. " px. Reopen the quest window.")
      apply()
    else
      msg("Padding: " .. tostring(WPQ_Settings.padding) .. " px  (usage: /wpq pad 10)")
    end
  elseif cmd == "top" then
    local n = tonumber(arg)
    if n then
      WPQ_Settings.topPadding = n
      msg("Top padding: " .. n .. " px. Reopen the quest window.")
      apply()
    else
      msg("Top padding: " .. tostring(WPQ_Settings.topPadding) .. " px  (usage: /wpq top 10)")
    end
  elseif cmd == "ach" then
    WPQ_Settings.achievements = (arg:lower() ~= "off")
    msg("Achievement descriptions: " .. (WPQ_Settings.achievements and "ON" or "OFF") .. " (reopen the achievement window)")
  elseif cmd == "lam" then
    WPQ_Settings.lamAlef = (arg:lower() ~= "off")
    msg("Lam-alef ligatures: " .. (WPQ_Settings.lamAlef and "ON" or "OFF"))
    apply()
  elseif cmd == "errors" then
    msg("Last error: " .. tostring(lastError or "none"))
  elseif cmd == "dump" then
    dump()
  elseif cmd == "status" then
    msg("v" .. VERSION .. " | font " .. tostring(WPQ_Settings.font) .. " | padding " ..
        tostring(WPQ_Settings.padding) .. " | top " .. tostring(WPQ_Settings.topPadding) .. " | lam-alef " .. tostring(WPQ_Settings.lamAlef))
  else
    msg("/wpq on | off | status | debug | errors | dump | font File.ttf | pad N | top N | lam on|off | ach on|off")
  end
end

-- small API for Speech.lua (boss/NPC chat translation)
WPQ_API = { fontPath = fontPath, expand = expand, msg = msg, trim = trim }
