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
     |---------------------------------------------------------------------------------------|
     |                     Feature requests and feedback welcomed! :)                        |
     |                        https://github.com/randygrolemund                              |
     |                           https://www.profitbotpro.com                                |
     |                           https://api.profitbotpro.com                                |
     |_______________________________________________________________________________________|

" -ForegroundColor Cyan
# Get the time and date.
$TimeNow = Get-Date
# Pull in settings from file
$get_settings = Get-Content -Path "settings.conf" | Out-String | ConvertFrom-Json
$get_coin_settings = Get-Content -Path "coin_settings.conf" | Out-String | ConvertFrom-Json
$version = $get_settings.version
$Host.UI.RawUI.WindowTitle = "Profitbot Pro Benchmark Tool created by Bearlyhealz v$version"

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

Write-Host "$TimeNow : Benchmarking each coin for 3 mins. Resume mining afterwards." -ForegroundColor Magenta

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

# Loop through each coin for 5 minutes, then write to file
$Array = $get_coin_settings.my_coins
foreach ($element in $array) {
        
    # Set variables for mining software
    $symbol = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty software
    $miner_type = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty software
    $diff_config = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty static_param
    $algo = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty algo
    $pool = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty pool
    $wallet = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty wallet
    $amd_config_file = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $element } | Select-Object -ExpandProperty amd_config_file
    $config = "config.txt"
    Set-Variable -Name "miner_app" -Value "$path\Miner-XMRstak\xmr-stak.exe"

    # Check if param exists
    if ($get_settings.stop_worker_delay -ne $null) {
        $stop_worker_delay = $get_settings.stop_worker_delay
    }
    else {
        $stop_worker_delay = 5
    }

    # Kill worker if already running.
    if ($miner_type -eq 'xmr-stak') {
        Set-Variable -Name "miner_app" -Value "$path\Miner-XMRstak\xmr-stak.exe"
    }
    $worker_running = Get-Process $miner_type -ErrorAction SilentlyContinue
    if ($worker_running) {
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
    write-host "
    
    "
    Write-Host "$TimeNow : Preparing to benchmark $element.... please wait $benchmark_minute minute." -ForegroundColor Yellow

    # Configure the attributes for the mining software.
    $worker_settings = "--poolconf $path\$pc\pools.txt --config $path\$config --currency $algo --url $pool --user $wallet$fixed_diff --rigid $pc --pass w=$pc --cpu $path\$pc\cpu.txt --amd $path\$pc\$amd_config_file --nvidia $path\$pc\nvidia.txt"

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
    Write-Host "$TimeNow : Starting XMR-Stak in another window."
    # Start the mining software, wait for the process to begin.
    start-process -FilePath $miner_app -args $worker_settings -WindowStyle Minimized
    Start-Sleep -Seconds 60

    # Get the time and date.
    $TimeNow = Get-Date

    # Pull hashrate from worker api.
    $get_hashrate = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api.json" -Method Get 
    $worker_hashrate = $get_hashrate.hashrate.total[0]
    $my_results = $get_hashrate.results.shares_good

    #If worker is displaying hashrate, calculate fixed diff.
    if ($worker_hashrate -match "[0-9]") {
        Write-Host "$TimeNow : Worker Hashrate:" $worker_hashrate "H/s, Accepted Shares: $my_results" -ForegroundColor Green
        Start-Sleep -Seconds $benchmark_timer
        
        # Get the time and date.
        $TimeNow = Get-Date

        # Pull hashrate from worker api.
        $get_hashrate = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api.json" -Method Get 
        $worker_hashrate = $get_hashrate.hashrate.total[0]
        $my_results = $get_hashrate.results.shares_good
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