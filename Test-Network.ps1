#####Set Local Variables
 #Set Host Names, or IP Addresses
 $hostnames = Read-Host -Prompt "Enter hostnames"
 #SQL Server Name\Instance
 $SQLname = Read-Host -Prompt "Enter SQL instance"
 #Configure Run Time in Minutes (helpful for debugging)
 $RunTime = 10
 #Configure an allowance for late pings (in ms, one way)
 $allowance = 0
 #####
 
 ### test connectivity ###
 Write-Host "Test Connectivity:"
 
 Write-Host "Testing Ping"
 $ping = New-Object System.Net.NetworkInformation.ping
 
 foreach($a in $hostnames){
 $status = $ping.send($a).Status
 if($status -ne "Success"){
 throw "Ping Failed to $($a)"
 }
 }
 Write-Host " - Succeeded `n"
 
 
 
 ### test SQL connectivity ###
 Write-Host "Testing SQL Connection"
 $SQLConnection = New-Object System.Data.Odbc.OdbcConnection
 $SQLConnection.connectionstring = "Driver={SQL Server};Server=$SQLname"
 $SQLConnection.open()
 if($SQLConnection.state -ne "Open"){
 throw "SQL Connection Failed"
 }
 Write-Host " - Succeeded `n"
 
 
 
 ### Intra-server latency consistency test ###
 Write-Host "Start network consistency test"
 
 
 $ScriptBlock = {
 # accept the loop variable across the job-context barrier
 param($InHost, $RunTime) 
 
 $start = [DateTime]::Now
 $ping = New-Object System.Net.NetworkInformation.ping
 
 $PingResults = @()
 while([datetime]::now -le $start.AddMinutes($RunTime)){ 
 $outping = $ping.send($InHost)
 if($outping.Status -ne "Success"){
 $PingResults = $PingResults + 100
 } else{
 $PingResults = $PingResults + $outping.RoundtripTime
 }
 Start-Sleep .1
 } 
 return $PingResults
 }
 
 
 #run ping jobs in parallel
 foreach($i in $hostnames){
 Start-Job $ScriptBlock -ArgumentList $i, $RunTime -Name "$i.latency_test"
 }
 
 Write-Host "
 processing...`n"
 
 #wait and clean up
 While (Get-Job -State "Running") { Start-Sleep 5 }
 
 $output = @{}
 foreach($i in $hostnames){
 $output[$i] = Receive-Job -Name "$i.latency_test"
 }
 Remove-Job *
 
 #test results
 $LatencyTestFailed = 0
 foreach($i in $hostnames){
 $BadPings = $output[$i] | ?{$_/2 -ge 1 + $allowance}
 $PercentBadPings = $BadPings.length / $output[$i].Length * 100
 if($PercentBadPings -ge .1){
 "$i DOES NOT meet the latency requirements with $PercentBadPings % of pings >$(1+$allowance)ms" | Write-Host
 $LatencyTestFailed = 1
 } else{
 "$i meets the latency requirements with $PercentBadPings % of pings >$(1+$allowance)ms" | Write-Host
 }
 }
 if($LatencyTestFailed -eq 1){
 throw "Farm Latency Test Failed"
 } 