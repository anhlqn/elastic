#Requires -Version 4.0
Import-Module "$PSScriptRoot\Common-Functions.psm1" -Force

# ---------------------- SCRIPT CONFIGURATION ----------------------
$runTime = (Get-Date).ToUniversalTime().ToString("o")

$jsonFilePath = "$PSScriptRoot\process_$((Get-Date).ToString("yyyyMMdd_HHmmss")).json"

# ---------------------- SCRIPT IMPLEMENTATION ---------------------
Test-RunInterval -Interval "0" -RunTime $runTime

$computers = @()

$computers += Get-ComputerName -DN "OU=Computers,DC=example,DC=com"

Invoke-Command -ComputerName $computers -HideComputerName -ArgumentList $runTime -ErrorAction SilentlyContinue -ScriptBlock {
    param (
        $runTime
    )

    $hostname = "$env:COMPUTERNAME".ToLower()        

    Clear-Variable processList -ErrorAction SilentlyContinue

    $processList = Get-Process | select @{N="process_name";E={$_.ProcessName}}, @{N="process_id";E={$_.id}},
        @{N="process_memory";E={$_.WorkingSet}}, @{N="process_path";E={$_.Path}},
        @{N="process_company";E={$_.Company}}, @{N="process_cpu";E={$_.CPU}},
        @{N="process_fullname";E={$_.Product}}, @{N="process_description";E={$_.Description}},
        @{N="process_version";E={$_.ProductVersion}},
        @{N="process_start_time";E={(Get-Date $_.StartTime).ToUniversalTime().ToString("o")}} |
        foreach {
            Add-Member -InputObject $_ -MemberType NoteProperty -Name "hostname" -Value $hostname
            Add-Member -InputObject $_ -MemberType NoteProperty -Name "department" -Value "it"
            Add-Member -InputObject $_ -MemberType NoteProperty -Name "category" -Value "process"
            Add-Member -InputObject $_ -MemberType NoteProperty -Name "type" -Value "audit"   
            Add-Member -InputObject $_ -MemberType NoteProperty -Name "@timestamp" -Value $runTime
            return $_
        }    
    
    return $processList

} | foreach {
    Write-JSON -InputObject $PSItem -Path $jsonFilePath -PassThru
}
