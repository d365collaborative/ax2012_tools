Function Initialize-SQLScript {
    Param(
        [hashtable] $Inputs
    )

    # $temp = @{
    #     DATABASENAME = 'AX2012R3_TEST'
    #     BACKUPPATH = 'C:\Temp\AX2012R3_TEST.bak'
    #     DATESTRING = '20180524'
    # }

    $str = Get-Content -Path ".\Ax2012_Tools\internal\sql\$($Inputs.File).sql"
    
    $Inputs.Keys | ForEach-Object {
        $str = $str.Replace("#$_#", "$($Inputs[$_])")
    }

    return $str
}