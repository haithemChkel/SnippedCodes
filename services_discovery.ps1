param (
    [string[]]$processNames,
    [string]$jsonFilePath
)

# Function to log messages
function LogMessage {
    param($message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp - $message"
}

# Initialize an empty array to store job results
$jobResults = @()

foreach ($processName in $processNames) {
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

    # Run jobs in parallel for each port
    foreach ($port in $ports) {
        $url = "http://localhost:$port/metrics"
        LogMessage "Starting job for Process $processName, Port $port"
        $job = Start-Job -ScriptBlock {
            param($url, $port, $processName)

            # Function to log messages
            function LogMessage {
                param($message)
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "$timestamp - $message"
            }

            # Function to check the HTTP status code
            function CheckHttpStatusCode {
                param($url, $port)
                try {
                    $response = Invoke-WebRequest -Uri $url -Method Head -ErrorAction Stop
                    $statusCode = $response.StatusCode
                    LogMessage "Process $processName, Port $port - HTTP Status Code: $statusCode"
                    return [PSCustomObject]@{
                        ProcessName = $processName
                        Port = $port
                        StatusCode = $statusCode
                    }
                } catch {
                    $statusCode = $_.Exception.Response.StatusCode.Value__
                    LogMessage "Process $processName, Port $port - Error: $_"
                    return [PSCustomObject]@{
                        ProcessName = $processName
                        Port = $port
                        StatusCode = $statusCode
                    }
                }
            }

            # Call the function within the job script block
            $result = CheckHttpStatusCode -url $url -port $port

            # Output the target and labels
            [PSCustomObject]@{
                targets = @("localhost:$($result.Port)")
                labels = @{
                    job = $result.ProcessName
                }
            }

        } -ArgumentList $url, $port, $processName
        $jobResults += $job
    }
}

# Wait for all jobs to complete
LogMessage "Waiting for all jobs to complete..."
Wait-Job -Job $jobResults | Out-Null

# Receive job results and remove unwanted properties
$receivedJobResults = Receive-Job -Job $jobResults | ForEach-Object { $_ | Select-Object -Property targets, labels }

# Generate JSON file content
$jsonContent = $receivedJobResults | ConvertTo-Json

# Write JSON content to a file
$jsonContent | Set-Content -Path $jsonFilePath

LogMessage "JSON file created: $jsonFilePath"

# Cleanup jobs
Remove-Job -Job $jobResults


# usage
# .\YourScript.ps1 -processNames @("Etl.Service.Rafale", "AnotherProcess") -jsonFilePath "result.json"
