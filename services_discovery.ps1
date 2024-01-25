# Set the process name variable
$processName = "Etl.Service.Rafale"

# Function to check the HTTP status code
function CheckHttpStatusCode {
    param($url, $port)
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -ErrorAction Stop
        $statusCode = $response.StatusCode
        return [PSCustomObject]@{
            Port = $port
            StatusCode = $statusCode
        }
    } catch {
        return [PSCustomObject]@{
            Port = $port
            StatusCode = $_.Exception.Response.StatusCode.Value__
        }
    }
}

# Get the list of ports in the "Listen" state used by processes with the specified name
$ports = Get-NetTCPConnection | Where-Object { $_.OwningProcess -in (Get-Process -Name $processName).Id -and $_.State -eq 'Listen' } | Select-Object -ExpandProperty LocalPort

# Initialize an empty array to store job results
$jobResults = @()

# Run jobs in parallel for each port
foreach ($port in $ports) {
    $url = "http://localhost:$port/metrics"
    $job = Start-Job -ScriptBlock {
        param($url, $port)
        CheckHttpStatusCode -url $url -port $port
    } -ArgumentList $url, $port
    $jobResults += $job
}

# Wait for all jobs to complete
Wait-Job -Job $jobResults | Out-Null

# Receive job results
$receivedJobResults = Receive-Job -Job $jobResults

# Display the list of ports with HTTP status code 200 in 'Listen' state for the specified process
Write-Host "Ports with HTTP status code 200 in 'Listen' state for process '$processName':"
$receivedJobResults | Where-Object { $_.StatusCode -eq 200 } | Select-Object Port
