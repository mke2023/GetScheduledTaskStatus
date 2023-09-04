# GetScheduledTaskStatus

This script uses the cmdlets Get-ScheduledTask and Get-ScheduledTaskInfo to retrieve status informations of a scheduled task on Windows computers. It is written for use with the Advanced EXE/Script Sensor of PRTG Network Monitor. To get information of a remote host, WinRM needs to be configured. Use 'winrm qc' for quick configuration on the remote host.

In my environement this script runs reliable. Network with Windows Server Standard 2019, Windows 10 Enterprise, PRTG Network Monitor 23.3.86.1520. Feel free to discuss possible bugs in the discussion area.

Unfortunately the build in sensor 'ScheduledTask2XML' didn't work reliable for me. Finally I think there's a problem with the activation of the RemoteRegistry that is required for retrieving the information of the scheduled task on remote computers. Another possibility is to use the COM object 'Schedule.Service'. Using PSRemoting and the Invoke-Command works well except for the computer that is running the PRTG Probe. There you need elevated rights to run the script. I've found no way to handle this with the need of returning the results as a console output.

I want to share this and say thanks to all the people that posted their ideas that gave me the possibility to develop this script.

To configure a sensor with this script follow this steps:
1. Copy this script to '(PRTG Network ProgramDir)\Custom Sensors\EXEXML' (e.g. C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML)
2. If the sensor is added to a remote computer first configure WinRM on the remote computer: use 'winrm qc' for quick configuration on the remote host (for more information see https://learn.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management).
3. Create a new sensor 'EXE/Script Advanced' with the following settings:
![image](https://github.com/mke2023/GetScheduledTaskStatus/assets/144008663/e6485dda-aa3c-4fdd-95a2-a78dca680f8b)

Note: you have to save the Windows account settings that the sensor should use in one of the objects in the device hierarchy. This must be an account with administrative rights on the remote computer.
