Write-Host "
      _______________________________________________________________________________________
     |                                                                                       |
     |                 Profitbot Pro Benchmark Tool created by Bearlyhealz.                  |
     |                 :: Automated Mining Software for the Average Joe ::                   |
     |---------------------------------------------------------------------------------------|
     |                       Free to use, donations kindly accepted.                         |
     |                                                                                       |
     |               ETH Address: 0x32cd01077b6cc9cedb17feadfc24cce0a7b775f8                 |
     |                   BTC Address: 1EUFmXVcyWR85c57z9wtr5Q6KxyBbR2UUn                     |
     |                                                                                       |
     |         Credit for XMR-Stak goes to Fierce-UK at http://github.com/fireice-uk         |
     |                                                                                       |   
     |                            https://www.profitbotpro.com                               |
     |_______________________________________________________________________________________|

" -ForegroundColor Cyan
# Get the time and date.
$TimeNow = Get-Date
# Pull in settings from file
$get_settings = Get-Content -Path "settings.conf" | Out-String | ConvertFrom-Json
$get_coin_settings = Get-Content -Path "coin_settings.conf" | Out-String | ConvertFrom-Json
$version = $get_settings.version
$Host.UI.RawUI.WindowTitle = "Profitbot Pro Benchmark Tool created by Bearlyhealz v$version"
$mine_cpu = $get_settings.mine_cpu
$mine_amd = $get_settings.mine_amd
$mine_nvidia = $get_settings.mine_nvidia

$benchmark_minute = $get_settings.benchmark_time
Write-Host "$TimeNow Setting benchmark to $benchmark_minute minutes."

#Pull in the computer name from Windows.
$pc = $env:ComputerName

# Set Benchmark time.
$seconds = 60
$benchmark_timer = $seconds * ([int]$get_settings.benchmark_time -1)

$pause_before_mining = 10

# Set path and URL parameters
$path = $get_settings.path
$update_url = $get_settings.update_url

Write-Host "$TimeNow : Benchmarking each coin for $benchmark_minute mins. Resume mining afterwards." -ForegroundColor Magenta

#Check folder structure, create missing folders.
if (Test-Path $path\$pc -PathType Container) {
    Write-Host "$TimeNow : Checking Folder Structure. (OK!)" -ForegroundColor green
    Write-Host "$TimeNow : Cleaning up old conf files. (OK!)" -ForegroundColor green
    Remove-Item $path\$pc\*.conf
}
else {
    Write-Host "$TimeNow : Creating Folder for $pc" -ForegroundColor yellow
    $fso = new-object -ComObject scripting.filesystemobject
    $fso.CreateFolder("$path\$pc")
}

# Remove lock file
if (Test-Path $path\$pc\system_benchmark.success) {
    Remove-Item $path\$pc\system_benchmark.success
}

# Get the time and date.
$TimeNow = Get-Date

# Check if param exists
if ($get_settings.stop_worker_delay -ne $null) {
    $stop_worker_delay = $get_settings.stop_worker_delay
}
else {
    $stop_worker_delay = 5
}

$rigname = $get_settings.rig_name
if (!$rigname) {
    $rigname = $pc
}
else {
    $rigname = $get_settings.rig_name
}

    # If previous worker is running, kill the process.

    # List of mining software processes
    $worker_array = @("xmr-stak","mox-stak","b2n-miner","xmr-freehaven", "SRBMiner-CN", "jce_cn_cpu_miner64", "jce_cn_cpu_miner32", "jce_cn_gpu_miner64")

    # Loop through each miner process, and kill the one that's running
    foreach ($element in $worker_array) {

        $worker_running = Get-Process $element -ErrorAction SilentlyContinue
        if ($worker_running) {
        # Write to the log.
            if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
                Write-Output "$TimeNow : $element is already running, attempting to stop." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
            }
            Write-Host "$TimeNow : Worker already running, stopping process." -ForegroundColor Red
            # try gracefully first
            $worker_running.CloseMainWindow() | out-null
            # kill after five seconds
            Write-Host "$TimeNow : Pausing for $stop_worker_delay seconds while worker shuts down." -ForegroundColor Yellow
            Start-Sleep $stop_worker_delay
            if (!$worker_running.HasExited) {
            $worker_running | Stop-Process -Force | out-null
            }
        }

        Remove-Variable worker_running
    }

# Loop through each coin for 5 minutes, then write to file
$Array = $get_coin_settings.my_coins
foreach ($element in $array) {
        
    # Set variables for mining software
    $symbol = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty symbol
    $miner_type = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty software
    $diff_config = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty static_param
    $algo = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty algo
    $pool = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty pool
    $wallet = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty wallet
    $amd_config_file = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty amd_config_file

    # If configured for SRB otherwise ignore
        if ($miner_type -eq 'SRBMiner-CN') {
            $srb_config = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty srb_config_file
        }

    # If configured for JCE, get the miner variation parameter.
        if ($miner_type -eq 'jce_cn_cpu_miner64' -or $miner_type -eq 'jce_cn_cpu_miner32' -or $miner_type -eq 'jce_cn_gpu_miner64') {
            $jce_miner_variation = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty jce_miner_variation 
        }

    $config = "config.txt"
    # These are the default apps used for mining. Updated software can be found at http://github.com/fireice-uk/xmr-stak/releases.
    if ($miner_type -eq 'xmr-stak') {
        Set-Variable -Name "miner_app" -Value "$path\Miner-XMRstak\xmr-stak.exe"
    }
    if ($miner_type -eq 'b2n-miner') {
        Set-Variable -Name "miner_app" -Value "$path\Miner-XMRb2n\b2n-miner.exe"
    }
    if ($miner_type -eq 'mox-stak') {
        Set-Variable -Name "miner_app" -Value "$path\Miner-XMRmox\mox-stak.exe"
    }
    if ($miner_type -eq 'xmr-freehaven') {
        Set-Variable -Name "miner_app" -Value "$path\Miner-XMRfreehaven\xmr-freehaven.exe"
    }
    if ($miner_type -eq 'SRBMiner-CN') {
        Set-Variable -Name "miner_app" -Value "$path\Miner-SRB\SRBMiner-CN.exe"
    }
    if ($miner_type -eq 'jce_cn_cpu_miner32') {
        Set-Variable -Name "miner_app" -Value "$path\Miner-JCE\jce_cn_cpu_miner32.exe"
    }
    if ($miner_type -eq 'jce_cn_cpu_miner64') {
        Set-Variable -Name "miner_app" -Value "$path\Miner-JCE\jce_cn_cpu_miner64.exe"
    }
    if ($miner_type -eq 'jce_cn_gpu_miner64') {
        Set-Variable -Name "miner_app" -Value "$path\Miner-JCE_CPU_GPU\jce_cn_gpu_miner64.exe"
    }
    Write-Host "$TimeNow : Setting Mining Application to $miner_type"
    write-host "
    
    "
    Write-Host "$TimeNow : Preparing to benchmark $symbol, please wait $benchmark_minute minutes." -ForegroundColor Yellow

    if ($miner_type -eq 'SRBMiner-CN') {
        $logfile = "$(get-date -f yyyy-MM-dd).log"
        $worker_settings = "--config $path\Miner-SRB\Config\$srb_config --pools $path\Miner-SRB\pools.txt --logfile $path\Miner-SRB\$logfile --apienable --apiport 8080 --apirigname $rigname --cworker $rigname --cpool $pool --cwallet $wallet$fixed_diff --cpassword $rigname"
    }
    elseif ($miner_type -eq 'xmr-stak' -or $miner_type -eq 'mox-stak' -or $miner_type -eq 'b2n-miner' -or $miner_type -eq 'xmr-freehaven') {
        # Set switches for mining CPU, AMD, NVIDIA
        if($mine_cpu -eq "yes"){
            $cpu_param = "--cpu $path\$pc\cpu.txt"
            Write-Host "$TimeNow : CPU Mining is Enabled." -ForegroundColor Cyan
        }
        else {
            $cpu_param = "--noCPU"
            Write-Host "$TimeNow : CPU Mining is Disabled." -ForegroundColor Cyan
        }
        if($mine_amd -eq "yes"){
            $amd_param = "--amd $path\$pc\$amd_config_file"
            Write-Host "$TimeNow : AMD Mining is Enabled." -ForegroundColor Cyan
        }
        else {
            $amd_param = "--noAMD"
            Write-Host "$TimeNow : AMD Mining is Disabled." -ForegroundColor Cyan
        }
        if($mine_nvidia -eq "yes"){
            $nvidia_param = "--nvidia $path\$pc\nvidia.txt"
            Write-Host "$TimeNow : Nvidia Mining is Enabled." -ForegroundColor Cyan
        }
        else {
            $nvidia_param = "--noNVIDIA"
            Write-Host "$TimeNow : Nvidia Mining is Disabled." -ForegroundColor Cyan
        }
        # Configure the attributes for the mining software.
        $worker_settings = "--poolconf $path\$pc\pools.txt --config $path\$config --currency $algo --url $pool --user $wallet$fixed_diff --rigid $rigname --pass w=$rigname $cpu_param $amd_param $nvidia_param"
    }
    elseif ($miner_type -eq 'jce_cn_cpu_miner64' -or $miner_type -eq 'jce_cn_cpu_miner32' -or $miner_type -eq 'jce_cn_gpu_miner64') {
        
        # Configure the attributes for the mining software.
        $worker_settings = "--auto --any --forever --keepalive --variation $jce_miner_variation --low -o $pool -u $wallet$fixed_diff -p w=$rigname --mport 8080 -t $jce_miner_threads --low "
    }

    # Check for CPU.txt file, delete if exists, will create a new one once mining app launches.
    if (Test-Path $path\$pc\cpu.txt) {
    
        if ($get_settings.delete_cpu_txt -eq 'yes') {
            Write-Host "$TimeNow : Purging old cpu.txt file (OK!)" -ForegroundColor Green
            Remove-Item $path\$pc\cpu.txt
        }
    }
    else {
        Write-Host "$TimeNow : Could not find cpu.txt file, there is nothing to delete. (OK!)" -ForegroundColor Green
    }

    # Check for pools.txt file, delete if exists, will create a new one once mining app launches.
    if (Test-Path $path\$pc\pools.txt) {
        Write-Host "$TimeNow : Purging old Pools.txt file (OK!)" -ForegroundColor Green
        del $path\$pc\pools.txt
    }
    else {
        Write-Host "$TimeNow : Could not find Pools.txt file, there is nothing to delete. (OK!)" -ForegroundColor Green
    }
    Write-Host "$TimeNow : Establishing connection to:" $pool
    Write-Host "$TimeNow : Switching Algo to:" $Algo
    Write-Host "$TimeNow : Authorizing inbound funds to Wallet."

    # Get the time and date.
    $TimeNow = Get-Date

    # Verify Diff config file is present
    If (Test-Path -Path $Path\$pc\$element.conf) {
        $set_diff_config = "yes"
        $set_diff_value = Get-Content -Path "$path\$pc\$element.conf"
        Write-Host "$TimeNow : Found old diff config file, deleting!" -ForegroundColor red
        Remove-Item $path\$pc\$element.conf
    }
    else { 
        Write-Host "$TimeNow : Diff config file for $element is not present, no need for cleanup." -ForegroundColor red
    }
    Write-Host "$TimeNow : Starting $miner_type in another window."
    # Start the mining software, wait for the process to begin.
    start-process -FilePath $miner_app -args $worker_settings -WindowStyle Minimized
    Start-Sleep -Seconds 60

    # Get the time and date.
    $TimeNow = Get-Date

    # Get the hashrate from XMR-Stak. If error state occurs, restart the worker.
    if ($miner_type -eq 'SRBMiner-CN') {

        $get_hashrate = Invoke-RestMethod -Uri "http://127.0.0.1:8080" -Method Get
        $worker_hashrate = $get_hashrate.hashrate_total_now
        $my_accepted_shares = $get_hashrate.shares.accepted
        $my_rejected_shares = $get_hashrate.shares.rejected
    
    }
    elseif($miner_type -eq 'xmr-stak' -or $miner_type -eq 'mox-stak' -or $miner_type -eq 'b2n-miner' -or $miner_type -eq 'xmr-freehaven') {

        $get_hashrate = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api.json" -Method Get
        $worker_hashrate = $get_hashrate.hashrate.total[0]
        $my_accepted_shares = $get_hashrate.results.shares_good
        $total_shares = $get_hashrate.results.shares_total
        $my_rejected_shares = ($total_shares - $my_accepted_shares)
    
    }
    elseif($miner_type -eq 'jce_cn_cpu_miner64' -or $miner_type -eq 'jce_cn_cpu_miner32' -or $miner_type -eq 'jce_cn_gpu_miner64') {

        $get_hashrate = Invoke-RestMethod -Uri "http://127.0.0.1:8080" -Method Get
        $worker_hashrate = $get_hashrate.hashrate.total[0]
        $my_accepted_shares = $get_hashrate.result.shares
        $total_shares = $get_hashrate.result.shares
        $my_rejected_shares = 0
    }

    
    #If worker is displaying hashrate, calculate fixed diff.
    if ($worker_hashrate -match "[0-9]") {
        Write-Host "$TimeNow : Worker Hashrate:" $worker_hashrate "H/s, Accepted Shares: $my_results" -ForegroundColor Green
        Start-Sleep -Seconds $benchmark_timer
        
        $suggested_diff = [math]::Round($worker_hashrate * 30)
        Write-Host "$TimeNow : Worker Hashrate:" $worker_hashrate "H/s, Accepted Shares: $my_results" -ForegroundColor Green
        Write-Host "$TimeNow : Creating difficulty config file for $element on this worker." -ForegroundColor yellow
        Write-Host "$TimeNow : We've calulated the fixed difficulty to be $suggested_diff for this algo." -ForegroundColor green
    
        # Create Diff/Hashrate objects in json
        [hashtable]$build_json = @{}
        $build_json.difficulty = "$suggested_diff"
        $build_json.worker_hashrate = "$worker_hashrate"
        $build_json | convertto-json | Set-Content "$path\$pc\$element.conf"
    
        # Wait for the executable to stop before continuing.
        $worker_running = Get-Process $miner_type 
        if ($worker_running) {
            Write-Host "$TimeNow : Stopping Worker process." -ForegroundColor Red
            # try gracefully first
            $worker_running.CloseMainWindow()  | Out-Null
            # kill after five seconds
            Sleep 5
            if (!$worker_running.HasExited) {
                $worker_running | Stop-Process -Force  | Out-Null
            }
        }
        Remove-Variable worker_running
    }
}
# Pause
Write-Host "
    
"
Write-Host "$TimeNow : Benchmarking is now complete, it is safe to close this window." -ForegroundColor Green
Write-Output "Creating file to let the worker know that a benchmark has been completed." | Out-File $path\$pc\system_benchmark.success
Write-Host "$TimeNow : Starting Profit Manager in $pause_before_mining seconds. (CTRL+C to exit now)" -ForegroundColor Green

Start-Sleep $pause_before_mining
./profit_manager.ps1