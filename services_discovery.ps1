# Set the process name variable
$processName = "Etl.Service.Rafale"

# Function to check the HTTP status code
function CheckHttpStatusCode($url) {
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -ErrorAction Stop
        return $response.StatusCode
    } catch {
        return $_.Exception.Response.StatusCode.Value__
    }
}

# Get the list of ports used by processes with the specified name
$ports = Get-NetTCPConnection | Where-Object { $_.OwningProcess -in (Get-Process -Name $processName).Id } | Select-Object -ExpandProperty LocalPort

# Initialize an empty list to store ports with HTTP status code 200
$portsWithStatusCode200 = @()

# Run parallel checks for each port
$ports | ForEach-Object -Parallel {
    param($port)
    $url = "http://localhost:$port/metrics"
    $statusCode = CheckHttpStatusCode $url

    if ($statusCode -eq 200) {
        $portsWithStatusCode200 += $port
    }

} -ArgumentList $_

# Display the list of ports with HTTP status code 200
Write-Host "Ports with HTTP status code 200 for process '$processName':"
$portsWithStatusCode200
