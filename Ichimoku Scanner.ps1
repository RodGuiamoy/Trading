cls
$ErrorActionPreference = "Continue"
#$stockList = $(Invoke-WebRequest -Uri "https://api2.pse.tools/api/quotes").Content | ConvertFrom-Json | Select -ExpandProperty Data | gm | Select Name -Skip 4
#$stockList = $(Invoke-WebRequest -Uri "https://api.pse.tools/api/stocks").Content | ConvertFrom-Json |  Select -ExpandProperty Data | Select symbol
$stockList = Get-Content -Path "$PSScriptRoot\Stocklist.txt"

Function Get-WeekNumber([datetime]$DateTime = (Get-Date)) {
    $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
    $cultureInfo.Calendar.GetWeekOfYear($DateTime,$cultureInfo.DateTimeFormat.CalendarWeekRule,$cultureInfo.DateTimeFormat.FirstDayOfWeek)
}

Function Get-CCI{
    param($Data, $Length)
    $Data | % {
        $_ | Add-Member @{TypicalPrice = $(([double]$_.High + [double]$_.Low + [double]$_.Close)/ 3)}
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
    Else{
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
    If(($DataNow."$($Timeframe)_TS" -eq 'Bull') -and ($DataPast."$($Timeframe)_TS" -ne 'Bull')){
        $triggers += "$($Timeframe): TS Cross"
    }

    If(($DataNow."$($Timeframe)_KS" -eq 'Bull') -and ($DataPast."$($Timeframe)_KS" -ne 'Bull')){
        $triggers += "$($Timeframe): KS Cross"
    }

    If(($DataNow."$($Timeframe)_Kumo" -eq 'Bull') -and ($DataPast."$($Timeframe)_Kumo" -ne 'Bull')){
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

    return $triggers
}

$Triggers = @()
$WeeklyTriggers = @()

$DailyHeatmap = @()
$WeeklyHeatmap = @()

$CCITable = @()

$dates = @()
$files = Get-ChildItem -Path "$PSScriptRoot\PSE_DB"
$files.name | % {
    $matches = @()
    $_ -match '\d{4}-\d{2}-\d{2}' | Out-Null
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

    Write-Host "$stock - $($_.Name)"



    $DailyCCI = Get-CCI -Data $($stockData | Select -First 20) -Length 20

    #Gets Ichimoku data today
    $Ichimoku_Today = Get-IchimokuData -Data $stockData
    $Ichimoku_Today |  Add-Member @{CCI = $DailyCCI}
    #$Ichimoku_Today

    $Ichimoku_Past = Get-IchimokuData -Data $($stockData | Select -Skip 26)
    $IchimokuSetup_Today = Get-IchimokuSetup -Stock $stock -Date $stockData[0].Date -DataNow $Ichimoku_Today -DataPast $Ichimoku_Past -Timeframe 'D'

    #Gets Ichimoku data yesterday
    $Ichimoku_Yday = Get-IchimokuData -Data $($stockData | Select -Skip 1)
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

    #Gets Ichimoku data for current week
    $Ichimoku_CurrentWeek = Get-IchimokuData -Data $weekData
    $Ichimoku_CurrentWeek |  Add-Member @{CCI = $WeeklyCCI}
    #$Ichimoku_CurrentWeek

    $Ichimoku_PastWeek = Get-IchimokuData -Data $($weekData | Select -Skip 26)
    $IchimokuSetup_CurrentWeek = Get-IchimokuSetup -Stock $stock -Date "$($weekData[0].Week)_$($weekData[0].Year)" -DataNow $Ichimoku_CurrentWeek -DataPast $Ichimoku_PastWeek -Timeframe 'W'

    $WeeklyHeatmap += $IchimokuSetup_CurrentWeek

    #Gets Ichimoku data for past week
    $Ichimoku_LastWeek = Get-IchimokuData -Data $($weekData | Select -Skip 1)
    $Ichimoku_PastWeek = Get-IchimokuData -Data $($weekData | Select -Skip 27)
    $IchimokuSetup_LastWeek = Get-IchimokuSetup -Stock $stock -Date "$($weekData[0].Week)_$($weekData[0].Year)" -DataNow $Ichimoku_LastWeek -DataPast $Ichimoku_PastWeek -Timeframe 'W'

    $OverallRating = $IchimokuSetup_Today.D_Rating + $IchimokuSetup_CurrentWeek.W_Rating
    
    #Gets Ichimoku triggers on daily timeframe
    Get-IchimokuTriggers -DataNow $IchimokuSetup_Today -DataPast $IchimokuSetup_Yday -Timeframe 'D' | % {
        $Triggers += [PSCustomObject]@{
            Stock = "$stock"
            Date = $stockData[0].Date
            Trigger = $_
            Rating = $OverallRating
        }
    }

    #Gets Ichimoku triggers on weekly timeframe
    Get-IchimokuTriggers -DataNow $IchimokuSetup_CurrentWeek -DataPast $IchimokuSetup_LastWeek -Timeframe 'W' | % {
        $Triggers += [PSCustomObject]@{
            Stock = $stock
            Date = "$($weekData[0].Week)_$($weekData[0].Year)"
            Trigger = $_
            Rating = $OverallRating
        }
    }

    $CCITable += [PSCustomObject]@{
        Stock = $stock
        DailyCCI = $DailyCCI
        WeeklyCCI = $WeeklyCCI
    }
}

$output = @()
$output += "‼️DAILY & WEEKLY TRIGGERS"

$Triggers | Select Rating | Sort-Object {$_.Rating -as [int]} -Descending | Get-Unique -AsString | % {
    $rating = $_.Rating
    Write-Host "Rating: $rating"
    $output += "Rating: $rating"
    $Triggers | Select Stock, Rating | Where Rating -eq $rating | Sort-Object Stock | Get-Unique -AsString | % {
        $stock = $_.Stock
        $stock
        $output += $stock
        $Triggers | Select Stock, Rating, Trigger | Where {($_.Stock -eq $stock) -and ($_.Rating -eq $rating)} | % {
            "  $($_.Trigger)"
            $output += "  $($_.Trigger)"
        }
    }
    
    $output += "`n"
    "`n"
}


#$DailyHeatmap | Sort-Object Rating -Descending | Export-Csv "$PSScriptRoot\Daily Heatmap\DailyHeatmap_$($([datetime]$stockData[0].Date).ToString('MMddyyyy')).csv"
#$WeeklyHeatmap | Sort-Object Rating -Descending | Export-Csv "$PSScriptRoot\Weekly Heatmap\WeeklyHeatmap_$($weekData[0].Week)_$($weekData[0].Year).csv"

$IchimokuHeatmap = @()
for($i = 0; $i -lt $DailyHeatmap.Count; $i++){
    $IchimokuHeatmap += [PSCustomObject]@{
        Stock = $DailyHeatmap[$i].Stock
        D_TS = $DailyHeatmap[$i].D_TS
        D_KS = $DailyHeatmap[$i].D_KS
        D_Kumo = $DailyHeatmap[$i].D_Kumo
        D_CS = $DailyHeatmap[$i].D_CS
        "D_TS/KS" = $DailyHeatmap[$i]."D_TS/KS"
        D_FutureKumo = $DailyHeatmap[$i].D_FutureKumo
        D_CCI = $DailyHeatmap[$i].D_CCI
        D_Rating = $DailyHeatmap[$i].D_Rating
        W_TS = $WeeklyHeatmap[$i].W_TS
        W_KS = $WeeklyHeatmap[$i].W_KS
        W_Kumo = $WeeklyHeatmap[$i].W_Kumo
        W_CS = $WeeklyHeatmap[$i].W_CS
        "W_TS/KS" = $WeeklyHeatmap[$i]."W_TS/KS"
        W_FutureKumo = $WeeklyHeatmap[$i].W_FutureKumo
        W_CCI = $WeeklyHeatmap[$i].W_CCI
        W_Rating = $WeeklyHeatmap[$i].W_Rating
        OverallRating = $DailyHeatmap[$i].D_Rating + $WeeklyHeatmap[$i].W_Rating
    }
}

$IchimokuHeatmap | Sort-Object OverallRating -Descending | Export-Csv "$PSScriptRoot\Ichimoku Scanner\Ichimoku Heatmap\IchimokuHeatmap_$($([datetime]$stockData[0].Date).ToString('MMddyyyy')).csv"

$CCITable | Export-Csv "$PSScriptRoot\CCI\CCI_$($([datetime]$stockData[0].Date).ToString('MMddyyyy')).csv"
$output > "$PSScriptRoot\Ichimoku Scanner\Triggers\IchimokuTriggers_$($([datetime]$stockData[0].Date).ToString('MMddyyyy')).txt"
$Triggers | Sort-Object Rating -Descending | Export-Csv "$PSScriptRoot\Ichimoku Scanner\Triggers\IchimokuTriggers_$($([datetime]$stockData[0].Date).ToString('MMddyyyy')).csv"
