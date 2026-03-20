# Android App Factory 🏭

> AI-powered Android app generator — describe your app in natural language, get a complete Android Studio project.

![Flutter](https://img.shields.io/badge/Flutter-3.41-blue)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6)
![LLM](https://img.shields.io/badge/LLM-MiniMax%20M2.7%20%7C%20Claude%20Opus%204-purple)

## What It Does

Type a plain-English description of an Android app you want → the AI generates a **complete, ready-to-open Android Studio project** with:
- Kotlin + Jetpack Compose code
- Multi-screen navigation (NavHost/NavController)
- Material 3 design
- Proper Gradle build files (version catalogs)
- Clean architecture structure

## Quick Start

### Prerequisites
- Windows 10/11
- Flutter SDK (`C:\flutter\bin` in PATH)
- Visual Studio Build Tools 2022 (with C++ workload)
- An API key for **MiniMax** or **Anthropic Claude**

### Run
```bash
cd C:\Users\thoma\android_app_factory
flutter run -d windows
```

### Or run the built executable
```bash
build\windows\x64\runner\Release\android_app_factory.exe
```

## How to Use

1. **Open Settings** (gear icon in sidebar) → Select your LLM provider and enter your API key
2. **Fill in app details** — app name, package name, output directory
3. **Describe your app** in the text area (be specific!)
4. **Click Generate** → Watch the console as the AI plans and builds your app
5. **Switch to Output tab** → Browse all generated files with syntax highlighting
6. **Open in Android Studio** → File → Open → Select the generated project folder

## Example Prompts

```
A recipe book app with a home screen showing recipe cards in a grid,
a detail page for each recipe with ingredients list and step-by-step
instructions, an add recipe screen with form fields for title, 
description, ingredients, and steps, and a favorites screen. 
Use a warm color palette with orange accents.
```

```
A workout tracker app with a dashboard showing today's exercises,
an exercise library screen with categorized exercises, a workout
session screen with a timer, and a history screen with past workouts.
Dark theme with green accents.
```

## Architecture

```
lib/
├── main.dart                    # App entry, window config
├── theme/
│   └── app_theme.dart           # Colors, typography, component themes
├── models/
│   ├── llm_config.dart          # LLM provider config (MiniMax/Anthropic)
│   └── generation_state.dart    # Generation status/progress state
├── services/
│   ├── llm_service.dart         # LLM API client (both providers)
│   └── project_generator.dart   # Orchestrates the full generation pipeline
├── providers/
│   ├── app_provider.dart        # Settings, API keys, preferences
│   └── generation_provider.dart # Generation state management
├── templates/
│   └── android_templates.dart   # Android project file templates
├── screens/
│   └── home_screen.dart         # Main layout with sidebar
└── widgets/
    ├── sidebar.dart             # Navigation sidebar
    ├── prompt_panel.dart        # App description input form
    ├── console_panel.dart       # Real-time generation logs
    ├── file_tree_panel.dart     # Generated file browser + viewer
    └── settings_dialog.dart     # LLM provider/API key config
```

## LLM Providers

| Provider | Model | Endpoint | Auth |
|----------|-------|----------|------|
| **MiniMax** | MiniMax-M2.7 | `https://api.minimax.io/v1/chat/completions` | Bearer token |
| **Anthropic** | claude-opus-4-20250514 | `https://api.anthropic.com/v1/messages` | x-api-key header |

Both support custom endpoints (e.g., for proxies or self-hosted models).

## Generation Pipeline

```
User Prompt
    │
    ▼
┌─────────────────┐
│ 1. Plan Phase   │  LLM plans screens, navigation, data models
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. Code Phase   │  LLM generates all Kotlin/Compose files
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. Parse Phase   │  Extracts individual files from LLM response
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. Scaffold      │  Adds build.gradle, AndroidManifest, etc.
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 5. Write Files   │  Writes complete project to disk
└─────────────────┘
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Desktop Framework | Flutter (Windows) |
| State Management | Provider |
| HTTP Client | Dio |
| UI Theme | Custom dark theme (Material 3) |
| Syntax Highlighting | flutter_highlight |
| File Management | file_picker + dart:io |
| Window Management | window_manager |
| Persistence | shared_preferences |

## Building

```bash
# Debug run
flutter run -d windows

# Release build
flutter build windows

# Output at: build/windows/x64/runner/Release/
```

## Testing Generated Apps

See the full guide: **[docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md)**

**Quick version:**
1. Launch emulator: double-click `launch_emulator.bat`
2. Open the generated project in **Android Studio** → File → Open
3. Select **Pixel_7_API_36** in the device dropdown → click **Run ▶**

Or from the command line:
```bash
cd <generated_project>
set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot
gradlew.bat assembleDebug
adb install app\build\outputs\apk\debug\app-debug.apk
```

## Future Roadmap

- [ ] Streaming LLM responses (live code generation view)
- [ ] Template library (pre-built app skeletons)
- [ ] APK compilation from within the app
- [ ] Multi-file code editor with live preview
- [ ] Project version history
- [ ] Export to GitHub
- [ ] Support for more LLM providers (Gemini, OpenAI, etc.)

## License

MIT
