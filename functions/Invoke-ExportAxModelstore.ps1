<#
.SYNOPSIS
Export AX 2012 modelstore from the AX 2012 modelstore database.

.DESCRIPTION
Export AX 2012 modelstore from the AX 2012 modelstore database.

Utilizes the standard Microsoft Dynamics AX 2012 Powershell module to export the modelstore from the modelstore database.

.PARAMETER DatabaseServer
The DNS or FullyQualifiedDomainName of the server running the SQL Server Database Engine. 

If the SQL Server runs with at named instance you have to supply that as part of the name.

.PARAMETER ModelstoreDatabase
The name of the database that contains the modelstore desired to export.

Please note that AX 2012 RTM & AX 2012 Feature Pack stores the modelstore inside the business database.

Please note that AX 2012 R2 & AX 2012 R3 stores the modelstore in a separate database.

.PARAMETER Path
The path where to store the AX 2012 modelstore file.

The cmdlet will append current date to the path, to ensure that it doesn't overwrite older exports

.PARAMETER GenerateOnly
switch used to instruct the cmdlet to only generate the command and write it to console.

.EXAMPLE
Invoke-ExportAxModelstore -DatabaseServer "SQL2012" -ModelstoreDatabase "AX2012R3_TEST_model"

Exports the AX 2012 modelstore from the AX2012R3_TEST_model database located on server named SQL2012 and storing the file on the default path

.EXAMPLE
Invoke-ExportAxModelstore -DatabaseServer "SQL2012" -ModelstoreDatabase "AX2012R3_TEST_model" -Path "C:\AX2012_Repo"

Exports the AX 2012 modelstore from the AX2012R3_TEST_model database located on server named SQL2012 and storing the file in "C:\AX2012_Repo"

.EXAMPLE
Export-AxModels -DatabaseServer "SQL2012\TEST" -ModelstoreDatabase "AX2012R3_TEST_model"

Exports the AX 2012 modelstore from the AX2012R3_TEST_model database located on server named SQL2012 with the TEST SQL instance and storing the file on the default path

.EXAMPLE
Export-AxModels -DatabaseServer "SQL2012" -ModelstoreDatabase "AX2012R3_TEST_model" -GenerateOnly

Generate the command that will export the AX 2012 modelstore from the AX2012R3_TEST_model database located on server named SQL2012 with the TEST SQL instance and storing the file on the default path

.NOTES
General notes
#>
Function Invoke-ExportAxModelstore {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='DefaultPipeline',ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [Parameter(ParameterSetName='TextValues',ValueFromPipeline = $true, Mandatory = $true)]
        $DatabaseServer,
        [Parameter(ParameterSetName='DefaultPipeline',ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [Parameter(ParameterSetName='TextValues',ValueFromPipeline = $true, Mandatory = $true)]
        $ModelstoreDatabase,
        [Parameter(ParameterSetName='DefaultPipeline',ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [Parameter(ParameterSetName='TextValues',ValueFromPipeline = $true, Mandatory = $true)]
        $InstanceName,
        [Parameter(ParameterSetName='DefaultPipeline')]
        [Parameter(ParameterSetName='TextValues')]
        [AllowEmptyString()]
        [string] $Path,
        [switch] $GenerateOnly
    )

    BEGIN {
        Write-Verbose "Starting the BEGIN section of $($MyInvocation.MyCommand.Name)"
        
        if ([System.String]::IsNullOrEmpty($DatabaseServer)) {
            $DatabaseServer = "localhost";
        }

        if ([System.String]::IsNullOrEmpty($ModelstoreDatabase)) {
            $ModelstoreDatabase = "MicrosoftDynamicsAx_Model";
        }

        if ([System.String]::IsNullOrEmpty($Path)) {
            $Path = "c:\Temp";
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

        $null = Import-Module "C:\Program Files\Microsoft Dynamics AX\60\ManagementUtilities\Microsoft.Dynamics.ManagementUtilities.ps1"

        Write-Verbose "End the BEGIN section of $($MyInvocation.MyCommand.Name)"
    }

    PROCESS {
        Write-Verbose "Starting the PROCESS section of $($MyInvocation.MyCommand.Name)"
        
        $DateString = $((Get-Date).ToString("yyyyMMdd"))
        
        if ([System.String]::IsNullOrEmpty($InstanceName)) {
            $tempName = "$($ModelstoreDatabase.Replace("_model"))_$DateString"
        }
        else {
            $tempName = "$InstanceName_$DateString"
        }

        $ExportPath = Join-Path $Path $DateString

        if ($GenerateOnly.IsPresent) {
            Write-Host "Export-AxModelStore -DatabaseServer `"$DatabaseServer`" -ModelstoreDatabase `"$ModelstoreDatabase`" -File `"$ExportPath`""
        }
        else {
            Export-AxModelStore -DatabaseServer $DatabaseServer -ModelstoreDatabase $ModelstoreDatabase -File $ExportPath
        }

        Write-Verbose "End the PROCESS section of $($MyInvocation.MyCommand.Name)"        
    }

    END {}
}
