#requires -Version 7
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$deck = Join-Path (Split-Path $PSScriptRoot -Parent) 'index.html'
$html = Get-Content -Raw -LiteralPath $deck
$slides = [regex]::Matches($html, '<section class="slide[\s\S]*?</section>')
$problems = [System.Collections.Generic.List[string]]::new()

if ($slides.Count -lt 5) {
    $problems.Add("expected at least 5 slides, found $($slides.Count)")
}
else {
    $slide = $slides[4].Value
    if ($slide -notmatch 'Chatting in the browser') {
        $problems.Add('slide 5 is missing the browser-chat framing')
    }
    if ($slide -notmatch 'generally can.t inspect your local repo or run commands on your machine') {
        $problems.Add('slide 5 does not qualify the local-machine access limitation')
    }
    if ($slide -match "can't open your files or run a single command") {
        $problems.Add('slide 5 still makes the obsolete absolute browser-access claim')
    }
}

if ($problems.Count -gt 0) {
    foreach ($problem in $problems) { Write-Output "FAIL  $problem" }
    exit 1
}

Write-Output 'OK  slide 5 distinguishes connected browser chat from local-machine access'
