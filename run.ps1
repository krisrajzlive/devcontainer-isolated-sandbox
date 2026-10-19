<#
.SYNOPSIS
  One command: build, start, seed, verify isolation, run the workload, tear down.
.PARAMETER Keep
  Leave the sandbox running afterwards (stop it later with: .\run.ps1 -Down).
.PARAMETER Shell
  Open an interactive shell inside the sandbox after the checks (implies -Keep).
.PARAMETER Down
  Stop the sandbox and delete its volumes.
#>
param([switch]$Keep, [switch]$Shell, [switch]$Down)

$ErrorActionPreference = "Continue"  # docker writes warnings to stderr; rely on exit codes instead
$compose = @("compose", "-f", "$PSScriptRoot/.devcontainer/docker-compose.yml")

function Invoke-Compose {
    docker @compose @args
    if ($LASTEXITCODE -ne 0) { throw "docker compose $($args -join ' ') failed" }
}

if ($Down) { Invoke-Compose down -v; return }

$null = docker info 2>&1
if ($LASTEXITCODE -ne 0) { throw "Docker is not running. Start Docker Desktop and retry." }

try {
    Invoke-Compose up -d --build
    Invoke-Compose exec -T workspace sh -c "cp -rn /opt/seed/. /workspace/"
    Invoke-Compose exec -T workspace python scripts/verify_isolation.py
    Invoke-Compose exec -T workspace python app/file_ops.py
    if ($Shell) { $Keep = $true; Invoke-Compose exec workspace bash }
}
finally {
    if (-not $Keep) { docker @compose down -v }
    else { Write-Host "Sandbox left running. Remove with: .\run.ps1 -Down" }
}
