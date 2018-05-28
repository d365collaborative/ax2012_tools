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
Function Export-AxModels {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName, Mandatory = $true, ValueFromPipeline=$true)]
        $DatabaseServer,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory = $true, ValueFromPipeline=$true)]
        $ModelstoreDatabase,
        [Parameter()]
        [AllowEmptyString()]
        [string]$Path
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

        $null = import-module "C:\Program Files\Microsoft Dynamics AX\60\ManagementUtilities\Microsoft.Dynamics.ManagementUtilities.ps1"

        Write-Verbose "End the BEGIN section of $($MyInvocation.MyCommand.Name)"
    }

    PROCESS {
        #region Variables
        Write-Verbose "Starting the PROCESS section of $($MyInvocation.MyCommand.Name)"

        [System.Collections.ArrayList] $layerList = New-Object System.Collections.ArrayList        
        $layerDictionary = @{"ISV" = "01."; "ISP" = "02."; "VAR" = "03."; "VAP" = "04."; "CUS" = "05."; "CUP" = "06."; "USR" = "07." ; "USP" = "08."}

        [System.Xml.XmlDocument] $xmlge
        [System.Xml.XmlNode] $obj
        [System.Xml.XmlNode] $property

        #endregion
        
        $backupFilePath = New-FolderWithDateTime -Path $Path
        $xml = (Get-AXModel -Server $DatabaseServer -Database $ModelstoreDatabase | ConvertTo-Xml )
        $nodes = $xml.SelectNodes("Objects/Object")

        foreach ($obj in $nodes) {
            $FilenameAxModel = "";
            $elementCount = "";
            $ModelId = "";

            # Loop all properties
            foreach ($property in $obj.SelectNodes("Property")) {
                if ($property.GetAttribute("Name").Equals( "Name" )) {
                    $ModelName = $property.InnerText
                    $FilenameAxModel = $ModelId + "_" + $ModelName + ".axmodel"
                }
        
                if ($property.GetAttribute("Name").Equals( "Layer" )) {
                    $layer = $property.InnerText
                }
        
                if ($property.GetAttribute("Name").Equals( "ElementCount" )) {
                    $elementCount = $property.InnerText
                }

                if ($property.GetAttribute("Name").Equals( "ModelId" )) {
                    $ModelId = $property.InnerText
                }
            }
    
            if ($layerDictionary.ContainsKey($layer.ToUpper()) -and $FilenameAxModel -ne "") {        
                $localLayer = $layerDictionary.Get_Item($layer.ToUpper()) + $layer.ToUpper();
                $TempPath = [System.IO.Path]::Combine($backupFilePath, "$localLayer")
        
                if ([System.IO.Directory]::Exists($TempPath) -ne $True) {            
                    $null = New-Item -ItemType directory -Path $TempPath -Force;            
                }
        
                $FilenameAxModel = [System.IO.Path]::Combine($TempPath, $FilenameAxModel)
                        
                Write-Verbose "Exporting $elementCount elements from $ModelName...";

                Invoke-ExportAxModel -Model $ModelName -Path $FilenameAxModel -DatabaseServer $DatabaseServer -ModelstoreDatabase $ModelstoreDatabase
            }
            else {
                Write-Verbose "Skipping $FilenameAxModel in layer $layer";
            }    
        }

        Write-Verbose "End the PROCESS section of $($MyInvocation.MyCommand.Name)"        
    }

    END {}
}
