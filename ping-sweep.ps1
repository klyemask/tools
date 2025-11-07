$servers = @"
klyetest_server_1
klyetest_server_2
"@

$servers -split "`n" | ForEach-Object {
	$server = $_
	
	Write-Host ""
	Write-Host "checking" $server -ForegroundColor Green
	$result = test-netconnection $server
	
	if ($result.PingSucceeded -eq $True) {
		Write-Host "Response Good"  -ForegroundColor Green
	} Else {
		Write-Host "Response Bad" -ForegroundColor Red
	}
	Write-Host "/////////////////////////////////////////"
}
