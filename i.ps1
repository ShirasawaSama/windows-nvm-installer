$URL = 'https://api.github.com/repos/coreybutler/nvm-windows/releases/latest'
$CWD = Get-Location
$CACHE = Join-Path $CWD 'nvm_cache'
$taobao = "node_mirror: http://npm.taobao.org/mirrors/node/`r`nnpm_mirror: https://npm.taobao.org/mirrors/npm/`r`n"

$currentWi = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentWp = [Security.Principal.WindowsPrincipal]$currentWi

if(-not $currentWp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  $boundPara = ($MyInvocation.BoundParameters.Keys | ForEach-Object {
     '-{0} {1}' -f $_, $MyInvocation.BoundParameters[$_] }) -join ' '
  $currentFile = (Resolve-Path $MyInvocation.InvocationName).Path
  $fullPara = $boundPara + ' ' + $args -join ' '
  Start-Process "$psHome\powershell.exe" -ArgumentList "$currentFile $fullPara" -verb runas
  exit
}
function rdf ($path) { Remove-Item $path -Recurse -Force -ErrorAction 'SilentlyContinue' }
function success ($str) { Write-Host -ForegroundColor 10 $str }
function info ($str) { Write-Host -ForegroundColor 14 "`n$str`n" }
function mkd ($path) { if (-not (Test-Path $path)) { mkdir $path | Out-Null }}
function err ($str) {
  Write-Host -ForegroundColor 12 "`nError: $str`n"
  exit
}
function read ($str, $def = '') {
  Write-Host -NoNewline -ForegroundColor 10 '? '
  Write-Host -NoNewline $str
  $text = ' ('
  $boolStr = 'n'
  $bool = $def.getType().Name -eq 'Boolean'
  if ($bool) {
    if ($def) { $text += 'Y/n' } else {
      $boolStr = 'y'
      $text += 'y/N'
    }
  } else {
    if ($def -ne '') { $text += $def }
  }
  Write-Host -NoNewline -ForegroundColor 11 ($text + ')')
  Write-Host -NoNewline ': '
  $text = Read-Host
  if ($bool) {
    if ($text -ine $boolStr) { $text = $def } else { $text = !$def }
  } else {
    if (!$text) { $text = $def }
  }
  return $text
}

info 'Thank you for your using, and then me will guide you to install of NVM!'
mkd $CACHE

if ($env:NVM_HOME) {
  $nvmHome = Join-Path $env:NVM_HOME 'nvm.exe'
  if ((Test-Path $nvmHome) -and
    (-not (read 'You have installed NVM, do you need to reinstall it?' $true))) {
    exit
  }
}

$data = (Invoke-WebRequest $URL).Content | ConvertFrom-Json
$accet = $data.assets | Where-Object { $_.name -eq 'nvm-noinstall.zip' }
if (!$accet) { err 'Unable to connect to the network!' }

$url = $accet.browser_download_url
$des = Join-Path $CACHE $accet.id.toString()
$target = $des + '.zip'

success 'Start installation.'

$nvmPath = Join-Path $des 'nvm.exe'
if (-not (Test-Path $nvmPath)) {
  if (-not (Test-Path $target)) {
    info "NVM-latest is about to start downloading......`n$url"
    Invoke-WebRequest -uri $url -OutFile $target
    if (-not (Test-Path $target)) { err 'Failed to download!' }
    Unblock-File $target
  }

  info 'Unzipping...'

  mkd $des
  $shellApp = New-Object -ComObject Shell.Application
  $files = $shellApp.nameSpace($target).items()
  $files | ForEach-Object {
    $file = $des + '\' + $_.name
    if (Test-Path $file) { Remove-Item $file -Force -Recurse }
  }
  $shellApp.nameSpace($des).copyHere($files)
  if (-not (Test-Path $nvmPath)) {
    rdf $des
    rdf $target
    err 'Download failed, please retry.'
  }
  success 'Unzipped!'
}

$nodeVersion = read 'Enter the version of the Node.js to install' 'latest'

$path = read 'Enter the installation position of NVM<NO SPACE>' 'C:\nvm'
if ($path.contains(' ')) { err 'Path can not contain spaces!' }
if (Test-Path $path) {
  info 'Path cleaning...'
  Remove-Item ($path + '\*') -Force -Recurse
  success 'cleaned!'
}

$node = read 'Enter the installation position of Node.js' 'C:\Program Files\nodejs'
if (Test-Path $node) {
  if ((Get-Childitem $node -ErrorAction 'SilentlyContinue').length) {
    if (read 'You have installed Node.js, do you want to uninstall it?' $true) {
      info 'Node.js uninstalling...'
      Get-Process | Where-Object { $_.processName.contains('node') } | Stop-Process -Force
      rdf $node
      rdf 'C:\Users\Administrator\AppData\Roaming\npm'
      success 'Uninstalled.'
    } else { err 'Please choose other paths to install Node.js.' }
  } else { rdf $node }
}

$mirror = read 'Using the TaoBao NPM Registry source?' $true

info 'Files copping...'
mkd $path
'elevate.cmd', 'elevate.vbs', 'nvm.exe', 'LICENSE' | ForEach-Object {
  Copy-Item (Join-Path $des $_ ) (Join-Path $path $_ ) }

$arch = '32'
if ([Environment]::Is64BitOperatingSystem) { $arch = '64'}

$setting = "root: $path`r`npath: $node`r`narch: $arch`r`nproxy: none`r`n"
if ($mirror) { $setting += $taobao }

$setting | Out-File (Join-Path $path 'settings.txt') -Force -Encoding 'Default'
success 'File copied.'

[Environment]::SetEnvironmentVariable('NVM_HOME', $path)
[Environment]::SetEnvironmentVariable('NVM_SYMLINK', $node)
[Environment]::SetEnvironmentVariable('NVM_HOME', $path, 'Machine')
[Environment]::SetEnvironmentVariable('NVM_SYMLINK', $node, 'Machine')
$p = $env:PATH
if (-not ($p.contains($path) -or $p.contains('%NVM_HOME%'))) { $p += ';%NVM_HOME%' }
if (-not ($p.contains($node) -or $p.contains('%NVM_SYMLINK%'))) { $p += ';%NVM_SYMLINK%' }
if ($env:PATH -ne $p) { [Environment]::SetEnvironmentVariable('PATH', $p, 'Machine') }

info "Installing Node.js v$nodeVersion..."
$nvm = Join-Path $path 'nvm.exe'
Start-Process -FilePath $nvm -ArgumentList "install $nodeVersion" -NoNewWindow -Wait -WorkingDirectory $path
Start-Process -FilePath $nvm -ArgumentList "use $nodeVersion" -NoNewWindow -Wait -WorkingDirectory $path
success 'Node.js has been installed.'

$npm = Join-Path $node 'npm.cmd'
if ($mirror) {
  info 'Installing NRM...'
  Start-Process -FilePath $npm -ArgumentList 'install -g nrm --registry=https://registry.npm.taobao.org' -NoNewWindow -Wait
  Start-Process -FilePath (Join-Path $node 'nrm.cmd') -ArgumentList 'use taobao' -NoNewWindow -Wait
  success 'NRM has been installed.'
}

$nodeExe = Join-Path $node 'node.exe'
Write-Host -NoNewline -ForegroundColor 11 'Nodejs test: '
Start-Process -FilePath $nodeExe -ArgumentList "-e `"console.log('Hello World!')`"" -NoNewWindow -Wait
Write-Host -NoNewline -ForegroundColor 11 'Nodejs version: '
Start-Process -FilePath $nodeExe -ArgumentList '-v' -NoNewWindow -Wait
Write-Host -NoNewline -ForegroundColor 11 'NPM version: '
Write-Host -NoNewline 'v'
Start-Process -FilePath $npm -ArgumentList '-v' -NoNewWindow -Wait

success "`nDone.`n"
