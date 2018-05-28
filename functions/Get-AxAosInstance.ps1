<#
.SYNOPSIS
Gets the Dynamics AX 2012 instances installed on the computer

.DESCRIPTION
Gets the Dynamics AX 2012 instances installed on the computer. 

It reads the registry where all installed AX 2012 AOS instance details are stored.

.PARAMETER Filter
An advanced filter to select the desired instances - '{$_.PROPERTY -eq VALUE}'

.EXAMPLE
Get-AxAosInstance

Get all installed AX 2012 AOS instances.

.EXAMPLE
Get-AxAosInstance -filter {$_.InstanceName -eq "AX2012R3_TEST"}

Gets the AX 2012 AOS instance with the AX2012_TEST as the instance name. This value can be found using the "Microsoft Dynamics AX 2012 Server Configuration"

.NOTES
The cmdlet supports pipe to other cmdlets. 
#>
function Get-AxAosInstance {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ScriptBlock]$Filter
    )
    BEGIN {}
    
    PROCESS {
        Write-Verbose "Starting the PROCESS section of $($MyInvocation.MyCommand.Name)"
        
        $Instances = Get-ChildItem -Path "HKLM:\SYSTEM\ControlSet001\Services\Dynamics Server\6.0"
        
        $res = New-Object System.Collections.ArrayList 
    
        $Instances | ForEach-Object {                
            $null = $res.Add((Get-AxAosInstanceDetails $_.Name))
        }
    
        if (-not ($Filter -eq $null)) {
            Write-Output ( $res | Where-Object $Filter)
        }
        else {
            Write-Output ($res)
        }
        
        Write-Verbose "End the PROCESS section of $($MyInvocation.MyCommand.Name)"
    }
    
    END {}
}