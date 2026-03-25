@echo off
setlocal

echo ============================================
echo  Plotrol Go Backend - Setup and Start
echo ============================================
echo.

REM Check Go is installed
where go >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Go is not installed or not in PATH.
    echo Download from: https://go.dev/dl/
    pause
    exit /b 1
)

REM Download dependencies
echo [1/3] Downloading Go dependencies...
go mod tidy
if errorlevel 1 (
    echo [ERROR] Failed to download dependencies. Check your internet connection.
    pause
    exit /b 1
)
echo       Done.
echo.

REM Make sure .env exists
if not exist ".env" (
    echo [WARN] .env file not found. Using default values.
    echo       Create a .env file based on the template if needed.
    echo.
)

REM Start the server
echo [2/3] Starting server...
echo       Make sure MySQL is running on localhost:3306
echo       DB: plotrol_new will be auto-created if it doesn't exist.
echo.
echo [3/3] Server starting...
echo       Local:    http://localhost:8080
echo       Emulator: http://10.0.2.2:8080
echo.
echo Press Ctrl+C to stop the server.
echo.

go run .

pause
