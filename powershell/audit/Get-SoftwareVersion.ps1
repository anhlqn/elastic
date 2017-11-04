#Requires -Version 4.0
Import-Module "$PSScriptRoot\Common-Functions.psm1" -Force

# ---------------------- SCRIPT CONFIGURATION ----------------------
$runTime = (Get-Date).ToUniversalTime().ToString("o")

$jsonFilePath = "$PSScriptRoot\software_$((Get-Date).ToString("yyyyMMdd_HHmmss")).json"

# ---------------------- SCRIPT IMPLEMENTATION ---------------------
Test-RunInterval -Interval "0" -RunTime $runTime

$computers = @()

$computers += Get-ComputerName -DN "OU=Computers,DC=example,DC=com"

Invoke-Command -ComputerName $computers -HideComputerName -ArgumentList $runTime -ErrorAction SilentlyContinue -ScriptBlock {
    param (
        $runTime
    )

    $hostname = "$env:COMPUTERNAME".ToLower()    

    Clear-Variable softwareList -ErrorAction SilentlyContinue
    
    Function Get-SoftwareVersion {
        param(
            [string]$RegistryPath
        )

        Get-ItemProperty -Path $RegistryPath -ErrorAction SilentlyContinue | select DisplayName, DisplayVersion, InstallLocation, InstallDate, InstallSource, ModifyPath | 
            Where-Object {$_.DisplayName -and $_.DisplayName -notlike "Update for*" -and $_.DisplayName -notlike "Security Update*" -and $_.DisplayName -notlike "Service Pack*" } | 
            foreach {
                Add-Member -InputObject $_ -MemberType NoteProperty -Name "hostname" -Value $hostname
                Add-Member -InputObject $_ -MemberType NoteProperty -Name "department" -Value "it"
                Add-Member -InputObject $_ -MemberType NoteProperty -Name "category" -Value "software"
                Add-Member -InputObject $_ -MemberType NoteProperty -Name "type" -Value "audit"   
                Add-Member -InputObject $_ -MemberType NoteProperty -Name "@timestamp" -Value $runTime
                return $_
            }
    }

    $softwareList += Get-SoftwareVersion -RegistryPath "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $softwareList += Get-SoftwareVersion -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

    return $softwareList
} | foreach {
    Write-JSON -Path $jsonFilePath -InputObject $PSItem -PassThru
}
