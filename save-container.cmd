@echo off
setlocal

if /i "%~1"=="list" goto LIST
if /i "%~1"=="help" goto HELP

if "%~2"=="" (
  echo Usage: %~nx0 ^<repertoire^> ^<image:tag^>
  exit /b 1
)

set "BACKUP_DIR=%~1%"
set "IMAGE_TAG=%~2%"

rem Contruire le nom du fichier TAR
set "TAR_NAME=%IMAGE_TAG::=_%"
set "TAR_PATH=%BACKUP_DIR%\%TAR_NAME%.tar"

rem Crer le repertoire si necessaire
if not exist "%BACKUP_DIR%\" (
  mkdir "%BACKUP_DIR%\"
  if errorlevel 1 (
    echo ERREUR : impossible de creer le repertoire %BACKUP_DIR%
    exit /b 1
  )
)

echo.
echo Sauvegarde de l'image : %IMAGE_TAG%
echo Destination : %TAR_PATH%
echo.

wslc save -o "%TAR_PATH%" "%IMAGE_TAG%"

if errorlevel 1 (
  echo.
  echo ERREUR : la sauvegarde a echoue.
  exit /b 1
)

echo.
echo ===================================
echo Sauvegarde terminee avec succes !
echo ===================================
echo.
echo Pour charger cette image sur une autre machine :
echo.
echo    wslc load -i "%TAR_PATH%"
echo.
exit /b 0

:LIST
echo.
echo Images WSLC disponibles :
echo =========================
wslc image list
exit /b %errorlevel%

:HELP
echo.
echo Usage:
echo   %~nx0 list
echo   %~nx0 ^<repertoire^> ^<image:tag^>
echo.
exit /b 1
