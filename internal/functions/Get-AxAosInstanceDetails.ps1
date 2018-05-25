function Get-AxAosInstanceDetails {
    param(
        [string] $RegistryPath
    )
    $RegKey = Get-Item -Path $RegistryPath.Replace("HKEY_LOCAL_MACHINE", "HKLM:")

    $InstanceDetail = @{}
    $InstanceDetail.RegistryKeyPath = $RegKey.Name
    $InstanceDetail.RegistryName = Split-Path -Path $RegKey.Name -Leaf
    
    $RegTemp = Get-ItemProperty -Path ($RegKey.Name).Replace("HKEY_LOCAL_MACHINE", "HKLM:")
    $InstanceDetail.InstanceName = $RegTemp.InstanceName
    $InstanceDetail.ConfigurationName = $RegTemp.Current        
        
    $RegTemp = Get-ItemProperty -Path (Join-Path $InstanceDetail.RegistryKeyPath $InstanceDetail.ConfigurationName).Replace("HKEY_LOCAL_MACHINE", "HKLM:")
    $InstanceDetail.BinDirectory = $RegTemp.bindir
    $InstanceDetail.DatabaseName = $RegTemp.database
    $InstanceDetail.DatabaseServer = $RegTemp.dbserver
    $InstanceDetail.ModelstoreDatabase = "$($RegTemp.database)_model"
    $InstanceDetail.NetTCPPort = $RegTemp.NetTCPPort
    $InstanceDetail.AosPort = $RegTemp.port
    $InstanceDetail.WSDLPort = $RegTemp.WSDLPort

    return [pscustomobject]$InstanceDetail
}

