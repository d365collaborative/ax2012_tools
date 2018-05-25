Function Get-AxAosService {
    Param(        
        [Parameter()]
        [string] $ServiceSearch = "*ax*object*server*",    
        [Parameter()]
        [string[]] $Computers,        
        [bool] $RunOnLocal,
        [bool] $RunOnRemote
    )
    BEGIN { }
    PROCESS {
        Write-Verbose "Starting the PROCESS section of $($MyInvocation.MyCommand.Name)"
        
        if ($RunOnLocal -eq $true) { 
            Get-Service -Display $ServiceSearch | Select-Object @{name = "Computer"; expression = {$env:computername}}, status, name, displayname | Format-Table -AutoSize        
        }

        if ($RunOnRemote -eq $true) {
            Invoke-Command -ComputerName $Computers { param($ServiceSearch) Get-Service -Display $ServiceSearch | Select-Object @{name = "Computer"; expression = {$env:computername}}, status, name, displayname | Format-Table -AutoSize} -ArgumentList $ServiceSearch
        }

        Write-Verbose "End the PROCESS section of $($MyInvocation.MyCommand.Name)"        
    }

    END {}
    
}