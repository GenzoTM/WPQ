# WotLK Persian Quest (WPQ)

افزونه‌ی فارسی‌ساز کوئست‌ها و دیالوگ‌ها برای World of Warcraft نسخه‌ی 3.3.5a (WotLK) که روی سرورهایی مثل Warmane کار می‌کند. نسخه‌ی فعلی **2.6.1** است.

*English: a Persian (RTL) localization addon for WoW 3.3.5a. It reshapes Arabic-script text, translates quest titles/text/objectives, boss and NPC speech, and some achievement descriptions, and ships with a Persian-capable font.*

## این افزونه چه کار می‌کند

متن کوئست‌ها (عنوان، توضیح، هدف‌ها، پنجره‌ی پیشرفت و تحویل) را فارسی و راست‌به‌چپ نشان می‌دهد و حروف را درست به هم می‌چسباند. علاوه بر کوئست، دیالوگ باس‌ها و NPCهای Icecrown Citadel و Ruby Sanctum و بخشی از توضیح اچیومنت‌ها هم ترجمه شده. کوئست‌هایی که هنوز ترجمه نشده‌اند همان متن اصلی بلیزارد را با فونت و چینش اصلی نشان می‌دهند، پس چیزی خراب نمی‌شود. ترجمه‌ها فعلاً شامل زنجیره‌ی Shadowmoon Valley، زنجیره‌ی Shadowmourne و کوئست‌های روزانه‌ی Dalaran (آشپزی، جواهرسازی، ماهیگیری) است.

## نصب

اول WoW را کامل ببندید. این ریپو را با دکمه‌ی Code و گزینه‌ی Download ZIP بگیرید و از حالت فشرده خارج کنید. داخلش یک پوشه به اسم `WotLK_Persian_Quest` هست؛ همان پوشه را (نه کل ریپو را) داخل `Interface\AddOns` پوشه‌ی بازی کپی کنید. اگر نسخه‌ی قدیمی‌تر را قبلاً نصب کرده‌اید، اول پوشه‌ی قدیمی را پاک کنید. اسم پوشه باید دقیقاً با اسم فایل `.toc` یکی باشد، وگرنه بازی افزونه را نمی‌بیند.

مسیر معمول پوشه‌ی افزونه‌ها این است:

```
World of Warcraft\Interface\AddOns\WotLK_Persian_Quest
```

بعد وارد بازی شوید و در چت بزنید `/wpq status` تا مطمئن شوید افزونه فعال است. اگر در صفحه‌ی انتخاب کاراکتر دکمه‌ی AddOns را بزنید باید «WotLK Persian Quest» را ببینید.

## دستورها

```
/wpq on | off | status | debug | errors | dump
/wpq font File.ttf     عوض کردن فونت (فایل باید داخل پوشه‌ی Fonts باشد)
/wpq pad N             فاصله‌ی راست متن
/wpq top N             فاصله‌ی بالای عنوان کوئست
/wpq lam on|off        روشن/خاموش کردن لیگاتور لام-الف (لا)
/wpq ach on|off        ترجمه‌ی توضیح اچیومنت‌ها
/wpqspeech on|off      ترجمه‌ی دیالوگ باس‌ها و NPCها
/wpqchat on|off        استفاده از فونت فارسی در پنجره‌های چت
```

اگر کوئستی درست نمایش داده نشد، `/wpq debug` را بزنید تا وضعیت کوئست انتخاب‌شده چاپ شود، و `/wpq errors` آخرین خطای داخلی را نشان می‌دهد.

## اضافه کردن کوئست جدید

ترجمه‌ها داخل فایل‌های JSON پوشه‌ی `tools` نگهداری می‌شوند و با اسکریپت‌های پایتون به فایل Lua تبدیل می‌شوند. برای کوئست‌های عمومی فایل `tools/translations.json` را ویرایش کنید. هر کوئست فیلدهای `title_en`، `title`، `description`، `objectives`، `progress`، `completion` و `lines` دارد و در صورت نیاز `id` و `faction`. بین پاراگراف‌ها یک خط خالی بگذارید و نیم‌فاصله را می‌توانید با `~` بنویسید. بعد از ویرایش از داخل پوشه‌ی افزونه این را اجرا کنید:

```
python tools/make_db.py tools/translations.json Database.lua
```

و در بازی `/reload` بزنید. برای دیالوگ‌ها از `tools/make_speech.py` و برای اچیومنت‌ها از `tools/make_achievements.py` استفاده کنید. فهرست اصطلاحات ثابت ترجمه در `tools/glossary_fa.txt` است تا ترجمه‌ها هماهنگ بمانند.

## فونت

افزونه با فونت Vazirmatn و Noto Sans Arabic همراه است. اگر فونت دیگری می‌خواهید، فایل `.ttf` را داخل پوشه‌ی `Fonts` بگذارید و `/wpq font Name.ttf` را بزنید. فونت حتماً باید Arabic Presentation Forms داشته باشد؛ با `python check_font.py MyFont.ttf` می‌شود این را چک کرد (به کتابخانه‌ی `fonttools` نیاز دارد).

## نکته‌ی تست

این افزونه با شبیه‌ساز Lua تست شده و روی کلاینت واقعی WoW کامل آزمایش نشده، پس اگر جایی باگ دیدید در بخش Issues بنویسید.

## لایسنس

فونت‌ها هرکدام لایسنس خودشان را دارند (فایل‌های `VAZIRMATN_FONT_LICENSE.txt` و `NOTO_FONT_LICENSE.txt` داخل پوشه‌ی افزونه). برای کد افزونه هنوز لایسنس مشخصی انتخاب نشده؛ اگر می‌خواهید دیگران آزادانه استفاده و تغییرش بدهند، یک فایل `LICENSE` (مثلاً MIT) اضافه کنید.

## تغییرات

فهرست کامل نسخه‌ها در `WotLK_Persian_Quest/CHANGELOG.txt` است.
