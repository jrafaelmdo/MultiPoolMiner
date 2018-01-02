﻿using module ..\Include.psm1

class Wrapper : Miner {
    [PSCustomObject]GetData ([String[]]$Algorithm, [Bool]$Safe = $false, [String]$DebugPreference = "SilentlyContinue") {
        $Server = "localhost"
        $Timeout = 10 #seconds

        $Delta = 0.05
        $Interval = 5
        $HashRates = @()

        $PowerDraws = @()
        $ComputeUsages = @()

        $Request = ""
        $Response = ""

        do {
            # Read Data from hardware
            $ComputeData = [PSCustomObject]@{}
            $ComputeData = (Get-ComputeData -MinerType $this.type -Index $this.index)
            $PowerDraws += $ComputeData.PowerDraw
            $ComputeUsages += $ComputeData.ComputeUsage

            $HashRates += $HashRate = [PSCustomObject]@{}

            try {
                try {
                    $Response = Get-Content ".\Wrapper\$($this.Port).txt" -Force -ErrorAction Stop
                    $Data = $Response | ConvertFrom-Json -ErrorAction Stop
                }
                catch {
                    Start-Sleep $Interval
                    $Response = Get-Content ".\Wrapper\$($this.Port).txt" -Force -ErrorAction Stop
                    $Data = $Response | ConvertFrom-Json -ErrorAction Stop
                }
            }
            catch {
                Write-Log -Level Error "$($this.API) failed to connect to miner ($($this.Name)). Could not hash rates from miner."
                break
            }

            $HashRate_Name = [String]$Algorithm[0]
            $HashRate_Value = [Double]$Data

            $HashRate | Where-Object {$HashRate_Name} | Add-Member @{$HashRate_Name = [Int64]$HashRate_Value}

            $Algorithm | Where-Object {-not $HashRate.$_} | ForEach-Object {break}

            if (-not $Safe) {break}

            Start-Sleep $Interval
        } while ($HashRates.Count -lt 6)

        $HashRate = [PSCustomObject]@{}
        $Algorithm | ForEach-Object {$HashRate | Add-Member @{$_ = [Int64]($HashRates.$_ | Measure-Object -Maximum -Minimum -Average | Where-Object {$_.Maximum - $_.Minimum -le $_.Average * $Delta}).Maximum}}
        $Algorithm | Where-Object {-not $HashRate.$_} | Select-Object -First 1 | ForEach-Object {$Algorithm | ForEach-Object {$HashRate.$_ = [Int64]0}}

        $PowerDraws_Info = [PSCustomObject]@{}
        $PowerDraws_Info = ($PowerDraws | Measure-Object -Maximum -Minimum -Average)
        $PowerDraw = if ($PowerDraws_Info.Maximum - $PowerDraws_Info.Minimum -le $PowerDraws_Info.Average * $Delta) {$PowerDraws_Info.Maximum} else {$PowerDraws_Info.Average}

        $ComputeUsages_Info = [PSCustomObject]@{}
        $ComputeUsages_Info = ($ComputeUsages | Measure-Object -Maximum -Minimum -Average)
        $ComputeUsage = if ($ComputeUsages_Info.Maximum - $ComputeUsages_Info.Minimum -le $ComputeUsages_Info.Average * $Delta) {$ComputeUsages_Info.Maximum} else {$ComputeUsages_Info.Average}

        return [PSCustomObject]@{
            HashRate     = $HashRate
            PowerDraw    = $PowerDraw
            ComputeUsage = $ComputeUsage
            Response     = $Response
        }
    }
}