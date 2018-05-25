<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER RegistryKeyPath
Parameter description

.PARAMETER Path
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Export-AxAosInstanceDetails {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $RegistryKeyPath,
        [Parameter(Mandatory = $true)]
        [string] $Path

    )
    BEGIN { }

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