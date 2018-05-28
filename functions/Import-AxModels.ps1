<#
.SYNOPSIS
Export AX 2012 models from the AX 2012 modelstore.

.DESCRIPTION
Export AX 2012 models from the AX 2012 modelstore database.

Utilizes the standard Microsoft Dynamics AX 2012 Powershell module to export all models from the modelstore database.
.PARAMETER DatabaseServer
The DNS or FullyQualifiedDomainName of the server running the SQL Server Database Engine. 

If the SQL Server runs with at named instance you have to supply that as part of the name.
.PARAMETER ModelstoreDatabase
The name of the database that contains the modelstore desired to export AX 2012 models from.

Please note that AX 2012 RTM & AX 2012 Feature Pack stores the modelstore inside the business database.

Please note that AX 2012 R2 & AX 2012 R3 stores the modelstore in a separate database.

.PARAMETER Path
The path where to store the all the AX 2012 models.

The cmdlet will append current date to the path, to ensure that it doesn't overwrite older exports

.EXAMPLE
Export-AxModels -DatabaseServer "SQL2012" -ModelstoreDatabase "AX2012R3_TEST_model"

Exports the AX 2012 models from the AX2012R3_TEST_model database located on server named SQL2012 and storing the files on the default path

.EXAMPLE
Export-AxModels -DatabaseServer "SQL2012" -ModelstoreDatabase "AX2012R3_TEST_model" -Path "C:\AX2012_Repo"

Exports the AX 2012 models from the AX2012R3_TEST_model database located on server named SQL2012 and storing the files in "C:\AX2012_Repo"

.EXAMPLE
Export-AxModels -DatabaseServer "SQL2012\TEST" -ModelstoreDatabase "AX2012R3_TEST_model"

Exports the AX 2012 models from the AX2012R3_TEST_model database located on server named SQL2012 with the TEST SQL instance and storing the files on the default path

.NOTES
General notes
#>
Function Import-AxModels {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName, Mandatory = $true, ValueFromPipeline=$true)]
        $DatabaseServer,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory = $true, ValueFromPipeline=$true)]
        $ModelstoreDatabase,
        [Parameter()]
        [AllowEmptyString()]
        [string] $Path,    
        [switch] $GenerateOnly
    )

    BEGIN {
        Write-Verbose "Starting the BEGIN section of $($MyInvocation.MyCommand.Name)"
        
        if ([System.IO.Directory]::Exists($Path) -ne $True) {
            Write-Warning "The path ($Path) supplied to Import-AxModels cmdlet doesn't not exists or your credentials doesn't have enough permissions"
            Write-Error -Message "The path ($Path) supplied to Import-AxModels cmdlet doesn't not exists. Run the script again if you need to continue." -ErrorAction Stop
        }
        
        $null = Import-Module "C:\Program Files\Microsoft Dynamics AX\60\ManagementUtilities\Microsoft.Dynamics.ManagementUtilities.ps1"
        
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

                $null = $res.Add("Install-AxModel -server $DatabaseServer -database $ModelstoreDatabase -NoPrompt -File `"$($_.FullName)`" -Conflict Overwrite");                
            }
            else {
                Write-Verbose "Running the import command"
                
                #Install-AXModel -Server $DatabaseServer -Database $ModelstoreDatabase -NoPrompt -File `"$($_.FullName)`" -Conflict Overwrite
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
