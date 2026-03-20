@echo off
set ANDROID_SDK=C:\Users\thoma\AppData\Local\Android\Sdk

REM Find a working JDK - try the one bundled with Android Studio or the one in PATH
for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-21*") do set JAVA_HOME=%%D
if not exist "%JAVA_HOME%\bin\java.exe" (
    for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-17*") do set JAVA_HOME=%%D
)
if not exist "%JAVA_HOME%\bin\java.exe" (
    REM Try to find any JDK
    for /f "delims=" %%i in ('where java') do (
        set JAVA_PATH=%%~dpi
        set JAVA_HOME=%%~dpi..
    )
)

echo Using JAVA_HOME: %JAVA_HOME%
"%JAVA_HOME%\bin\java.exe" -version 2>&1

echo.
echo === Accepting Android SDK licenses ===
echo y| call "%ANDROID_SDK%\cmdline-tools\latest\bin\sdkmanager.bat" --licenses 2>&1

echo.
echo === Listing available AVD device types ===
call "%ANDROID_SDK%\cmdline-tools\latest\bin\avdmanager.bat" list device 2>&1 | findstr /i "pixel"

echo.
echo === Creating Pixel 7 AVD ===
echo no| call "%ANDROID_SDK%\cmdline-tools\latest\bin\avdmanager.bat" create avd -n Pixel_7_API_36 -k "system-images;android-36.1;google_apis_playstore;x86_64" -d pixel_7 --force 2>&1

echo.
echo === Listing AVDs ===
call "%ANDROID_SDK%\cmdline-tools\latest\bin\avdmanager.bat" list avd 2>&1

echo.
echo === DONE ===
pause
