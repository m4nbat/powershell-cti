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
    if ($ipRange -notmatch '/') {
        $ipRange += '/32'
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
    $expectedContent = '<pre align=center><form method=post>Password: <input type=password name=pass><input type=submit value=">>"></form></pre>'
    
    foreach ($url in $urls) {
        try {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 1 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200 -and $response.BaseResponse.ResponseUri.AbsoluteUri -eq $url -and $response.Content.Contains($expectedContent)) {
                return "SystemBC Found: $url"
            }
        } catch {
            Write-Output "Failed to connect to $url"
        }
        Start-Sleep -Seconds 0
    }
    return "Clean: $ip"
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

if ($choice -eq 1) {
    $ipRange = Read-Host 'Enter IP address or IP address range'
    $ipInt, $subnetSize = GetIPRange -ipRange $ipRange
    for ($i = 0; $i -lt $subnetSize; $i++) {
        $currentIP = ConvertToIP -ipInt ($ipInt + $i)
        $result = Test-HttpConnection -ip $currentIP
        WriteToOutput $result
    }
} elseif ($choice -eq 2) {
    $ips = Get-Content 'ips.txt'
    foreach ($ip in $ips) {
        $result = Test-HttpConnection -ip $ip
        WriteToOutput $result
    }
} elseif ($choice -eq 3) {
    $ranges = Get-Content 'ranges.txt'
    foreach ($range in $ranges) {
        $ipInt, $subnetSize = GetIPRange -ipRange $range
        for ($i = 0; $i -lt $subnetSize; $i++) {
            $currentIP = ConvertToIP -ipInt ($ipInt + $i)
            $result = Test-HttpConnection -ip $currentIP
            WriteToOutput $result
        }
    }
}

if ($outputChoice -eq 2) {
    Write-Output "Results written to output.txt"
    Start-Process explorer.exe -ArgumentList (Get-Location).Path
}

# Display summary at the end
$foundCount = $foundPanels.Count
$summary = "`nSummary:`nTotal SystemBC Panels Found: $foundCount"
$foundPanels += $summary
