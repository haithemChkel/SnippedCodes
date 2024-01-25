# Set the process name variable
$processName = "Etl.Service.Rafale"

# Function to log messages
function LogMessage {
    param($message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp - $message"
}

# Get processes with the specified name
$matchingProcesses = Get-Process -Name $processName

# Log information about matching processes
LogMessage "Processes with name '$processName' found:"
$matchingProcesses | ForEach-Object {
    LogMessage "Process Name: $($_.ProcessName), PID: $($_.Id)"
}

# Get the list of process IDs
$processIds = $matchingProcesses.Id

# Get the list of ports in the "Listen" state used by the specified processes
$ports = Get-NetTCPConnection | Where-Object { $_.OwningProcess -in $processIds -and $_.State -eq 'Listen' } | Select-Object -ExpandProperty LocalPort

LogMessage "Found ports in 'Listen' state for processes with name '$processName': $ports"

# Initialize an empty array to store job results
$jobResults = @()

# Run jobs in parallel for each port
foreach ($port in $ports) {
    $url = "http://localhost:$port/metrics"
    LogMessage "Starting job for Port $port"
    $job = Start-Job -ScriptBlock {
        param($url, $port)
        CheckHttpStatusCode -url $url -port $port
    } -ArgumentList $url, $port
    $jobResults += $job
}

# Wait for all jobs to complete
LogMessage "Waiting for all jobs to complete..."
Wait-Job -Job $jobResults | Out-Null

# Receive job results
$receivedJobResults = Receive-Job -Job $jobResults

# Display the list of ports with HTTP status code 200 in 'Listen' state for the specified process
$portsWithStatusCode200 = $receivedJobResults | Where-Object { $_.StatusCode -eq 200 } | Select-Object Port
LogMessage "Ports with HTTP status code 200 in 'Listen' state for processes with name '$processName': $portsWithStatusCode200"

# Cleanup jobs
Remove-Job -Job $jobResults
