cls
#$ErrorActionPreference = "SilentlyContinue"
#$stockList = $(Invoke-WebRequest -Uri "https://api2.pse.tools/api/quotes").Content | ConvertFrom-Json | Select -ExpandProperty Data | gm | Select Name -Skip 4
$stockList = $(Invoke-WebRequest -Uri "https://api.pse.tools/api/stocks").Content | ConvertFrom-Json |  Select -ExpandProperty Data | Select symbol
$stockList = Get-Content -Path "$PSScriptRoot\Stocklist.txt"

Function Get-WeekNumber([datetime]$DateTime = (Get-Date)) {
    $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
    $cultureInfo.Calendar.GetWeekOfYear($DateTime,$cultureInfo.DateTimeFormat.CalendarWeekRule,$cultureInfo.DateTimeFormat.FirstDayOfWeek)
}

Function Get-CCI{
    param($Data, $Length)
    $Data | % {
        $_ | Add-Member @{TypicalPrice = $(([double]$_.High + [double]$_.Low + [double]$_.Close)/ 3)} -Force
    }

    $TPSMA20 = $($Data | Measure-Object -Property TypicalPrice -Average).Average
    
    $MeanDeviation = 0
    $Data | % {
        $MeanDeviation += [math]::abs($TPSMA20 - $_.TypicalPrice)  
    }
    $MeanDeviation = $MeanDeviation / $Length
    $CCI = ($Data[0].TypicalPrice - $TPSMA20) / (0.015 * $MeanDeviation)
    return $CCI
}

Function Get-IchimokuData{
    param($Data)  
    
    $TS = [double]$(($($DATA | Select High -First 9 | Measure-Object -Property High -Maximum).Maximum + $($DATA | Select Low -First 9 | Measure-Object -Property Low -Minimum).Minimum) / 2)
    $KS = [double]$(($($DATA | Select High -First 26 | Measure-Object -Property High -Maximum).Maximum + $($DATA | Select Low -First 26 | Measure-Object -Property Low -Minimum).Minimum) / 2)
    $SSA = [double]$(($TS + $KS) / 2)
    $SSB = [double]$(($($DATA | Select High -First 52| Measure-Object -Property High -Maximum).Maximum + $($DATA | Select Low -First 52 | Measure-Object -Property Low -Minimum).Minimum) / 2)
    $Open = [double]$($DATA[0].Open)
    $Close = [double]$($DATA[0].Close)
    
    $IchimokuData = [PSCustomObject]@{
        TS = $TS
        KS = $KS
        SSA = $SSA
        SSB = $SSB
        Open = $Open
        Close = $Close
    }
    return $IchimokuData
}

Function Get-IchimokuSetup{
    param($Stock, $Date, $DataNow, $DataPast, $Timeframe)

    $rating = 0

    If($DataNow.Close -gt $DataNow.TS){
        $TenkanSen = 'Bull'
        #Write-Host "TenkanSen - $TenkanSen" -ForegroundColor Green
        #$Rating++
    }
    ElseIf($DataNow.Close -lt $DataNow.TS){
        $TenkanSen = 'Bear'
        #Write-Host "TenkanSen - $TenkanSen" -ForegroundColor Red
    }
    Else{
        $TenkanSen = 'Neutral'
        #Write-Host "TenkanSen - $TenkanSen" -ForegroundColor Yellow
    }

    If($DataNow.Close -gt $DataNow.KS){
        $KijunSen = 'Bull'
        #Write-Host "KijunSen - $KijunSen" -ForegroundColor Green
        $Rating++
    }
    ElseIf($DataNow.Close -lt $DataNow.KS){
        $KijunSen = 'Bear'
        #Write-Host "KijunSen - $KijunSen" -ForegroundColor Red
    }
    Else{
        $KijunSen = 'Neutral'
        #Write-Host "KijunSen - $KijunSen" -ForegroundColor Yellow
    }

    If(($DataNow.Close -gt $DataPast.SSA) -and ($DataNow.Close -gt $DataPast.SSB)){
        $Cloud = 'Bull'
        #Write-Host "Cloud - $Cloud" -ForegroundColor Green
        $Rating++
    }
    ElseIf(($DataNow.Close -lt $DataPast.SSA) -and ($DataNow.Close -lt $DataPast.SSB)){
        $Cloud = 'Bear'
        #Write-Host "Cloud - $Cloud" -ForegroundColor Red
    }
    Else{
        $Cloud = 'Neutral'
        #Write-Host "Cloud - $Cloud" -ForegroundColor Yellow
    }

    If(($DataNow.Close -gt $DataPast.Open) -and ($DataNow.Close -gt $DataPast.Close)){
        $ChikouSpan = 'Bull'
        #Write-Host "ChikouSpan - $ChikouSpan" -ForegroundColor Green
        $Rating++
    }
    ElseIf(($DataNow.Close -lt $DataPast.Open) -and ($CurrentPrice -lt $DataPast.Close)){
        $ChikouSpan = 'Bear'
        #Write-Host "ChikouSpan - $ChikouSpan" -ForegroundColor Red
    }
    Else{
        $ChikouSpan = 'Neutral'
        #Write-Host "ChikouSpan - $ChikouSpan" -ForegroundColor Yellow
    }

    If($DataNow.TS -gt $DataNow.KS){
        $TenkanSenKijunSen = 'Bull'
        #Write-Host "TenkanSenKijunSen - $TenkanSenKijunSen" -ForegroundColor Green
        #$Rating++
    }
    ElseIf($DataNow.TS -lt $DataNow.KS){
        $TenkanSenKijunSen = 'Bear'
        #Write-Host "TenkanSenKijunSen - $TenkanSenKijunSen" -ForegroundColor Red
    }
    Else{
        $TenkanSenKijunSen = 'Neutral'
        #Write-Host "TenkanSenKijunSen - $TenkanSenKijunSen" -ForegroundColor Yellow
    }

    If($DataNow.SSA -gt $DataNow.SSB){
        $FutureCloud = 'Bull'
        #Write-Host "FutureCloud - $FutureCloud" -ForegroundColor Green
        $Rating++
    }
    ElseIf($DataNow.SSA -lt $DataNow.SSB){
        $FutureCloud = 'Bear'
        #Write-Host "FutureCloud - $FutureCloud" -ForegroundColor Red
    }
    Else{
        $FutureCloud = 'Neutral'
        #Write-Host "FutureCloud - $FutureCloud" -ForegroundColor Yellow
    }

    If($DataNow.CCI -gt 0){
        $CCIBias = 'Bull'
        $Rating++
    }
    ElseIf($DataNow.CCI -lt 0){
        $CCIBias = 'Bear'
    }
    ElseIf($DataNow.CCI -eq 0){
        $CCIBias = 'Neutral'
    }

    $IchimokuSetup = [PSCustomObject]@{
        Stock = $Stock
        Date = $Date
        "$($Timeframe)_TS" = $TenkanSen
        "$($Timeframe)_KS" = $KijunSen
        "$($Timeframe)_Kumo" = $Cloud
        "$($Timeframe)_CS" = $ChikouSpan
        "$($Timeframe)_TS/KS" = $TenkanSenKijunSen
        "$($Timeframe)_FutureKumo" = $FutureCloud
        "$($Timeframe)_CCI" = $CCIBias
        "$($Timeframe)_Rating" = $Rating   
    }

    return $IchimokuSetup

}

Function Get-IchimokuTriggers{
    param($DataNow, $DataPast, $Timeframe)
    $triggers = @()
    <#If(($DataNow."$($Timeframe)_TS" -eq 'Bull') -and ($DataPast."$($Timeframe)_TS" -ne 'Bull')){
        $triggers += "$($Timeframe): TS Cross"
    }#>

    If(($DataNow."$($Timeframe)_KS" -eq 'Bull') -and ($DataPast."$($Timeframe)_KS" -ne 'Bull')){
        $triggers += "$($Timeframe): KS Cross Buy"
    }

    If(($DataNow."$($Timeframe)_KS" -eq 'Bear') -and ($DataPast."$($Timeframe)_KS" -ne 'Bear')){
        $triggers += "$($Timeframe): KS Cross Sell"
    }

    <#If(($DataNow."$($Timeframe)_Kumo" -eq 'Bull') -and ($DataPast."$($Timeframe)_Kumo" -ne 'Bull')){
        $triggers += "$($Timeframe): Kumo Breakout"
    }

    If(($DataNow."$($Timeframe)_Kumo" -eq 'Neutral') -and ($DataPast."$($Timeframe)_Kumo" -eq 'Bear')){
        $triggers += "$($Timeframe): Kumo Entry"
    }

    If(($DataNow."$($Timeframe)_CS" -eq 'Bull') -and ($DataPast."$($Timeframe)_CS" -ne 'Bull')){
        $triggers += "$($Timeframe): CS Breakout"
    }

    If(($DataNow."$($Timeframe)_TS/KS" -eq 'Bull') -and ($DataPast."$($Timeframe)_TS/KS" -ne 'Bull')){
        $triggers += "$($Timeframe): TS/KS Cross"
    }

    If(($DataNow."$($Timeframe)_FutureKumo" -eq 'Bull') -and ($DataPast."$($Timeframe)_FutureKumo" -ne 'Bull')){
        $triggers += "$($Timeframe): Kumo Twist"
    }

    If(($DataNow."$($Timeframe)_CCI" -eq 'Bull') -and ($DataPast."$($Timeframe)_CCI" -ne 'Bull')){
        $triggers += "$($Timeframe): CCI Breakout"
    }#>

    return $triggers
}


$WeeklyTriggers = @()

$DailyHeatmap = @()
$WeeklyHeatmap = @()

$CCITable = @()

$stockList | % {
    cls
    $stock = $_
    Write-Host "$stock"
    If($(Test-Path "$PSScriptRoot\KSCross\$stock.csv") -eq $false){
        $trades = @()
    
        $tradeMode = $false
        $entryDate = $null
        $entryPrice = 0
        $exitDate = $null
        $exitPrice = $null
        $highestPrice = 0
        $lowestPrice = 0
        $tradeTriggers = $null
        $entryOverallRating = 0
        $entryDailyRating = 0
        $entryWeeklyRating = 0
        $D_CCI = 0
        $W_CCI = 0

        #$DB = $($(Invoke-WebRequest -Uri "https://ph24.colfinancial.com/ape/colcharts/HISTORICAL/$stock.asp").Content | ConvertFrom-Json) | Select Date, Open, High, Low, Close | Sort-Object Date -Descending
        $DB = Import-Csv -Path "$PSScriptRoot\PSE_DB\*_$stock.csv"
        $DB | % {
            $_ | Add-Member @{
                Week = Get-WeekNumber -DateTime $_.Date
                Year = $([datetime]$_.Date).ToString('yyyy')
            } 
        }
        #$DB

        

        for($i = 260; $i -ge 0; $i--){
            $Triggers = @()
            $stockData = $DB | Select * -Skip $i
            #$stockData[0].Date
            #$stockData
            $DailyCCI = Get-CCI -Data $($stockData | Select -First 20) -Length 20
            $DailyCCI_Yday = Get-CCI -Data $($stockData | Select -Skip 1 | Select -First 20) -Length 20

            #Gets Ichimoku data today
            $Ichimoku_Today = Get-IchimokuData -Data $stockData
            $Ichimoku_Today |  Add-Member @{CCI = $DailyCCI}
            #$Ichimoku_Today

            $Ichimoku_Past = Get-IchimokuData -Data $($stockData | Select -Skip 26)
            $IchimokuSetup_Today = Get-IchimokuSetup -Stock $stock -Date $stockData[0].Date -DataNow $Ichimoku_Today -DataPast $Ichimoku_Past -Timeframe 'D'

            #Gets Ichimoku data yesterday
            $Ichimoku_Yday = Get-IchimokuData -Data $($stockData | Select -Skip 1)
            $Ichimoku_Yday |  Add-Member @{CCI = $DailyCCI_Yday}

            $Ichimoku_Past = Get-IchimokuData -Data $($stockData | Select -Skip 27)
            $IchimokuSetup_Yday = Get-IchimokuSetup -Stock $stock -Date $stockData[1].Date -DataNow $Ichimoku_Yday -DataPast $Ichimoku_Past -Timeframe 'D'

            $DailyHeatmap += $IchimokuSetup_Today

            #Creates weekly stock data
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

            #$weekData

            $WeeklyCCI = Get-CCI -Data $($weekData | Select -First 20) -Length 20
            $WeeklyCCI_LastWeek = Get-CCI -Data $($weekData | Select -Skip 1 | Select -First 20) -Length 20

            #Gets Ichimoku data for current week
            $Ichimoku_CurrentWeek = Get-IchimokuData -Data $weekData
            $Ichimoku_CurrentWeek |  Add-Member @{CCI = $WeeklyCCI}
            #$Ichimoku_CurrentWeek

            $Ichimoku_PastWeek = Get-IchimokuData -Data $($weekData | Select -Skip 26)
            $IchimokuSetup_CurrentWeek = Get-IchimokuSetup -Stock $stock -Date "$($weekData[0].Week)_$($weekData[0].Year)" -DataNow $Ichimoku_CurrentWeek -DataPast $Ichimoku_PastWeek -Timeframe 'W'

            $WeeklyHeatmap += $IchimokuSetup_CurrentWeek

            #Gets Ichimoku data for past week
            $Ichimoku_LastWeek = Get-IchimokuData -Data $($weekData | Select -Skip 1)
            $Ichimoku_LastWeek |  Add-Member @{CCI = $WeeklyCCI_LastWeek}

            $Ichimoku_PastWeek = Get-IchimokuData -Data $($weekData | Select -Skip 27)
            $IchimokuSetup_LastWeek = Get-IchimokuSetup -Stock $stock -Date "$($weekData[0].Week)_$($weekData[0].Year)" -DataNow $Ichimoku_LastWeek -DataPast $Ichimoku_PastWeek -Timeframe 'W'

            $OverallRating = $IchimokuSetup_Today.D_Rating + $IchimokuSetup_CurrentWeek.W_Rating
        
            #Gets Ichimoku triggers on daily timeframe
            Get-IchimokuTriggers -DataNow $IchimokuSetup_Today -DataPast $IchimokuSetup_Yday -Timeframe 'D' | % {
                $Triggers += [PSCustomObject]@{
                    Stock = "$stock"
                    Date = $stockData[0].Date
                    Trigger = $_
                    #Rating = $OverallRating
                }
            }

            <##Gets Ichimoku triggers on weekly timeframe
            Get-IchimokuTriggers -DataNow $IchimokuSetup_CurrentWeek -DataPast $IchimokuSetup_LastWeek -Timeframe 'W' | % {
                $Triggers += [PSCustomObject]@{
                    Stock = $stock
                    Date = "$($weekData[0].Week)_$($weekData[0].Year)"
                    Trigger = $_
                    #Rating = $OverallRating
                }
            }#>

            
            If($triggers.Count -gt 0){
                #Write-Host "$stock - $OverallRating"
                Write-Host $Triggers

                If(($Triggers[0].Trigger -eq "D: KS Cross Buy") -and ($tradeMode -eq $false)){
                    #Write-Host "$i - $($stockData[0].Date) - $OverallRating"
                    $tradeMode = $true
                    $entryDate = $stockData[0].Date
                    $entryPrice = $stockData[0].Close
                    $highestPrice = $stockData[0].Close
                    $lowestPrice = $stockData[0].Close
                    $tradeTriggers = [string]$Triggers[0].Trigger
                    $entryDailyRating = $IchimokuSetup_Today.D_Rating
                    $entryWeeklyRating = $IchimokuSetup_CurrentWeek.W_Rating
                    $entryOverallRating = $OverallRating
                    $D_CCI = $Ichimoku_Today.CCI
                    $W_CCI = $Ichimoku_CurrentWeek.CCI

                    Write-Host "Entry Date: $entryDate"
                    Write-Host "Entry Price: $entryPrice"
                    Write-Host $Triggers.Trigger
                }

                If($tradeMode -eq $true){
                    #Write-Host "$i - $($stockData[0].Date) - $OverallRating"
                    If($stockData[0].Close -gt $highestPrice){
                        $highestPrice = $stockData[0].Close
                    }
                    If($stockData[0].Close -lt $lowestPrice){
                        $lowestPrice = $stockData[0].Close
                    }
                }

                If(($Triggers[0].Trigger -eq "D: KS Cross Sell") -and ($tradeMode -eq $true)){
                    $tradeMode = $false
                    $exitDate = $stockData[0].Date
                    $exitPrice = $stockData[0].Close
                    $maxProfit = $([math]::Round($((($highestPrice - $entryPrice) / $entryPrice) * 100),2))
                    $maxDrawdown = $([math]::Round($((($lowestPrice - $entryPrice) / $entryPrice) * 100),2))
                    $gainLoss = $([math]::Round($((($exitPrice - $entryPrice) / $entryPrice) * 100),2))
                    Write-Host "Exit Date: $exitDate"
                    Write-Host "Exit Price: $exitPrice"
                    Write-Host "MaxProfit%: $maxProfit%"
                    Write-Host "MaxDrawdown%: $maxDrawdown%"
                    Write-Host "%Gain/Loss: $gainLoss%"

                    $trades += [PSCustomObject]@{
                        Stock = $stock
                        EntryDailyRating = $entryDailyRating
                        EntryWeeklyRating = $entryWeeklyRating
                        EntryOverallRating = $entryOverallRating
                        EntryDate = $entryDate
                        EntryPrice = $entryPrice
                        ExitDate = $exitDate
                        ExitPrice = $exitPrice
                        MaxProfit = $maxProfit
                        MaxDrawdown = $maxDrawdown
                        PercentGainLoss = $gainLoss
                        Triggers = $tradeTriggers
                        D_CCI = $D_CCI
                        W_CCI = $W_CCI
                    }

                    "`n"
                }
            }
            <#
            If(($OverallRating -eq 10) -and ($tradeMode -eq $false)){
                Write-Host "$i - $($stockData[0].Date) - $OverallRating"
                $tradeMode = $true
                $entryDate = $stockData[0].Date
                $entryPrice = $stockData[0].Close
                $highestPrice = $stockData[0].Close
                $lowestPrice = $stockData[0].Close
                $tradeTriggers = [string]$Triggers.Trigger
                $D_CCI = $Ichimoku_Today.CCI
                $W_CCI = $Ichimoku_CurrentWeek.CCI

                Write-Host "Entry Date: $entryDate"
                Write-Host "Entry Price: $entryPrice"
                Write-Host $Triggers.Trigger
            }

            If($tradeMode -eq $true){
                Write-Host "$i - $($stockData[0].Date) - $OverallRating"
                If($stockData[0].Close -gt $highestPrice){
                    $highestPrice = $stockData[0].Close
                }
                If($stockData[0].Close -lt $lowestPrice){
                    $lowestPrice = $stockData[0].Close
                }
            }

            If(($OverallRating -ne 10) -and ($tradeMode -eq $true)){
                Write-Host "$i - $($stockData[0].Date) - $OverallRating"
                $tradeMode = $false
                $exitDate = $stockData[0].Date
                $exitPrice = $stockData[0].Close
                $maxProfit = $([math]::Round($((($highestPrice - $entryPrice) / $entryPrice) * 100),2))
                $maxDrawdown = $([math]::Round($((($lowestPrice - $entryPrice) / $entryPrice) * 100),2))
                $gainLoss = $([math]::Round($((($exitPrice - $entryPrice) / $entryPrice) * 100),2))
                Write-Host "Exit Date: $exitDate"
                Write-Host "Exit Price: $exitPrice"
                Write-Host "MaxProfit%: $maxProfit%"
                Write-Host "MaxDrawdown%: $maxDrawdown%"
                Write-Host "%Gain/Loss: $gainLoss%"

                $trades += [PSCustomObject]@{
                    Stock = $stock
                    EntryDate = $entryDate
                    EntryPrice = $entryPrice
                    ExitDate = $exitDate
                    ExitPrice = $exitPrice
                    MaxProtif = $maxProfit
                    MaxDrawdown = $maxDrawdown
                    PercentGainLoss = $gainLoss
                    Triggers = $tradeTriggers
                    D_CCI = $D_CCI
                    W_CCI = $W_CCI
                }

                "`n"
            }#>
        
        
            <#If($OverallRating -eq 10){
                $maxRating += $stockData[0].Date
            }#>
            #Write-Host $triggers.Trigger
            #$Ichimoku_Today.CCI
            #$Ichimoku_CurrentWeek.CCI
        } 

        $trades | Export-csv "$PSScriptRoot\KSCross\$stock.csv"
        #Read-Host
    }

    
    
}
