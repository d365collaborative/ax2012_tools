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

.EXAMPLE
An example

.NOTES
General notes
#>
Function Export-AxModels {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        $DatabaseServer,
        [Parameter(ValueFromPipelineByPropertyName)]
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
            $Path = "c:\Temp\AXModels\";
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

        import-module "C:\Program Files\Microsoft Dynamics AX\60\ManagementUtilities\Microsoft.Dynamics.ManagementUtilities.ps1"

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

                Invoke-AxModelExport -Model $ModelName -Path $FilenameAxModel -DatabaseServer $DatabaseServer -ModelstoreDatabase $ModelstoreDatabase
            }
            else {
                Write-Verbose "Skipping $FilenameAxModel in layer $layer";
            }    
        }

        Write-Verbose "End the PROCESS section of $($MyInvocation.MyCommand.Name)"        
    }

    END {}
}
