<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER DatabaseServer
Parameter description

.PARAMETER DatabaseName
Parameter description

.PARAMETER InstanceName
Parameter description

.PARAMETER ModelstoreDatabase
Parameter description

.PARAMETER ExportPath
Parameter description

.PARAMETER Computers
Parameter description

.PARAMETER GenerateSQL
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#Get-AxAosInstance -Filter {$_.InstanceName -eq "AX2012R3_TEST"} | Start-DataRefresh -Computers VM-TESTAXSRV02 -ExportPath c:\Temp\AxModel_new -GenerateSQL -Verbose:$false
#>
function Start-DataRefresh {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        $DatabaseServer,
        [Parameter(ValueFromPipelineByPropertyName)]
        $DatabaseName,
        [Parameter(ValueFromPipelineByPropertyName)]
        $InstanceName,
        [Parameter(ValueFromPipelineByPropertyName)]
        $ModelstoreDatabase,
        [Parameter()]
        [string] $ExportPath,
        [Parameter()]
        [string[]] $Computers,
        [switch] $GenerateSQL
    )
    BEGIN {    
        Write-Verbose "Starting the BEGIN section of Start-DataRefresh.ps1"
        
        $RunLocal = $false
        $RunRemote = $false;

        $ComputersLocal = {$Computers}.Invoke() # Convert to ArrayList / Collection
        $RunLocal = $ComputersLocal.Contains($env:computername) # Check if local machine is part of the computers
        
        $null = $ComputersLocal.Remove($env:computername)
    
        #* Check if we need to run commands against remote computers
        if ($ComputersLocal.Count -gt 0) {
            $RunRemote = $true
        }
        
        if ([System.String]::IsNullOrEmpty($ExportPath)) {
            $ExportPath = "c:\Temp\AXModels\";
        }
        
        #* Make sure that the path exists or ask to create it
        if ([System.IO.Directory]::Exists($ExportPath) -ne $True) {
            if ($PSCmdlet.ShouldContinue("Confirm that you want the script to create the path: $ExportPath", "Create path?")) {
                $null = New-Item -ItemType directory -Path $ExportPath -Force 
            }
            else {
                Write-Warning "You cancelled the operation at 'Create Path'. Run the script again if you need to continue."
                Write-Error -Message "You cancelled the operation at 'Create Path'. Run the script again if you need to continue." -ErrorAction Stop
            }
        }
    
        Write-Verbose "End the BEGIN section of Start-DataRefresh.ps1"
    }
    
    PROCESS {
        <#
        #! The script checks whether it has to run against the local machine and/or remote machines multiple times during the execution.
        #! Below example shows how it is done. All actions that need to take place has this structure.
        #* if ($RunLocal) { 
        #* Do-Stuff
        #* }
        #* 
        #* if ($RunRemote) {
        #* Invoke-Command -Computername
        #* }
        #>

        Write-Verbose "Starting the PROCESS section of Start-DataRefresh.ps1"
        
        $ServiceSearch = "*ax*object*server*$InstanceName*" #* We need to make sure that we only target the specific instance
    
        Write-Verbose "The database server is: $DatabaseServer"
        Write-Verbose "The database name is: $DatabaseName"
        Write-Verbose "The AX AOS instance name is: $InstanceName"
        Write-Verbose "The file path were we will save all the exported ax models is: $ExportPath"
        Write-Verbose "The list of computers that we will work against is: $Computers"
    
        #* List status of AOS service across all computers               
        Get-AxAosService -ServiceSearch $ServiceSearch -Computers $ComputersLocal -RunOnLocal:$RunLocal -RunOnRemote:$RunRemote        
    
        #* Confirm to stop the specific AOS instance across all computers
        if ($PSCmdlet.ShouldProcess($($Computers -join ", "), "Stop AX AOS Services")) {
            Write-Verbose "Confirmation supplied for stopping the AOS instance across all computers"
            
            Stop-AxAosService -ServiceSearch $ServiceSearch -Computers $ComputersLocal -RunOnLocal:$RunLocal -RunOnRemote:$RunRemote        
        }
        else {
            Write-Verbose "Confirmation was NOT supplied for stopping the AOS instance across all computers"
            Write-Warning "You cancelled the operation at 'Stop Services'. Run the script again if you need to continue."
            Write-Error -Message "You cancelled the operation at 'Stop Services'. Run the script again if you need to continue." -ErrorAction Stop
        }
    
        #* List status of AOS service across all computers               
        Get-AxAosService -ServiceSearch $ServiceSearch -Computers $ComputersLocal -RunOnLocal:$RunLocal -RunOnRemote:$RunRemote        
    
        #* Confirm to export all AX models from the modelstore
        if ($PSCmdlet.ShouldProcess($InstanceName, "Export all of the models from the modelstore")) {
            Write-Verbose "Confirmation supplied for exporting all the AX models from the modelstore"
            
            Export-AxModels -DatabaseServer $DatabaseServer -ModelstoreDatabase $ModelstoreDatabase -Path $ExportPath
        }
        else {
            Write-Verbose "Confirmation was NOT supplied for exporting all the AX models from the modelstore"
            Write-Warning "You skipped the export of all models. Unless you have backups in place or don't the need the export, you should consider restarting the script"
        }
        
        Write-Host "`n" "If you want to take a backup of the databases for this instance now is the time" -ForegroundColor Yellow
    
        #* Is GenerateSQL configured - write (BACKUP) template commands to console
        if ($GenerateSQL.IsPresent) {
            Write-Verbose "Generating the SQL commands for the backup of the instance databases"
            
            $sqlTemp = New-Object System.Collections.ArrayList 

            $DateString = $((Get-Date).ToString("yyyyMMdd"))
            
            $null = $sqlTemp.Add((Initialize-SQLScript -Inputs @{DATABASENAME = $DatabaseName; BACKUPPATH = "$(Join-Path $ExportPath $DatabaseName)_$DateString.bak"; DATESTRING = $DateString; FILE = "BackupDatabaseTemplate"}))
            $null = $sqlTemp.Add("")
            $null = $sqlTemp.Add((Initialize-SQLScript -Inputs @{DATABASENAME = $ModelstoreDatabase; BACKUPPATH = "$(Join-Path $ExportPath $ModelstoreDatabase)_$DateString.bak"; DATESTRING = $DateString; FILE = "BackupDatabaseTemplate"}))            
            $($sqlTemp.ToArray() -join "`r`n") | clip
        
            Write-Host "`n" "The sql scripts to do a backup is generated below and already copied into your clipboard. (CTRL-V) in SSMS and you're good to go." -ForegroundColor Yellow    
            Write-Host "`n" $($sqlTemp.ToArray() -join "`r`n")
        }
    
        #* Confirm that backup was taken for this environment or that we don't need it
        if ($PSCmdlet.ShouldContinue("Confirm that you either did take a backup of the databases or don't want to", "Backup $InstanceName databases")) {
            Write-Verbose "Confirmation supplied for backup either being executed or not needed"
        }
        else {
            Write-Verbose "Confirmation was NOT supplied for backup either being executed or not needed"
            Write-Warning "You cancelled the operation at 'Backup Confirmation'. Run the script again if you need to continue."
            Write-Error -Message "You cancelled the operation at 'Backup Confirmation'. Run the script again if you need to continue." -ErrorAction Stop
        }
            
        Write-Host "`n" "Now you can overwrite the database with the backup you want" -ForegroundColor Yellow
    
        #* Is GenerateSQL configured - write (RESTORE) template commands to console
        if ($GenerateSQL.IsPresent) {
            Write-Verbose "Generating the SQL commands for the backup of the instance databases"

            $sqlTemp = New-Object System.Collections.ArrayList 

            $DateString = $((Get-Date).ToString("yyyyMMdd"))

            $null = $sqlTemp.AddRange((Initialize-SQLScript -Inputs @{DATABASENAME = $DatabaseName; RESTOREPATH = "$(Join-Path $ExportPath $DatabaseName)_$DateString.bak"; FILE = "RestoreDatabaseTemplate"}))
            $null = $sqlTemp.Add("")
            $null = $sqlTemp.AddRange((Initialize-SQLScript -Inputs @{DATABASENAME = $ModelstoreDatabase; RESTOREPATH = "$(Join-Path $ExportPath $ModelstoreDatabase)_$DateString.bak"; FILE = "RestoreDatabaseTemplate"}))            
            $($sqlTemp.ToArray() -join "`r`n") | clip
        
            Write-Host "`n" "The sql scripts to generate the restore commands is generated below and already copied into your clipboard. (CTRL-V) in SSMS and you're good to go." -ForegroundColor Yellow    
            Write-Host "`n" $($sqlTemp.ToArray() -join "`r`n")
        }
    
        #* Confirm that restore was executed successfully
        if ($PSCmdlet.ShouldContinue("Confirm that you did restore the databases", "Restore databases into $InstanceName ")) {    
            Write-Verbose "Confirmation supplied for that the restore of the databases was executed successfully"
        }
        else {
            Write-Verbose "Confirmation was NOT supplied for that the restore of the databases was executed successfully"
            Write-Warning "You cancelled the operation at 'Restore Confirmation'. Run the script again if you need to continue."
            Write-Error -Message "You cancelled the operation at 'Restore Confirmation'. Run the script again if you need to continue." -ErrorAction Stop
        }
    
        #* Confirm to import all AX models from path into the modelstore
        if ($PSCmdlet.ShouldProcess($InstanceName, "Import all of the ax models into the modelstore")) {
            Write-Verbose "Confirmation supplied for the AX models into the modelstore database"

            Import-AxModels -DatabaseServer $DatabaseServer -ModelstoreDatabase $ModelstoreDatabase -Path $ExportPath -GenerateOnly

            #* Confirm that all needed AX models are imported or that they are not needed
            if ($PSCmdlet.ShouldContinue("Confirm that you imported all needed AX models or you don't need any. ", "AX models imported into $InstanceName ")) {    
                Write-Verbose "Confirmation supplied for that the import of AX models into the modelstore was completed or not needed"
            }
            else {
                Write-Verbose "Confirmation was NOT supplied for that the import of AX models into the modelstore was completed or not needed"
                Write-Warning "You cancelled the operation at 'AX models imported'. Run the script again if you need to continue."
                Write-Error -Message "You cancelled the operation at 'AX models imported'. Run the script again if you need to continue." -ErrorAction Stop
            }
        }
        else {
            Write-Verbose "Confirmation was NOT supplied for the AX models into the modelstore database"
            Write-Warning "You skipped the import of all models. Unless you don't the need to import the axmodels, you should consider restarting the script"
        }
        
        Write-Host "`n" "Now is a good time to run the Data Refresh SQL Script for the environment" -ForegroundColor Yellow
        
        #* Confirm that the SQL script for this environment was executed successfully or that we don't need it
        if ($PSCmdlet.ShouldContinue("Confirm that you executed the SQL Script that refreshes data or you don't need it. ", "SQL Data Refresh Script executed in $InstanceName ")) {    
        }
        else {
            Write-Warning "You cancelled the operation at 'SQL Data Refresh'. Run the script again if you need to continue."
            Write-Error -Message "You cancelled the operation at 'SQL Data Refresh'. Run the script again if you need to continue." -ErrorAction Stop
        }
    
        #* Confirm that start the AOS instance on the primary AOS server (first computer in list)
        if ($PSCmdlet.ShouldProcess($Computers[0], "Start primary AX AOS Service")) {
            Write-Verbose "Confirmation supplied for starting the primary AX AOS instance"
            
            if ($Computers[0] -eq $env:computername) {
                Start-AxAosService -ServiceSearch $ServiceSearch -RunOnLocal:$true
            }
            else {
                Start-AxAosService -ServiceSearch $ServiceSearch -Computers $Computers[0] -RunOnRemote:$true
            }
        }
        else {
            Write-Verbose "Confirmation was NOT supplied for starting the primary AX AOS instance"
            Write-Warning "You cancelled the operation at 'Start AX AOS Services'. Run the script again if you need to continue."
            Write-Error -Message "You cancelled the operation at 'Start AX AOS Services'. Run the script again if you need to continue." -ErrorAction Stop
        }
    
        #* List status of AOS service across all computers               
        Get-AxAosService -ServiceSearch $ServiceSearch -Computers $ComputersLocal -RunOnLocal:$RunLocal -RunOnRemote:$RunRemote        
    
        Write-Host "`n" "After the AX AOS service has started you should open an AX client and synchronize the database" -ForegroundColor Yellow
        
        #* Confirm that the database synchronization was executed successfully or that we don't need it
        if ($PSCmdlet.ShouldContinue("Confirm that you executed and completed the database synchronization from inside the AX client or you don't need it. ", "AX Database Synchronization completed in $InstanceName ")) {    
            Write-Verbose "Confirmation supplied for that the database synchronization was completed successfully"
        }
        else {
            Write-Verbose "Confirmation was NOT supplied for that the database synchronization was completed successfully"
            Write-Warning "You cancelled the operation at 'Database Synchronization'. Run the script again if you need to continue."
            Write-Error -Message "You cancelled the operation at 'Database Synchronization'. Run the script again if you need to continue." -ErrorAction Stop
        }
    
        Write-Host "`n" "After the completion of the database synchronization inside AX you should run the AX Data Refresh job from inside AX" -ForegroundColor Yellow

        #* Confirm that the AX Data Refresh job executed successfully or that we don't need it        
        if ($PSCmdlet.ShouldContinue("Confirm that you executed and completed the AX Data Refresh job from inside AX. ", "AX Data Refresh executed in $InstanceName ")) {    
            Write-Verbose "Confirmation supplied for that the AX Data Refresh job was executed and completed successfully or that it is not needed"
        }
        else {
            Write-Verbose "Confirmation was NOT supplied for that the AX Data Refresh job was executed and completed successfully or that it is not needed"
            Write-Warning "You cancelled the operation at 'AX Data Refresh Execution'. Run the script again if you need to continue."
            Write-Error -Message "You cancelled the operation at 'AX Data Refresh Execution'. Run the script again if you need to continue." -ErrorAction Stop
        }

        #* Confirm to start the specific AOS instance across all computers
        if ($PSCmdlet.ShouldProcess($($Computers -join ", "), "Start AX AOS Services")) {
            Write-Verbose "Confirmation supplied for starting the AX AOS instance across all computers"
            
            Start-AxAosService -ServiceSearch $ServiceSearch -Computers $ComputersLocal -RunOnLocal:$RunLocal -RunOnRemote:$RunRemote
        }
        else {
            Write-Verbose "Confirmation was NOT supplied for starting the AX AOS instance across all computers"
            
            Write-Warning "You cancelled the operation at 'Start Services'. Run the script again if you need to continue."
        }

        #* List status of AOS service across all computers               
        Get-AxAosService -ServiceSearch $ServiceSearch -Computers $ComputersLocal -RunOnLocal:$RunLocal -RunOnRemote:$RunRemote        
    }
    
    END {}
}
    
    