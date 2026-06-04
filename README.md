# KM Downloader Bridge — Browser Extension

<img src="chrome_extension/icons/icon128.png" align="right" width="128" height="128">

ربط Chrome/Edge/Brave/Vivaldi/Opera بتطبيق **KM Downloader** للتحميل بضغطة زر.

[![Build](https://github.com/kerolesmounir6-sys/km-downloader-extension/actions/workflows/build.yml/badge.svg)](https://github.com/kerolesmounir6-sys/km-downloader-extension/actions/workflows/build.yml)

## Features

- تحميل الفيديو والصوت من أي موقع بضغطة زر
- Context Menu: اضغط كليك يمين على الرابط → "تحميل عبر KM Downloader"
- اكتشاف تلقائي للوسائط في الصفحة
- Native Messaging للتواصل مع تطبيق KM Downloader

## التثبيت

### تلقائياً (مستحسن)
يتم تثبيت الإضافة تلقائياً عند تثبيت تطبيق **KM Downloader**.

### يدوياً
1. افتح `chrome://extensions`
2. فعّل **Developer mode**
3. اسحب `km_extension.crx` إلى الصفحة  
   أو استخدم **Load unpacked** ← اختر مجلد `chrome_extension/`

## Build

```bash
python build_extension.py
```

المخرجات في مجلد `build/`.

## Extension ID

```
ceojdhgfbcnbfdipehfdfalmcpjjnglg
```

## License

MIT
