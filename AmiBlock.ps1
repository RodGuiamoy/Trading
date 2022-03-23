$exe = get-childitem -Path 'C:\Program Files (x86)\AmiBroker\*.exe' -recurse
for($i = 1; $i -le $exe.Count; $i++){
    $exe[$i].fullname
    #New-NetFirewallRule -DisplayName "Block Ami $i" -Direction Inbound -Action Block -Program $exe[$i].fullname
    New-NetFirewallRule -DisplayName "Block Ami $i" -Direction Outbound -Action Block -Program $exe[$i].fullname
}