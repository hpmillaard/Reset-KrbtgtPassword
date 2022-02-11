If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit}

$DR = (Get-WmiObject Win32_ComputerSystem).DomainRole
If ($DR -eq 4 -or $DR -eq 5) {Write-Host "This is a Domain Controller, continuing" -ForegroundColor Green} Else {Write-Host "This script can only run on a Domain Controller" -ForegroundColor Red;pause}

Get-AdUser krbtgt -property created, passwordlastset, enabled
$diff = New-TimeSpan -Start ((Get-AdUser krbtgt -property passwordlastset).passwordlastset) -End (get-Date)
If ($diff.Days -gt 7){
	Write-Host "Password will be reset" -foregroundcolor Green
	Add-Type -AssemblyName System.Web
	Set-ADAccountPassword krbtgt -Reset -NewPassword (ConvertTo-SecureString -AsPlainText ([System.Web.Security.Membership]::GeneratePassword(128,64)) -Force -Verbose) –PassThru
	Get-AdUser krbtgt -property created, passwordlastset, enabled
} Else {
	Write-Host "Password already reset in the last week" -foregroundcolor Red
}

$a = new-object -comobject wscript.shell 
$Answer = $a.popup("Do you want to schedule this script to run on the first of every next month?",60,"Schedule",4)
If ($Answer -eq 6){schtasks /create /RU '""' /SC MONTHLY /D 1 /M * /TN 'reset krbtgt password' /TR ('powershell -executionpolicy bypass -file """' + $PSCommandPath + '"""') /ST 00:00 /SD 01/01/2000 /RL HIGHEST /F;pause}