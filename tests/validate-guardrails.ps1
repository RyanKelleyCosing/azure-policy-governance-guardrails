$ErrorActionPreference = 'Stop'

function Invoke-BicepBuild {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $bicepCommand = Get-Command bicep -ErrorAction SilentlyContinue
    if ($bicepCommand) {
        & $bicepCommand.Source build --file $FilePath | Out-Null
        return
    }

    $azCommand = Get-Command az -ErrorAction SilentlyContinue
    if (-not $azCommand) {
        throw 'Install either the Bicep CLI or Azure CLI before running validation.'
    }

    az bicep install | Out-Null
    az bicep build --file $FilePath | Out-Null
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$filesToValidate = @(
    'infra/main.bicep'
    'infra/policy-definitions.bicep'
    'infra/policy-set.bicep'
    'infra/policy-assignments.bicep'
)

Push-Location $repoRoot
try {
    foreach ($file in $filesToValidate) {
        Invoke-BicepBuild -FilePath $file
        Write-Host "Validated $file"
    }

    Write-Host 'Offline validation completed successfully.'
}
finally {
    Pop-Location
}