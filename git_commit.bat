@echo off
cd /d C:\Users\thoma\android_app_factory
git init
git add -A
git commit -m "Initial commit: Android App Factory MVP

Features:
- Desktop Flutter app for generating Android projects from natural language prompts
- Support for MiniMax M2.7 and Anthropic Claude Opus 4 LLM providers
- Settings persistence (API keys, output directory)
- Real-time console output during generation
- File tree viewer with syntax highlighting for generated code
- Dark theme with sidebar navigation

Tech stack:
- Flutter Windows desktop app
- Provider for state management
- Dio for HTTP
- Material Design 3 dark theme

Generated Android projects:
- Kotlin + Jetpack Compose (Material 3)
- Multi-screen navigation (NavHost/NavController)
- Version catalog Gradle build system
- Material Icons Extended

Templates:
- Android project scaffold (build.gradle.kts, settings.gradle.kts)
- AndroidManifest.xml, strings.xml, themes.xml
- Gradle wrapper (gradlew.bat, gradle-wrapper.properties)
- Version catalog (libs.versions.toml) with BOM"
