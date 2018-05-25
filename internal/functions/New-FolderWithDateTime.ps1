Function New-FolderWithDateTime {
    param(
        [string] $Path
    )

    $dte = Get-Date
    $dte = $dte.ToString() -replace "[:\s/]", "."
    
    $backUpPath = [System.IO.Path]::Combine($Path, $dte)
    $null = New-Item -Path $backUpPath -ItemType Directory
    return $backUpPath
}