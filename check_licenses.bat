@echo off
for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-21*") do set JAVA_HOME=%%D
set ANDROID_SDK=C:\Users\thoma\AppData\Local\Android\Sdk
set PATH=%ANDROID_SDK%\cmdline-tools\latest\bin;%PATH%

echo === Current license files ===
dir "%ANDROID_SDK%\licenses" /b 2>nul
echo.
echo === Checking what sdkmanager says ===
call sdkmanager.bat --licenses --verbose 2>&1 | findstr /i "license accepted missing"
echo.
echo === Trying to list installed packages ===
call sdkmanager.bat --list_installed 2>&1 | head -20
