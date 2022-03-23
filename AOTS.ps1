cls

function Get-WeekNumber([datetime]$DateTime = (Get-Date)) {
    $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
    $cultureInfo.Calendar.GetWeekOfYear($DateTime,$cultureInfo.DateTimeFormat.CalendarWeekRule,$cultureInfo.DateTimeFormat.FirstDayOfWeek)
}


$AOTS = @()

#$stockList = $(Invoke-WebRequest -Uri "https://api2.pse.tools/api/quotes").Content | ConvertFrom-Json | Select -ExpandProperty Data | gm | Select Name -Skip 4
#$stockList = $(Invoke-WebRequest -Uri "https://api.pse.tools/api/stocks").Content | ConvertFrom-Json |  Select -ExpandProperty Data | Sort-Object Symbol
#$stockList = Get-Content -Path "$PSScriptRoot\Stocklist.txt"
$priceData = [xml]$(Invoke-WebRequest -Uri http://phisix-api.appspot.com/stocks.xml).Content
$stockList = $priceData.stocks.stock| Select Symbol

$dates = @()
$files = Get-ChildItem -Path "$PSScriptRoot\PSE_DB"
$files.name | % {
    $matches = @()
    $_ -match '^(\d{4}-\d{2}-\d{2})' | Out-Null
    $dates += [datetime]$matches[0]
}

$latestDate = $($dates | Sort-Object -Descending)[0].ToString('yyyy-MM-dd')


Get-ChildItem -Path "$PSScriptRoot\PSE_DB" | Where-Object {$_.Name -like "$latestDate*"} | % {

    $matches = @()
    $_ -match '._(.+?)\.csv' | Out-Null
    $stock = $matches[1]
    $stockData = Import-Csv $_.FullName
    $stockData | % {
        $_ | Add-Member @{
            Week = Get-WeekNumber -DateTime $_.Date
            Year = $([datetime]$_.Date).ToString('yyyy')
        }
    }

    $weekData = @()
    $stockData | Select * | Group-Object Week, Year | % {
        $week = $_ | Select -ExpandProperty Group
        $weekData += [PSCustomObject]@{
            Symbol = $stock
            Date = $week[$($week.Count) - 1].Date
            Week = $week[$($week.Count) - 1].Week
            Year = $week[$($week.Count) - 1].Year
            Open = [double]$week[$($week.Count) - 1].Open
            High = [double]$($week | Measure-Object -Property High -Maximum).Maximum
            Low = [double]$($week | Measure-Object -Property Low -Minimum).Minimum
            Close = [double]$week[0].Close
        }
    }

    Write-Host "$stock - $($stockData[0].Date)"

    $close = $stockData[0].Close

    $AOTSData = [PSCustomObject]@{ 
        Stock = $stock
        Date = $stockData[0].Date
    }

    $D_MA20 = $($stockData | Select -First 20 | Measure-Object -Property Close -Average).Average
    $D_MA50 = $($stockData | Select -First 50 | Measure-Object -Property Close -Average).Average
    $D_MA100 = $($stockData | Select -First 100 | Measure-Object -Property Close -Average).Average

    $W_MA20 = $($weekData | Select -First 20 | Measure-Object -Property Close -Average).Average
    $W_MA50 = $($weekData | Select -First 50 | Measure-Object -Property Close -Average).Average
    $W_MA100 = $($weekData | Select -First 100 | Measure-Object -Property Close -Average).Average

    <#$D_MA20
    $D_MA50 
    $D_MA100

    $W_MA20
    $W_MA50 
    $W_MA100#>

        
    $rating = 0
    If([double]$close -gt [double]$D_MA20){
        $rating++
        $AOTSData | Add-Member @{
            "D>20" = 'Y'
        }
    }
    Else{
        $AOTSData | Add-Member @{
            "D>20" = 'N'
        }
    }


    If([double]$D_MA20 -gt [double]$D_MA50){
        $rating++
        $AOTSData | Add-Member @{
            "D>50" = 'Y'
        }
    }
    Else{
        $AOTSData | Add-Member @{
            "D>50" = 'N'
        }
    }

    If([double]$D_MA50 -gt [double]$D_MA100){
        $rating++
        $AOTSData | Add-Member @{
            "D>100" = 'Y'
        }
    }
    Else{
        $AOTSData | Add-Member @{
            "D>100" = 'N'
        }
    }

    <#If([double]$D_MA100 -gt [double]$D_MA200){
        $rating++
        $AOTSData | Add-Member @{
            "D>200" = 'Y'
        }
    }
    Else{
        $AOTSData | Add-Member @{
            "D>200" = 'N'
        }
    }#>

    If([double]$close -gt [double]$W_MA20){
        $rating++
        $AOTSData | Add-Member @{
            "W>20" = 'Y'
        }
    }
    Else{
        $AOTSData | Add-Member @{
            "W>20" = 'N'
        }
    }

    If([double]$W_MA20 -gt [double]$W_MA50){
        $rating++
        $AOTSData | Add-Member @{
            "W>50" = 'Y'
        }
    }
    Else{
        $AOTSData | Add-Member @{
            "W>50" = 'N'
        }
    }

    If([double]$W_MA50 -gt [double]$W_MA100){
        $rating++
        $AOTSData | Add-Member @{
            "W>100" = 'Y'
        }
    }
    Else{
        $AOTSData | Add-Member @{
            "W>100" = 'N'
        }
    }
    <#If([double]$W_MA100 -gt [double]$W_ALMA200){
        $rating++
        $AOTSData | Add-Member @{
            "W>200" = 'Y'
        }
    }
    Else{
        $AOTSData | Add-Member @{
            "W>200" = 'N'
        }
    }#>

    $AOTSData | Add-Member @{
        Rating = $rating    
    }

    Write-Host "Rating: $rating"

    
    "`n"

    $AOTSData
    $AOTS += $AOTSData

    "`n"

}

$AOTS | Export-Csv "$PSScriptRoot\AOTS\AOTS_$($([datetime]$stockData[0].Date).ToString('MMddyyyy')).csv"
Write-Host "END"
Read-Host
