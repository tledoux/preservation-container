
@echo off
setlocal

if "%~1"=="" goto usage
if "%~2"=="" goto usage

set "INPUT_DIR=%~f1"
set "OUTPUT_DIR=%~f2"
set "CONTAINER_VERSION=preservation-tools:1.0"

if not exist "%INPUT_DIR%\" (
    echo ERREUR : le repertoire des donnees en entree n'existe pas.
    echo "%INPUT_DIR%"
    exit /b 1
)

if not exist "%OUTPUT_DIR%\" (
    mkdir "%OUTPUT_DIR%"
    if errorlevel 1 (
        echo ERREUR : impossible de creer le repertoire de sortie.
        exit /b 1
    )
)

echo Entree : %INPUT_DIR%
echo Sortie : %OUTPUT_DIR%
echo.

where wslc >nul 2>&1
if errorlevel 1 (
    echo ERREUR : commande wslc introuvable.
    exit /b 1
)

wslc run --rm -it ^
  --mount "type=bind,source=%INPUT_DIR%,target=/mnt/input,readonly" ^
  --mount "type=bind,source=%OUTPUT_DIR%,target=/mnt/output" ^
  %CONTAINER_VERSION%

exit /b %errorlevel%

:usage
echo Utilisation :
echo   %~nx0 "repertoire_donnees" "repertoire_sortie"
echo.
echo Exemple :
echo   %~nx0 "D:\Archives a analyser" "D:\Rapports"
exit /b 2
