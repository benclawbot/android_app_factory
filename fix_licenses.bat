@echo off
for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-21*") do set JAVA_HOME=%%D
echo y| call "C:\Users\thoma\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --licenses >nul 2>&1
echo Licenses accepted.
set PATH=C:\flutter\bin;%PATH%
flutter doctor > C:\Users\thoma\android_app_factory\doctor_final.txt 2>&1
echo Done.
