Function Stop-AxAosService {
    Param(        
        [Parameter()]
        [string] $ServiceSearch,    
        [Parameter()]
        [string[]] $Computers,        
        [bool] $RunOnLocal,
        [bool] $RunOnRemote
    )
    BEGIN {
        Write-Verbose "Starting the BEGIN section of $($MyInvocation.MyCommand.Name)"
        Write-Verbose "End the BEGIN section of $($MyInvocation.MyCommand.Name)"
    }
    PROCESS {
        Write-Verbose "Starting the PROCESS section of $($MyInvocation.MyCommand.Name)"
        
        #* List status of AOS service across all computers
        if ($RunOnLocal -eq $true) { 
            Get-Service -Display $ServiceSearch | Stop-Service
        }

        if ($RunOnRemote -eq $true) {
            Invoke-Command -ComputerName $Computers { param($ServiceSearch) Get-Service -Display $ServiceSearch | Stop-Service} -ArgumentList $ServiceSearch
        }

        Write-Verbose "End the PROCESS section of $($MyInvocation.MyCommand.Name)"
        
    }

    END {}
    
}