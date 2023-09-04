<#
.NOTES
    Name:      GetScheduledTaskStatus.ps1
    Version:   1.00
    Author:    Markus Keinath
    Requires:  PowerShell Version 5 or higher
               Windows Remote Management (WinRM) configured on the target host

.SYNOPSIS
    Retrieve the status information of a registered scheduled task in windows and return the results in Json format

.DESCRIPTION
    This script uses the cmdlets Get-ScheduledTask and Get-ScheduledTaskInfo to retrieve status informations of a scheduled task.
    It is written for use with the Advanced EXE/Script Sensor of PRTG Network Monitor.
    To get information of a remote host, WinRM needs to be configured. Use 'winrm qc' for quick configuration on the remote host
    (see https://learn.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management)

    PRTG links:  https://www.paessler.com/manuals/prtg/exe_script_advanced_sensor
                 https://www.paessler.com/manuals/prtg/custom_sensors
                 https://kb.paessler.com/en/topic/86669-powershell-prtg-advanced-custom-sensor-json-and-xml

.PARAMETERS
    TargetHost:  Name of the host where the scheduled task is configured
    TaskName:    Name of an existing scheduled task on the target host
    TaskPath:    Path of the scheduled task (you need to include a leading and trailing backslash)

.EXAMPLES
    -TargetHost 'myServer' - TaskName 'myTask' -TaskPath '\myPath\'

.OUTPUTS
    Text in JSON Format structured for PRTG Network Monitor

.CHANGELOG
    1.00       initial release
#>

Param(
    [Parameter(Mandatory=$true)][string]$TargetHost,
    [Parameter(Mandatory=$true)][string]$TaskName,
    [Parameter(Mandatory=$false)][string]$TaskPath = '\'
)

Try {
    # leading and trailing backslash is mandatory for the used cmdlet
    If ($TaskPath.Substring($TaskPath.Length - 1, 1) -ne '\') {
        $TaskPath = $TaskPath + '\'
    }
    
    # if running on local host don't use a CimSession (otherwise elevated rights are needed)
    $objDNS = [System.Net.Dns]::GetHostByName($env:COMPUTERNAME)
    If (($TargetHost -eq $env:COMPUTERNAME) -or ($TargetHost -eq $objDNS.HostName) -or ($TargetHost -match $objDNS.AddressList)) {    
        $objTask = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction Stop
        $objTaskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -TaskPath $TaskPath -ErrorAction Stop
    } Else {
        $SessionID = New-CimSession -ComputerName $TargetHost -ErrorAction Stop
        $objTask = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -CimSession $SessionID -ErrorAction Stop
        $objTaskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -TaskPath $TaskPath -CimSession $SessionID -ErrorAction Stop
    }

    # convert the return values to the format needed by PRTG (only digits allowed)
    $TaskEnabled = [int]$objTask.Settings.Enabled
    $TaskLastTaskResult = [int]$objTaskInfo.LastTaskResult
    $TaskLastRunTime = ($objTaskInfo.LastRunTime).ToString('ddMMyyyy')
    
    $Success = $true
} Catch {
    # error messages in non english format needs to be converted in ASCII, otherwise PRTG can't read the Json text
    $Message = $Error[0]
    $EncMsg = [System.Text.Encoding]::ASCII.GetBytes($Message)
    $Message = [System.Text.Encoding]::ASCII.GetString($EncMsg)
    $Success = $false
} Finally {
    Get-CimSession | Remove-CimSession -ErrorAction SilentlyContinue | Out-Null
}

# create the PRTG response in JSON format   
If ($Success -eq $true) {
    If ($TaskEnabled -eq 0) {
        $Msg1 = 'disabled'
    } Else {
        $Msg1 = 'enabled'
    }
    $Message = "The scheduled task '$TaskPath$TaskName' on host '$TargetHost' is $Msg1 and ran last at $TaskLastRunTime with a result code of $TaskLastTaskResult."

    $Channels = @()
    $Channels += [pscustomobject]@{
        'channel'         = 'Last task result'
        'value'           =  "$TaskLastTaskResult"
        'unit'            = 'Count'
        'float'           = '0'
        'showChart'       = '0'
        'showTable'       = '0'
        'LimitMaxError'   = '0'
        'LimitErrorMsg'   = 'Resultcode is <> 0!'
        'LimitMode'       = '1'
    }
    $Channels += [pscustomobject]@{
        'channel'         = 'Task Enabled'
        'value'           = "$TaskEnabled"
        'unit'            = 'Count'
        'float'           = '0'
        'showChart'       = '0'
        'showTable'       = '0'
        'LimitMinError'   = '1'
        'LimitErrorMsg'   = 'Task is not active!'
        'LimitMode'       = '1'
    }
    $Channels += [pscustomobject]@{
        'channel'         = 'Last run time'
        'value'           = "$TaskLastRunTime"
        'unit'            = 'Custom'
        'customUnit'      = 'date'
        'float'           = '0'
        'showChart'       = '0'
        'showTable'       = '0'
    }

    $Result = [pscustomobject]@{
        result = $Channels
        text = "$Message"
    }
    $PRTGResult = [pscustomobject]@{prtg = $Result}
    $PRTGResult = ConvertTo-Json -InputObject $PRTGResult -Depth 3 -ErrorAction SilentlyContinue
# return an error message if something went wrong
} Else {
    $Result = [pscustomobject]@{
        error = '1'
        text = "$Message"
    }
    $PRTGResult = [pscustomobject]@{prtg = $Result}
    $PRTGResult = ConvertTo-Json -InputObject $PRTGResult -ErrorAction SilentlyContinue
}

# return the result to console
$PRTGResult