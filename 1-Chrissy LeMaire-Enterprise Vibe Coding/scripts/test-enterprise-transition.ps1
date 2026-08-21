#requires -Version 7
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$deck = Join-Path (Split-Path $PSScriptRoot -Parent) 'index.html'
$html = Get-Content -Raw -LiteralPath $deck
$transition = [regex]::Match(
    $html,
    '<section class="slide s-close" data-section="§05 · enterprise transition">[\s\S]*?</section>'
).Value
$problems = [System.Collections.Generic.List[string]]::new()

if ([string]::IsNullOrWhiteSpace($transition)) {
    $problems.Add('enterprise transition slide is missing')
}
else {
    if ($transition -notmatch 'You saw what the agent can build') {
        $problems.Add('enterprise transition does not acknowledge the demo')
    }
    if ($transition -notmatch 'rules that shape every subsequent action') {
        $problems.Add('enterprise transition does not set up the guardrails section')
    }
    if ($transition -notmatch 'data-reveal') {
        $problems.Add('enterprise transition content does not use the deck reveal treatment')
    }
}

if ($problems.Count -gt 0) {
    foreach ($problem in $problems) { Write-Output "FAIL  $problem" }
    exit 1
}

Write-Output 'OK  enterprise transition bridges the demo and guardrails'
