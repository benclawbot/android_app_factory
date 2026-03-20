@echo off
for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-21*") do set JAVA_HOME=%%D
set PATH=C:\flutter\bin;%PATH%
echo.
echo =============================================
echo   ACCEPT ANDROID LICENSES
echo =============================================
echo.
echo When prompted, type 'y' and press Enter for each license.
echo There will be about 6-7 licenses to accept.
echo.
flutter doctor --android-licenses
echo.
echo =============================================
echo   VERIFYING...
echo =============================================
flutter doctor
pause
