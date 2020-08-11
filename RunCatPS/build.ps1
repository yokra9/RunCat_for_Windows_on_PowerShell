Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)
Copy-Item "..\RunCat\resources" ".\src" -recurse -Force
Set-Location "../"
Copy-Item LICENSE .\RunCatPS\src
Copy-Item README.md .\RunCatPS\src
Compress-Archive -Path ".\RunCatPS\src\*" -DestinationPath ".\RunCatPS\build.zip" -Force