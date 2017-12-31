﻿using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-Ccminer_x11ghost\ccminer_x11gost.exe"
$Uri = "https://github.com/nicehash/ccminer-x11gost/releases/download/ccminer-x11gost_windows/ccminer_x11gost.7z"

$Port = 4068

$CommonCommands = ""

# Uncomment defunct or outpaced algorithms with _ (do not use # to distinguish from default config)
$Commands = [PSCustomObject]@{
    "blake2s"      = " -i 31,31,31" # fastest, do not use Excavator, high rejects
    "_blakecoin"   = " -i 31,31,31" # beaten by CcminerAlexis78hsr 
    "c11"         = " -i 21" # Beaten by Ccminer-HSR
    #"decred"      = "" # boo
    "_keccak"      = " -i 31,30,29" # Beaten by Excavator138aNvidia4
	"keccakc"      = "" # Keccak-256 (CreativeCoin)
    "_lbry"        = " -i 29,28,28" # Beaten by Excavator138aNvidia4
    "_lyra2v2"     = "" # beaten by CcminerAlexis78Hsr
    "_myr-gr"       = " -i 24,24,24" # Beaten by CcminerKlaust817_CUDA91
    "_neoscrypt"   = " -i 17.1,16.6,15.2" # beaten by CcminerKlaust-817-CUDA91 & PalginHSR_Neoscrypt
    "nist5"       = "" # fastest
    "_nist5"       = " -i 26.75,26.25,24.75" # fastest
	"penta"        = "" # Pentablake hash (5x Blake 512)
    "_phi"          = " -i 25,24,24" # Ccminer 2.2.3 x86 is faster
	"_polytimos"    = " -i 26.25,26.25" # polytimos, beaten by CcminerPolytimos
    "sia"          = " -i 31,31,31" #
    "sib"         = " -i 23.1,21.5,21.12" # Fastest
    "_skein"       = " -i 30,29,28.9" # beaten by CcminerSp, dodgy hasrate
    "_tribus"      = ""
    "_vanilla"     = ""
    "_veltor"      = "" # Veltor, beaten by CcminerAlexis78Hsr
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

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

		{while (Get-NetTCPConnection -State "Listen" -LocalPort $($Port) -ErrorAction SilentlyContinue){$Port++}} | Out-Null

		if ($Algorithm -ne "Decred" -and $Algorithm -ne "Sia") {
			if ($Pools.$Algorithm.Name) {
				[PSCustomObject]@{
					Name        = $Name
					Type		= $Type
					Device		= $Device.Device
					Path        = $Path
					Arguments   = "-a $Algorithm -o $($Pools.($Algorithm).Protocol)://$($Pools.($Algorithm).Host):$($Pools.($Algorithm).Port) -u $($Pools.($Algorithm).User) -p $($Pools.($Algorithm).Pass) -b $Port$Command$CommonCommands"
					HashRates   = [PSCustomObject]@{$Algorithm = ($Stats."$($Name)_$($Algorithm)_HashRate".Week)}
					API         = "Ccminer"
					Port        = $Port
					Wrap        = $false
					URI         = $Uri
					PowerDraw   = $Stats."$($Name)_$($Algorithm)_PowerDraw".Week
					ComputeUsage= $Stats."$($Name)_$($Algorithm)_ComputeUsage".Week
					Pool        = "$($Pools.$Algorithm.Name)"
					Index		= $Index
				}    
			}
		}
		else {
			if ($Pools."$($Algorithm)Nicehash".Name) {
				[PSCustomObject]@{
					Miner_Device= $Name
					Type		= $Type
					Device		= $Device.Device
					Path        = $Path
					Arguments   = "-a $Algorithm -o stratum+tcp://$($Pools."$($Algorithm)NiceHash".Host):$($Pools."$($Algorithm)NiceHash".Port) -u $($Pools."$($Algorithm)NiceHash".User) -p $($Pools."$($Algorithm)NiceHash".Pass) -b $Port$Command$CommonCommands"
					HashRates   = [PSCustomObject]@{"$($Algorithm)NiceHash" = ($Stats."$($Name)_$($Algorithm)NiceHash_HashRate".Week)}
					API         = "Ccminer"
					Port        = $Port
					Wrap        = $false
					URI         = $Uri
					PowerDraw   = $Stats."$($Name)_$($Algorithm)_PowerDraw".Week
					ComputeUsage= $Stats."$($Name)_$($Algorithm)_ComputeUsage".Week
					Pool        = $Pools."$($Algorithm)Nicehash".Name
					Index		= $Index
				}
			}
		}
    }
	if ($Port) {$Port ++}
}