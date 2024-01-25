# Get all Windows services that start with "Thor."
$services = Get-Service | Where-Object { $_.DisplayName -like "Thor.*" }

# Create an array to store the results
$results = @()

# Iterate through each service
foreach ($service in $services) {
    # Extract env and shortname from the service name using the separator "."
    $serviceName = $service.DisplayName
    Write-Host "Processing service: $serviceName"

    # Use Get-WmiObject to get the actual process ID (PID) for the service
    $serviceInfo = Get-WmiObject Win32_Service | Where-Object { $_.DisplayName -eq $serviceName }
    
    if ($serviceInfo) {
        $targetProcessID = $serviceInfo.ProcessId
        Write-Host "Target process ID: $targetProcessID"

        # Get TCP connections associated with the specified process ID
        $tcpConnections = Get-NetTCPConnection | Where-Object { $_.OwningProcess -eq $targetProcessID }
        Write-Host "Found $($tcpConnections.Count) TCP connections for process ID: $targetProcessID"

        # Extract the port from the TCP connections
        $port = $tcpConnections.LocalPort | Select-Object -Unique
        Write-Host "Extracted port: $port"

        # Create a hashtable with the extracted information
        $result = @{
            'env'       = $serviceInfo.DisplayName.Split(".")[1]
            'shortname' = ($serviceInfo.DisplayName.Split(".")[2..$($serviceInfo.DisplayName.Split(".").Count - 1)]) -join '.'
            'port'      = $port
        }

        # Add the hashtable to the results array
        $results += New-Object PSObject -Property $result
    }
    else {
        Write-Host "Unable to retrieve information for service $serviceName."
    }
}

# Display the results in a table
$results | Format-Table -AutoSize
