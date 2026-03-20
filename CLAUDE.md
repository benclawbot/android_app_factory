# Android App Factory — Project Context

Stack: Provider | Material Icons | max-w-1400

## Quick Reference
- **Flutter SDK**: C:\flutter\bin (add to PATH)
- **Build**: `set PATH=C:\flutter\bin;%PATH% && flutter build windows`
- **Run**: `set PATH=C:\flutter\bin;%PATH% && flutter run -d windows`
- **Executable**: `build\windows\x64\runner\Release\android_app_factory.exe`

## Architecture
- `lib/services/llm_service.dart` — Dual LLM client (MiniMax M2.7 + Anthropic Claude Opus 4)
- `lib/services/project_generator.dart` — 5-phase pipeline: Plan → Code → Parse → Scaffold → Write
- `lib/templates/android_templates.dart` — Android build files (Gradle KTS, manifest, version catalog)
- `lib/providers/` — Provider-based state management (AppProvider + GenerationProvider)
- `lib/widgets/` — All UI components (sidebar, prompt, console, file viewer, settings)

## Key Design Decisions
1. **Two-pass LLM generation**: First call plans the architecture, second generates code. Improves quality.
2. **Robust file parsing**: Three-level regex fallback to extract files from LLM responses.
3. **Template + LLM hybrid**: Static build files from templates, dynamic Kotlin code from LLM.
4. **OpenAI-compatible endpoint for MiniMax**: Uses `/v1/chat/completions` format.
5. **Both streaming and non-streaming**: Streaming wired but non-streaming used by default (more reliable).

## Generated Android Project Structure
Output is a standard Android Studio project with:
- `build.gradle.kts` (root + app)
- `settings.gradle.kts` with version catalogs
- `gradle/libs.versions.toml` — centralized dependency versions
- Kotlin/Compose source in `app/src/main/java/<package>/`
- AndroidManifest.xml, strings.xml, themes.xml
