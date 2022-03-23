#cls
$BreakWatch = @()
$BreakWatch += "‼️NEW HIGHS"
#$stockList = $(Invoke-WebRequest -Uri "https://api2.pse.tools/api/quotes").Content | ConvertFrom-Json | Select -ExpandProperty Data | gm | Select Name -Skip 4
$stockList = $(Invoke-WebRequest -Uri "https://api.pse.tools/api/stocks").Content | ConvertFrom-Json |  Select -ExpandProperty Data | Select symbol

$stockList | % {
    $stock = $_.Symbol
    #$stock
    #$stockData = $($(Invoke-WebRequest -Uri "https://ph24.colfinancial.com/ape/colcharts/HISTORICAL/$stock.asp").Content | ConvertFrom-Json) | Select Date, Open, High, Low, Close | Sort-Object Date -Descending
    #$stockData[0].Date
    $stockData = Import-Csv -Path "$PSScriptRoot\PSE_DB\*_$stock.csv"

    $breakouts = "$stock - "
    $currentprice = [double]$($stockData[0]).Close

    #$10DayHigh = $($stocksData | Where-Object Symbol -eq $_ | Select High -First 10 | Measure-Object -Property High -Maximum).Maximum
    $10DayHighPrev = $($stockData | Select High -First 11 | Select -Skip 1 | Measure-Object -Property High -Maximum).Maximum

    #$20DayHigh = $($stocksData | Where-Object Symbol -eq $_ | Select High -First 20 | Measure-Object -Property High -Maximum).Maximum
    $20DayHighPrev = $($stockData | Select High -First 21 | Select -Skip 1 | Measure-Object -Property High -Maximum).Maximum

    #$60DayHigh = $($stocksData | Where-Object Symbol -eq $_ | Select High -First 60 | Measure-Object -Property High -Maximum).Maximum
    $60DayHighPrev = $($stockData | Select High -First 61 | Select -Skip 1 | Measure-Object -Property High -Maximum).Maximum

    #$100DayHigh = $($stocksData | Where-Object Symbol -eq $_ | Select High -First 100 | Measure-Object -Property High -Maximum).Maximum
    $100DayHighPrev = $($stockData | Select High -First 101 | Select -Skip 1 | Measure-Object -Property High -Maximum).Maximum

    #$120DayHigh = $($stocksData | Where-Object Symbol -eq $_ | Select High -First 120 | Measure-Object -Property High -Maximum).Maximum
    $120DayHighPrev = $($stockData | Select High -First 121 | Select -Skip 1 | Measure-Object -Property High -Maximum).Maximum
    
    If($currentprice -gt $10DayHighPrev){
        $breakouts += "10/"
    }

    If($currentprice -gt $20DayHighPrev){
        $breakouts += "20/"
    }

    If($currentprice -gt $60DayHighPrev){
        $breakouts += "60/"
    }

    If($currentprice -gt $100DayHighPrev){
        $breakouts += "100/"
    }

    If($currentprice -gt $120DayHighPrev){
        $breakouts += "120/"
    }

    $breakouts += " day breakout!"

    If($breakouts -ne "$stock -  day breakout!"){
        $breakouts

        $Breakwatch += $breakouts
    }

    

}

$Breakwatch > "$PSScriptRoot\Breakwatch\Breakwatch_$($([datetime]$stockData[0].Date).ToString('MMddyyyy')).txt"
#$Breakwatch | Export-Csv "$PSScriptRoot\BreakWatch\BreakWatch_$($([datetime]$stockData[0].Date).ToString('MMddyyyy')).csv"
Write-Host "END"