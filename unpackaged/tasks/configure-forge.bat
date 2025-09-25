@echo off
REM JIRA Forge App Configuration Utility - Windows Version
REM Small Office Helper Script

echo 🚀 JIRA Integration v4 - Configuration Helper
echo ==============================================
echo.

REM Check if curl is available
curl --version >nul 2>&1
if errorlevel 1 (
    echo ❌ curl is required but not found
    echo    Please install curl or use Git Bash to run configure-forge.sh
    pause
    exit /b 1
)

REM Check if forge CLI is available
forge --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Forge CLI is required but not installed
    echo    Run: npm install -g @forge/cli
    pause
    exit /b 1
)

echo ✅ All dependencies found
echo.

echo 🔍 Getting Forge app URL...
REM Get forge install list and extract URL (simplified for Windows)
forge install --list > temp_forge_output.txt

REM Note: This is a simplified version. The full shell script has better URL extraction.
echo ℹ️  Please manually get your Forge app URL from the above output
echo    Look for a URL like: https://[app-id].atlassian-dev.net
echo.

set /p FORGE_URL="Enter your Forge app URL: "

echo.
echo ⚙️  Configuring Forge app...
echo.

set /p SF_INSTANCE_URL="Salesforce Instance URL: "
set /p CLIENT_ID="Connected App Consumer Key: "
set /p CLIENT_SECRET="Connected App Consumer Secret: "
set /p JIRA_PROJECT_KEY="JIRA Project Key (default SH): "
set /p JIRA_INSTANCE_URL="JIRA Instance URL (default https://shulman-hill.atlassian.net): "

REM Set defaults
if "%JIRA_PROJECT_KEY%"=="" set JIRA_PROJECT_KEY=SH
if "%JIRA_INSTANCE_URL%"=="" set JIRA_INSTANCE_URL=https://shulman-hill.atlassian.net

echo.
echo 📝 Configuration Summary:
echo    Salesforce: %SF_INSTANCE_URL%
echo    JIRA Project: %JIRA_PROJECT_KEY%
echo    JIRA Instance: %JIRA_INSTANCE_URL%
echo.

set /p CONFIRM="Proceed with configuration? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo ❌ Configuration cancelled
    pause
    exit /b 1
)

REM Create JSON payload file
echo { > config_payload.json
echo   "instanceUrl": "%SF_INSTANCE_URL%", >> config_payload.json
echo   "clientId": "%CLIENT_ID%", >> config_payload.json  
echo   "clientSecret": "%CLIENT_SECRET%", >> config_payload.json
echo   "jiraProjectKey": "%JIRA_PROJECT_KEY%", >> config_payload.json
echo   "jiraInstanceUrl": "%JIRA_INSTANCE_URL%" >> config_payload.json
echo } >> config_payload.json

REM Send configuration
curl -s -X POST "%FORGE_URL%/webtrigger/config-handler" ^
     -H "Content-Type: application/json" ^
     -d @config_payload.json > response.txt

REM Check response
findstr "success.*true" response.txt >nul
if errorlevel 1 (
    echo ❌ Configuration failed
    echo    Response:
    type response.txt
    pause
    exit /b 1
) else (
    echo ✅ Forge app configured successfully!
)

echo.
echo 📋 Next Steps for Salesforce Configuration:
echo ===========================================
echo.
echo 1. In Salesforce Setup → External Services → New External Service
echo    Service Name: Jira Bridge Forge App  
echo    Service URL: %FORGE_URL%
echo    Schema: Import from external-service-schema.json
echo.
echo 2. Update MANUAL_CONFIG_CHECKLIST.md with:
echo    Forge App URL: %FORGE_URL%
echo    Configuration Status: ✅ Completed
echo.
echo 3. Test the integration by running:
echo    cci task run robot --org dev
echo.

REM Cleanup
del temp_forge_output.txt config_payload.json response.txt 2>nul

echo 🎉 Configuration completed successfully!
echo    Your JIRA integration is ready for testing.
echo.
pause