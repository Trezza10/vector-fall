param(
    [Parameter(Mandatory = $true)][string]$Message,
    [string]$PythonBin = 'python',
    [string]$GodotBin = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
if ($GodotBin) { $env:GODOT_BIN = $GodotBin }
$branch = git branch --show-current
if ($LASTEXITCODE -ne 0 -or $branch -ne 'main') { throw 'Publish from main after reviewing your changes.' }
& $PythonBin tools/web_build.py
if ($LASTEXITCODE -ne 0) { throw 'Build/checks failed; nothing was pushed.' }
git add -A
if ($LASTEXITCODE -ne 0) { throw 'Could not stage the project.' }
git diff --cached --quiet
if ($LASTEXITCODE -eq 1) {
    git commit -m $Message
    if ($LASTEXITCODE -ne 0) { throw 'Commit failed; nothing was pushed.' }
}
git push origin main
if ($LASTEXITCODE -ne 0) { throw 'Push failed. Your local commit is preserved.' }
Write-Output 'Pushed. GitHub Actions will check, export and publish the new game.'
