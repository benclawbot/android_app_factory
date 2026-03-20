@echo off
REM Directly write accepted license hashes — this is what sdkmanager creates
set LDIR=C:\Users\thoma\AppData\Local\Android\Sdk\licenses
if not exist "%LDIR%" mkdir "%LDIR%"

echo.> "%LDIR%\android-sdk-license"
echo 24333f8a63b6825ea9c5514f83c2829b004d1fee>> "%LDIR%\android-sdk-license"
echo d56f5187479451eabf01fb78af6dfcb131a6481e>> "%LDIR%\android-sdk-license"

echo.> "%LDIR%\android-sdk-preview-license"
echo 84831b9409646a918e30573bab4c9c91346d8abd>> "%LDIR%\android-sdk-preview-license"

echo.> "%LDIR%\android-googletv-license"
echo 601085b94cd77f0b54ff86406957099ebe79c4d6>> "%LDIR%\android-googletv-license"

echo.> "%LDIR%\android-sdk-arm-dbt-license"
echo 859f317696f67ef3d7f30a50a5560e7834b43903>> "%LDIR%\android-sdk-arm-dbt-license"

echo.> "%LDIR%\google-gdk-license"
echo 33b6a2b64607f11b759f320ef9dff4ae5c47d97a>> "%LDIR%\google-gdk-license"

echo.> "%LDIR%\intel-android-extra-license"
echo d975f751698a77b662f1254ddbeed3901e976f5a>> "%LDIR%\intel-android-extra-license"

echo.> "%LDIR%\mips-android-sysimage-license"
echo e9acab5b5fbb560a72cfaecber8acf4457f3ed00>> "%LDIR%\mips-android-sysimage-license"

echo.> "%LDIR%\android-googlexr-license"
echo 5bfc0635be64b5b09a71b22a556e2b0aeece63f5>> "%LDIR%\android-googlexr-license"

echo Licenses written to %LDIR%
echo.

set PATH=C:\flutter\bin;%PATH%
flutter doctor
pause
