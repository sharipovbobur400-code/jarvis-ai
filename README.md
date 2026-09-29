# 🤖 JARVIS — Personal AI Computer Assistant

Futuristik dizayn, AI miya, tabiiy qiz bola ovozi (Female AI Voice), kompyuterni to‘liq boshqarish va Android telefon orqali masofadan boshqarish imkoniyatiga ega personal AI yordamchi.

---

## 🌟 Asosiy Imkoniyatlar

1. **AI Miya & Multi-Provider Arxitekturasi**
   - **Google Gemini** (`gemini-1.5-flash` / `gemini-1.5-pro`)
   - **OpenAI** (`gpt-4o-mini` / `gpt-4o`)
   - **Anthropic Claude** (`claude-3-5-sonnet`)
   - **Lokal AI & Intelligent Offline Fallback** (Ollama va internet bo‘lmaganda ham kompyuter amallarini to‘liq bajaruvchi aqlli qoidalar tizimi).

2. **Ovoz Tizimi (Female AI Voice & STT/TTS)**
   - **Speech-to-Text (STT)**: O‘zbekcha, Ruscha, Inglizcha va Yaponcha real vaqtda ovoz tanish.
   - **Text-to-Speech (TTS)**: Yandex Alice kabi yoqimli, tabiiy qiz bola ovozi ohangi, tezlik va pitch boshqaruvi.
   - **Wake Word Detection**: `"JARVIS"`, `"Hey JARVIS"`, `"Salom JARVIS"` chaqiruvlarini doimiy eshitib turish.

3. **Kompyuterni Boshqarish & Dasturlar (Computer Control)**
   - **Dasturlarni ishga tushirish**: VS Code, Google Chrome, Telegram, Notepad, Kalkulyator, Fayl boshqaruvchisi.
   - **Brauzer va YouTube**: YouTube'dan musiqalarni qidirish va darhol ijro etish (masalan, *“JARVIS, Chrome orqali YouTube'ni och va M1nor musiqasini qo‘y”*).
   - **Media nazorati**: Ovozni balandlatish/pasaytirish, to‘xtatish, davom ettirish, keyingi trekka o‘tish, muting.
   - **Fayllar va Kod yaratish**: Desktopda papkalar ochish, fayllar yozish, Python/Telegram bot loyihalarini avtomatik tuzish, syntax tekshirish va VS Code'da ochish.
   - **Xavfsiz Terminal**: Buyruqlarni xavfsizlik darajasini tekshirgan holda PowerShell / CMD orqali bajarish.
   - **Tizim diagnostikasi**: Haqiqiy vaqtdagi CPU %, RAM %, Batareya % va OS holati.

4. **Task Planner (Ko‘p bosqichli Rejalashtiruvchi)**
   - Murakkab vazifalarni avtomatik bosqichlarga ajratish.
   - Bosqichma-bosqich bajarish va real vaqtda foiz ko‘rinishida holatni ko‘rsatish.

5. **Masofaviy Boshqaruv (Android Remote Control & QR Pairing)**
   - Laptopda o‘rnatilgan xavfsiz WebSocket Server.
   - QR kod orqali telefon va kompyuterni bir zumda ulash (Pairing).
   - Telefondan turib ovozli yoki tezkor tugmalar orqali kompyuterni boshqarish.

---

## 📁 Loyiha Tuzilishi

```text
jarvis/
├── lib/
│   ├── main.dart                      # Asosiy kirish nuqtasi & Navigatsiya
│   ├── core/
│   │   ├── config/                    # Theme, Constants, AppConfig
│   │   ├── security/                  # SecurityGuard & Permission tizimi
│   │   ├── storage/                   # SecureStorage & LocalDatabase (Memory)
│   │   └── utils/                     # SystemInfoUtil (CPU/RAM) & Logger
│   ├── ai/
│   │   ├── ai_provider.dart           # AI Provider interfeysi
│   │   ├── gemini_provider.dart       # Gemini AI Function Calling
│   │   ├── openai_provider.dart       # OpenAI GPT
│   │   ├── anthropic_provider.dart    # Claude
│   │   ├── local_ai_provider.dart     # Lokal/Offline AI engine
│   │   ├── prompt_manager.dart        # Dinamik tizim prompti
│   │   ├── memory_manager.dart        # Xotira va foydalanuvchi ma'lumotlari
│   │   ├── task_planner.dart          # Multi-step Task Planner
│   │   └── ai_service.dart            # Markaziy AI xizmati
│   ├── voice/
│   │   ├── speech_to_text.dart        # Mikrofondan ovoz yozib olish
│   │   ├── text_to_speech.dart        # Tabiiy ayol ovozida o'qish
│   │   └── wake_word.dart             # Wake-word detektori
│   ├── tools/
│   │   ├── base_tool.dart             # Asosiy Tool abstraksiyasi
│   │   ├── application_tool.dart      # Windows dasturlarini ochish
│   │   ├── browser_tool.dart          # Chrome, Web qidiruv, YouTube
│   │   ├── media_tool.dart            # Ovoz va pleer nazorati
│   │   ├── file_tool.dart             # Fayl & papka amallari
│   │   ├── terminal_tool.dart         # Terminal buyruqlari
│   │   ├── code_generator_tool.dart   # Bot & loyiha generatori
│   │   ├── system_tool.dart           # Tizim diagnostikasi & Lock PC
│   │   └── tool_registry.dart         # Barcha tool'lar ro'yxati
│   ├── remote/
│   │   ├── websocket_service.dart     # Desktop Server & Mobile Client
│   │   ├── device_pairing.dart        # IP aniqlash & QR kod formati
│   │   └── authentication.dart        # Token & xavfsizlik
│   ├── screens/
│   │   ├── home/                      # Arc Reactor UI & Bosh ekran
│   │   ├── brain/                     # AI Chat va suhbatlar
│   │   ├── tasks/                     # Task Planner monitoringi
│   │   ├── files/                     # Kod loyihalari va papkalar
│   │   ├── remote/                    # QR Pairing & Masofaviy boshqaruv
│   │   └── settings/                  # API kalitlar & Ovoz sozlamalari
│   └── widgets/                       # Arc Reactor, Waveform, HUD kartalari
└── test/
    └── jarvis_test.dart               # Test to'plami
```

---

## 🚀 Ishga Tushirish (Build & Run)

### Talablar:
- Flutter SDK (3.x yoki undan yuqori)
- Windows 10/11 yoki Android qurilma

### Windows Desktop:
```bash
flutter pub get
flutter run -d windows
```

### Windows Release:
```bash
flutter build windows --release
```

### Android:
```bash
flutter build apk --release
```
