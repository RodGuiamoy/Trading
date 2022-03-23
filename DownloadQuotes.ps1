#$stockList = $(Invoke-WebRequest -Uri "https://api.pse.tools/api/stocks").Content | ConvertFrom-Json |  Select -ExpandProperty Data | Select symbol
$stockList = Get-Content -Path "$PSScriptRoot\Stocklist.txt"
$db = @()

$priceData = [xml]$(Invoke-WebRequest -Uri http://phisix-api.appspot.com/stocks.xml).Content
#$priceData
$stockList = $priceData.stocks.stock | Select Symbol

$stockList | % {
    $stock = $_.Symbol
    #$stock = $_

    $stockData = $($(Invoke-WebRequest -Uri "https://ph17.colfinancial.com/ape/colcharts/HISTORICAL/$stock.asp").Content | ConvertFrom-Json) | Select Symbol, Date, Open, High, Low, Close, Volume | Sort-Object Date -Descending
    $stockData | % {
        $_.Symbol = "PH:$stock"
    }
    Write-Host "$stock - $($stockData[0].Date)"
    $Old = Get-ChildItem -Path "$PSScriptRoot\PSE_DB\*_$stock.csv"
    If($Old.Count -gt 0){Remove-Item -Path $old.FullName -Force}

    $stockData | Export-Csv "$PSScriptRoot\PSE_DB\$($stockData[0].Date)_$stock.csv"
}
