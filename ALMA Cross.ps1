cls
$CROSS = @()

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

    $ALAverage = $WtdSum / $CumWt
    return $ALAverage
    
}


$stocksList =  $(Invoke-WebRequest -Uri "https://api2.pse.tools/api/quotes").Content | ConvertFrom-Json | Select -ExpandProperty Data | gm | Select Name -Skip 4

$stocksList | % {
    $stock = $_.Name
    #$stock
    #$stockData = $($(Invoke-WebRequest -Uri "https://ph24.colfinancial.com/ape/colcharts/HISTORICAL/$stock.asp").Content | ConvertFrom-Json) | Select Date, Open, High, Low, Close | Sort-Object Date -Descending
    $stockData = Import-Csv -Path "$PSScriptRoot\PSE_DB\*_$stock.csv"
    #$stockData[0].Date
    $sigma = 6
    $offset = 0.85

    $alerts = @()
    $ALMAData = [PSCustomObject]@{}
    
    $window = 20
    $data = $stockData | Select -First $window
    $ALMA20 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    $data = $stockData | Select -Skip 1 | Select -First $window
    $Y_ALMA20 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    #"ALMA20: {0}" -f $ALMA20
    
    $window = 50
    $data = $stockData | Select -First $window
    $ALMA50 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    $data = $stockData | Select -Skip 1 | Select -First $window
    $Y_ALMA50 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    #"ALMA50: {0}" -f $ALMA50

    $window = 100
    $data = $stockData | Select -First $window
    $ALMA100 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    $data = $stockData | Select -Skip 1 | Select -First $window
    $Y_ALMA100 = ALMA -Data $data -Window $window -Sigma $sigma -Offset $offset
    #"ALMA100: {0}" -f $ALMA100

    $candle = $stockData[0]
    $Y_candle = $stockData[1]

    <#If((($ALMA4 -ge $candle.Low) -and ($ALMA4 -le $candle.High)) -and ($candle.Close -gt $candle.Open)){#>
    If((($candle.Close -gt $ALMA20) -eq $true) -and (($Y_candle.Close -gt $Y_ALMA20) -eq $false)){
        $alerts += "ALMA20 Cross!"
        
        $CROSS += [PSCustomObject]@{
            Stock = $stock
            Alert = "ALMA20 Cross!"
            Date = $candle.Date
        }
    }

    If((($candle.Close -gt $ALMA50) -eq $true) -and (($Y_candle.Close -gt $Y_ALMA50) -eq $false)){
        $alerts += "ALMA50 Cross!"
        
        $CROSS += [PSCustomObject]@{
            Stock = $stock
            Alert = "ALMA50 Cross!"
            Date = $candle.Date
        }
    }

    If((($candle.Close -gt $ALMA100) -eq $true) -and (($Y_candle.Close -gt $Y_ALMA100) -eq $false)){
        $alerts += "ALMA100 Cross!"
        
        $CROSS += [PSCustomObject]@{
            Stock = $stock
            Alert = "ALMA100 Cross!"
            Date = $candle.Date
        }
    }

    If($alerts.Count -gt 0){
        $stock
        $stockData[0].Date
        $alerts

        "`n"
    } 

}

$CROSS | Export-Csv "$PSScriptRoot\ALMA Cross\ALMACross_$($([datetime]$stockData[0].Date).ToString('MMddyyy')).csv"
#$PIERCE | Export-Csv "C:\Users\guiamoj\Desktop\Stock Screeners\ALMAPierce_$($([datetime]$stockData[0].Date).ToString('MMddyyy')).csv"
#$stockData[0]