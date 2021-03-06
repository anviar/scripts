param( [string]$file );

Write-Host (
"Выберите алгоритм хэширования:
    1. MD5
    2. SHA1
    3. SHA256
Нажмите любую другую кнопку для выхода..."
)
$key=$host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown").Character;
switch ($key) {
    1 { $digest="MD5"}
    2 { $digest="SHA1"}
    3 { $digest="SHA256"}
    default { exit 0 }
}

[IO.Directory]::SetCurrentDirectory((Convert-Path(Get-Location -PSProvider FileSystem)))
$algo = [System.Security.Cryptography.HashAlgorithm]::Create("$digest")
$stream = New-Object System.IO.FileStream($file, [System.IO.FileMode]::Open)
$HashStringBuilder = New-Object System.Text.StringBuilder
$algo.ComputeHash($stream) | % { [void] $HashStringBuilder.Append($_.ToString("x2")) }
$summ=$HashStringBuilder.ToString()
$stream.Dispose()
Write-Host ("$digest",": $summ")

Write-Host ("Скопировать в буфер обмена[д] или сравнить[c]? Для выхода нажмите любую другую клавишу...")
$key=$host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown").VirtualKeyCode;
if (( $key -eq 76 ) -or ( $key -eq 89 )) {
  echo "$summ"|clip
}
elseif ( $key -eq 67 ) {
   $c_summ=Read-Host ("Введите контрольную сумму для проверки")
   if ( $summ -match $c_summ ) {
    Write-Host ("Суммы совпадают.") -ForegroundColor Green
   } else {
    Write-Host ("Суммы не совпадают!") -ForegroundColor Red
   }
   Write-Host ("Нажмите любую кнопку для выхода...")
   $host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
}
else { exit 0 }

