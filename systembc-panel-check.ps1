# Ensure you have the necessary text files in the same directory as this script.

$choice = Read-Host 'Enter 1 to input IP address/range manually, 2 to read from ips.txt, or 3 to read from ranges.txt'
$outputChoice = Read-Host 'Enter 1 to output to screen or 2 to output to a file'

# Counters for the summary
$systemBCFoundCount = 0
$cleanCount = 0

# Function to calculate the number of usable IPs based on subnet mask
function Get-UsableIPs {
    param (
        [int]$subnetMask
    )
    if ($subnetMask -eq 32) {
        return 1
    } else {
        return [math]::Pow(2, (32 - $subnetMask)) - 2
    }
}

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
        if ($outputChoice -eq '1') {
            Write-Output "SystemBC Found: $url"
        } else {
            Add-Content -Path .\output.txt -Value "SystemBC Found: $url"
        }
    } else {
        $script:cleanCount++ # Increment the counter
        if ($outputChoice -eq '1') {
            Write-Output "Clean: $ip"
        } else {
            Add-Content -Path .\output.txt -Value "Clean: $ip"
        }
    }
}

if ($choice -eq '1') {
    $ipInput = Read-Host 'Enter IP address or IP address range'
    # Check if input is IP range
    if ($ipInput -match '\/') {
        $ipParts = $ipInput -split '\/'
        $subnetMask = [int]$ipParts[1]
        $usableIPs = Get-UsableIPs -subnetMask $subnetMask
        $ipBase = $ipParts[0] -split '\.'
        if ($subnetMask -eq 32) {
            Test-HttpConnection -ip $ipInput.Replace("/32", "")
        } else {
            1..$usableIPs | ForEach-Object {
                $ip = "$($ipBase[0]).$($ipBase[1]).$($ipBase[2]).$_"
                Test-HttpConnection -ip $ip
            }
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
} elseif ($choice -eq '3') {
    # Reading IP ranges from ranges.txt
    $ranges = Get-Content -Path .\ranges.txt
    foreach ($range in $ranges) {
        $ipParts = $range -split '\/'
        $subnetMask = [int]$ipParts[1]
        $usableIPs = Get-UsableIPs -subnetMask $subnetMask
        $ipBase = $ipParts[0] -split '\.'
        if ($subnetMask -eq 32) {
            Test-HttpConnection -ip $range.Replace("/32", "")
        } else {
            1..$usableIPs | ForEach-Object {
                $ip = "$($ipBase[0]).$($ipBase[1]).$($ipBase[2]).$_"
                Test-HttpConnection -ip $ip
            }
        }
    }
} else {
    Write-Output 'Invalid choice'
}

# Display the summary
if ($outputChoice -eq '1') {
    Write-Output "`nSummary:"
    Write-Output "Total SystemBC Found: $systemBCFoundCount"
    Write-Output "Total Clean IPs: $cleanCount"
} else {
    Add-Content -Path .\output.txt -Value "`nSummary:"
    Add-Content -Path .\output.txt -Value "Total SystemBC Found: $systemBCFoundCount"
    Add-Content -Path .\output.txt -Value "Total Clean IPs: $cleanCount"
}
