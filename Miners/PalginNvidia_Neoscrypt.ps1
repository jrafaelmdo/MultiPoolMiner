﻿using module ..\Include.psm1

$Path = ".\Bin\NeoScrypt-Palgin\hsrminer_neoscrypt.exe"
$Uri = "https://github.com/palginpav/hsrminer/raw/master/Neoscrypt%20algo/Windows/hsrminer_neoscrypt.exe"
$Fee = 0.99 # 1% miner fee

# Custom command to be applied to all algorithms
$CommonCommands = ""

# Uncomment defunct or outpaced algorithms with _ (do not use # to distinguish from default config)
$Commands = [PSCustomObject]@{
    "neoscrypt" = "" # neoscrypt, fastest!
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$Port = 4001 + 40 * $ItemCounter # Miner has currently no API port available, must use wrapper
$Type = "NVIDIA"
$Devices = ($GPUs | Where {$Type -contains $_.Type}).Device
    $Devices | ForEach-Object {
    $Device = $_

    $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where {$_ -cnotmatch "^_.+" -and $Pools.$(Get-Algorithm($_)).Name -and {$Pools.$(Get-Algorithm($_)).Protocol -eq "stratum+tcp" <#temp fix#>}} | ForEach-Object {

        $Algorithm = Get-Algorithm($_)
        $Command =  $Commands.$_

        if ($Devices.count -gt 1) {
            $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)_$($Device.Device_Norm)"
            $Command = "$(Get-CommandPerDevice -Command "$Command" -Devices $Device.Devices) -d $($Device.Devices -join ',')"
            $Index = $Device.Devices -join ","
        }

        while ([Bool](Get-NetTCPConnection -State "Listen" -LocalPort $Port -ErrorAction SilentlyContinue)) {$Port++}

        [PSCustomObject]@{
            Name        = $Name
            Type		= $Device.Type
            Device		= $Device.Device
            Path		= $Path
            Arguments	= ("-o $($Pools.$Algorithm.Protocol)://$($Pools.$Algorithm.Host):$($Pools.$Algorithm.Port) -u $($Pools.$Algorithm.User) -p $($Pools.$Algorithm.Pass) $Command $CommonCommands").trim()
            HashRates	= [PSCustomObject]@{$Algorithm = (($Stats."$($Name)_$($Algorithm)_HashRate".Week) * $Fee)}
            API			= "Wrapper"
            Port		= $Port
            URI			= $Uri
            PowerDraw   = $Stats."$($Name)_$($Algorithm)_PowerDraw".Week
            ComputeUsage= $Stats."$($Name)_$($Algorithm)_ComputeUsage".Week
            Pool		= "$($Pools.$Algorithm.Name)"
            Index		= $Index
        }
    }
    if ($Port) {$Port ++}
}
Sleep 0