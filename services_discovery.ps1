# Get all Windows services that start with "Thor."
$services = Get-Service | Where-Object { $_.DisplayName -like "Thor.*" }

# Create an array to store the results
$results = @()

# Iterate through each service
foreach ($service in $services) {
    # Extract env and shortname from the service name using the separator "."
    $serviceName = $service.DisplayName
    Write-Host "Processing service: $serviceName"

    # Use Get-Service to get the actual process ID (PID) for the service
    $serviceInfo = Get-Service -Name $serviceName

    if ($serviceInfo) {
        $targetProcessID = $serviceInfo.ServiceProcessId

        # Check if the process ID is not 0
        if ($targetProcessID -ne 0) {
            Write-Host "Target process ID: $targetProcessID"

            # Get the ParentProcessId (PPID) to find the hosting svchost.exe process
            $parentProcessId = (Get-CimInstance Win32_Process -Filter "ProcessId = $targetProcessID").ParentProcessId

            # Get the hosting svchost.exe process for the service
            $hostingSvchost = Get-Process -Id $parentProcessId | Where-Object { $_.ProcessName -eq 'svchost' } | Select-Object -ExpandProperty Path

            Write-Host "Hosting svchost.exe process: $hostingSvchost"

            # Get TCP connections associated with the specified process ID
            $tcpConnections = Get-NetTCPConnection | Where-Object { $_.OwningProcess -eq $targetProcessID }
            Write-Host "Found $($tcpConnections.Count) TCP connections for process ID: $targetProcessID"

            # Extract the port from the TCP connections
            $port = $tcpConnections.LocalPort | Select-Object -Unique
            Write-Host "Extracted port: $port"

            # Create a hashtable with the extracted information
            $result = @{
                'env'       = $serviceName.Split(".")[1]
                'shortname' = ($serviceName.Split(".")[2..$($serviceName.Split(".").Count - 1)]) -join '.'
                'port'      = $port
                'svchost'   = $hostingSvchost
            }

            # Add the hashtable to the results array
            $results += New-Object PSObject -Property $result
        }
        else {
            Write-Host "Error: Target process ID is 0 for service $serviceName."
        }
    }
    else {
        Write-Host "Unable to retrieve information for service $serviceName."
    }
}

# Display the results in a table
$results | Format-Table -AutoSize
