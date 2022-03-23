$data = @()
Get-ChildItem -Path 'C:\Users\Rod Guiamoy\Desktop\Stock Screeners v2\Nimoku - Copy (3)\*.csv' | % {
    $data += Import-Csv -Path $_.Fullname
}

$data | Export-Csv 'C:\Users\Rod Guiamoy\Desktop\Stock Screeners v2\NimokuData.csv'