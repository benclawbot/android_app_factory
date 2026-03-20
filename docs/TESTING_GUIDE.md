# Testing Generated Apps in the Android Emulator

## Your Setup

| Component | Path |
|-----------|------|
| Android SDK | `C:\Users\thoma\AppData\Local\Android\Sdk` |
| Emulator | `...\Sdk\emulator\emulator.exe` |
| AVD (virtual phone) | `Pixel_7_API_36` (Android 36.1, Google Play, x86_64) |
| JDK | `C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot` |
| Flutter | `C:\flutter\bin` |

---

## Step-by-Step: Test a Generated App

### 1. Launch the Emulator

Double-click `launch_emulator.bat` or run:
```bash
"C:\Users\thoma\AppData\Local\Android\Sdk\emulator\emulator.exe" -avd Pixel_7_API_36
```
Wait until you see the Android home screen (first boot takes 1-2 min).

### 2. Open the Generated Project in Android Studio

After generating an app with Android App Factory:
1. Open **Android Studio**
2. **File → Open** → Navigate to the generated project folder  
   (e.g. `C:\Users\thoma\Documents\myapp`)
3. Wait for Gradle sync to complete (first time takes a few minutes)

### 3. Run on the Emulator

- In Android Studio, select the **Pixel_7_API_36** emulator from the device dropdown (top toolbar)
- Click the **green Run ▶ button** (or `Shift+F10`)
- Wait for the build + install (~30-60 seconds first time)
- Your app appears on the emulator!

### 4. Alternative: Command Line Build & Run

If you prefer the terminal (no Android Studio needed):

```bash
cd <your_generated_project>

REM Set environment
set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot
set ANDROID_HOME=C:\Users\thoma\AppData\Local\Android\Sdk
set PATH=%ANDROID_HOME%\platform-tools;%PATH%

REM Build the debug APK
gradlew.bat assembleDebug

REM Install on running emulator
adb install app\build\outputs\apk\debug\app-debug.apk

REM Launch the app (replace com.example.myapp with your package name)
adb shell am start -n com.example.myapp/.MainActivity
```

---

## Quick Reference Commands

### Emulator Management
```bash
REM List available AVDs
"C:\Users\thoma\AppData\Local\Android\Sdk\emulator\emulator.exe" -list-avds

REM Launch with GPU acceleration (faster rendering)
"C:\Users\thoma\AppData\Local\Android\Sdk\emulator\emulator.exe" -avd Pixel_7_API_36 -gpu auto

REM Cold boot (fresh start, no snapshot)
"C:\Users\thoma\AppData\Local\Android\Sdk\emulator\emulator.exe" -avd Pixel_7_API_36 -no-snapshot-load
```

### ADB (Android Debug Bridge)
```bash
set PATH=C:\Users\thoma\AppData\Local\Android\Sdk\platform-tools;%PATH%

REM Check connected devices
adb devices

REM Install APK
adb install path\to\app.apk

REM Uninstall app
adb uninstall com.example.myapp

REM View device logs (useful for debugging)
adb logcat

REM Take screenshot
adb exec-out screencap -p > screenshot.png
```

---

## Troubleshooting

### "JAVA_HOME not set" when building
```bash
set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot
```

### Emulator is slow
- Enable **Hardware Acceleration**: Check that Intel HAXM or Windows Hypervisor Platform is enabled
- Settings → Apps → Windows Features → tick "Windows Hypervisor Platform"
- Use `-gpu auto` flag when launching emulator

### Gradle sync fails
- Make sure you're using JDK 17 or 21 (not 25)
- Delete `.gradle` folder in the project and re-sync
- Check your internet connection (Gradle downloads dependencies on first build)

### "No connected devices"
- Make sure the emulator is fully booted (you see the home screen)
- Run `adb devices` — should show `emulator-5554  device`
- If not listed, try `adb kill-server && adb start-server`
