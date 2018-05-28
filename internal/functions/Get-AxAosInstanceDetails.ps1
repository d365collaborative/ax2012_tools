function Get-AxAosInstanceDetails {
    param(
        [string] $RegistryPath
    )
    $RegKey = Get-Item -Path $RegistryPath.Replace("HKEY_LOCAL_MACHINE", "HKLM:")
    $RegOuter = Get-ItemProperty -Path ($RegKey.Name).Replace("HKEY_LOCAL_MACHINE", "HKLM:")
    $RegInner = Get-ItemProperty -Path (Join-Path $RegKey.Name $RegOuter.Current).Replace("HKEY_LOCAL_MACHINE", "HKLM:")
    $BuildNumbers = Get-FileVersion -Path $(Join-Path $RegInner.bindir "Ax32Serv.exe")

    $InstanceDetail = [ordered]@{}
    
    $InstanceDetail.InstanceName = $RegOuter.InstanceName
    $InstanceDetail.ConfigurationName = $RegOuter.Current        
    $InstanceDetail.BinDirectory = $RegInner.bindir

    $InstanceDetail.FileVersion = $BuildNumbers.FileVersion
    $InstanceDetail.ProductVersion = $BuildNumbers.ProductVersion
    $InstanceDetail.FileVersionUpdated = $BuildNumbers.FileVersionUpdated
    $InstanceDetail.ProductVersionUpdated = $BuildNumbers.ProductVersionUpdated

    $InstanceDetail.DatabaseServer = $RegInner.dbserver
    $InstanceDetail.DatabaseName = $RegInner.database
    $InstanceDetail.ModelstoreDatabase = "$($RegInner.database)_model"

    $InstanceDetail.AosPort = $RegInner.port
    $InstanceDetail.WSDLPort = $RegInner.WSDLPort
    $InstanceDetail.NetTCPPort = $RegInner.NetTCPPort
    
    $InstanceDetail.RegistryKeyPath = $RegKey.Name
    $InstanceDetail.InstanceNumber = Split-Path -Path $RegKey.Name -Leaf
       
    [pscustomobject]$InstanceDetail
}

