# Get all services with names starting with "Thor."
$services = Get-Service | Where-Object { $_.DisplayName -like "Thor.*" }

# Iterate through each matching service
foreach ($service in $services) {
    # Get service dependencies
    $serviceDependencies = Get-Service $service.ServiceName | Select-Object -ExpandProperty Dependencies

    # Extract port information from service dependencies
    $port = $serviceDependencies -match ':\d+' | ForEach-Object { $_ -replace '.*:(\d+)', '$1' }

    # Display service name and port if port information is found
    if ($port) {
        Write-Host "Service Name: $($service.DisplayName), Port: $port"
    } else {
        Write-Host "Service Name: $($service.DisplayName), Port information not found."
    }
}
