<div align="center">

<img src="docs/chefit-logo.png" alt="Chef It" width="160" />

# Chef It

### *scan. cook. enjoy.*

**Smart recipes from what you already have.**

[![Swift](https://img.shields.io/badge/Swift-5.10-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%2017+-007AFF?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Xcode](https://img.shields.io/badge/Xcode-15+-1575F9?style=for-the-badge&logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![Node.js](https://img.shields.io/badge/Node.js-Express-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org)
[![License](https://img.shields.io/badge/License-MIT-FFB79D?style=for-the-badge)](LICENSE)

[![Hackathon](https://img.shields.io/badge/🏆_Built_at-ConHacks_2026-4C5A3E?style=for-the-badge)](https://conhacks.io/)
[![Platform](https://img.shields.io/badge/Platform-iOS-A8C5A1?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/ios)

</div>

---

## 📖 About

**Chef It** is a native iOS app that turns whatever's sitting in your fridge into dinner. Snap a photo of your pantry, let on-device + cloud vision detect every ingredient, and get instant AI-matched recipes you can actually cook *right now* — no extra grocery run required.

Built end-to-end in **36 hours** at **ConHacks 2026** 🏆.

> Less food waste. Less decision fatigue. More cooking.

---

## ✨ Features

- 📸 **Pantry Scanning** — Computer-vision ingredient detection from a single photo
- 🧠 **Smart Matching** — Recipe scoring engine ranks suggestions by what you already own
- 🥬 **Ingredient Intake** — Manual add, undo, rename, smart suggestions, persistent store
- 🍳 **Recipe Discovery** — Edamam-powered search + curated seed recipes
- ❤️ **Favorites & Saved** — Persistent recipe library across sessions
- 🛒 **Shopping List** — Auto-generated for missing ingredients
- 👨‍🍳 **Cooking Mode** — Step-by-step guided cooking flow
- 🌐 **Social Feed** — Share dishes, comment, review, build a community
- 🔐 **Auth** — Email, Google Sign-In, Apple Sign-In
- 🔔 **Notifications** — Engagement + cooking reminders

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│  iOS App  (SwiftUI · iOS 17+)               │
│  └─ App/ChefIt/                             │
│     screens · navigation · design tokens    │
├─────────────────────────────────────────────┤
│  ChefItKit  (SwiftPM library)               │
│  └─ Sources/ChefItKit/                      │
│     • Features/   Scan · Auth · Recommend   │
│     • Services/   Edamam · Vision · Auth    │
│     • Matching/   RecipeMatcher · Scoring   │
│     • Models/     Ingredient · Recipe       │
│     • Normalization/  IngredientNormalizer  │
└─────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│  Backend  (Node.js · Express · PostgreSQL)  │
│  └─ backend/                                │
│     auth · users · posts · reviews ·        │
│     comments · Cloudinary uploads           │
└─────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

<table>
  <tr>
    <td valign="top" width="33%">

### 📱 iOS
- Swift 5.10
- SwiftUI (iOS 17+)
- Swift Package Manager
- XcodeGen
- VisionKit / Core ML
- Google Sign-In SDK
- Sign in with Apple

</td>
    <td valign="top" width="33%">

### 🌐 Backend
- Node.js + Express
- PostgreSQL
- JWT auth
- bcrypt
- Google OAuth
- Cloudinary (image hosting)
- Multer

</td>
    <td valign="top" width="33%">

### 🤖 AI / Data
- Edamam Recipe API
- OpenAI Vision API
- Google Gemini
- Custom recipe scoring
- Ingredient normalizer

</td>
  </tr>
</table>

---

## 🚀 Getting Started

### Prerequisites

- macOS with **Xcode 15+**
- [`xcodegen`](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- **Node.js 18+** and **PostgreSQL 16**
- Edamam API key ([sign up](https://developer.edamam.com))

### iOS App

```bash
git clone https://github.com/MatthewKim07/chef-it.git
cd chef-it

# Fill in API keys
cp Secrets.xcconfig.template Secrets.xcconfig

# Generate the .xcodeproj (gitignored)
xcodegen generate

# Build & test from CLI
swift build
swift test

# Or open in Xcode
open ChefIt.xcodeproj
```

Required keys in `Secrets.xcconfig`:

```
EDAMAM_APP_ID         = your_id
EDAMAM_APP_KEY        = your_key
GOOGLE_CLIENT_ID      = your_google_oauth_id
GEMINI_API_KEY        = optional
OPENAI_API_KEY        = optional
AUTH_BASE_URL         = http://127.0.0.1:3000
```

### Backend

```bash
cd backend
npm install
cp .env.example .env       # fill in DB + JWT + OAuth secrets
npm run schema             # init PostgreSQL schema
npm run dev                # localhost:3000
```

> ⚠️ **After every `git pull` or branch switch, re-run `xcodegen generate`.** The `.xcodeproj` is gitignored.

---

## 📂 Project Structure

```
chef-it/
├── App/ChefIt/                  # SwiftUI app — screens, navigation, theme
├── Sources/ChefItKit/           # Core library (SwiftPM)
│   ├── Features/                # Scan · Auth · Recommendations
│   ├── Services/                # Edamam · Vision · Auth · Posts · Reviews
│   ├── Matching/                # Recipe scoring engine
│   ├── Models/                  # Ingredient · Recipe · ScanResult
│   ├── Normalization/           # IngredientNormalizer · ProteinDetector
│   └── SeedData/                # 17 starter recipes
├── Tests/ChefItKitTests/        # XCTest suite
├── backend/                     # Node + Express + Postgres API
│   ├── routes/                  # auth · users · posts · reviews
│   └── src/                     # entry · db · schema
├── docs/                        # Flow diagrams + asset library
├── CHEFIT_BRAND_GUIDELINES.md   # Visual identity reference
├── Package.swift                # SwiftPM manifest
└── project.yml                  # XcodeGen config
```

---

## 🎨 Brand

Chef It has a full design system — sage greens, peach CTAs, rounded everything, Playfair Display + Nunito. See **[CHEFIT_BRAND_GUIDELINES.md](CHEFIT_BRAND_GUIDELINES.md)** for the complete reference.

| Sage Green | Matcha | Pistachio | Cream | Peach | Honey |
|:---:|:---:|:---:|:---:|:---:|:---:|
| `#4C5A3E` | `#A8C5A1` | `#E8F0E3` | `#FFF7E8` | `#FFB79D` | `#FFD26F` |

---

## 👥 The Team

Built with love at ConHacks 2026 by:

<table>
  <tr>
    <td align="center" width="33%">
      <a href="https://github.com/MatthewKim07">
        <img src="https://github.com/MatthewKim07.png" width="100" style="border-radius:50%" alt="Matthew Kim"/><br/>
        <sub><b>Matthew Kim</b></sub>
      </a><br/>
      <sub>🧠 AI · Vision · Pantry Detection</sub>
    </td>
    <td align="center" width="33%">
      <a href="https://github.com/SoroushKhajehpour">
        <img src="https://github.com/SoroushKhajehpour.png" width="100" style="border-radius:50%" alt="Soroush Khajehpour"/><br/>
        <sub><b>Soroush Khajehpour</b></sub>
      </a><br/>
      <sub>🎨 iOS UI · SwiftUI · Design</sub>
    </td>
    <td align="center" width="33%">
      <a href="https://github.com/alihusseini07">
        <img src="https://github.com/alihusseini07.png" width="100" style="border-radius:50%" alt="Ali Husseini"/><br/>
        <sub><b>Ali Husseini</b></sub>
      </a><br/>
      <sub>⚙️ Backend · Database · Recipe API</sub>
    </td>
  </tr>
</table>

---

## 🏆 ConHacks 2026

Chef It was built in **36 hours** at **[ConHacks 2026](https://conhacks.io/)** — Conestoga College's flagship hackathon.

---

## 📜 License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

*Made with 🥑, ☕, and zero sleep.*

**scan. cook. enjoy.** ❤️

</div>
