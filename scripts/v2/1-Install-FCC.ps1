<#
  EXPERIMENTAL v2, step 1 of 4 - not yet in the guide.
  Appendix A (Building the machine - FreedomPay FCC) for one region:
    1. Install FCC - skipped if its services already exist
    2. Apply the WeKnow configuration:
       a. delete HKEY_LOCAL_MACHINE\SOFTWARE\Freedompay\Atlas\PAL
       b. copy the region's config into the FCC folder, and run its PAL package
       c. restart FreewayServerService, then FreewayClientService
    3. Verify the build: both services Running; the log shows Lane Open,
       Successfully pushed and PalWriteSucceeded
  A rerun skips 2a, the PAL package and 3's log check if this region's package is
  the last one run here, and restarts the services only if the config changed.
  Run as SYSTEM, with the PDQ plugged in. Next: 2-Download-App.txt
#>

$Region = '{UK|DE|ES|PT}'
$FccFeedUrl = 'https://wkgdevstore.blob.core.windows.net/kiosk/FCC/'

$regions = @{ # folders as uploaded to the feed
  UK = @{ Config = 'UK_PAL_and_Config/live_uk_config'; Pal = 'UK_PAL_and_Config/Lane3600TS_UPP07_96_00_0005_UK_EMV_OfflinePIN_A_20241003' }
  DE = @{ Config = 'DE_PAL_and_Config/live_de_config'; Pal = 'DE_PAL_and_Config/Lane3600TS_UPP07_96_00_0005_DE_EMV_OnlinePIN_NoDebit_A_20240814' }
  ES = @{ Config = 'ES_PAL_and_Config/live_es_confiig/live_eu_ES_confiig'; Pal = 'ES_PAL_and_Config/Lane3600TS_UPP07_96_00_0005_ES_EMV_OnlinePIN_NoDebit_A_20250328' }
  PT = @{ Config = 'PT_PAL_and_Config/live_pt_config'; Pal = 'PT_PAL_and_Config/Lane3600TS_UPP07_96_00_0005_PT_EMV_OnlinePIN_NoDebit_A_20240814' }
}
$configFiles = 'FreeWayClientService.exe.config', 'FreeWayServerService.exe.config'
$palFiles = 'config-regional.upp-L3600TS.palpkg', 'profile.dat', 'updateNewPal.bat'

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue' # the progress bar slows large downloads badly on PowerShell 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$start = Get-Date
$summary = [ordered]@{}
$script:warnings = @()
$script:current = ''

function Stamp { "[{0,5:n1}s]" -f ((Get-Date)-$start).TotalSeconds }
function Step($m) { $script:current = $m; Write-Host "$(Stamp) $m" }
function Ok($m) { Write-Host "$(Stamp) OK $m" -ForegroundColor Green }
function Warn($m) { $script:warnings += $m; Write-Host "$(Stamp) ! $m" -ForegroundColor Yellow }
function Show-Summary {
  Write-Host 'Summary:'
  foreach ($k in $summary.Keys) { Write-Host ("  {0,-12} {1}" -f $k, $summary[$k]) }
  foreach ($w in $script:warnings) { Write-Host "  Warning      $w" -ForegroundColor Yellow }
}

# Downloads <feed>/<relative path> into $dir; each path segment is URL-escaped
function Get-FccFile($rel, $dir) {
  $url = $FccFeedUrl.TrimEnd('/') + '/' + ((($rel -split '/') | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/')
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $target = Join-Path $dir (Split-Path -Leaf $rel)
  Invoke-WebRequest -Uri $url -OutFile "$target.download" -UseBasicParsing
  Move-Item -LiteralPath "$target.download" -Destination $target -Force
  Ok ("Downloaded {0} ({1:n0} KB)" -f $rel, ((Get-Item -LiteralPath $target).Length / 1KB))
  $target
}

# The service the guide names, e.g. FreewayServerService = display name "Freeway Server Service" (service FCCServerSvc)
function Get-FccService($guideName) {
  Get-Service | Where-Object { ($_.DisplayName -replace ' ') -eq $guideName } | Select-Object -First 1
}

# The text of a log file from byte $from on (from the start if it was rotated), read while FCC still has it open
function Get-LogTextSince($path, [long]$from) {
  $s = [IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
  try {
    if ($s.Length -lt $from) { $from = 0 }
    $null = $s.Seek($from, 'Begin')
    (New-Object IO.StreamReader($s)).ReadToEnd()
  } finally { $s.Dispose() }
}

try {
  $names ='Region', 'FccFeedUrl'
  for ($i = 0; $i -lt $args.Count; $i += 2) {
    $name = "$($args[$i])".TrimStart('-').TrimEnd(':')
    if ($name -notin $names) { throw "Unknown parameter '$($args[$i])'. Use: -$($names -join ', -')" }
    Set-Variable -Name $name -Value "$($args[$i + 1])"
  }

  Write-Host ""
  Write-Host "=== WKG Kiosk v2 step 1 - FreedomPay FCC ($Region) on $env:COMPUTERNAME ==="
  Write-Host ""

  Step 'Validating parameters'
  if ($Region -cnotin $regions.Keys) { throw "Region must be one of $($regions.Keys -join ', '), not '$Region'" }
  if ($FccFeedUrl -notmatch '^https://\S+$') { throw "FccFeedUrl is not an https:// link: '$FccFeedUrl'" }
  $src = $regions[$Region]
  $fccDir = 'C:\Program Files (x86)\FreedomPay\FreewayCommerceConnect'
  $logDir = 'C:\ProgramData\FreedomPay\Freeway Commerce Connect\log'
  $palKey = 'HKLM\SOFTWARE\Freedompay\Atlas\PAL'
  $markKey = 'HKLM\SOFTWARE\WeKnow\Kiosk' # ours: PalPackage = the last package run here, with the services back up
  $work = Join-Path ([IO.Path]::GetTempPath()) "WKG-FCC-$Region"
  Ok "Region $Region"

  # --- 1. Install FCC ----------------------------------------------------------
  Step 'Checking FreedomPay FCC'
  $server = Get-FccService FreewayServerService
  $client = Get-FccService FreewayClientService
  if ($server -and $client) {
    Ok 'FCC already installed - skipping the install'
    $summary['FCC'] = 'already installed (not reinstalled)'
  } else {
    $fccExe = Get-FccFile 'FCC_5.3.2.15/FreewayCommerceConnect.exe' $work
    $msiLog = Join-Path $work 'fcc-install.log'
    Remove-Item -LiteralPath $msiLog -Force -ErrorAction SilentlyContinue

    Step 'Installing FCC 5.3.2.15 silently with the Appendix A choices (max 10 min)'
    # The launcher hands its arguments to Windows Installer. Appendix A's choices, as a logged manual install recorded them:
    #   SKIP_AMA_CHECKS=true  skip the RUS activation
    #   ADDLOCAL=...          Custom: Freeway POI Drivers (USBDriver) + Freeway Server Service (FCCServer); FCCClient, WixSwidTag came with them
    $p = Start-Process -FilePath $fccExe -ArgumentList "/qn /l*v `"$msiLog`" SKIP_AMA_CHECKS=true ADDLOCAL=FCCClient,USBDriver,FCCServer,WixSwidTag" -PassThru
    $null = $p.Handle # without it, ExitCode can come back empty on PowerShell 5.1
    if (-not $p.WaitForExit(600000)) { throw 'FCC installer still running after 10 min - did its activation window open?' }
    # the launcher can exit before Windows Installer does, so the log's last line is the result
    $by = (Get-Date).AddMinutes(10)
    do {
      $text = if (Test-Path -LiteralPath $msiLog) { Get-Content -LiteralPath $msiLog -Raw } else { '' }
      if ($text -match '-- Installation (completed successfully|failed)') { break }
      Start-Sleep 5
    } while ((Get-Date) -lt $by)
    if ($text -notmatch '-- Installation completed successfully') { throw "FCC install failed, exit $($p.ExitCode) (log: $msiLog)" }
    $server = Get-FccService FreewayServerService
    $client = Get-FccService FreewayClientService
    if (-not ($server -and $client)) {
      throw 'FCC installer finished but FreewayServerService / FreewayClientService do not exist'
    }
    Ok 'FCC installed'
    $summary['FCC'] = 'installed 5.3.2.15'
  }
  $server = $server.Name
  $client = $client.Name

  Step "Downloading the $Region config and PAL package"
  $configDir = Join-Path $work 'config'
  $pkg = Split-Path -Leaf $src.Pal
  $palDir = Join-Path $work $pkg # local folder holding only the package
  Remove-Item -LiteralPath $palDir -Recurse -Force -ErrorAction SilentlyContinue
  foreach ($f in $configFiles) { $null = Get-FccFile "$($src.Config)/$f" $configDir }
  foreach ($f in $palFiles) { $null = Get-FccFile "$($src.Pal)/$f" $palDir }

  Step 'Checking which PAL package the terminal last took'
  # /reg:64 is the key Registry Editor shows, whatever the bitness of this shell
  $applied = foreach ($l in @(cmd /c "reg query `"$markKey`" /v PalPackage /reg:64 2>nul")) { if ($l -match '^\s*PalPackage\s+REG_SZ\s+(.+?)\s*$') { $Matches[1] } }
  $runPal = $applied -ne $pkg
  if ($runPal) { Ok $(if ($applied) { "$applied - updating to $pkg" } else { "none recorded - running $pkg" }) }
  else { Ok "$pkg already taken - not running it again" }

  # --- 2a. Delete the PAL registry key -------------------------------------------
  if ($runPal) {
    Step "Deleting HKEY_LOCAL_MACHINE\SOFTWARE\Freedompay\Atlas\PAL"
    cmd /c "reg query `"$palKey`" /reg:64 >nul 2>&1"
    if ($LASTEXITCODE -eq 0) {
      cmd /c "reg delete `"$palKey`" /f /reg:64 >nul 2>&1"
      cmd /c "reg query `"$palKey`" /reg:64 >nul 2>&1"
      if ($LASTEXITCODE -eq 0) { throw "Could not delete $palKey" }
      $summary['Registry'] = 'deleted HKEY_LOCAL_MACHINE\SOFTWARE\Freedompay\Atlas\PAL'
    } else {
      $summary['Registry'] = 'Atlas\PAL key was not present'
    }
    Ok $summary['Registry']
  }

  # --- 2b. Copy the config, run the PAL package -----------------------------------
  Step "Copying the $Region config into $fccDir"
  $changed = @($configFiles | Where-Object {
    $dest = Join-Path $fccDir $_
    -not (Test-Path -LiteralPath $dest) -or (Get-FileHash -LiteralPath $dest).Hash -ne (Get-FileHash -LiteralPath (Join-Path $configDir $_)).Hash
  })
  if ($changed) {
    foreach ($f in $configFiles) { Copy-Item -LiteralPath (Join-Path $configDir $f) -Destination $fccDir -Force }
    Ok "$($configFiles -join ', ') copied"
    $summary['Config'] = "$Region ($($src.Config))"
  } else {
    Ok 'Already in place'
    $summary['Config'] = "$Region ($($src.Config)), already in place"
  }

  if ($runPal) {
    Step "Running the $Region PAL package"
    # FCC appends to its log all day, so only what is written from here on counts.
    # From here, not from the restart below: the terminal can take the package while the .bat runs
    $logSizes = @{}
    Get-ChildItem -LiteralPath $logDir -File -ErrorAction SilentlyContinue | ForEach-Object { $logSizes[$_.FullName] = $_.Length }
    $palStarted = Get-Date
    Push-Location -LiteralPath $palDir
    try { cmd /c "updateNewPal.bat <nul" | Out-Host; $code = $LASTEXITCODE } finally { Pop-Location } # <nul: unattended, nobody to press a key
    if ($code -ne 0) { throw "updateNewPal.bat exited with $code" }
    Ok 'PAL package run'
    $summary['PAL'] = $pkg
  } else {
    $summary['PAL'] = "$pkg, already taken (not run again; to force it, delete PalPackage in HKEY_LOCAL_MACHINE\SOFTWARE\WeKnow\Kiosk)"
  }

  # --- 2c. Restart the services in order ------------------------------------------
  if ($runPal -or $changed) {
    Step "Restarting $server, then $client"
    Restart-Service -Name $server -Force
    Restart-Service -Name $client -Force
    Ok 'Services restarted'

    # --- 3. Verify the build -------------------------------------------------------
    Step 'Checking both services are Running'
    $stopped = @($server, $client | Where-Object { (Get-Service -Name $_).Status -ne 'Running' })
    if ($stopped) { throw "Not running: $($stopped -join ', ')" }
    $summary['Services'] = 'FreewayServerService, FreewayClientService Running'
    Ok 'Both Running'
  } else {
    $summary['Services'] = 'not restarted - PAL package and config unchanged'
  }

  if ($runPal) {
    # recorded now, not after the log check: on a terminal that already has the package FCC may never log the push
    cmd /c "reg add `"$markKey`" /v PalPackage /t REG_SZ /d `"$pkg`" /f /reg:64 >nul"
    if ($LASTEXITCODE -ne 0) { Warn "Could not record $pkg in $markKey - the next run will apply it again" }

    Step 'Waiting for Lane Open, Successfully pushed, PalWriteSucceeded in the FCC log (max 120s)'
    $want = 'Lane Open', 'Successfully pushed', 'PalWriteSucceeded'
    $by = (Get-Date).AddSeconds(120)
    do {
      $text = (Get-ChildItem -LiteralPath $logDir -File -ErrorAction SilentlyContinue | Where-Object LastWriteTime -ge $palStarted |
        ForEach-Object { Get-LogTextSince $_.FullName ([long]$logSizes[$_.FullName]) }) -join "`n"
      $missing = @($want | Where-Object { $text -notmatch [regex]::Escape($_) })
      if ($missing) { Start-Sleep 3 }
    } while ($missing -and (Get-Date) -lt $by)
    if ($missing) {
      Warn "FCC log has no $($missing -join ', ') - check the PDQ, then Appendix A 'When the build goes wrong'"
      $summary['Log'] = 'checks INCOMPLETE - do not hand the machine on'
    } else {
      $summary['Log'] = 'Lane Open, Successfully pushed, PalWriteSucceeded'
    }
  } else {
    $summary['Log'] = 'not checked - PAL package not run again'
  }

  Write-Host ""
  Write-Host ("=== SUCCESS in {0:n1}s ===" -f ((Get-Date)-$start).TotalSeconds) -ForegroundColor Green
  Show-Summary
  Write-Host "Next: 2-Download-App.txt"
  Write-Host ""
  exit 0
}
catch {
  Write-Host ""
  Write-Host ("=== FAILED after {0:n1}s ===" -f ((Get-Date)-$start).TotalSeconds) -ForegroundColor Red
  Write-Host $_.Exception.Message -ForegroundColor Red
  $summary['Failed at'] = $script:current
  Show-Summary
  Write-Host ""
  exit 1
}
