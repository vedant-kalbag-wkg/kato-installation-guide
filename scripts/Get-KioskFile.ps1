<#
  Download a file into a folder on the kiosk. Run as SYSTEM from the
  N-central Script/Software Repository, against one kiosk or many.
  Command-line parameters:
    -Url '<https link>' -Destination '<folder>' [-FileName '<name>']
  Replaces any existing copy, so re-run it whenever the file is updated.
#>

param(
  [string]$Url,
  [string]$Destination,
  [string]$FileName # defaults to the name at the end of the URL
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue' # the progress bar slows large downloads badly on PowerShell 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
  if (-not $Url -or -not $Destination) {
    throw "Usage: -Url '<https link>' -Destination '<folder>' [-FileName '<name>']"
  }
  if (-not $FileName) { $FileName = [IO.Path]::GetFileName(([uri]$Url).LocalPath) }
  if (-not $FileName) { throw "No file name in the URL; pass -FileName" }

  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  $target = Join-Path $Destination $FileName
  $partial = "$target.download"

  Invoke-WebRequest -Uri $Url -OutFile $partial -UseBasicParsing
  Move-Item -LiteralPath $partial -Destination $target -Force

  $file = Get-Item -LiteralPath $target
  $hash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
  Write-Host ("=== SUCCESS on {0}: {1} ({2:n0} KB, SHA256 {3}) ===" -f $env:COMPUTERNAME, $file.FullName, ($file.Length / 1KB), $hash)
  exit 0
}
catch {
  if ($partial) { Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue }
  Write-Host ("=== FAILED on {0} === {1}" -f $env:COMPUTERNAME, $_.Exception.Message)
  exit 1
}
