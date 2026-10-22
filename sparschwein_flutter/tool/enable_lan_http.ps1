$ErrorActionPreference = 'Stop'
$manifest = Join-Path $PSScriptRoot '..\android\app\src\main\AndroidManifest.xml'
if (-not (Test-Path $manifest)) {
  throw 'Android runner not found. Run flutter create for Android first.'
}

$text = [System.IO.File]::ReadAllText($manifest)
$attribute = 'android:usesCleartextTraffic\s*=\s*"[^"]*"'
if ([regex]::IsMatch($text, $attribute)) {
  $text = [regex]::new($attribute).Replace($text, 'android:usesCleartextTraffic="true"', 1)
} else {
  $text = [regex]::new('<application(?=\s|>)').Replace(
    $text,
    '<application android:usesCleartextTraffic="true"',
    1
  )
}
$null = [xml]$text
[System.IO.File]::WriteAllText($manifest, $text, [System.Text.UTF8Encoding]::new($false))
Write-Host 'Enabled LAN HTTP for the Android app.'
