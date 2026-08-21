#requires -Version 7
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$deck = Join-Path (Split-Path $PSScriptRoot -Parent) 'index.html'
$html = Get-Content -Raw -LiteralPath $deck
$slides = [regex]::Matches($html, '<section class="slide[\s\S]*?</section>')
$problems = [System.Collections.Generic.List[string]]::new()

if ($slides.Count -lt 24) {
    $problems.Add("expected at least 24 slides, found $($slides.Count)")
}
else {
    $controlSlide = $slides[20].Value
    foreach ($label in @('Hooks', 'Skills', 'MCP')) {
        if ($controlSlide -notmatch ">\s*$label\s*<") {
            $problems.Add("slide 21 is missing the $label control surface")
        }
    }
    if ($controlSlide -match '>\s*Commands\s*<') {
        $problems.Add('slide 21 still presents Commands as an authoring primitive')
    }

    $workflowSlide = $slides[23].Value
    if ($workflowSlide -notmatch 'The slash is just the doorway') {
        $problems.Add('slide 24 does not explain the modern Skill invocation model')
    }
    if ($workflowSlide -match 'Commands make steps repeatable') {
        $problems.Add('slide 24 still uses the deprecated custom-command framing')
    }
    if ($workflowSlide -notmatch '\$verify') {
        $problems.Add('slide 24 does not show the Codex Skill invocation form')
    }
}

if ($problems.Count -gt 0) {
    foreach ($problem in $problems) { Write-Output "FAIL  $problem" }
    exit 1
}

Write-Output 'OK  slides 21 and 24 use the current Hooks, Skills, and MCP model'
