cls

function Get-WeekNumber([datetime]$DateTime = (Get-Date)) {
    $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
    $cultureInfo.Calendar.GetWeekOfYear($DateTime,$cultureInfo.DateTimeFormat.CalendarWeekRule,$cultureInfo.DateTimeFormat.FirstDayOfWeek)
}

function ALMA{
    param($Data, $Window, $Sigma, $Offset)
    $m = [math]::floor($Offset * ($Window -1))
    $s = $Window/$Sigma

    $WtdSum = 0
    $CumWt = 0

    for($k = 0; $k -lt $window; $k++){
        $wtd = [math]::exp(-(($k-$m)*($k-$m))/(2*$s*$s))
        $WtdSum = $WtdSum + ($Wtd * $Data[$Window - 1 - $k].Close)
        $CumWt = $CumWt + $Wtd
    }

    [double]$ALAverage = $WtdSum / $CumWt
    return $ALAverage
    
}

$ALMA = @()
$ALMACROSS = @()

#$stockList = $(Invoke-WebRequest -Uri "https://api2.pse.tools/api/quotes").Content | ConvertFrom-Json | Select -ExpandProperty Data | gm | Select Name -Skip 4
#$stockList = $(Invoke-WebRequest -Uri "https://api.pse.tools/api/stocks").Content | ConvertFrom-Json |  Select -ExpandProperty Data | Sort-Object Symbol
$stockList = Get-Content -Path "$PSScriptRoot\Stocklist.txt"

$stockList | % {
    $stock = $_#.Symbol

    $stockData = Import-Csv -Path "$PSScriptRoot\PSE_DB\*_$stock.csv"
    #$stockData = $($(Invoke-WebRequest -Uri "https://ph24.colfinancial.com/ape/colcharts/HISTORICAL/$stock.asp").Content | ConvertFrom-Json) | Select Date, Open, High, Low, Close | Sort-Object Date -Descending
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
    $PDClose = $stockData[1].Close
    $PWClose = $weekData[1].Close

    $sigma = 6
    $offset = 0.85

    $ALMAData = [PSCustomObject]@{ 
        Stock = $stock
        Date = $stockData[0].Date
    }

    $window = 20
    $data = $stockData | Select -First $window
    $D_ALMA20 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    $D_ALMA20
    $close
    $data = $stockData | Select -Skip 1 | Select -First $window
    $PD_ALMA20 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset

    $window = 50
    $data = $stockData | Select -First $window
    $D_ALMA50 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    $data = $stockData | Select -Skip 1 | Select -First $window
    $PD_ALMA50 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset

    $window = 100
    $data = $stockData | Select -First $window
    $D_ALMA100 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    $data = $stockData | Select -Skip 1 | Select -First $window
    $PD_ALMA100 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset

    $window = 200
    $data = $stockData | Select -First $window
    $D_ALMA200 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    $data = $stockData | Select -Skip 1 | Select -First $window
    $PD_ALMA200 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset

    $window = 20
    $data = $weekData | Select -First $window
    $W_ALMA20 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    $data = $weekData | Select -Skip 1 | Select -First $window
    $PW_ALMA20 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset

    $window = 50
    $data = $weekData | Select -First $window
    $W_ALMA50 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    $data = $weekData | Select -Skip 1 | Select -First $window
    $PW_ALMA50 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset

    $window = 100
    $data = $weekData | Select -First $window
    $W_ALMA100 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    $data = $weekData | Select -Skip 1 | Select -First $window
    $PW_ALMA100 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset

    $window = 200
    $data = $weekData | Select -First $window
    $W_ALMA200 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    $data = $weekData | Select -Skip 1 | Select -First $window
    $PW_ALMA200 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
        
    $rating = 0
    If([double]$close -gt [double]$D_ALMA20){
        $rating++
        $ALMAData | Add-Member @{
            "D>20" = 'Y'
        }
    }
    Else{
        $ALMAData | Add-Member @{
            "D>20" = 'N'
        }
    }


    If([double]$D_ALMA20 -gt [double]$D_ALMA50){
        $rating++
        $ALMAData | Add-Member @{
            "D>50" = 'Y'
        }
    }
    Else{
        $ALMAData | Add-Member @{
            "D>50" = 'N'
        }
    }

    If([double]$D_ALMA50 -gt [double]$D_ALMA100){
        $rating++
        $ALMAData | Add-Member @{
            "D>100" = 'Y'
        }
    }
    Else{
        $ALMAData | Add-Member @{
            "D>100" = 'N'
        }
    }

    If([double]$D_ALMA100 -gt [double]$D_ALMA200){
        $rating++
        $ALMAData | Add-Member @{
            "D>200" = 'Y'
        }
    }
    Else{
        $ALMAData | Add-Member @{
            "D>200" = 'N'
        }
    }

    If([double]$close -gt [double]$W_ALMA20){
        $rating++
        $ALMAData | Add-Member @{
            "W>20" = 'Y'
        }
    }
    Else{
        $ALMAData | Add-Member @{
            "W>20" = 'N'
        }
    }

    If([double]$W_ALMA20 -gt [double]$W_ALMA50){
        $rating++
        $ALMAData | Add-Member @{
            "W>50" = 'Y'
        }
    }
    Else{
        $ALMAData | Add-Member @{
            "W>50" = 'N'
        }
    }

    If([double]$W_ALMA50 -gt [double]$W_ALMA100){
        $rating++
        $ALMAData | Add-Member @{
            "W>100" = 'Y'
        }
    }
    Else{
        $ALMAData | Add-Member @{
            "W>100" = 'N'
        }
    }
    If([double]$W_ALMA100 -gt [double]$W_ALMA200){
        $rating++
        $ALMAData | Add-Member @{
            "W>200" = 'Y'
        }
    }
    Else{
        $ALMAData | Add-Member @{
            "W>200" = 'N'
        }
    }

    $ALMAData | Add-Member @{
        Rating = $rating    
    }

    Write-Host "Rating: $rating"

    <#If((($close -gt $D_ALMA20) -eq $true) -and (($PDClose -gt $PD_ALMA20) -eq $false)){
        Write-Host "D_ALMA20 Cross!"
        
        $ALMACROSS += [PSCustomObject]@{
            Stock = $stock
            Alert = "D_ALMA20 Cross"
            Rating = $rating
            Date = $($stockData[0].Date)
        }
    }

    If((($close -gt $D_ALMA50) -eq $true) -and (($PDClose -gt $PD_ALMA50) -eq $false)){
        Write-Host "D_ALMA50 Cross!"
        
        $ALMACROSS += [PSCustomObject]@{
            Stock = $stock
            Alert = "D_ALMA50 Cross"
            Rating = $rating
            Date = $($stockData[0].Date)
        }
    }

    If((($close -gt $D_ALMA100) -eq $true) -and (($PDClose -gt $PD_ALMA100) -eq $false)){
        Write-Host "D_ALMA100 Cross!"
        
        $ALMACROSS += [PSCustomObject]@{
            Stock = $stock
            Alert = "D_ALMA100 Cross"
            Rating = $rating
            Date = $($stockData[0].Date)
        }
    }

    If((($close -gt $D_ALMA200) -eq $true) -and (($PDClose -gt $PD_ALMA200) -eq $false)){
        Write-Host "D_ALMA200 Cross!"
        
        $ALMACROSS += [PSCustomObject]@{
            Stock = $stock
            Alert = "D_ALMA200 Cross"
            Rating = $rating
            Date = $($stockData[0].Date)
        }
    }

    If((($close -gt $W_ALMA20) -eq $true) -and (($PWClose -gt $PW_ALMA20) -eq $false)){
        Write-Host "W_ALMA20 Cross!"
        
        $ALMACROSS += [PSCustomObject]@{
            Stock = $stock
            Alert = "W_ALMA20 Cross"
            Rating = $rating
            Date = $($stockData[0].Date)
        }
    }

    If((($close -gt $W_ALMA50) -eq $true) -and (($PWClose -gt $PW_ALMA50) -eq $false)){
        Write-Host "W_ALMA50 Cross!"
        
        $ALMACROSS += [PSCustomObject]@{
            Stock = $stock
            Alert = "W_ALMA50 Cross"
            Rating = $rating
            Date = $($stockData[0].Date)
        }
    }


    If((($close -gt $W_ALMA100) -eq $true) -and (($PWClose -gt $PW_ALMA100) -eq $false)){
        Write-Host "W_ALMA100 Cross!"
        
        $ALMACROSS += [PSCustomObject]@{
            Stock = $stock
            Alert = "W_ALMA100 Cross"
            Rating = $rating
            Date = $($stockData[0].Date)
        }
    }


    If((($close -gt $W_ALMA200) -eq $true) -and (($PWClose -gt $PW_ALMA200) -eq $false)){
        Write-Host "W_ALMA200 Cross!"
        
        $ALMACROSS += [PSCustomObject]@{
            Stock = $stock
            Alert = "W_ALMA200 Cross"
            Rating = $rating
            Date = $($stockData[0].Date)
        }
    }#>
    
    "`n"

    $ALMAData
    $ALMA += $ALMAData

    "`n"

}

$ALMA | Export-Csv "$PSScriptRoot\ALMA\ALMA_$($([datetime]$stockData[0].Date).ToString('MMddyyyy')).csv"
Write-Host "END"
Read-Host
