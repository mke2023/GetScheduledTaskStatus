# GetScheduledTaskStatus
Retrieve the status information of a registered scheduled task in windows and return the results in Json format

This script uses the cmdlets Get-ScheduledTask and Get-ScheduledTaskInfo to retrieve status informations of a scheduled task. It is written for use with the
Advanced EXE/Script Sensor of PRTG Network Monitor. To get information of a remote host, WinRM needs to be configured. Use 'winrm qc' for quick configuration
on the remote host (see https://learn.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management).

Unfortunately the build in sensor 'ScheduledTask2XML' didn't work reliable for me. Finally I think there's a problem with the activation of the RemoteRegistry
that is required for retrieving the information of the scheduled task on remote computers.
Another possibility is to use the COM object 'Schedule.Service'. Using PSRemoting and the Invoke-Command works well except for the computer that is running the
PRTG Probe. There you need elevated rights to run the script. I've found no way to handle this with the need of returning the results as a console output.

In my environement the script runs reliable: Windows Server Standard 2019, Windows 10 Enterprise, PRTG Network Monitor 23.3.86.1520
Feel free to discuss possible bugs in the discussion area.

I want to share this and say thanks to all the people that posted their ideas that gave me the possibility to develop this script.

Markus
