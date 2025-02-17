# Ensure Docker is running
$service = Get-Service -Name "docker" -ErrorAction SilentlyContinue
if ($service -and $service.Status -ne "Running") {
    Write-Host "Starting Docker service..."
    Start-Service -Name "docker"
    Start-Sleep -Seconds 5
} else {
    Write-Host "Docker is already running."
}

# Start Docker Compose
$composePath = "C:\path\to\your\docker-compose.yml"
if (Test-Path $composePath) {
    Write-Host "Starting Docker Compose..."
    Set-Location (Split-Path -Path $composePath)
    docker-compose up -d
} else {
    Write-Host "Error: docker-compose.yml not found at $composePath"
}