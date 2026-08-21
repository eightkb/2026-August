#requires -Version 7
<#
.SYNOPSIS
    Validates the EightKB deck's structure and copy rules.
.DESCRIPTION
    Checks that every local file reference resolves, that slide copy contains no
    em dashes, en dashes, or double hyphens used as dashes, that every slide
    carries a data-section and at least one data-reveal, and that element ids are
    unique. Exits 1 with a FAIL line per problem, 0 when clean.
#>
[CmdletBinding()]
param(
    [string]$Path = (Join-Path (Split-Path $PSScriptRoot -Parent) 'index.html')
)

$ErrorActionPreference = 'Stop'

$deck = (Resolve-Path -LiteralPath $Path).Path
# -Parent lives in Split-Path's -Path parameter set, so -LiteralPath cannot be
# used with it. $deck is already a resolved absolute path.
$root = Split-Path -Path $deck -Parent
$html = Get-Content -LiteralPath $deck -Raw
$problems = [System.Collections.Generic.List[string]]::new()

# Commented-out markup is not part of the deck. Strip it once, up front, so a
# reference parked in a comment neither fails the file check nor trips the dash
# check on the comment delimiters themselves.
$live = [regex]::Replace($html, '(?s)<!--.*?-->', ' ')

# 1. Every local src/href resolves to a file on disk. Script and style contents
# are not markup, so strip them before looking for attributes: assignments such
# as `image.src = source.currentSrc` must not be treated as file references.
# Accept normal HTML attribute spacing, single or double quotes, and unquoted
# simple values.
$markup = [regex]::Replace($live, '(?is)<(script|style)\b.*?</\1>', ' ')
$referencePattern = '(?i)\b(?:src|href)\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^\s>]+))'
foreach ($match in [regex]::Matches($markup, $referencePattern)) {
    if ($match.Groups[1].Success) { $rel = $match.Groups[1].Value }
    elseif ($match.Groups[2].Success) { $rel = $match.Groups[2].Value }
    else { $rel = $match.Groups[3].Value }

    if ([string]::IsNullOrWhiteSpace($rel)) { continue }
    if ($rel -match '^(?i:https?:|//|#|mailto:|data:)') { continue }

    $target = Join-Path $root $rel
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        $problems.Add("missing file: $rel")
    }
}

# 2. Visible copy carries no em dash, en dash, or double hyphen used as a dash.
$text = [regex]::Replace($live, '(?s)<(script|style)\b.*?</\1>', ' ')
$text = [regex]::Replace($text, '<[^>]+>', ' ')
$text = [System.Net.WebUtility]::HtmlDecode($text)

if ($text.Contains([char]0x2014)) { $problems.Add('em dash in slide copy') }
if ($text.Contains([char]0x2013)) { $problems.Add('en dash in slide copy') }
if ($text -match '\S\s--\s\S')    { $problems.Add('double hyphen used as a dash in slide copy') }

# 3. Every slide carries data-section, and at least one data-reveal. Parse
# section attributes separately so class order, quote style, and spacing do
# not decide whether a slide is validated.
$sectionPattern = '(?is)<section\b(?<attrs>[^>]*)>(?<body>.*?)</section>'
$classPattern = '(?i)\bclass\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^\s>]+))'
$slides = [regex]::Matches($live, $sectionPattern)
$index = 0
foreach ($slide in $slides) {
    $attrs = $slide.Groups['attrs'].Value
    $class = [regex]::Match($attrs, $classPattern)
    if (-not $class.Success) { continue }
    if ($class.Groups[1].Success) { $classValue = $class.Groups[1].Value }
    elseif ($class.Groups[2].Success) { $classValue = $class.Groups[2].Value }
    else { $classValue = $class.Groups[3].Value }
    if ($classValue -notmatch '(?i)(^|\s)slide(\s|$)') { continue }

    $index++
    if ($attrs -notmatch '(?i)\bdata-section\s*=') {
        $problems.Add("slide $index has no data-section")
    }
    if ($slide.Groups['body'].Value -notmatch '(?i)\bdata-reveal\b') {
        $problems.Add("slide $index has no data-reveal element")
    }
}

# 4. Element ids are unique.
$ids = foreach ($match in [regex]::Matches($live, '(?i)\bid\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^\s>]+))')) {
    if ($match.Groups[1].Success) { $match.Groups[1].Value }
    elseif ($match.Groups[2].Success) { $match.Groups[2].Value }
    else { $match.Groups[3].Value }
}
foreach ($group in ($ids | Group-Object | Where-Object { $_.Count -gt 1 })) {
    $problems.Add("duplicate id: $($group.Name)")
}

if ($problems.Count -gt 0) {
    foreach ($problem in $problems) { Write-Output "FAIL  $problem" }
    Write-Output ''
    Write-Output "$($problems.Count) problem(s) in $deck"
    exit 1
}

Write-Output "OK  $index slides, no problems"
exit 0
