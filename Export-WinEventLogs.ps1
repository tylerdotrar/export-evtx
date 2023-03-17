function Export-WinEventLogs {
#.SYNOPSIS
# Export Windows Event Logs to a format ingestible by Security Onion (.evtx)
# ARBITRARY VERSION NUMBER:  1.5.7
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# Exports Windows Event Logs to an archive, which can then be exported to different
# SIEMs and SecurityOnion solutions (utilizing 'so-import-evtx'). Exports files to
# Public Documents directory (%PUBLIC%\Documents).
#
# Attempts to export the following logsets by default:
#   "Application",
#   "System",
#   "Security",
#   "Microsoft-Windows-Sysmon/Operational",
#   "Microsoft-Windows-PowerShell/Operational"
#
# MUST BE RAN WITH ELEVATED PRIVILEGES.
#
# Parameters:
#    -Context       -->    The name of the TTP being collected (example: 'Sliver HTTP C2')
#    -Offset        -->    The last X minutes of logs to collect (default: last 30 minutes)
#    -OutputDir     -->    Intended output directory (default: %PUBLIC%\Documents)
#    -LogSet        -->    Additional logset to collect & export.
#    -Help          -->    Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/export-evtx

    [Alias('export-evtx')]

    Param (
        [string] $Context = "Default Context",
        [int]    $Offset = 30,
		[string] $LogSet,
		[string] $OutputDir,
        [switch] $Help
    )    
    

    # Return help information
    if ($Help) { return (Get-Help Export-WinEventLogs) }


    # Exit if session doesn't have elevated privileges
    $User = [Security.Principal.WindowsIdentity]::GetCurrent();
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if (!$isAdmin) { return (Write-Host 'This script requires elevated privileges.' -ForegroundColor Red) }


    # Format Time as Sortable and UTC
    $CurrentTime = Get-Date ((Get-Date).ToUniversalTime()) -Format s
    $OffsetTime  = Get-Date ((Get-Date).ToUniversalTime().AddMinutes(-$Offset)) -Format s

    # Simplified Date and Time for notes.txt
    $SimpleTime1 = Get-Date (Get-Date).AddMinutes(-$Offset) -Format "HH:mm"
    $SimpleTime2 = Get-Date -Format "HH:mm"
    $SimpleDate  = Get-Date -Format "yyyy-MM-dd"


    # Logs to Capture & Logs Currently Available on the Host
    $LogSets = @(
        "Application",
        "System",
        "Security",
        "Microsoft-Windows-Sysmon/Operational",
        "Microsoft-Windows-PowerShell/Operational"
    )
	if ($LogSet) { $LogSets += $LogSet }
    $AvailableLogs = (Get-WinEvent -ListLog *).LogName


    # Context for what is being Captured
    $ContextName = $Context.Replace(' ','-')

	if (!$OutputDir) { $OutputDir   = "$env:PUBLIC\Documents\Evtx_$ContextName" }
    else { $OutputDir += "\Evtx_$ContextName" }

    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null


    # Iterate through all log types with unique names
    Write-Host "Outputing last $Offset minutes of Windows Event Logs..." -ForegroundColor Yellow
    foreach ($Set in $LogSets) {
        
        if ($AvailableLogs -contains $Set) {

            $SetName = ($Set.Split('/')[0]).Split('-')[-1]
            wevtutil export-log $Set "$OutputDir\$(hostname)_$SetName.evtx" "/q:*[System[TimeCreated[@SystemTime<=`'$CurrentTime`' and @SystemTime>=`'$OffsetTime`']]]"

            if (Test-Path -LiteralPath "$OutputDir\$(hostname)_$SetName.evtx") { Write-Host "- $OutputDir\$(hostname)_$SetName.evtx" }
            else { Write-Host "- $OutputDir\$(hostname)_$SetName.evtx [FAILED]" -ForegroundColor Red }
        }
    }


    # Log Collection Information
    Write-Output @"
----------
EVENT LOGS
----------
HOSTNAME : $env:COMPUTERNAME
CONTEXT  : $Context
DATE     : $SimpleDate
TIME     : $SimpleTime1 - $SimpleTime2
"@ > $OutputDir\notes.txt
    Write-Host "- $OutputDir\notes.txt"
    

    # Compress output logs to a .zip
    Write-Host "Compressing output logs..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    Compress-Archive -Path "$OutputDir\*" -DestinationPath "$OutputDir\${ContextName}_$SimpleDate.zip" | Out-Null
    Write-Host "- $OutputDir\${ContextName}_$SimpleDate.zip"
}