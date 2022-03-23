$data = @()
Get-ChildItem -Path 'C:\Users\Rod Guiamoy\Desktop\Stock Screeners v2\KSCross\*.csv' | % {
    $data += Import-Csv -Path $_.Fullname
}

$data | Export-Csv 'C:\Users\Rod Guiamoy\Desktop\Stock Screeners v2\KSCrossData.csv'