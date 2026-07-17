@echo off
REM Subly web release build — double-click me. Output: app\build\web (Claude deploys it).
cd /d "%~dp0app"
echo Building Subly for web (release)...
call flutter build web --release --pwa-strategy=none --dart-define-from-file=config/subly.live.json
echo.
if exist build\web\main.dart.js (echo BUILD OK — tell Claude to deploy.) else (echo BUILD FAILED — copy the error above to Claude.)
pause
