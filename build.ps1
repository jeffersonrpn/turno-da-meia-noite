$PICO8 = "C:\Program Files (x86)\PICO-8\pico8.exe"
$GAME = "midnightshift"

Set-Location $PSScriptRoot

Write-Host ""
Write-Host "=== Exportando cartucho ===" -ForegroundColor Cyan

& $PICO8 -export "$GAME.p8.png" "$GAME.p8"

Write-Host ""
Write-Host "=== Exportando HTML ===" -ForegroundColor Cyan

& $PICO8 -export "index.html" "$GAME.p8"

Write-Host ""
Write-Host "Concluido!" -ForegroundColor Green