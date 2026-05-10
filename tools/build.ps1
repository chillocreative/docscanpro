# DocScan AR build helper.
#
# C: is tight on this machine, so we redirect the Gradle cache to D:\.gradle
# for *this project only*. Run:  .\tools\build.ps1 [debug|release|clean]
#
# Usage:
#   .\tools\build.ps1 debug      # flutter build apk --debug
#   .\tools\build.ps1 release    # flutter build apk --release
#   .\tools\build.ps1 clean      # flutter clean
#   .\tools\build.ps1 analyze    # flutter analyze
#   .\tools\build.ps1 test       # flutter test
#   .\tools\build.ps1 run        # flutter run

$env:GRADLE_USER_HOME = 'D:\.gradle'
$env:TMP = 'D:\.tmp'
$env:TEMP = 'D:\.tmp'
# Flutter is installed at D:\TEMPORARY FOLDER\flutter\flutter — the space
# breaks Dart's native-asset hook runner. D:\flt is a junction to the same
# install but with no spaces, which the hook runner can shell to safely.
$env:Path = "D:\flt\bin;" + (
  $env:Path -replace [regex]::Escape("D:\TEMPORARY FOLDER\flutter\flutter\bin") + ';?',''
)
Write-Host "GRADLE_USER_HOME = $env:GRADLE_USER_HOME"
Write-Host "TMP / TEMP       = $env:TMP"
Write-Host "Flutter on PATH  = D:\flt\bin (junction)"

$cmd = if ($args.Count -gt 0) { $args[0] } else { 'debug' }

switch ($cmd) {
    'debug'   { flutter build apk --debug }
    'release' { flutter build apk --release }
    'clean'   { flutter clean }
    'analyze' { flutter analyze }
    'test'    { flutter test }
    'run'     { flutter run }
    default   { Write-Error "Unknown command: $cmd"; exit 1 }
}
