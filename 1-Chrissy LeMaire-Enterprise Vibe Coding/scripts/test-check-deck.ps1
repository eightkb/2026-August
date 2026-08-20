#requires -Version 7
<#
.SYNOPSIS
    Ensures the deck validator ignores JavaScript assignments while scanning
    markup attributes.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$checker = Join-Path $PSScriptRoot 'check-deck.ps1'
$fixture = New-TemporaryFile

try {
    @'
<!doctype html>
<html><body>
  <section class="slide s-test" data-section="test">
    <span data-reveal>fixture content</span>
  </section>
  <script>image.src = source.currentSrc || source.src;</script>
</body></html>
'@ | Set-Content -LiteralPath $fixture -NoNewline

    & $checker -Path $fixture
    if ($LASTEXITCODE -ne 0) {
        Write-Output 'FAIL  validator treated a JavaScript assignment as a local file reference'
        exit 1
    }

    Write-Output 'OK  validator ignores script contents while resolving markup references'
}
finally {
    Remove-Item -LiteralPath $fixture -Force -ErrorAction SilentlyContinue
}
