# Get all services with names starting with "Thor."
$services = Get-Service | Where-Object { $_.DisplayName -like "Thor.*" }

# Iterate through each matching service
foreach ($service in $services) {
    # Get service description
    $serviceDescription = Get-Service $service.ServiceName | Select-Object -ExpandProperty Description

    # Extract port information from the service description
    $portRegex = [regex]::Matches($serviceDescription, 'Port:\s*(\d+)')
    
    # Display service name and port if port information is found
    if ($portRegex.Success) {
        $port = $portRegex.Groups[1].Value
        Write-Host "Service Name: $($service.DisplayName), Port: $port"
    } else {
        Write-Host "Service Name: $($service.DisplayName), Port information not found."
    }
}
