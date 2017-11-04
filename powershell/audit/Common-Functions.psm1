#Requires -Version 4.0

# Write JSON content to local file
Function Write-JSON {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$InputObject,    
        [switch]$PassThru
    )
    
    ($InputObject | ConvertTo-Json -Compress) | Out-File -FilePath $Path -Append -Force -Encoding utf8   

    If ($PassThru) {
        Write-Output $InputObject
    }
}

# Get computer objects from an AD Distinguish Name
Function Get-ComputerName {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DN,
        [string]$network = "10.0.0"
    )

    $computerNames = @()

    Get-ADComputer -SearchBase "$DN" -Filter * -SearchScope Subtree |
        Where {$PSItem.Enabled -eq "True"} | Select -ExpandProperty Name | foreach {        

        Clear-Variable rawIP -ErrorAction SilentlyContinue
        
        # Check if IP is reachable
        $rawIP = (nslookup.exe $PSItem 2> null | Select-String -Pattern $network).ToString().Trim()
    
        If ($rawIP -notmatch "^$network") {
            $rawIP = ($rawIP -split '\s+')[1]
        }            
    
        If ($rawIP -and (ping -n 1 -w 15 $rawIP | select-string "reply from" -Quiet)) {
            $computerNames += $PSItem
        }
    }    
        
    return $computerNames
}

# Split time string into amount and unit
Function Split-TimeString {
    param (
        [string]$Time
    )

    $timeObject = [PSCustomObject]@{
        Amount = [int]($Time.Substring(0, $Time.Length -1))
        Unit = $Time.Substring($Time.Length -1)
    }
    
    If ($timeObject.Unit -notin "m", "h", "d", "0") {
        Write-Warning "Invalid timestring: $Time. Require supported time unit (m, h, d)."
    }

    $totalMinutes = 0

    switch -CaseSensitive ($timeObject.Unit) {
        "m" {$totalMinutes = [int]$timeObject.Amount}
        "h" {$totalMinutes = [int]$timeObject.Amount * 60}
        "d" {$totalMinutes = [int]$timeObject.Amount * 1440}
    }

    Add-Member -InputObject $timeObject -MemberType NoteProperty -Name "Minutes" -Value $totalMinutes
    
    return $timeObject
}

# Test execution interval
Function Test-RunInterval {
    param (
        [string]$Interval,
        [datetime]$RunTime
    )
    # Parse runtime internal
    $runEveryParsed = Split-TimeString -Time $Interval

    switch -CaseSensitive ($runEveryParsed.Unit) {
        "0" {
                $validRunTime = $true
        }
        "m" {
            If (($RunTime.Minute % $runEveryParsed.Amount) -eq 0) {                
                $validRunTime = $true
            }
        }
        "h" {If (($RunTime.Hour % $runEveryParsed.Amount) -eq 0 -and $RunTime.Minute -eq 0) {
                $validRunTime = $true
            }
        }
        "d" {
            If (($RunTime.DayOfYear % $runEveryParsed.Amount) -eq 0 -and $RunTime.Hour -eq 0 -and $RunTime.Minute -eq 0) {
                $validRunTime = $true
            }
        }
        default {
            Write-Warning "Invalid runtime internal value"
            $validRunTime = $false
        }
    }

    If(-not $validRunTime) {
        Write-Output "Wrong runtime internal. Exit"
        Exit
    }
}
