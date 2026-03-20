@echo off
for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-21*") do set JAVA_HOME=%%D
set PATH=C:\flutter\bin;%PATH%
flutter doctor > C:\Users\thoma\android_app_factory\doctor_final.txt 2>&1
