# Get all Windows services that start with "Thor."
$services = Get-Service | Where-Object { $_.DisplayName -like "Thor.*" }

# Create an array to store the results
$results = @()

# Iterate through each service
foreach ($service in $services) {
    # Extract env and shortname from the service name using the separator "."
    $serviceName = $service.DisplayName
    Write-Host "Processing service: $serviceName"

    $nameParts = $serviceName -split '\.'

    # Ensure that there are at least three parts in the name
    if ($nameParts.Count -ge 3) {
        $env = $nameParts[1]
        $shortname = ($nameParts[2..$($nameParts.Count - 1)]) -join '.'
        Write-Host "Extracted env: $env, shortname: $shortname"

        # Get the process ID (targetProcessID) for the service
        $targetProcessID = Get-WmiObject Win32_Service | Where-Object { $_.DisplayName -eq $serviceName } | Select-Object -ExpandProperty ProcessId
        Write-Host "Target process ID: $targetProcessID"

        # Get TCP connections associated with the specified process ID
        $tcpConnections = Get-NetTCPConnection | Where-Object { $_.OwningProcess -eq $targetProcessID }
        Write-Host "Found $($tcpConnections.Count) TCP connections for process ID: $targetProcessID"

        # Extract the port from the TCP connections
        $port = $tcpConnections.LocalPort | Select-Object -Unique
        Write-Host "Extracted port: $port"

        # Create a hashtable with the extracted information
        $result = @{
            'env'       = $env
            'shortname' = $shortname
            'port'      = $port
        }

        # Add the hashtable to the results array
        $results += New-Object PSObject -Property $result
    }
    else {
        Write-Host "Skipping service $serviceName. It does not have at least three parts in its name."
    }
}

# Display the results in a table
$results | Format-Table -AutoSize
