# Get all Windows services that start with "Thor."
$services = Get-Service | Where-Object { $_.DisplayName -like "Thor.*" }

# Create an array to store the results
$results = @()

# Iterate through each service
foreach ($service in $services) {
    # Extract env and shortname from the service name
    $serviceName = $service.DisplayName
    $env, $shortname = $serviceName -split '\.DEV\.'

    # Get the process ID (targetProcessID) for the service
    $targetProcessID = Get-WmiObject Win32_Service | Where-Object { $_.DisplayName -eq $serviceName } | Select-Object -ExpandProperty ProcessId

    # Get TCP connections associated with the specified process ID
    $tcpConnections = Get-NetTCPConnection | Where-Object { $_.OwningProcess -eq $targetProcessID }

    # Extract the port from the TCP connections
    $port = $tcpConnections.LocalPort | Select-Object -Unique

    # Create a hashtable with the extracted information
    $result = @{
        'env'       = $env
        'shortname' = $shortname
        'port'      = $port
    }

    # Add the hashtable to the results array
    $results += New-Object PSObject -Property $result
}

# Display the results in a table
$results | Format-Table -AutoSize
