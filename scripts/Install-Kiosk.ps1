<#
  Deploy WKG Kiosk. Run as SYSTEM.
  Per-user install into the target account's profile via a scheduled task.
  Picks the highest-versioned installer present in the folder.
#>

$TargetUser     = 'SelfBooker'
$InstallerDir   = 'C:\Users\SelfBooker\Documents'
$KioskId        = '{KIOSK_ID_FROM_COMMAND_CENTRE}'
$WorkstationId  = '{WKG-POS-XXX}'
$ApiKey         = '{API_KEY_FROM_COMMAND_CENTRE}'
$RequireVersion = $null      # e.g. '1.1.1' to pin; $null accepts the newest found

$ErrorActionPreference = 'Stop'
$task  = 'KioskInstall'
$start = Get-Date

function Step($m) { Write-Host ("[{0,5:n1}s] {1}"       -f ((Get-Date)-$start).TotalSeconds, $m) }
function Ok($m)   { Write-Host ("[{0,5:n1}s]   OK  {1}" -f ((Get-Date)-$start).TotalSeconds, $m) -ForegroundColor Green }
function Warn($m) { Write-Host ("[{0,5:n1}s]   !   {1}" -f ((Get-Date)-$start).TotalSeconds, $m) -ForegroundColor Yellow }

try {
  Write-Host ""
  Write-Host "=== WKG Kiosk install: $WorkstationId on $env:COMPUTERNAME ==="
  Write-Host ""

  Step 'Validating parameters'
  $checks = @{
    KioskId       = @($KioskId,       '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')
    WorkstationId = @($WorkstationId, '^[A-Za-z0-9][A-Za-z0-9-]{1,14}$')
    ApiKey        = @($ApiKey,        '^kcs_[A-Za-z0-9_-]{24,}$')
  }
  foreach ($k in $checks.Keys) {
    $val, $pattern = $checks[$k]
    if ($val -cnotmatch $pattern) { throw "$k is malformed: '$val'" }
  }
  Ok 'Parameters well-formed'

  Step "Locating installer in $InstallerDir"
  if (-not (Test-Path -LiteralPath $InstallerDir)) { throw "Folder not found: $InstallerDir" }

  $candidates = Get-ChildItem -LiteralPath $InstallerDir -Filter 'Kiosk*Setup*.exe' -File -ErrorAction SilentlyContinue |
    ForEach-Object {
      if ($_.Name -match '(\d+\.\d+\.\d+)') {
        [pscustomobject]@{ Path = $_.FullName; Version = [version]$Matches[1]; Name = $_.Name }
      }
    } | Sort-Object Version -Descending

  if (-not $candidates) { throw "No Kiosk installer found in $InstallerDir" }

  $chosen        = @($candidates)[0]
  $InstallerPath = $chosen.Path
  Ok "Selected $($chosen.Name)  (v$($chosen.Version))"

  if (@($candidates).Count -gt 1) {
    $older = (@($candidates) | Select-Object -Skip 1 | ForEach-Object { $_.Name }) -join ', '
    Warn "$(@($candidates).Count) installers present. Ignoring: $older"
  }

  $fileVer = (Get-Item -LiteralPath $InstallerPath).VersionInfo.ProductVersion
  if ($fileVer -and ([version]$fileVer) -ne $chosen.Version) {
    Warn "Filename says v$($chosen.Version) but file metadata says v$fileVer"
  }
  if ($RequireVersion -and $chosen.Version -ne [version]$RequireVersion) {
    throw "Expected v$RequireVersion, found v$($chosen.Version)"
  }

  Step "Checking target user: $TargetUser"
  if (-not (Get-LocalUser -Name $TargetUser -ErrorAction SilentlyContinue)) {
    throw "No local user '$TargetUser'"
  }
  if ((quser 2>$null) -match "\s$TargetUser\s") { Ok 'User present and logged on' }
  else { Warn 'User exists but is not logged on - per-user install may misbehave' }

  Step 'Registering scheduled task'
  $argLine = "/S /KIOSKID=$KioskId /WORKSTATIONID=$WorkstationId /APIKEY=$ApiKey"
  Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false
  Register-ScheduledTask -TaskName $task `
    -Action    (New-ScheduledTaskAction -Execute $InstallerPath -Argument $argLine) `
    -Principal (New-ScheduledTaskPrincipal -UserId $TargetUser -LogonType Interactive -RunLevel Limited) `
    -Force | Start-ScheduledTask
  Ok 'Task registered and started'

  Step 'Waiting for installer to start (max 15s)'
  $by = (Get-Date).AddSeconds(15)
  do { Start-Sleep 1 }
  while ((Get-ScheduledTask -TaskName $task).State -ne 'Running' -and (Get-Date) -lt $by)

  $info = Get-ScheduledTask -TaskName $task | Get-ScheduledTaskInfo
  if ((Get-ScheduledTask -TaskName $task).State -ne 'Running' -and $info.LastTaskResult -ne 0) {
    throw ("Task did not start. LastTaskResult 0x{0:X}" -f $info.LastTaskResult)
  }
  Ok 'Installer running'

  Step 'Waiting for task to complete (max 120s)'
  $by = (Get-Date).AddSeconds(120)
  do { Start-Sleep 2 }
  while ((Get-ScheduledTask -TaskName $task).State -eq 'Running' -and (Get-Date) -lt $by)
  if ((Get-ScheduledTask -TaskName $task).State -eq 'Running') { Warn 'Task still running at timeout' }
  else { Ok 'Task finished' }

  Step 'Waiting for setup process to exit (max 60s)'
  $setupName = [System.IO.Path]::GetFileNameWithoutExtension($InstallerPath)
  $by = (Get-Date).AddSeconds(60)
  while ((Get-Process -Name $setupName -ErrorAction SilentlyContinue) -and (Get-Date) -lt $by) {
    Start-Sleep 2
  }
  if (Get-Process -Name $setupName -ErrorAction SilentlyContinue) {
    Warn 'Setup still alive (likely session 0, no desktop) - stopping it'
    Get-Process -Name $setupName -ErrorAction SilentlyContinue | Stop-Process -Force
  } else {
    Ok 'Setup exited cleanly'
  }
  Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false

  Step 'Verifying install'
  $exe  = "C:\Users\$TargetUser\AppData\Local\Programs\Kiosk\Kiosk.exe"
  $json = "C:\Users\$TargetUser\AppData\Roaming\WKG Kiosk\kiosk-identity.json"

  if (-not (Test-Path -LiteralPath $exe)) { throw "Kiosk.exe missing at $exe" }
  Ok ("Kiosk.exe present ({0} MB)" -f [math]::Round((Get-Item -LiteralPath $exe).Length / 1MB))

  if (-not (Test-Path -LiteralPath $json)) { throw "Not provisioned, no file at $json" }
  Ok 'Identity file written'

  $cfg = Get-Content -LiteralPath $json -Raw | ConvertFrom-Json
  $bad = @()
  if ($cfg.kioskId       -cne $KioskId)       { $bad += "kioskId='$($cfg.kioskId)'" }
  if ($cfg.workstationId -cne $WorkstationId) { $bad += "workstationId='$($cfg.workstationId)'" }
  if ($bad) { throw "Config mismatch: $($bad -join '; ')" }

  Ok "Identity matches: $WorkstationId"
  Ok "Printer: $($cfg.printerDestination)"

  Write-Host ""
  Write-Host ("=== SUCCESS in {0:n1}s  (v{1}) ===" -f ((Get-Date)-$start).TotalSeconds, $chosen.Version) -ForegroundColor Green
  Write-Host ""
  exit 0
}
catch {
  Write-Host ""
  Write-Host ("=== FAILED after {0:n1}s ===" -f ((Get-Date)-$start).TotalSeconds) -ForegroundColor Red
  Write-Host $_.Exception.Message -ForegroundColor Red
  Write-Host ""
  Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false
  exit 1
}
