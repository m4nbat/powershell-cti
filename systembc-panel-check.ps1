# Ensure you have a text file named 'ips.txt' in the same directory as this script.
# The text file should have one IP address per line.

$choice = Read-Host 'Enter 1 to input IP address/range manually or 2 to read from ips.txt'

# Counters for the summary
$systemBCFoundCount = 0
$cleanCount = 0

# Function to test connection
function Test-HttpConnection {
    param (
        [string]$ip
    )
    $urls = @("http://$ip/systembc/password.php", "http://$ip/www/systembc/password.php")
    $success = $false
    $expectedContent = '<pre align=center><form method=post>Password: <input type=password name=pass><input type=submit value=">>"></form></pre>'
    
    foreach ($url in $urls) {
        try {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 1 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200 -and $response.BaseResponse.ResponseUri.AbsoluteUri -eq $url -and $response.Content.Contains($expectedContent)) {
                $success = $true
                break
            }
        } catch {
            # Do nothing on error
        }
        # Introducing a delay of 0 seconds between each web request
        Start-Sleep -Seconds 0
    }
    if ($success) {
        $script:systemBCFoundCount++ # Increment the counter
        Write-Output "SystemBC Found: $url"
    } else {
        $script:cleanCount++ # Increment the counter
        Write-Output "Clean: $ip"
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
    # Reading IP addresses from ips.txt
    $ips = Get-Content -Path .\ips.txt
    foreach ($ip in $ips) {
        Test-HttpConnection -ip $ip
        # Introducing a delay of 0 seconds between each IP address check
        Start-Sleep -Seconds 0
    }
} else {
    Write-Output 'Invalid choice'
}

# Display the summary
Write-Output "`nSummary:"
Write-Output "Total SystemBC Found: $systemBCFoundCount"
Write-Output "Total Clean IPs: $cleanCount"
