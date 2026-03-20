@echo off
set ANDROID_SDK=C:\Users\thoma\AppData\Local\Android\Sdk
set PATH=C:\flutter\bin;%ANDROID_SDK%\cmdline-tools\latest\bin;%ANDROID_SDK%\platform-tools;%ANDROID_SDK%\emulator;%PATH%

echo === Downloading Android cmdline-tools ===
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest 'https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip' -OutFile '%TEMP%\cmdline-tools.zip'"
if errorlevel 1 (
    echo ERROR: Failed to download cmdline-tools
    pause
    exit /b 1
)

echo === Extracting cmdline-tools ===
powershell -NoProfile -Command "Expand-Archive -Path '%TEMP%\cmdline-tools.zip' -DestinationPath '%TEMP%\cmdline-tools-extract' -Force"

echo === Installing to SDK ===
if not exist "%ANDROID_SDK%\cmdline-tools\latest" mkdir "%ANDROID_SDK%\cmdline-tools\latest"
xcopy /E /Y /Q "%TEMP%\cmdline-tools-extract\cmdline-tools\*" "%ANDROID_SDK%\cmdline-tools\latest\"

echo === Accepting licenses ===
echo y| "%ANDROID_SDK%\cmdline-tools\latest\bin\sdkmanager.bat" --licenses

echo === Creating AVD ===
echo no| "%ANDROID_SDK%\cmdline-tools\latest\bin\avdmanager.bat" create avd -n Pixel_7_API_36 -k "system-images;android-36.1;google_apis_playstore;x86_64" -d pixel_7

echo === DONE ===
echo.
echo To launch the emulator, run:
echo   %ANDROID_SDK%\emulator\emulator.exe -avd Pixel_7_API_36
echo.
pause
