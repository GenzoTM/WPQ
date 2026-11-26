-- Persian/Arabic shaping helper (Unicode presentation forms) + visual RTL layout
-- for WoW 3.3.5a's LTR text renderer. v2: paragraphs, mixed LTR runs, mirrored
-- brackets, lam-alef ligatures, manual line wrapping.
local WPQ_FORMS = {
  ["ء"] = { iso="ﺀ", fin="ﺀ", ini="ﺀ", med="ﺀ", jp=false, jn=false },
  ["آ"] = { iso="ﺁ", fin="ﺂ", ini="ﺁ", med="ﺂ", jp=true, jn=false },
  ["أ"] = { iso="ﺃ", fin="ﺄ", ini="ﺃ", med="ﺄ", jp=true, jn=false },
  ["ؤ"] = { iso="ﺅ", fin="ﺆ", ini="ﺅ", med="ﺆ", jp=true, jn=false },
  ["إ"] = { iso="ﺇ", fin="ﺈ", ini="ﺇ", med="ﺈ", jp=true, jn=false },
  ["ئ"] = { iso="ﺉ", fin="ﺊ", ini="ﺋ", med="ﺌ", jp=true, jn=true },
  ["ا"] = { iso="ﺍ", fin="ﺎ", ini="ﺍ", med="ﺎ", jp=true, jn=false },
  ["ب"] = { iso="ﺏ", fin="ﺐ", ini="ﺑ", med="ﺒ", jp=true, jn=true },
  ["ة"] = { iso="ﺓ", fin="ﺔ", ini="ﺓ", med="ﺔ", jp=true, jn=false },
  ["ت"] = { iso="ﺕ", fin="ﺖ", ini="ﺗ", med="ﺘ", jp=true, jn=true },
  ["ث"] = { iso="ﺙ", fin="ﺚ", ini="ﺛ", med="ﺜ", jp=true, jn=true },
  ["ج"] = { iso="ﺝ", fin="ﺞ", ini="ﺟ", med="ﺠ", jp=true, jn=true },
  ["ح"] = { iso="ﺡ", fin="ﺢ", ini="ﺣ", med="ﺤ", jp=true, jn=true },
  ["خ"] = { iso="ﺥ", fin="ﺦ", ini="ﺧ", med="ﺨ", jp=true, jn=true },
  ["د"] = { iso="ﺩ", fin="ﺪ", ini="ﺩ", med="ﺪ", jp=true, jn=false },
  ["ذ"] = { iso="ﺫ", fin="ﺬ", ini="ﺫ", med="ﺬ", jp=true, jn=false },
  ["ر"] = { iso="ﺭ", fin="ﺮ", ini="ﺭ", med="ﺮ", jp=true, jn=false },
  ["ز"] = { iso="ﺯ", fin="ﺰ", ini="ﺯ", med="ﺰ", jp=true, jn=false },
  ["س"] = { iso="ﺱ", fin="ﺲ", ini="ﺳ", med="ﺴ", jp=true, jn=true },
  ["ش"] = { iso="ﺵ", fin="ﺶ", ini="ﺷ", med="ﺸ", jp=true, jn=true },
  ["ص"] = { iso="ﺹ", fin="ﺺ", ini="ﺻ", med="ﺼ", jp=true, jn=true },
  ["ض"] = { iso="ﺽ", fin="ﺾ", ini="ﺿ", med="ﻀ", jp=true, jn=true },
  ["ط"] = { iso="ﻁ", fin="ﻂ", ini="ﻃ", med="ﻄ", jp=true, jn=true },
  ["ظ"] = { iso="ﻅ", fin="ﻆ", ini="ﻇ", med="ﻈ", jp=true, jn=true },
  ["ع"] = { iso="ﻉ", fin="ﻊ", ini="ﻋ", med="ﻌ", jp=true, jn=true },
  ["غ"] = { iso="ﻍ", fin="ﻎ", ini="ﻏ", med="ﻐ", jp=true, jn=true },
  ["ف"] = { iso="ﻑ", fin="ﻒ", ini="ﻓ", med="ﻔ", jp=true, jn=true },
  ["ق"] = { iso="ﻕ", fin="ﻖ", ini="ﻗ", med="ﻘ", jp=true, jn=true },
  ["ك"] = { iso="ﻙ", fin="ﻚ", ini="ﻛ", med="ﻜ", jp=true, jn=true },
  ["ل"] = { iso="ﻝ", fin="ﻞ", ini="ﻟ", med="ﻠ", jp=true, jn=true },
  ["م"] = { iso="ﻡ", fin="ﻢ", ini="ﻣ", med="ﻤ", jp=true, jn=true },
  ["ن"] = { iso="ﻥ", fin="ﻦ", ini="ﻧ", med="ﻨ", jp=true, jn=true },
  ["ه"] = { iso="ﻩ", fin="ﻪ", ini="ﻫ", med="ﻬ", jp=true, jn=true },
  ["و"] = { iso="ﻭ", fin="ﻮ", ini="ﻭ", med="ﻮ", jp=true, jn=false },
  ["ى"] = { iso="ﻯ", fin="ﻰ", ini="ﯨ", med="ﯩ", jp=true, jn=true },
  ["ي"] = { iso="ﻱ", fin="ﻲ", ini="ﻳ", med="ﻴ", jp=true, jn=true },
  ["ٱ"] = { iso="ﭐ", fin="ﭑ", ini="ﭐ", med="ﭑ", jp=true, jn=false },
  ["ٷ"] = { iso="ﯝ", fin="ﯝ", ini="ﯝ", med="ﯝ", jp=false, jn=false },
  ["ٹ"] = { iso="ﭦ", fin="ﭧ", ini="ﭨ", med="ﭩ", jp=true, jn=true },
  ["ٺ"] = { iso="ﭞ", fin="ﭟ", ini="ﭠ", med="ﭡ", jp=true, jn=true },
  ["ٻ"] = { iso="ﭒ", fin="ﭓ", ini="ﭔ", med="ﭕ", jp=true, jn=true },
  ["پ"] = { iso="ﭖ", fin="ﭗ", ini="ﭘ", med="ﭙ", jp=true, jn=true },
  ["ٿ"] = { iso="ﭢ", fin="ﭣ", ini="ﭤ", med="ﭥ", jp=true, jn=true },
  ["ڀ"] = { iso="ﭚ", fin="ﭛ", ini="ﭜ", med="ﭝ", jp=true, jn=true },
  ["ڃ"] = { iso="ﭶ", fin="ﭷ", ini="ﭸ", med="ﭹ", jp=true, jn=true },
  ["ڄ"] = { iso="ﭲ", fin="ﭳ", ini="ﭴ", med="ﭵ", jp=true, jn=true },
  ["چ"] = { iso="ﭺ", fin="ﭻ", ini="ﭼ", med="ﭽ", jp=true, jn=true },
  ["ڇ"] = { iso="ﭾ", fin="ﭿ", ini="ﮀ", med="ﮁ", jp=true, jn=true },
  ["ڈ"] = { iso="ﮈ", fin="ﮉ", ini="ﮈ", med="ﮉ", jp=true, jn=false },
  ["ڌ"] = { iso="ﮄ", fin="ﮅ", ini="ﮄ", med="ﮅ", jp=true, jn=false },
  ["ڍ"] = { iso="ﮂ", fin="ﮃ", ini="ﮂ", med="ﮃ", jp=true, jn=false },
  ["ڎ"] = { iso="ﮆ", fin="ﮇ", ini="ﮆ", med="ﮇ", jp=true, jn=false },
  ["ڑ"] = { iso="ﮌ", fin="ﮍ", ini="ﮌ", med="ﮍ", jp=true, jn=false },
  ["ژ"] = { iso="ﮊ", fin="ﮋ", ini="ﮊ", med="ﮋ", jp=true, jn=false },
  ["ڤ"] = { iso="ﭪ", fin="ﭫ", ini="ﭬ", med="ﭭ", jp=true, jn=true },
  ["ڦ"] = { iso="ﭮ", fin="ﭯ", ini="ﭰ", med="ﭱ", jp=true, jn=true },
  ["ک"] = { iso="ﮎ", fin="ﮏ", ini="ﮐ", med="ﮑ", jp=true, jn=true },
  ["ڭ"] = { iso="ﯓ", fin="ﯔ", ini="ﯕ", med="ﯖ", jp=true, jn=true },
  ["گ"] = { iso="ﮒ", fin="ﮓ", ini="ﮔ", med="ﮕ", jp=true, jn=true },
  ["ڱ"] = { iso="ﮚ", fin="ﮛ", ini="ﮜ", med="ﮝ", jp=true, jn=true },
  ["ڳ"] = { iso="ﮖ", fin="ﮗ", ini="ﮘ", med="ﮙ", jp=true, jn=true },
  ["ں"] = { iso="ﮞ", fin="ﮟ", ini="ﮞ", med="ﮟ", jp=true, jn=false },
  ["ڻ"] = { iso="ﮠ", fin="ﮡ", ini="ﮢ", med="ﮣ", jp=true, jn=true },
  ["ھ"] = { iso="ﮪ", fin="ﮫ", ini="ﮬ", med="ﮭ", jp=true, jn=true },
  ["ۀ"] = { iso="ﮤ", fin="ﮥ", ini="ﮤ", med="ﮥ", jp=true, jn=false },
  ["ہ"] = { iso="ﮦ", fin="ﮧ", ini="ﮨ", med="ﮩ", jp=true, jn=true },
  ["ۅ"] = { iso="ﯠ", fin="ﯡ", ini="ﯠ", med="ﯡ", jp=true, jn=false },
  ["ۆ"] = { iso="ﯙ", fin="ﯚ", ini="ﯙ", med="ﯚ", jp=true, jn=false },
  ["ۇ"] = { iso="ﯗ", fin="ﯘ", ini="ﯗ", med="ﯘ", jp=true, jn=false },
  ["ۈ"] = { iso="ﯛ", fin="ﯜ", ini="ﯛ", med="ﯜ", jp=true, jn=false },
  ["ۉ"] = { iso="ﯢ", fin="ﯣ", ini="ﯢ", med="ﯣ", jp=true, jn=false },
  ["ۋ"] = { iso="ﯞ", fin="ﯟ", ini="ﯞ", med="ﯟ", jp=true, jn=false },
  ["ی"] = { iso="ﯼ", fin="ﯽ", ini="ﯾ", med="ﯿ", jp=true, jn=true },
  ["ې"] = { iso="ﯤ", fin="ﯥ", ini="ﯦ", med="ﯧ", jp=true, jn=true },
  ["ے"] = { iso="ﮮ", fin="ﮯ", ini="ﮮ", med="ﮯ", jp=true, jn=false },
  ["ۓ"] = { iso="ﮰ", fin="ﮱ", ini="ﮰ", med="ﮱ", jp=true, jn=false },
}




local function U(cp)
  if cp < 0x80 then return string.char(cp) end
  if cp < 0x800 then return string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64) end
  return string.char(0xE0 + math.floor(cp / 4096), 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
end

local function WPQ_UTF8Chars(s)
  local out, i = {}, 1
  while i <= #s do
    local b = string.byte(s, i)
    local n = 1
    if b >= 240 then n = 4 elseif b >= 224 then n = 3 elseif b >= 192 then n = 2 end
    out[#out+1] = string.sub(s, i, i+n-1)
    i = i + n
  end
  return out
end

local ZWNJ = U(0x200C)
-- characters that are never drawn (they only affect joining / direction)
local INVISIBLE = {
  [ZWNJ] = true, [U(0x200D)] = true, [U(0x200E)] = true, [U(0x200F)] = true,
  [U(0x202A)] = true, [U(0x202B)] = true, [U(0x202C)] = true, [U(0x202D)] = true, [U(0x202E)] = true,
  [U(0x2066)] = true, [U(0x2067)] = true, [U(0x2068)] = true, [U(0x2069)] = true,
}

-- glyph mirroring: we reverse character order by hand, so brackets must flip too
local MIRROR = {
  ["("] = ")", [")"] = "(", ["["] = "]", ["]"] = "[", ["{"] = "}", ["}"] = "{",
  ["<"] = ">", [">"] = "<", [U(0xAB)] = U(0xBB), [U(0xBB)] = U(0xAB),
}

-- lam + alef ligatures: {isolated, final}
local LAM = U(0x0644)
local LAMALEF = {
  [U(0x0627)] = { U(0xFEFB), U(0xFEFC) },
  [U(0x0622)] = { U(0xFEF5), U(0xFEF6) },
  [U(0x0623)] = { U(0xFEF7), U(0xFEF8) },
  [U(0x0625)] = { U(0xFEF9), U(0xFEFA) },
}

local TAIL_MULTI = { U(0x060C), U(0x061B), U(0x061F), U(0x2026) }  -- ، ؛ ؟ …

local function lamAlefEnabled()
  return not (WPQ_Settings and WPQ_Settings.lamAlef == false)
end

local function isLatinOrDigit(ch)
  if #ch == 1 then return ch:find("^%w") ~= nil end
  if #ch == 2 then
    local a, b = ch:byte(1, 2)
    if (a == 217 and b >= 160 and b <= 169) or (a == 219 and b >= 176 and b <= 185) then return true end
  end
  return false
end

local function stripInvisible(s)
  if not s:find("\226", 1, true) then return s end
  local out = {}
  for _, ch in ipairs(WPQ_UTF8Chars(s)) do
    if not INVISIBLE[ch] then out[#out+1] = ch end
  end
  return table.concat(out)
end

local function classify(chars)
  local rtl, ltr = false, false
  for _, ch in ipairs(chars) do
    if WPQ_FORMS[ch] then rtl = true
    elseif isLatinOrDigit(ch) then ltr = true end
  end
  if rtl then return "rtl" elseif ltr then return "ltr" end
  return "neutral"
end

-- Shape one Persian token and return it in visual (left-to-right) order.
local function WPQ_ShapeRTLToken(token)
  local chars = WPQ_UTF8Chars(token)
  local n = #chars
  local glyphs = {}
  local useLig = lamAlefEnabled()
  local i = 1
  while i <= n do
    local ch = chars[i]
    local f = WPQ_FORMS[ch]
    if INVISIBLE[ch] then
      -- not drawn; absent from WPQ_FORMS, so it breaks joining
    elseif f then
      local pf = i > 1 and WPQ_FORMS[chars[i-1]] or nil
      local prevJoins = pf and pf.jn or false
      local nx = chars[i+1]
      if useLig and ch == LAM and nx and LAMALEF[nx] then
        local lig = LAMALEF[nx]
        glyphs[#glyphs+1] = { s = prevJoins and lig[2] or lig[1] }
        i = i + 1
      else
        local nf = nx and WPQ_FORMS[nx] or nil
        local jp = prevJoins and f.jp
        local jn = f.jn and nf and nf.jp
        local g
        if jp and jn then g = f.med
        elseif jp then g = f.fin
        elseif jn then g = f.ini
        else g = f.iso end
        glyphs[#glyphs+1] = { s = g }
      end
    else
      glyphs[#glyphs+1] = { s = MIRROR[ch] or ch, ltr = isLatinOrDigit(ch) }
    end
    i = i + 1
  end
  -- digits / latin letters inside a Persian token keep their own left-to-right order
  local units = {}
  for _, g in ipairs(glyphs) do
    local last = units[#units]
    if g.ltr and last and last.ltr then last.s = last.s .. g.s
    else units[#units+1] = { s = g.s, ltr = g.ltr } end
  end
  local out = {}
  for k = #units, 1, -1 do out[#out+1] = units[k].s end
  return table.concat(out)
end

-- Split trailing sentence punctuation off a Latin/number token ("5." -> "5", ".")
local function splitTail(token)
  local tail = ""
  while #token > 1 do
    local last = token:sub(-1)
    if last:find("^[%.:,;!%?]$") then
      tail = last .. tail
      token = token:sub(1, -2)
    else
      local hit
      for _, p in ipairs(TAIL_MULTI) do
        if #token > #p and token:sub(-#p) == p then hit = p break end
      end
      if not hit then break end
      tail = hit .. tail
      token = token:sub(1, -#hit - 1)
    end
  end
  local rev = WPQ_UTF8Chars(tail)
  local r = {}
  for k = #rev, 1, -1 do r[#r+1] = rev[k] end
  return token, table.concat(r)
end

local function makeWords(paragraph)
  local words = {}
  for token in paragraph:gmatch("%S+") do
    local chars = WPQ_UTF8Chars(token)
    local kind = classify(chars)
    if kind == "ltr" then
      local core, tail = splitTail(stripInvisible(token))
      words[#words+1] = { t = core, tail = tail, ltr = true }
    else
      words[#words+1] = { t = WPQ_ShapeRTLToken(token), ltr = false }
    end
  end
  return words
end

-- Build the visual line for logical words first..last.
-- Consecutive Latin/number words stay in reading order as one block.
local function visual(words, first, last)
  local units = {}
  local k = first
  while k <= last do
    local w = words[k]
    if w.ltr then
      local run = {}
      local lead = ""
      while k <= last and words[k].ltr do
        local x = words[k]
        local isEnd = (k == last) or not words[k+1].ltr
        run[#run+1] = x.t .. (isEnd and "" or x.tail)
        if isEnd then lead = x.tail end
        k = k + 1
      end
      units[#units+1] = lead .. table.concat(run, " ")
    else
      units[#units+1] = w.t
      k = k + 1
    end
  end
  local out = {}
  for u = #units, 1, -1 do out[#out+1] = units[u] end
  return table.concat(out, " ")
end

local measureFS, measureKey
local function measure(s, fs)
  if not measureFS then
    measureFS = UIParent:CreateFontString(nil, "OVERLAY")
    measureFS:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, 0)
    measureFS:SetAlpha(0)
  end
  local font, size, flags = fs:GetFont()
  local key = tostring(font) .. "|" .. tostring(size) .. "|" .. tostring(flags)
  if key ~= measureKey then
    measureFS:SetFont(font, size or 12, flags or "")
    measureKey = key
  end
  measureFS:SetText(s)
  return measureFS:GetStringWidth() or 0
end

local function splitLines(s)
  local t, pos = {}, 1
  while true do
    local a = s:find("\n", pos, true)
    if not a then t[#t+1] = s:sub(pos) break end
    t[#t+1] = s:sub(pos, a - 1)
    pos = a + 1
  end
  return t
end

local ARABIC_YEH, ARABIC_KAF = U(0x064A), U(0x0643)
local PERSIAN_YEH, PERSIAN_KEH = U(0x06CC), U(0x06A9)

local cache, cacheCount = {}, 0

-- text: logical Persian (may contain "\n" for paragraph breaks)
-- targetFS: used only for its font (measuring); width: wrap width in px (0/nil = no wrapping)
-- returns visual text where every line is already reversed; lines are separated by "\n"
function WPQ_RTL(text, targetFS, width)
  if type(text) ~= "string" then return text end
  width = tonumber(width) or 0
  local canMeasure = width >= 50 and targetFS and targetFS.GetFont
  if not canMeasure then width = 0 end

  local fontKey = ""
  if canMeasure then
    local f, s, fl = targetFS:GetFont()
    fontKey = tostring(f) .. "|" .. tostring(s) .. "|" .. tostring(fl)
  end
  local key = fontKey .. "|" .. math.floor(width) .. "|" .. tostring(lamAlefEnabled()) .. "|" .. text
  if cache[key] then return cache[key] end

  text = text:gsub("|", ""):gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("\t", " ")
  text = text:gsub(ARABIC_YEH, PERSIAN_YEH):gsub(ARABIC_KAF, PERSIAN_KEH)

  local lines = {}
  for _, para in ipairs(splitLines(text)) do
    para = para:gsub("^%s+", ""):gsub("%s+$", "")
    if para == "" then
      lines[#lines+1] = ""
    else
      local words = makeWords(para)
      local n = #words
      if width > 0 then
        local first = 1
        for k = 2, n do
          if measure(visual(words, first, k), targetFS) > width then
            lines[#lines+1] = visual(words, first, k - 1)
            first = k
          end
        end
        lines[#lines+1] = visual(words, first, n)
      else
        lines[#lines+1] = visual(words, 1, n)
      end
    end
  end

  local result = table.concat(lines, "\n")
  if cacheCount > 400 then cache, cacheCount = {}, 0 end
  cache[key] = result
  cacheCount = cacheCount + 1
  return result
end
