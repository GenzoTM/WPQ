-- UI strings (English -> Persian). Edit freely; this file is NOT overwritten by tools/make_db.py.
-- Keys must match the English client text exactly (leading/trailing spaces are ignored).
-- Use the real half-space character (ZWNJ, U+200C) inside Persian words.
WPQ_UI = {
  labels = {
    -- quest panels
    ["Description"] = "توضیحات",
    ["Quest Objectives"] = "اهداف کوئست",
    ["Rewards"] = "پاداش‌ها",
    ["You will be able to choose one of these rewards:"] = "می‌توانی یکی از این پاداش‌ها را انتخاب کنی:",
    ["You will receive:"] = "دریافت می‌کنی:",
    ["You will also receive:"] = "همچنین دریافت می‌کنی:",
    ["Experience:"] = "تجربه:",
    ["Required Items:"] = "آیتم‌های موردنیاز:",
    ["Requirements:"] = "نیازمندی‌ها:",
    ["Current Quests"] = "کوئست‌های فعلی",
    ["Available Quests"] = "کوئست‌های موجود",
    -- buttons
    ["Accept"] = "قبول",
    ["Decline"] = "رد کردن",
    ["Continue"] = "ادامه",
    ["Cancel"] = "لغو",
    ["Close"] = "بستن",
    ["Goodbye"] = "خداحافظ",
    ["Complete Quest"] = "تکمیل کوئست",
    ["Abandon Quest"] = "رها کردن کوئست",
    ["Share Quest"] = "اشتراک کوئست",
    -- zone headers in the quest log (add more as you need)
    ["Sholazar Basin"] = "حوضه شولازار",
    ["Shadowmoon Valley"] = "دره‌ی شادومون",
    ["Icecrown Citadel"] = "ارگ آیس‌کراون",
    -- daily tag in the quest log list + zone header
    ["Daily"] = "روزانه",
    ["(Daily)"] = "(روزانه)",
    ["Daily Quest"] = "کوئست روزانه",
    ["Daily quest"] = "کوئست روزانه",
    ["Dalaran"] = "دالاران",
    -- quest log tags
    ["Complete"] = "تکمیل شد",
    ["(Complete)"] = "(تکمیل شد)",
    ["Failed"] = "ناموفق",
    ["(Failed)"] = "(ناموفق)",
  },
  -- status suffix after objective lines / quest titles: "Vegetable Stew: 1/1 (Complete)"
  status = {
    ["Complete"] = "تکمیل شد",
    ["Failed"] = "ناموفق",
  },
  -- used for $c / $r in quest text
  classes = {
    WARRIOR = "جنگجو", PALADIN = "پالادین", HUNTER = "شکارچی", ROGUE = "سارق",
    PRIEST = "کشیش", DEATHKNIGHT = "شوالیه مرگ", SHAMAN = "شمن", MAGE = "جادوگر",
    WARLOCK = "وارلاک", DRUID = "دروید",
  },
  races = {
    Human = "انسان", Dwarf = "کوتوله", NightElf = "الف شب", Gnome = "گنوم",
    Draenei = "درنایی", Orc = "ارک", Scourge = "مرده‌زنده", Tauren = "تورن",
    Troll = "ترول", BloodElf = "الف خونین",
  },
}
