cls

function Get-WeekNumber([datetime]$DateTime = (Get-Date)) {
    $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
    $cultureInfo.Calendar.GetWeekOfYear($DateTime, $cultureInfo.DateTimeFormat.CalendarWeekRule, $cultureInfo.DateTimeFormat.FirstDayOfWeek)
}

function ATR {
    param($Data, $Length)
    $HL = @()
    $HCp = @()
    $LCp = @()
    $TR = @()
    $FATR = 0
    
    $Data | % {
        $_
        Read-Host
    }


    <#for($i = $Data.Length - 1; $i -ge 1; $i--){
        #$HL += $Data[$i].High - $Data[$i].Low
        Write-Host $Data[$i].High
    }
    Write-Host $HL#>
}

#$stockList = Get-Content -Path "$PSScriptRoot\Stocklist.txt"
$priceData = [xml]$(Invoke-WebRequest -Uri http://phisix-api.appspot.com/stocks.xml).Content
$stockList = $priceData.stocks.stock | Select Symbol

$dates = @()
$files = Get-ChildItem -Path "$PSScriptRoot\PSE_DB"
$files.name | % {
    $matches = @()
    $_ -match '^(\d{4}-\d{2}-\d{2})' | Out-Null
    $dates += [datetime]$matches[0]
}

$latestDate = $($dates | Sort-Object -Descending)[0].ToString('yyyy-MM-dd')

$BBData = @()
Get-ChildItem -Path "$PSScriptRoot\PSE_DB" | Where-Object { $_.Name -like "$latestDate*" } | % {
    #$_.Name
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
            Date   = $week[$($week.Count) - 1].Date
            Week   = $week[$($week.Count) - 1].Week
            Year   = $week[$($week.Count) - 1].Year
            Open   = [double]$week[$($week.Count) - 1].Open
            High   = [double]$($week | Measure-Object -Property High -Maximum).Maximum
            Low    = [double]$($week | Measure-Object -Property Low -Minimum).Minimum
            Close  = [double]$week[0].Close
        }
    }

    Write-Host "$stock - $($stockData[0].Date)"

    $close = $stockData[0].Close

    #$ATRLength = 14
    #ATR($($stockData | Select -First $($ATRLength + 1)), $ATRLength)

    
    #$52WeekHigh = $($weekData | Select High -First 52 | Select -Skip 1 | Measure-Object -Property High -Maximum).Maximum
    #$9MH = $($weekData | Select High -First 39 | Select -Skip 1 | Measure-Object -Property High -Maximum).Maximum
    #$6MH = $($weekData | Select High -First 26 | Select -Skip 1 | Measure-Object -Property High -Maximum).Maximum
    #$3MH = $($weekData | Select High -First 13 | Select -Skip 1 | Measure-Object -Property High -Maximum).Maximum


    $52WH = $($weekData | Select High -First 52 | Measure-Object -Property High -Maximum).Maximum
    $9MH = $($weekData | Select High -First 39 | Measure-Object -Property High -Maximum).Maximum
    $6MH = $($weekData | Select High -First 26 | Measure-Object -Property High -Maximum).Maximum
    $3MH = $($weekData | Select High -First 13 | Measure-Object -Property High -Maximum).Maximum
    
    #$status = '3MH'
    $ctr = 1

    If ($3MH -eq $6MH) { $ctr++ }
    If ($3MH -eq $9MH) { $ctr++ }
    If ($3MH -eq $52WH) { $ctr++ }

    switch ($ctr) {
        2 { $status = '6MH' }
        3 { $status = '9MH' }
        4 { $status = '52WH' }
        default { $status = '3MH' }
    }
    
    Write-Host "Close: $close"
    $52WH
    $9MH
    $6MH
    $3MH
    $status
    "`n"

    $data = [PSCustomObject]@{ 
        Stock  = $stock
        Date   = $stockData[0].Date
        _52WH  = $52WH
        _9MH   = $9MH
        _6MH   = $6MH
        _3MH   = $3MH
        Status = $status
    }
    #Read-Host

    $BBData += $data
}

$BBData | Export-CSV "$PSScriptRoot\BBScanner\BBData.csv"
Write-Host "END"
Read-Host
