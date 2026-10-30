
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$InputDir,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$OutputDir
)

$ErrorActionPreference = "Stop"
$ContainerVersion = "preservation-tools:1.0"

try {
    # Vérifier que le répertoire source existe.
    $InputPath = (Resolve-Path -LiteralPath $InputDir).Path

    if (-not (Test-Path -LiteralPath $InputPath -PathType Container)) {
        throw "Le chemin des données n'est pas un répertoire."
    }

    # Créer le répertoire des résultats si nécessaire.
    if (-not (Test-Path -LiteralPath $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force |
            Out-Null
    }

    $OutputPath = (Resolve-Path -LiteralPath $OutputDir).Path

    if (-not (Test-Path -LiteralPath $OutputPath -PathType Container)) {
        throw "Le chemin de sortie  n'est pas un répertoire."
    }

    # Vérifier la présence de wslc.
    if (-not (Get-Command wslc -ErrorAction SilentlyContinue)) {
        throw "La commande wslc est introuvable dans le PATH."
    }

    Write-Host "Entree : $InputPath"
    Write-Host "Sortie : $OutputPath"
    Write-Host ""

    # Montage des données en lecture seule et des rapports en écriture.
    & wslc run --rm -it `
        --mount "type=bind,source=$InputPath,target=/mnt/input,readonly" `
        --mount "type=bind,source=$OutputPath,target=/mnt/output" `
        $ContainerVersion

    if ($LASTEXITCODE -ne 0) {
        throw "Le conteneur s'est termine avec le code $LASTEXITCODE."
    }
}
catch {
    Write-Error $_
    exit 1
}
