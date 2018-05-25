<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER DatabaseServer
Parameter description

.PARAMETER ModelstoreDatabase
Parameter description

.PARAMETER Path
Parameter description

.PARAMETER GenerateOlny
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
Function Import-AxModels {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        $DatabaseServer,
        [Parameter(ValueFromPipelineByPropertyName)]
        $ModelstoreDatabase,
        [Parameter()]
        [AllowEmptyString()]
        [string] $Path,    
        [switch] $GenerateOnly
    )

    BEGIN {
        Write-Verbose "Starting the BEGIN section of $($MyInvocation.MyCommand.Name)"
        
        Import-Module "C:\Program Files\Microsoft Dynamics AX\60\ManagementUtilities\Microsoft.Dynamics.ManagementUtilities.ps1"
        
        Write-Verbose "Database server is: $DatabaseServer"
        Write-Verbose "Modelstore database is: $ModelstoreDatabase"
        Write-Verbose "Path containing the axmodel files: $Path"
        Write-Verbose "GenerateOnly switch present: $($GenerateOnly.IsPresent)"
        
        Write-Verbose "End the BEGIN section of $($MyInvocation.MyCommand.Name)"
    }
    PROCESS {
        Write-Verbose "Starting the PROCESS section of $($MyInvocation.MyCommand.Name)"
        
        $AxModelsPath = (Get-ChildItem -Path $Path | Where-Object {$_.PSIsContainer} | Sort-Object CreationTime -Descending | Select-Object -First 1 | Select-Object Fullname).FullName
        Write-Verbose "Path containing the newest axmodel files: $AxModelsPath"

        $AxModelFiles = Get-ChildItem -Path $AxModelsPath -Recurse -File
        
        $res = New-Object System.Collections.ArrayList

        $AxModelFiles | ForEach-Object {
            Write-Verbose "Working on file: $($_.FullName)"
        
            if ($GenerateOnly.IsPresent) {
                Write-Verbose "GenerateOnly is active - saving the import command"

                $null = $res.Add("Install-AxModel -server $DatabaseServer -database $ModelstoreDatabase -NoPrompt -File `"$($_.FullName)`"");                
            }
            else {
                Write-Verbose "Running the import command"
                
                #Install-AXModel -Server $DatabaseServer -Database $ModelstoreDatabase -NoPrompt -File `"$($_.FullName)`"
            }
        }

        Write-Verbose "End the PROCESS section of $($MyInvocation.MyCommand.Name)"
    }

    END {
        Write-Verbose "Starting the END section of $($MyInvocation.MyCommand.Name)"
                
        if ($GenerateOnly.IsPresent) {
            Write-Verbose "GenerateOnly is active - write all import commands to console"
            
            Write-Host "`n" "The scripts to import the ax models are generated below and already copied into your clipboard. (CTRL-V) in powershell and you're good to go." -ForegroundColor Yellow    
            Write-Host $($res.ToArray() -join "`r`n")
            
            $($res.ToArray() -join "`r`n") | clip

        }

        Write-Verbose "End the END section of $($MyInvocation.MyCommand.Name)"
    }
}
