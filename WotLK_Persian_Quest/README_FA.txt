WPQ 1.0.0  (WoW 3.3.5a / Warmane)

نصب: WoW را ببندید، پوشه‌ی قدیمی WotLK_Persian_Quest را پاک کنید، این پوشه را بگذارید.
در بازی: /wpq status

فایل‌ها
- Database.lua   متن کوئست‌ها (با ابزار tools/make_db.py از translations.json ساخته می‌شود)
- UIStrings.lua  عنوان‌ها، دکمه‌ها، اسم زون‌ها، کلاس/نژاد (دستی ویرایش کنید)
- Fonts\         فونت‌ها

اضافه کردن کوئست
1) tools/translations.json را ویرایش کنید (نمونه: The Ghostfish).
   فیلدها: title_en, title, description, objectives, progress, completion, lines (و در صورت نیاز id)
   بین پاراگراف‌ها یک خط خالی بگذارید. نیم‌فاصله را می‌توانید با ~ بنویسید.
2) python tools/make_db.py tools/translations.json Database.lua
3) در بازی /reload

دستورها
/wpq on | off | status | debug | errors | dump | font File.ttf | pad N | top N | lam on|off | ach on|off
/wpqspeech on|off  (ترجمه‌ی دیالوگ باس‌ها و NPCها)   /wpqchat on|off (فونت فارسی در چت)
- debug: وضعیت کوئست انتخاب‌شده را چاپ می‌کند.
- errors: آخرین خطای داخلی را نشان می‌دهد.
- dump: اسم و متن FontStringهای پنجره‌ی باز را چاپ می‌کند (برای پیدا کردن اسم المان‌ها).

فونت اختصاصی: فایل .ttf را در Fonts بگذارید (WoW بسته باشد)، بعد /wpq font Name.ttf
فونت باید Arabic Presentation Forms داشته باشد (check_font.py).

این نسخه داخل کلاینت واقعی WoW اجرا نشده؛ فقط با شبیه‌ساز Lua تست شده.
