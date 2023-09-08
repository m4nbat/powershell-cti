# Usage Instructions for Option 2:
# Ensure you have a CSV file named 'ips.csv' in the same directory as this script.
# The CSV file should have a column named 'IPAddress' containing the list of IP addresses.

$choice = Read-Host 'Enter 1 to input IP address/range manually or 2 to read from ips.csv'

# Function to test connection
function Test-HttpConnection {
    param (
        [string]$ip
    )
    $urls = @("http://$ip/systembc/password.php", "http://$ip/www/systembc/password.php")
    $success = $false
    foreach ($url in $urls) {
        try {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200 -and $response.BaseResponse.ResponseUri.AbsoluteUri -eq $url) {
                $success = $true
                break
            }
        } catch {
            # Do nothing on error
        }
    }
    if ($success) {
        Write-Output "Success: $ip"
    } else {
        Write-Output "Fail - no panel: $ip"
    }
}

if ($choice -eq '1') {
    $ipInput = Read-Host 'Enter IP address or IP address range'
    # Check if input is IP range
    if ($ipInput -match '\/') {
        $ipParts = $ipInput -split '\/'
        $ipBase = $ipParts[0] -split '\.'
        1..254 | ForEach-Object {
            $ip = "$($ipBase[0]).$($ipBase[1]).$($ipBase[2]).$_"
            Test-HttpConnection -ip $ip
        }
    } else {
        Test-HttpConnection -ip $ipInput
    }
} elseif ($choice -eq '2') {
    $ips = Import-Csv -Path .\ips.csv
    foreach ($ip in $ips.IPAddress) {
        Test-HttpConnection -ip $ip
    }
} else {
    Write-Output 'Invalid choice'
}
