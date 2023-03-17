# export-evtx
Export Windows Event Logs to a format ingestible by Security Onion (.evtx)

## Description
Exports Windows Event Logs to an archive, which can then be exported to different SIEMs and SecurityOnion solutions.

Parameters:
```
#    -Context       -->    The name of the TTP being collected (example: 'Sliver HTTP C2')
#    -Offset        -->    The last X minutes of logs to collect (default: last 30 minutes)
#    -OutputDir     -->    Intended output directory (default: %PUBLIC%\Documents)
#    -LogSet        -->    Additional logset to collect & export.
#    -Help          -->    Return Get-Help information
```

Defaults:
- Exports logs to the Public Documents directory (``%PUBLIC%\Documents``)
- Exports the the last 30 minutes of logs.
- Attempts to export the following logsets:
  - "Application",
  - "System",
  - "Security",
  - "Microsoft-Windows-Sysmon/Operational",
  - "Microsoft-Windows-PowerShell/Operational"
  
(Note: ``MUST BE RAN WITH ELEVATED PRIVILEGES.``)

## Usage
```powershell
# Below example will create a labeled .zip in containing the last 45 minutes of logs
export-evtx -Context 'Github Showcase -Offset 45 -OutputDir .\Examples
```
![Usage](https://cdn.discordapp.com/attachments/855920119292362802/1086422635778429049/image.png)

## Security Onion Ingestion
1) Move the archived logs to your Security Onion sensor via your preferred method (USB, SCP, etc.)
2) Unzip the archive
3) Import with ``so-import-evtx``

(Note: ``Below image unrelated to usage example.``)
![Ingestion](https://cdn.discordapp.com/attachments/855920119292362802/1086424386342498335/Pasted_image_20230126180644.png)

## Get-Help
![Get-Help](https://cdn.discordapp.com/attachments/855920119292362802/1086423429047128156/image.png)
