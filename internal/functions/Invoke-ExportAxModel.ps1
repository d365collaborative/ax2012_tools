Function Invoke-ExportAxModel {
    [CmdletBinding()]
    param (
        [string] $Model, 
        [string] $Path, 
        [string] $DatabaseServer,
        [string] $ModelstoreDatabase
        ) 

        BEGIN {
            Write-Verbose "Starting the BEGIN section of $($MyInvocation.MyCommand.Name)"
         
            $null = Import-Module "C:\Program Files\Microsoft Dynamics AX\60\ManagementUtilities\Microsoft.Dynamics.ManagementUtilities.ps1"

            Write-Verbose "End the BEGIN section of $($MyInvocation.MyCommand.Name)"
        }
        PROCESS { 
            Write-Verbose "Starting the PROCESS section of $($MyInvocation.MyCommand.Name)"
            
            Write-Verbose "Export-AXModel -Model $Model -File $Path -DatabaseServer $DatabaseServer -Database $ModelstoreDatabase"

            $mes = Export-AXModel -Model $Model -File $Path -Server $DatabaseServer -Database $ModelstoreDatabase

            Write-Verbose $mes

            Write-Verbose "End the PROCESS section of $($MyInvocation.MyCommand.Name)"        
        } 
        END { }
    
}