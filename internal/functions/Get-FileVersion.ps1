<#! https://blogs.technet.microsoft.com/askpfeplat/2014/12/07/how-to-correctly-check-file-versions-with-powershell/#>
function Get-FileVersion {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName, Mandatory = $true, ValueFromPipeline=$true)]
        [string] $Path
    )
    BEGIN { 
        Write-Verbose "Starting the BEGIN section of $($MyInvocation.MyCommand.Name)"
       
        if ([System.String]::IsNullOrEmpty($Path)) {
            Write-Warning "You didn't supply a valid Path ($Path) for Get-FileVersion. Run the script again if you need to continue."
            Write-Error -Message"You didn't supply a valid Path ($Path) for Get-FileVersion. Run the script again if you need to continue." -ErrorAction Stop
        }

        Write-Verbose "End the BEGIN section of $($MyInvocation.MyCommand.Name)"
    }

    PROCESS {
        Write-Verbose "Starting the PROCESS section of $($MyInvocation.MyCommand.Name)"
        $Filepath = Get-Item -Path $Path

        [PSCustomObject]@{
            FileVersion = $Filepath.VersionInfo.FileVersion
            ProductVersion = $Filepath.VersionInfo.ProductVersion
            FileVersionUpdated = "$($Filepath.VersionInfo.FileMajorPart).$($Filepath.VersionInfo.FileMinorPart).$($Filepath.VersionInfo.FileBuildPart).$($Filepath.VersionInfo.FilePrivatePart)"
            ProductVersionUpdated = "$($Filepath.VersionInfo.ProductMajorPart).$($Filepath.VersionInfo.ProductMinorPart).$($Filepath.VersionInfo.ProductBuildPart).$($Filepath.VersionInfo.ProductPrivatePart)"
        }

        Write-Verbose "End the PROCESS section of $($MyInvocation.MyCommand.Name)"        
    }

    END {}
}

