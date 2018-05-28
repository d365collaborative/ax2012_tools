<#
.SYNOPSIS
Export the basic details for a given AX 2012 AOS instance to a PSCustomObject as a CSV file

.DESCRIPTION
Export the basic details for a given AX 2012 AOS instance to a PSCustomObject as a CSV file.

The cmdlet parses all the details from the registry into a PSCustomObject and stores it as a csv file.

.PARAMETER RegistryKeyPath
The complete registry path to the AX 2012 AOS instance desired to be exported.

The format can be either
HKLM:\SYSTEM\ControlSet001\Services\Dynamics Server\6.0\01 
or
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\Dynamics Server\6.0\01

.PARAMETER Path
The path where to store the PSCustomObject.

If left empty the script will default to c:\temp

.EXAMPLE
Export-AxAosInstanceDetails -RegistryKeyPath "HKLM:\SYSTEM\ControlSet001\Services\Dynamics Server\6.0\01" 

Exports the desired AX 2012 AOS instance details to the default path using the PowerShell style for registry path.

.EXAMPLE
Export-AxAosInstanceDetails -RegistryKeyPath "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\Dynamics Server\6.0\01" 

Exports the desired AX 2012 AOS instance details to the default path using the classic style for registry path.

.EXAMPLE
Export-AxAosInstanceDetails -RegistryKeyPath "HKLM:\SYSTEM\ControlSet001\Services\Dynamics Server\6.0\01" -Path "C:\AX2012_Repo"

Exports the desired AX 2012 AOS instance details to 'c:\AX2012_Repo' using the PowerShell style for registry path.

.EXAMPLE
Export-AxAosInstanceDetails -RegistryKeyPath "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\Dynamics Server\6.0\01" -Path "C:\AX2012_Repo"

Exports the desired AX 2012 AOS instance details to 'c:\AX2012_Repo' using the classic style for registry path.

.NOTES
General notes
#>
function Export-AxAosInstanceDetails {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName, Mandatory = $true, ValueFromPipeline=$true)]
        [string] $RegistryKeyPath,
        [Parameter(Mandatory = $false)]
        [string] $Path

    )
    BEGIN { 
        Write-Verbose "Starting the BEGIN section of $($MyInvocation.MyCommand.Name)"
       
        if ([System.String]::IsNullOrEmpty($Path)) {
            $Path = "C:\Temp";
        }
        
        #* Make sure that the path exists or ask to create it
        if ([System.IO.Directory]::Exists($Path) -ne $True) {
            if ($PSCmdlet.ShouldContinue("Confirm that you want the script to create the path: $ExportPath", "Create path?")) {
                Write-Verbose "Confirmation supplied for creation of the path: $ExportPath"

                $null = New-Item -ItemType directory -Path $Path -Force 
            }
            else {
                Write-Verbose "Confirmation was NOT supplied for creation of the path: $ExportPath"
            
                Write-Warning "You cancelled the operation at 'Create Path'. Run the script again if you need to continue."
                Write-Error -Message "You cancelled the operation at 'Create Path'. Run the script again if you need to continue." -ErrorAction Stop
            }
        }

        Write-Verbose "End the BEGIN section of $($MyInvocation.MyCommand.Name)"
    }

    PROCESS {
        Write-Verbose "Starting the PROCESS section of $($MyInvocation.MyCommand.Name)"

        $Obj = Get-AxAosInstanceDetails $RegistryKeyPath
        $Filename = "$($Obj.RegistryName)-$($Obj.InstanceName).csv"
        $ExportPath = Join-Path $Path $Filename
        
        Write-Verbose "Saving the AxAosInstanceDetails object here: $ExportPath"

        $Obj | Export-Csv -Path $ExportPath -Force
        
        Write-Verbose "End the PROCESS section of $($MyInvocation.MyCommand.Name)"        
    }

    END {}
}