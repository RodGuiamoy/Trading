cls
$dates = @()
$files = Get-ChildItem -Path "$PSScriptRoot\PSE_DB"
$files.name | % {
    $matches = @()
    $_ -match '\d{4}-\d{2}-\d{2}' | Out-Null
    $dates += [datetime]$matches[0]
}

$latestDate = $($dates | Sort-Object -Descending)[0].ToString('yyyy-MM-dd')

$files = Get-ChildItem -Path "$PSScriptRoot\PSE_DB" | Where-Object {$_.Name -like "$latestDate*"}
$files | % {
    $matches = @()
    $_ -match '._(.+?)\.csv' | Out-Null
    #$matches[1]

    $_.FullName
}