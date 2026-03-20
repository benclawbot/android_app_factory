@echo off
for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-21*") do set JAVA_HOME=%%D
call "C:\Users\thoma\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\avdmanager.bat" list avd
