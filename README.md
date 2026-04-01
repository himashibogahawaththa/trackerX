# 🌍 Global Webcam Monitor

**Flutter · GraphQL · Mapbox · Windy Webcam API**
Technical Case Study — Himashi Bogahawaththa (2026)

---

# 📌 Overview

Global Webcam Monitor is a Flutter-based interactive world map that allows users to explore **live webcams across the globe**. The application integrates **GraphQL**, **Mapbox**, and **Windy Webcam API** to deliver real‑time webcam feeds with a polished, modern UI.

This project was built as a **technical Flutter assignment** and intentionally goes beyond the minimum requirements with production‑level architecture and UX.

---

# ✨ Features

• 🌍 Interactive 3D globe using Mapbox
• 🔎 Predictive country search
• 📡 Live webcam markers
• 🎥 Embedded webcam player (Windy)
• 🧊 Glassmorphic draggable detail sheet
• ⚡ Parallel async data fetching
• 🔄 Auto-refresh webcam preview
• 💾 GraphQL caching (HiveStore)
• 🌙 Material 3 Dark UI

---

# 🏗️ Architecture

The project follows a **Service-Based Architecture** with clear separation of responsibilities:

```
lib/
 ├── core/
 │   ├── constants/
 │   ├── router/
 │   └── theme/
 │
 ├── screens/
 │   ├── splash_screen.dart
 │   ├── main_map_screen.dart
 │   └── webcam_player_screen.dart
 │
 ├── services/
 │   ├── graphql_service.dart
 │   ├── webcam_service.dart
 │   └── location_service.dart
 │
 ├── widgets/
 │   ├── glassmorphism_sheet.dart
 │   └── webcam_card.dart
 │
 ├── models/
 │   └── webcam_model.dart
 │
 └── main.dart
```

---

# 🧠 How It Works

## 1. GraphQL Data Layer

The app uses the public GraphQL API:

```
https://countries.trevorblades.com
```

GraphQL provides:

• Country name
• Country emoji
• ISO country code
• Capital city

The **ISO code** is then used to fetch webcam data from **Windy API**.

This creates a **real dependency** between GraphQL and the webcam layer.

---

# 🗺️ Mapbox Integration

Mapbox is used as the **primary interaction layer**.

### Dual Annotation System

### Country Layer

• Emoji flag markers
• Loaded once at startup
• Tap to search country

### Webcam Layer

• Custom webcam icon markers
• Loaded per search
• Tap to open webcam details

---

# 🎬 Screens

## Splash Screen

• Fade animation
• Globe icon
• Progress indicator

---

## Interactive Globe

• Full-screen Mapbox globe
• Floating search bar
• Dark starfield background

---

## Predictive Search

Two‑pass search algorithm:

1. Prefix matches
2. Contains matches

Example:

```
it → Italy
it → Switzerland
it → United Kingdom
```

---

## Webcam Detail Sheet

Glassmorphic draggable panel showing:

• Country flag
• City location
• Live preview image
• Last updated timestamp
• Timeline playback buttons

---

# 🎥 Webcam Player

Full-screen WebView player

Timeline modes:

• Today
• Month
• Year
• All Time

---

# ⚙️ Tech Stack

## Core

• Flutter (Dart null-safe)
• Material 3

## APIs

• GraphQL Countries API
• Windy Webcam API
• Mapbox SDK

## Packages

```
graphql_flutter
mapbox_maps_flutter
cached_network_image
webview_flutter
http
hive
hive_flutter
```

---

# ⚡ Engineering Highlights

## Parallel Async Fetching

While the map camera animates:

```
Future.wait([
 fetchCountries(),
 fetchWebcams(),
 fetchNearest()
])
```

This removes perceived loading time.

---

## Cache Busting

Each image URL appends timestamp:

```
_ts=millisecondsSinceEpoch
```

Ensures fresh webcam previews.

---

## Request Deduplication

Search request ID prevents stale results:

```
_searchRequestId++
```

Avoids race condition UI bugs.

---

# 🔄 Auto Refresh

Detail sheet refreshes every **10 minutes**:

```
Timer.periodic()
```

Keeps webcam previews current.

---

# 📱 Screenshots

(Add screenshots here)

```
/assets/screenshots/
```

Recommended screenshots:

• Splash Screen
• Globe Map
• Country Search
• Webcam Markers
• Detail Sheet
• Webcam Player

---

# 🚀 Getting Started

## 1. Clone Repository

```
git clone https://github.com/yourusername/global-webcam-monitor.git
```

---

## 2. Install Dependencies

```
flutter pub get
```

---

## 3. Add Mapbox Token

Create:

```
app_config.dart
```

Add:

```
static const mapboxAccessToken = "YOUR_TOKEN";
```

---

## 4. Run Project

```
flutter run
```

---

# 📌 Requirements Coverage

| Requirement        | Status |
| ------------------ | ------ |
| Flutter App        | ✅      |
| GraphQL Data       | ✅      |
| Clean UI           | ✅      |
| Mapbox Integration | ✅      |
| Code Architecture  | ✅      |
| SDK Integration    | ✅      |

---

# 👩‍💻 Author

**Himashi Bogahawaththa**
Flutter Developer
2026

---

# 📄 License

This project is for technical assessment and educational purposes.

---

# ⭐ Conclusion

Global Webcam Monitor demonstrates:

• Production‑ready Flutter architecture
• Real GraphQL dependency
• Advanced Mapbox integration
• Polished UI/UX
• Clean service-based code structure

This project intentionally exceeds assignment requirements and showcases **senior‑level Flutter engineering decisions**.

---

# ⭐ If you like this project

Give it a star ⭐ on GitHub

---
