#Get-AxAosInstance -Filter {$_.InstanceName -eq "AX2012R3_TEST"}
<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Filter
Parameter description

.EXAMPLE
An example

.NOTES
General notes
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
    
#$InstallInstances