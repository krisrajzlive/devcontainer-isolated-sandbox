<#
.SYNOPSIS
  One command: build, start, seed, verify isolation, run the workload. Leaves the sandbox running.
.PARAMETER Keep
  Leave the sandbox running afterwards (stop it later with: .\run.ps1 -Down).
.PARAMETER Shell
  Open an interactive shell inside the sandbox after the checks.
.PARAMETER Down
  Stop the sandbox and delete its volumes.
#>
param([switch]$Clean, [switch]$Shell, [switch]$Down)

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
    if ($Shell) { Invoke-Compose exec workspace bash }
}
finally {
    if ($Clean) { docker @compose down -v }
    else { Write-Host "Sandbox left running. Remove with: .\run.ps1 -Down" }
}
