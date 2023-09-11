function ConvertToIP {
    param (
        [long]$ipInt
    )
    $octet1 = $ipInt -band 0xFF
    $octet2 = ($ipInt -shr 8) -band 0xFF
    $octet3 = ($ipInt -shr 16) -band 0xFF
    $octet4 = ($ipInt -shr 24) -band 0xFF
    return "$octet4.$octet3.$octet2.$octet1"
}

function ConvertToInteger {
    param (
        [string]$ip
    )
    $octets = $ip -split '\.'
    return [long]($octets[0] -shl 24) + [long]($octets[1] -shl 16) + [long]($octets[2] -shl 8) + [long]$octets[3]
}

function GetIPRange {
    param (
        [string]$ipRange
    )
    # Check if subnet mask is provided
    if (-not ($ipRange -like "*/*")) {
        $ipRange += "/32"
    }
    $ip, $subnet = $ipRange -split '/'
    $ipInt = ConvertToInteger -ip $ip
    $subnetSize = [math]::Pow(2, (32 - [int]$subnet))
    return $ipInt, $subnetSize
}

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
        Start-Sleep -Seconds 0
    }
    if ($success) {
        return "SystemBC Found: $url"
    } else {
        return $null
    }
}

function WriteToOutput {
    param (
        [string]$message
    )
    if ($outputChoice -eq 1) {
        Write-Output $message
    } elseif ($outputChoice -eq 2) {
        $message | Out-File -Append 'output.txt'
    }
}

$choice = Read-Host 'Enter 1 to input IP address/range manually, 2 to read from ips.txt, or 3 to read from ranges.txt'
$outputChoice = Read-Host 'Enter 1 to output to screen or 2 to output to a file'

$foundPanels = @()

if ($choice -eq 1) {
    $ipRange = Read-Host 'Enter IP address or IP address range'
    $ipInt, $subnetSize = GetIPRange -ipRange $ipRange
    if ($subnetSize -eq 1) { # If it's a single IP
        $result = Test-HttpConnection -ip (ConvertToIP -ipInt $ipInt)
        if ($result) { 
        $foundPanels += $result 
        WriteToOutput $result
    }
    } else { # If it's a range
        for ($i = 1; $i -lt $subnetSize; $i++) {
            $currentIP = ConvertToIP -ipInt ($ipInt + $i)
            $result = Test-HttpConnection -ip $currentIP
            if ($result) { $foundPanels += $result }
        }
    }

} elseif ($choice -eq 2) {
    $ips = Get-Content 'ips.txt'
    foreach ($ip in $ips) {
        $result = Test-HttpConnection -ip $ip
        if ($result) { 
        $foundPanels += $result 
        WriteToOutput $result
    }
    }
} elseif ($choice -eq 3) {
    if (Test-Path 'ranges.txt') {
        $ranges = Get-Content 'ranges.txt'
        Write-Output "Reading from ranges.txt..."
        foreach ($range in $ranges) {
            Write-Output "Processing range: $range"
            $ipInt, $subnetSize = GetIPRange -ipRange $range
            for ($i = 1; $i -lt $subnetSize; $i++) {
                $currentIP = ConvertToIP -ipInt ($ipInt + $i)
                $result = Test-HttpConnection -ip $currentIP
                if ($result) { 
        $foundPanels += $result 
        WriteToOutput $result
        Write-Output "Found panel at: $currentIP"
    }
                     
                    
                
            }
        }
    } else {
        Write-Output "ranges.txt not found in the current directory!"
    }
}

# Display summary at the end
$foundCount = $foundPanels.Count
$summary = "`nSummary:`nTotal SystemBC Panels Found: $foundCount"
$foundPanels += $summary

if ($outputChoice -eq 1) {
    $foundPanels | ForEach-Object { Write-Output $_ }
} elseif ($outputChoice -eq 2) {
    Write-Output "Writing results to file..."
    $foundPanels | Out-File -Append 'output.txt'
    Start-Process explorer.exe -ArgumentList (Get-Location).Path
    Write-Output "Results written to output.txt"
}
