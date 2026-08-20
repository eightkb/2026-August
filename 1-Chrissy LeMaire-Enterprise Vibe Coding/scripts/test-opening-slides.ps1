#requires -Version 7
<#
.SYNOPSIS
    Confirms the opening establishes vibe coding, enterprise vibe engineering,
    and the shift from chat to agents.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$deck = Join-Path (Split-Path $PSScriptRoot -Parent) 'index.html'
$html = Get-Content -LiteralPath $deck -Raw
$required = @(
    'What is vibe coding?',
    "I don’t read the diffs anymore.",
    'What is enterprise vibe coding?',
    'AI-assisted development with testing, verification, governance, and automated enforcement built into the generation loop.',
    'What changes when AI can act?'
)

$missing = @($required | Where-Object { -not $html.Contains($_) })
if ($missing.Count -gt 0) {
    $missing | ForEach-Object { Write-Output "FAIL  missing opening copy: $_" }
    exit 1
}

if ($html.Contains('Vibe coding with a harness.')) {
    Write-Output 'FAIL  a harness is presented as the definition of vibe engineering'
    exit 1
}

if ($html.Contains('Using AI to build production software while retaining engineering ownership.')) {
    Write-Output 'FAIL  enterprise vibe coding is defined only as ownership'
    exit 1
}

$opening = [regex]::Match($html, '(?s)<section class="slide s-title"[^>]*>(.*?)</section>').Groups[1].Value
if (-not $opening.Contains('Chrissy LeMaire') -or $opening.Contains('opening-books')) {
    Write-Output 'FAIL  opening slide no longer matches its original speaker layout'
    exit 1
}

if ($html.Contains('data-cookbook-target') -or $html.Contains('id="slide-cookbooks"')) {
    Write-Output 'FAIL  cookbook navigation still branches away from the bio sequence'
    exit 1
}

$bios = @([regex]::Matches($html, '(?s)<section class="slide s-bio(?:\s+[^" ]+)*"[^>]*>(.*?)</section>'))
if ($bios.Count -lt 2) {
    Write-Output 'FAIL  bio does not have a second cookbook reveal slide'
    exit 1
}

if ($bios[0].Groups[1].Value -notmatch 'genai-book\.png' -or $bios[0].Groups[1].Value -notmatch 'dbatools-book\.png') {
    Write-Output 'FAIL  first bio slide is missing the Manning book covers'
    exit 1
}

$authority = $bios[0].Groups[1].Value
$reveal = $bios[1].Groups[1].Value

if ($html -notmatch '<section class="slide s-bio s-bio--authority"' -or
    $html -notmatch '<section class="slide s-bio s-bio--cookbooks"') {
    Write-Output 'FAIL  bio slides do not declare the authority and cookbook silhouettes'
    exit 1
}

if (-not $reveal.Contains('<h2 class="bio-reveal-title" data-reveal>Also, five Cajun cookbooks.</h2>')) {
    Write-Output 'FAIL  cookbook beat is missing its reveal headline'
    exit 1
}

if ($reveal.Contains('bio-name') -or $reveal.Contains('bio-creds')) {
    Write-Output 'FAIL  cookbook beat repeats the speaker bio'
    exit 1
}

$cookbookAssets = @('cajun-original.webp', 'cajun-thanksgiving.webp', 'cajun-christmas.webp', 'cajun-mardigras.webp', 'cajun-icecream.webp')
$missingCookbooks = @($cookbookAssets | Where-Object { -not $reveal.Contains($_) })
if ($missingCookbooks.Count -gt 0) {
    Write-Output "FAIL  second bio slide is missing cookbook covers: $($missingCookbooks -join ', ')"
    exit 1
}

$coverClassCount = [regex]::Matches("$authority$reveal", 'class="bio-cover"').Count
if ($coverClassCount -ne 7) {
    Write-Output "FAIL  expected seven consistently framed covers, found $coverClassCount"
    exit 1
}

if ($html -notmatch '\.s-bio \.bio-name\{[^}]*white-space:nowrap' -or $html -notmatch '\.s-bio \.bio-creds\{[^}]*white-space:nowrap') {
    Write-Output 'FAIL  bio name and subtitle are not kept to one line each'
    exit 1
}

if ($html -notmatch '(?s)\.bio-cover\{[^}]*border:2px solid var\(--line\)[^}]*border-bottom:4px solid var\(--accent\)[^}]*box-shadow:') {
    Write-Output 'FAIL  shared cover border, green accent, or shadow is missing'
    exit 1
}

if ($html -notmatch '(?s)\.bio-cookbook-band\{[^}]*display:flex[^}]*align-items:flex-end') {
    Write-Output 'FAIL  cookbook reveal is not one baseline-aligned row'
    exit 1
}

Write-Output 'OK  opening establishes vibe coding, enterprise vibe engineering, and agentic action'
