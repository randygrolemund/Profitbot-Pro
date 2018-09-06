# Set the size of the window
Function Set-WindowSize {
    Param([int]$x = $host.ui.rawui.windowsize.width,
        [int]$y = $host.ui.rawui.windowsize.heigth)

    $size = New-Object System.Management.Automation.Host.Size($x, $y)
    $host.ui.rawui.WindowSize = $size
}
Set-WindowSize 100 50

# Startup banner
Write-Host "
      _______________________________________________________________________________________
     |                                                                                       |
     |                        Profitbot Pro created by Bearlyhealz.                          |
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

# ************************************************************************************************************************************

# Pull in settings from file
$get_settings = Get-Content -Path "settings.conf" | Out-String | ConvertFrom-Json
$get_coin_settings = Get-Content -Path "coin_settings.conf" | Out-String | ConvertFrom-Json
$version = $get_settings.version
$Host.UI.RawUI.WindowTitle = "Profitbot Pro created by Bearlyhealz v$version"
$pc = $env:ComputerName

# Set Log variables
$enable_log = $get_settings.enable_logging
$log_age = $get_settings.log_age

# Get the time and date
$TimeNow = Get-Date

# Set path parameter
$path = $get_settings.path
$update_url = $get_settings.update_url

# ************************************************************************************************************************************

#Check folder structures, create missing folders.
if (Test-Path $path\$pc -PathType Container) {
    Write-Host "$TimeNow : Checking Folder Structure. (OK!)" -ForegroundColor green
}
else {
    Write-Host "$TimeNow : Creating Folder for $pc" -ForegroundColor yellow
    # Create folder structure for PC name.
    $fso = new-object -ComObject scripting.filesystemobject
    $fso.CreateFolder("$path\$pc")
}

# Create previous versions folder
if (Test-Path $path\Previous_Version -PathType Container) {
    Write-Host "$TimeNow : Checking previous version folder structure. (OK!)" -ForegroundColor green
}
else {
    Write-Host "$TimeNow : Creating folder for previous versions. (OK!)" -ForegroundColor yellow
    # Create folder structure for PC name.
    $fso = new-object -ComObject scripting.filesystemobject
    $fso.CreateFolder("$path\Previous_Version")
}

# Create backup folder
if (Test-Path $path\Backups -PathType Container) {
    Write-Host "$TimeNow : Checking backup folder structure. (OK!)" -ForegroundColor green
}
else {
    Write-Host "$TimeNow : Creating folder for backups.(OK!)" -ForegroundColor yellow
    # Create folder structure for PC name.
    $fso = new-object -ComObject scripting.filesystemobject
    $fso.CreateFolder("$path\Backups")
}

# Check for log file, if doesn't exist, create.
if ($enable_log -eq 'yes') {
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Host "$TimeNow : Log file and structure exists. (OK!)" -ForegroundColor Green
    }
    else {
        Write-Output "$TimeNow : Created log file for $pc" | Out-File $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
}
    
# ************************************************************************************************************************************

#Settings for Updater
$my_path = $get_settings.path
$settings_path = "$my_path\Previous_Version\settings.conf"
$coin_settings_path = "$my_path\Previous_Version\coin_settings.conf"

# If check for updates is enabled, pull in version information.
if ($get_settings.update_check -eq 'yes') {
    $check_update = Invoke-RestMethod -Uri "https://$update_url" -Method Get
    $web_version = $check_update.version
    $installed_settings_version = $get_settings.version
    $installed_coin_settings_version = $get_coin_settings.version
    Write-Host "$TimeNow : Installed version: SCPM v$installed_settings_version" -ForegroundColor Yellow
    Write-Host "$TimeNow :       Web version: SCPM v$web_version" -ForegroundColor Yellow
    # check to see if running the newest version
    if ($web_version -gt $installed_settings_version) {
        Write-Host "$TimeNow : An update is available!" -ForegroundColor Cyan
        # If automatic updates are allowed.
        if ($get_settings.allow_automatic_updates -eq 'yes') {
            # If lockfile exists skip, otherwise download new profit_manager.ps1 file
            if (Test-Path $path\lockfile.lock) {
                $read_lockfile = Get-Content $path\lockfile.lock -First 1
                Write-Host "$TimeNow : Lockfile is owned by $read_lockfile."
                if($PC -ne $read_lockfile){
                    Write-Host "$TimeNow : Another worker has started the update process, waiting 30 seconds." -ForegroundColor Red
                    # Write to log
                    if ($enable_log -eq 'yes'){
                        # Write to the log
                        if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log){
                            Write-Output "$TimeNow : Pausing while worker $read_lockfile performs software upgrade." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
                        }
                    }
                    Start-Sleep 30
                    ./profit_manager.ps1
                }
            }
            else {
                # Download updates from server
                $url = "https://$update_url/releases/profit_manager.ps1"
                $output = "$path\profit_manager.ps1"
                Invoke-WebRequest -Uri $url -OutFile $output
                Start-Sleep 1
                #Restart Worker and pull in new profit_manager.ps1 before updating the rest of the files.
                Write-Host "$TimeNow : Creating lockfile.lock. Lockfile will be removed after update." -ForegroundColor Red
                Write-Output "$PC" | Out-File $path\lockfile.lock
                Write-Host "$TimeNow : Restarting worker before updating additional files." -ForegroundColor Green 
                ./profit_manager.ps1
            }
            if ($installed_settings_version -ne $installed_coin_settings_version) {
                Write-Host "$TimeNow : Version mismatch. Settings.conf is v$installed_settings_version and coin_settings.conf is $installed_coin_settings_version." -ForegroundColor Red
                Write-Host "$TimeNow : If automatic upadates are enabled, we will attempt to resolve the issue for you." -ForegroundColor Red
            }

            # Check if Backups folders exists, otherwise create
            if (Test-Path $path\Backups -PathType Container) {
                
                #Test if Previous Versions is empty
                $directoryInfo = Get-ChildItem $path\Previous_Version | Measure-Object
                if ($directoryInfo.Count -eq 0) {
                    Write-Host "$TimeNow : The are no files staged for backup. We will check on the next update cycle." -ForegroundColor Red
                }
                else {
                    Write-Host "$TimeNow : Adding previously backed up files to archive. (OK!)" -ForegroundColor Green
                    $source = "$path\Previous_Version"
                    $destination = "$path\Backups\backup_$(get-date -f 'yyyy-MM-dd_hh_mm_ss').zip"
                    Add-Type -assembly "system.io.compression.filesystem"
                    [io.compression.zipfile]::CreateFromDirectory($Source, $destination) 
                }
            }
                 
            # Copy files from root to previous_version
            Write-Host "$TimeNow : Backing up your current files to Previous_Version." -ForegroundColor Yellow
            Copy-Item -Path $path\*.conf -Destination $path\Previous_Version -force
            Copy-Item -Path $path\*.ps1 -Destination $path\Previous_Version -force
            Write-Host "$TimeNow : Downloading updates...." -ForegroundColor Cyan
            
            # Download Additional Updates
            $url = "https://$update_url/releases/benchmark.ps1"
            $output = "$path\benchmark.ps1"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://$update_url/releases/settings.conf"
            $output = "$path\settings.conf"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://$update_url/releases/coin_settings.conf"
            $output = "$path\coin_settings.conf"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://$update_url/releases/config.txt"
            $output = "$path\config.txt"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://$update_url/releases/Instructions.pdf"
            $output = "$path\Instructions.pdf"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://$update_url/releases/profit_manager.ps1"
            $output = "$path\profit_manager.ps1"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://$update_url/releases/Profitbot_Pro.ico"
            $output = "$path\Profitbot_Pro.ico"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://$update_url/releases/Profitbot_Pro.lnk"
            $output = "$path\Profitbot_Pro.lnk"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://$update_url/releases/Profitbot_Pro.bat"
            $output = "$path\Profitbot_Pro.bat"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://$update_url/releases/Benchmark.bat"
            $output = "$path\Benchmark.bat"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://$update_url/releases/LICENSE"
            $output = "$path\LICENSE"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1

            # Remove old BAT file
            if (Test-Path $path\Start_mining.bat) {
                Remove-Item $path\Start_mining.bat
            }
            
            Write-Host "$TimeNow : Importing settings from coin_settings.conf." -ForegroundColor Yellow
            # Copy user's settings from original config files to new config files.
            $original_coin_settings = Get-Content $coin_settings_path -raw | ConvertFrom-Json
            $original_coin_settings.default_coin = $original_coin_settings.default_coin
            $original_coin_settings.my_coins = $original_coin_settings.my_coins
            $original_coin_settings.mining_params = $original_coin_settings.mining_params
            $original_coin_settings.version = $web_version
            $original_coin_settings | ConvertTo-Json -Depth 10 | set-content 'coin_settings.conf'
            Start-Sleep 2
            
            Write-Host "$TimeNow : Importing settings from settings.conf." -ForegroundColor Yellow
            $original_settings = Get-Content $settings_path -raw | ConvertFrom-Json
            $original_settings.path = $original_settings.path
            $original_settings.static_mode = $original_settings.static_mode
            $original_settings.update_check = $original_settings.update_check
            $original_settings.allow_automatic_updates = $original_settings.allow_automatic_updates
            $original_settings.update_url = "api.profitbotpro.com"
            $original_settings.enable_logging = $original_settings.enable_logging
            $original_settings.log_age = $original_settings.log_age
            $original_settings.delete_cpu_txt = $original_settings.delete_cpu_txt
            $original_settings.mining_timer = $original_settings.mining_timer
            $original_settings.sleep_seconds = $original_settings.sleep_seconds
                
            $original_settings.voice = $original_settings.voice
            $original_settings.version = $web_version
            if ($original_settings.stop_worker_delay -ne $null) {
                $original_settings.stop_worker_delay = $original_settings.stop_worker_delay
            }
            else {
                $original_settings | add-member -Name "benchmark_time" -value "5" -MemberType NoteProperty
            }
            if ($original_settings.benchmark_time -ne $null) {
                $original_settings.benchmark_time = $original_settings.benchmark_time
            }
            else {
                $original_settings | add-member -Name "benchmark_time" -value "5" -MemberType NoteProperty
            }
            if ($original_settings.enable_coin_data -ne $null) {
                $original_settings.enable_coin_data = $original_settings.enable_coin_data
            }
            else {
                $original_settings | add-member -Name "enable_coin_data" -value "yes" -MemberType NoteProperty
            }
            if ($original_settings.coin_data_age -ne $null) {
                $original_settings.coin_data_age = $original_settings.coin_data_age
            }
            else {
                $original_settings | add-member -Name "coin_data_age" -value "24hr" -MemberType NoteProperty
            }
            $original_settings | ConvertTo-Json -Depth 10 | set-content 'settings.conf' 
            
            Write-Host "$TimeNow : Removing lockfile." -ForegroundColor White
            Remove-Item lockfile.lock
            Start-Sleep 2
            
            Write-Host "$TimeNow : Updates installed! Restarting worker." -ForegroundColor Green
            # Pull in settings from file
            $get_settings = Get-Content -Path "settings.conf" | Out-String | ConvertFrom-Json
            $get_coin_settings = Get-Content -Path "coin_settings.conf" | Out-String | ConvertFrom-Json
            $version = $get_settings.version
            ./profit_manager.ps1
        }
    }
    else {
        Write-Host "$TimeNow : You are running the newest version!" -ForegroundColor Green
    }
}

# ************************************************************************************************************************************

# If this is the 1st time running, force benchmark testing.
if (Test-Path $path\$pc\system_benchmark.success) {
    Write-Host "$TimeNow : This worker has already performed a benchmark, skipping." -ForegroundColor White
}
else {
    Write-Host "$TimeNow : This worker has not performed a benchmark. Starting benchmark now." -ForegroundColor Red
    # Write to the log.
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Output "$TimeNow : Beginning benchmark for $PC." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
    ./benchmark.ps1
}

# ************************************************************************************************************************************

# Set a default coin in the event the application wants to mine a coin that you do not have a wallet for.
$default_coin = $get_coin_settings.default_coin
# How many minutes do you want the miner to run before checking for a new coin?
$mine_minutes = $get_settings.mining_timer
$mine_seconds = $mine_seconds = [int]$get_settings.mining_timer * [int]60
$set_sleep = $get_settings.sleep_seconds
$enable_voice = $get_settings.voice
$static_mode = $get_settings.static_mode
$config = "config.txt"

# Check if params exists
if ($get_settings.stop_worker_delay -ne $null) {
    $stop_worker_delay = $get_settings.stop_worker_delay
}
else {
    $stop_worker_delay = 5
}
if ($get_settings.coin_data_age -ne $null) {
    $coin_data_age = $get_settings.coin_data_age
}
else {
    $coin_data_age = "1hr"
}

# Pull correct data average type
if($coin_data_age -eq "current"){
    $live_update_url = $update_url
    $update_url = ($update_url + "/current_release.json")
}
elseif ($coin_data_age -eq "1hr") {
    $live_update_url = $update_url
    $update_url = ($update_url + "/1hr_average.json")
}
elseif ($coin_data_age -eq "24hr") {
    $live_update_url = $update_url
    $update_url = ($update_url + "/24hr_average.json")
}
elseif($coin_data_age -eq "1wk"){
    $live_update_url = $update_url
    $update_url = ($update_url + "/1wk_average.json")
}



#Pull in the computer name from Windows.
$pc = $env:ComputerName

# Set mode variables for best coin
if ($static_mode -eq "yes") {
    $best_coin = $default_coin
}
else {
    #list all the coins you plan to mine.
    $Array = $get_coin_settings.my_coins
    # Pick the most profitable coin to mine from the top 10 list.
    Write-Host "$TimeNow : Connecting to https://$update_url." -ForegroundColor Magenta
    Write-Host "$TimeNow : Retreiving list of coins." -ForegroundColor Magenta
    $get_coin = Invoke-RestMethod -Uri "https://$update_url" -Method Get 
    
    # Cycle through the API's top list of coins, report error & restart if null.
    Try {
        if ($get_coin.top_list.symbol[0] -in $Array.ToUpper()) {
            $best_coin = $get_coin.top_list.symbol[0]
            $top_list_position = 1
        }
        elseif ($get_coin.top_list.symbol[1] -in $Array.ToUpper()) {
            $best_coin = $get_coin.top_list.symbol[1]
            $top_list_position = 2
        }
        elseif ($get_coin.top_list.symbol[2] -in $Array.ToUpper()) {
            $best_coin = $get_coin.top_list.symbol[2]
            $top_list_position = 3
        }
        elseif ($get_coin.top_list.symbol[3] -in $Array.ToUpper()) {
            $best_coin = $get_coin.top_list.symbol[3]
            $top_list_position = 4
        }
        elseif ($get_coin.top_list.symbol[4] -in $Array.ToUpper()) {
            $best_coin = $get_coin.top_list.symbol[4]
            $top_list_position = 5
        }
        elseif ($get_coin.top_list.symbol[5] -in $Array.ToUpper()) {
            $best_coin = $get_coin.top_list.symbol[5]
            $top_list_position = 6
        }
        elseif ($get_coin.top_list.symbol[6] -in $Array.ToUpper()) {
            $best_coin = $get_coin.top_list.symbol[6]
            $top_list_position = 7
        }
        elseif ($get_coin.top_list.symbol[7] -in $Array.ToUpper()) {
            $best_coin = $get_coin.top_list.symbol[7]
            $top_list_position = 8
        }
        elseif ($get_coin.top_list.symbol[8] -in $Array.ToUpper()) {
            $best_coin = $get_coin.top_list.symbol[8]
            $top_list_position = 9
        }
        elseif ($get_coin.top_list.symbol[9] -in $Array.ToUpper()) {
            $best_coin = $get_coin.top_list.symbol[9]
            $top_list_position = 10
        }
        else {
            $best_coin = $get_coin_settings.default_coin
            $top_list_position = 1000
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Host "$TimeNow : Worker has discovered an error:" $ErrorMessage -ForegroundColor Cyan
        Write-Host "$TimeNow : Waiting 10 seconds, then restarting the worker. API data is likely missing." -ForegroundColor Yellow
        Write-Host "$TimeNow : Restarting the worker now. If this happens again, please refer to logs."
        Start-Sleep 10
        # Write to the log.
        if ($enable_log -eq 'yes') {
            if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
            Write-Output "$TimeNow : Error encountered - $errormessage Restarting worker." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
            }
        }
        ./profit_manager.ps1
    }
}
# Establish the date and time
$TimeStart = Get-Date
$TimeNow = Get-Date

# Write to the log.
if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
    Write-Output "$TimeNow : Cleaning up old backup files, if older than $log_age days." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
}

# Clean up log and backup files older than x
$DatetoDelete = $TimeNow.AddDays(-$log_age)
Get-ChildItem $path\$pc\*.log | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item
Get-ChildItem $path\Backups\*.zip | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item

# Check worker mining mode. Set variables accordingly.
if ($static_mode -eq 'yes') {
    # Write to the log.
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Output "$TimeNow : Worker is set to static mode." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
    Write-Host "$TimeNow : Worker is set to static mode, configured to mine $best_coin." -ForegroundColor red  
}
else {
    #Check if the best coin to mine is in your list.
    if ($best_coin -in $Array.ToUpper()) {
        if($top_list_position -eq 1000){
            Write-Host "$TimeNow : No top list coint match. You will be mining your default coin." -ForegroundColor Magenta  
        }
        else {
            Write-Host "$TimeNow : You will be mining coin number $top_list_position in the API list." -ForegroundColor Magenta  
        }
        
    }
    else {
        Write-Host "$TimeNow : The best coin to mine is $best_coin but it's not in your list" -ForegroundColor red
        $timenow = Get-Date
        # Write to log.
        if ($enable_log -eq 'yes') {
            if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
                Write-Output "$TimeNow : Switched mining to $default_coin, $best_coin is not in your list" | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
            }
        }
    }
}

Write-Host "$TimeNow : Activating Worker on [$pc]"

# Get information about the GPU, print to screen
Write-Host "$TimeNow : This system has the following GPU's:" -ForegroundColor Yellow
foreach ($gpu in Get-WmiObject Win32_VideoController) {
    if ($gpu.Description -notlike "*Intel*" -and $gpu.Description -notlike "*Microsoft*") {Write-Host "                       -"$gpu.Description}
}
Write-Host "$TimeNow : Configured to Mine: $best_coin <--------" -ForegroundColor Magenta

# Pull in worker config information from settings.conf
$symbol = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty symbol
$miner_type = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty software
$diff_config = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty static_param
$algo = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty algo
$pool = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty pool
$wallet = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty wallet
$amd_config_file = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty amd_config_file

# Check if wallet param exists, if not then display error
if ($symbol -ne $null) {
}
else {


    # Write to the log.
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Output "$TimeNow : Configuration error! Coin list does not match wallet list." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
    [console]::beep(2000, 500)
    Write-Host "$TimeNow : ERROR! You are setup to mine $best_coin, but there's no wallet config." -ForegroundColor Red
    [console]::beep(2000, 500)
    Write-Host "$TimeNow : You can leave this window open while adding the parameters." -ForegroundColor Red
    [console]::beep(2000, 500)
    Write-Host "$TimeNow : When you are done, hit enter." -ForegroundColor Cyan
    Write-Host "  "
    pause
    #The miner will reload the Powershell file. You can make changes while it's running, and they will be applied on reload.
    .\profit_manager.ps1
}
Write-Host "$TimeNow : Establishing connection to:" $pool
Write-Host "$TimeNow : Switching Algo to:" $Algo
Write-Host "$TimeNow : Authorizing inbound funds to Wallet:" -ForegroundColor Cyan
Write-Host ("[" + $wallet + "]") -ForegroundColor Cyan

# Verify Diff config file is present
If (Test-Path -Path $Path\$pc\$symbol.conf) {
    $set_diff_config = "yes"
    $import_diff_value = Get-Content -Path "$path\$pc\$symbol.conf" | Out-String | ConvertFrom-Json
    $set_diff_value = $import_diff_value.difficulty
    Write-Host "$TimeNow : Diffuculty config for $symbol is present, setting to $set_diff_value" -ForegroundColor Yellow
}
else { 
    Write-Host "$TimeNow : No diffuculty config for $symbol is present, skipping this time." -ForegroundColor red
    $set_diff_config = "no"
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
# These are the default apps used for mining. Updated software can be found at http://github.com/fireice-uk/xmr-stak/releases.
if ($miner_type -eq 'xmr-stak') {
    Set-Variable -Name "miner_app" -Value "$path\Miner-XMRstak\xmr-stak.exe"
}
if ($miner_type -eq 'festival-miner') {
    Set-Variable -Name "miner_app" -Value "$path\Miner-XMRfest\festival-miner.exe"
}

Write-Host "$TimeNow : Setting Mining Application to $miner_type"

# This section establishes a fixed diff for each worker. The format depends on which pool you connect to.
if ($set_diff_config -eq 'yes') {
    if ($diff_config -eq '1') {
        Set-Variable -Name "fixed_diff" -Value "+$set_diff_value"
    }
    if ($diff_config -eq '2') {
        Set-Variable -Name "fixed_diff" -Value ".$set_diff_value"
    }
    if ($diff_config -eq '3') {
        Set-Variable -Name "fixed_diff" -Value ".$pc+$set_diff_value"
    }
    if ($diff_config -eq '4') {
        Set-Variable -Name "fixed_diff" -Value ".$pc"
    }
    if ($diff_config -eq '5') {
        Set-Variable -Name "fixed_diff" -Value ""
    }
}
else {
    Set-Variable -Name "fixed_diff" -Value ""
}

# Kill worker if already running.
$worker_running = Get-Process $miner_type -ErrorAction SilentlyContinue
if ($worker_running) {
    # Write to the log.
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Output "$TimeNow : $miner_type is already running, attempting to stop." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
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

# Extra kill process if using festival-miner, stop xmr-stak if it was running previously.
if($miner_type -eq 'festival-miner'){

    $worker_running = Get-Process xmr-stak -ErrorAction SilentlyContinue
    if ($worker_running) {
        # Write to the log.
        if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
            Write-Output "$TimeNow : xmr-stak is already running, attempting to stop." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
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

# Extra kill process if using xmr-stak, stop festival-miner if it was running previously.
if($miner_type -eq 'xmr-stak'){

    $worker_running = Get-Process festival-miner -ErrorAction SilentlyContinue
    if ($worker_running) {
        # Write to the log.
        if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
            Write-Output "$TimeNow : festival-miner is already running, attempting to stop." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
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

# Configure the attributes for the mining software.
$worker_settings = "--poolconf $path\$pc\pools.txt --config $path\$config --currency $algo --url $pool --user $wallet$fixed_diff --rigid $pc --pass w=$pc --cpu $path\$pc\cpu.txt --amd $path\$pc\$amd_config_file --nvidia $path\$pc\nvidia.txt"

Write-Host "$TimeNow : Starting $miner_type in another window."

# Edit for adding static mining
if ($static_mode -eq 'yes') {
    $best_coin_check = $default_coin
}
else {
    # Check to see if this is the best coin to mine
    $get_coin_check = Invoke-RestMethod -Uri "https://$update_url" -Method Get
    if ($get_coin_check.top_list.symbol[0] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.top_list.symbol[0]
    }
    elseif ($get_coin_check.top_list.symbol[1] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.top_list.symbol[1]
    }
    elseif ($get_coin_check.top_list.symbol[2] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.top_list.symbol[2]
    }
    elseif ($get_coin_check.top_list.symbol[3] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.top_list.symbol[3]
    }
    elseif ($get_coin_check.top_list.symbol[4] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.top_list.symbol[4]
    }
    elseif ($get_coin_check.top_list.symbol[5] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.top_list.symbol[5]
    }
    elseif ($get_coin_check.top_list.symbol[6] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.top_list.symbol[6]
    }
    elseif ($get_coin_check.top_list.symbol[7] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.top_list.symbol[7]
    }
    elseif ($get_coin_check.top_list.symbol[8] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.top_list.symbol[8]
    }
    elseif ($get_coin_check.top_list.symbol[9] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.top_list.symbol[9]
    }
    else {
        $best_coin_check = $get_coin_settings.default_coin
        $not_in_list = "yes"
    }
}
$timenow = Get-Date
# Write to log.
if ($enable_log -eq 'yes') {
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Output "$TimeNow : Configured to mine $best_coin." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
}
# Start the mining software, wait for the process to begin.
# Write to the log.
if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
    Write-Output "$TimeNow : Starting the worker $miner_type." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
}
start-process -FilePath $miner_app -args $worker_settings -WindowStyle Minimized
Start-Sleep -Seconds 2
$TimeNow = Get-Date
$check_worker_running = Get-Process $miner_type -ErrorAction SilentlyContinue
if ($check_worker_running -eq $null) {
    Do {
        Write-Host "$TimeNow : Waiting for worker to start...." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        $check_worker_running = Get-Process $miner_type -ErrorAction SilentlyContinue
    } until($check_worker_running -eq $True)  
}
# Mine for established time, then look to see if there's a new coin.
$TimeEnd = $timeStart.addminutes($mine_minutes)
Write-Host " "
Write-Host "$TimeNow : Started Worker" -ForegroundColor Green
if ($static_mode -eq 'no') {
    Write-Host "$TimeNow : Check Profitiability again: $TimeEnd" -ForegroundColor Green
}
# If we are mining the default coin, pause for 5 minutes.
if ($not_in_list -eq 'yes') {
    $TimeNow = Get-Date
    Write-Host "$TimeNow : Worker is set to mine default coin: $best_coin." -ForegroundColor cyan
}
Write-Host " "
# Begin a loop to check if the current coin is the best coin to mine. If not, restart the app and switchin coins.
Do { 
    if ($TimeNow -ge $TimeEnd) {
        
        $TimeNow = Get-Date
        # Edit for adding static mining

        if ($static_mode -eq "yes") {
            $best_coin_check = $default_coin
        }
        else {
            # Check if worker can talk to the API, if not, wait 10 seconds.
            try {
                $get_coin_check = Invoke-RestMethod -Uri "https://$update_url" -Method Get
                if ($get_coin_check.top_list.symbol[0] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[0]
                }
                elseif ($get_coin_check.top_list.symbol[1] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[1]
                }
                elseif ($get_coin_check.top_list.symbol[2] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[2]
                }
                elseif ($get_coin_check.top_list.symbol[3] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[3]
                }
                elseif ($get_coin_check.top_list.symbol[4] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[4]
                }
                elseif ($get_coin_check.top_list.symbol[5] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[5]
                }
                elseif ($get_coin_check.top_list.symbol[6] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[6]
                }
                elseif ($get_coin_check.top_list.symbol[7] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[7]
                }
                elseif ($get_coin_check.top_list.symbol[8] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[8]
                }
                elseif ($get_coin_check.top_list.symbol[9] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[9]
                }
                else {
                    $best_coin_check = $get_coin_settings.default_coin
                }
            }
            catch {
                Write-Host "$TimeNow : Cannot read from Profitbot Pro API, pausing 10 seconds." -ForegroundColor Red
                Start-Sleep 10
                $get_coin_check = Invoke-RestMethod -Uri "https://$update_url" -Method Get
                if ($get_coin_check.top_list.symbol[0] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[0]
                }
                elseif ($get_coin_check.top_list.symbol[1] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[1]
                }
                elseif ($get_coin_check.top_list.symbol[2] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[2]
                }
                elseif ($get_coin_check.top_list.symbol[3] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[3]
                }
                elseif ($get_coin_check.top_list.symbol[4] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[4]
                }
                elseif ($get_coin_check.top_list.symbol[5] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[5]
                }
                elseif ($get_coin_check.top_list.symbol[6] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[6]
                }
                elseif ($get_coin_check.top_list.symbol[7] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[7]
                }
                elseif ($get_coin_check.top_list.symbol[8] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[8]
                }
                elseif ($get_coin_check.top_list.symbol[9] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.top_list.symbol[9]
                }
                else {
                    $best_coin_check = $get_coin_settings.default_coin
                }
            }
             
            Write-Host "$TimeNow : Checking Coin Profitability." -ForegroundColor Yellow
            Write-Host "$TimeNow : Best Coin to Mine:" $best_coin_check -ForegroundColor Magenta
            if ($best_coin -eq $best_coin_check) {
                Write-Host "$TimeNow : Sleeping for another" $set_sleep "seconds, then checking again."
            }
        }
    }
    else {
        if ($static_mode -eq "no") {
            Write-Host "$TimeNow : Currently mining $best_coin. Checking profits again: $TimeEnd." -ForegroundColor White
        }
    }
    # Check if worker url is working, then get the current hashrate from mining software
    $TimeNow = Get-Date
    try {
        $HTTP_Request = [System.Net.WebRequest]::Create('http://127.0.0.1:8080/api.json')
        $HTTP_Response = $HTTP_Request.GetResponse()
        $HTTP_Status = [int]$HTTP_Response.StatusCode
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Host "$TimeNow : Worker has discovered an error:" $ErrorMessage -ForegroundColor Cyan
        Write-Host "$TimeNow : If XMR-Stak does not have its HTTP API enabled, we cannot get the hashrate." -ForegroundColor Yellow
        Write-Host "$TimeNow : Restarting the worker now. If this happens again, please refer to logs." -ForegroundColor Yellow
        # Write to the log.
        if ($enable_log -eq 'yes') {
            if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
            Write-Output "$TimeNow : Error encountered - $errormessage Restarting worker." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
            }
        }
        Start-Sleep 5
        ./profit_manager.ps1
    } 

    # Refresh coin values
    $get_coin = Invoke-RestMethod -Uri "https://$live_update_url" -Method Get 
    # Set coin variables from API
    $symbol = $get_coin.top_list | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty symbol
    $coin_name = $get_coin.top_list | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty coin_name
    $base_coin_price = $get_coin.top_list | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty base_coin_price
    $base_coin_symbol = $get_coin.top_list | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty base_coin_symbol
    $coin_usd = $get_coin.top_list | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty coin_usd
    $last_reward = $get_coin.top_list | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty last_reward
    $difficulty = $get_coin.top_list | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty difficulty
    $coin_units = $get_coin.top_list | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty coin_units
    $last_updated = $get_coin.top_list | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty last_updated
    $satoshi = $get_coin.top_list | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty satoshi
    
    # Verify the API json is not empty  -----not currently used in code
    $json_count = $get_coin.top_list | Measure-Object | Select-Object Count
   
    If ($HTTP_Status -eq 200) {
    }
    Else {
        Write-Host "$TimeNow : Worker is taking a little longer than expected to start." -ForegroundColor Yellow
        Start-Sleep -Seconds $set_sleep
    }
    $HTTP_Response.Close()

    # Get the current date and time.
    $TimeNow = Get-Date

    # Get the hashrate from XMR-Stak. If error state occurs, restart the worker.
    Try {
        $get_hashrate = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api.json" -Method Get
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Host "$TimeNow : Worker has discovered an error:" $ErrorMessage -ForegroundColor Cyan
        Write-Host "$TimeNow : If XMR-Stak does not have its HTTP API enabled, we cannot get the hashrate." -ForegroundColor Yellow
        Write-Host "$TimeNow : Restarting the worker now. If this happens again, please refer to logs." -ForegroundColor Yellow
        # Write to the log.
        if ($enable_log -eq 'yes') {
            if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
            Write-Output "$TimeNow : Error encountered - $errormessage Restarting worker." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
            }
        }
        Start-Sleep 5
        ./profit_manager.ps1
    }
    # Calculate the worker hashrate and accepted shares.
    $worker_hashrate = $get_hashrate.hashrate.total[0]
    $my_results = $get_hashrate.results.shares_good
    $suggested_diff = [math]::Round($worker_hashrate * 30)
    if ($worker_hashrate -match "[0-9]") {

        try {
            # Get the hashrate for each thread and write to the log.
            $count = $get_hashrate.hashrate.threads.count
            $start_thread = 1
            $thread_count = $count -1
            if($get_hashrate.hashrate.threads[0][0] -ne $null){
                $thread_hashrate = $get_hashrate.hashrate.threads[0][0]
            }
            
            if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
                Write-Output "$TimeNow : Thread 0 - $thread_hashrate H/s" | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
            }
            if($start_thread -ne $null -and $thread_count -ne $null){
                foreach ($_ in $start_thread..$thread_count){
                    $i++
                    $a = "Thread "
                    $thread_hashrate = $get_hashrate.hashrate.threads[$i][0]
                    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
                        Write-Output "$TimeNow : $a$i - $thread_hashrate H/s" | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
                        }
                }
            }
        }
        catch {
            Write-Host "$Timenow : Cannot log thread data yet, worker is still warming up."
        }
        
        

        # Print the worker hashrate and accepted share to screen.
        Write-Host "$TimeNow : Worker hashrate:" $worker_hashrate "H/s, $best_coin Accepted Shares: $my_results" -ForegroundColor Cyan
        if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
            Write-Output "$TimeNow : Total Worker Hashrate - $worker_hashrate H/s" | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
        }
        if ($get_settings.enable_coin_data -eq 'yes') {
            # Caclulate estimated shares over 24 hours if not null
            Try {
                $reward_24H = [math]::round(($worker_hashRate / $difficulty * ($last_reward / $coin_units) * 86400), 4)
            }
            Catch {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                Write-Host "$TimeNow : Worker has discovered an error:" $ErrorMessage -ForegroundColor Cyan
                Write-Host "$TimeNow : Waiting 10 seconds, then restarting the worker. API data is likely missing." -ForegroundColor Yellow
                Write-Host "$TimeNow : Restarting the worker now. If this happens again, please refer to logs."
                Start-Sleep 10
                # Write to the log.
                if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
                    Write-Output "$TimeNow : Error encountered - $errormessage Restarting worker." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
                }
                ./profit_manager.ps1
            }           
            # Caclulate daily profit in USD if not null
            Try {
                $earned_24H = [math]::round([float]($reward_24H * [float]$coin_usd), 2)
            }
            Catch {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                Write-Host "$TimeNow : Worker has discovered an error:" $ErrorMessage -ForegroundColor Cyan
                Write-Host "$TimeNow : Waiting 10 seconds, then restarting the worker. API data is likely missing." -ForegroundColor Yellow
                Write-Host "$TimeNow : Occasionally, the worker will query the API data during a db refresh, restarting will fix this error."
                Start-Sleep 10
                # Write to the log.
                if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
                    Write-Output "$TimeNow : Error encountered - $errormessage Restarting worker." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
                }
                ./profit_manager.ps1
            }
            Write-Host "$TimeNow : API data last refreshed: $last_updated (UTC)." -ForegroundColor White
            Write-Host "$TimeNow : Network Difficulty: $difficulty." $symbol ("$" + $coin_usd + " USD") ("(" + $satoshi + " " + $base_coin_symbol + ")") -ForegroundColor DarkCyan
            Write-Host "$TimeNow : Estimated 24H Reward:" $reward_24H "Estimated 24H Earnings:"("$" + $earned_24H.tostring("00.00")) -ForegroundColor Green
        }
        if ($static_mode -eq 'yes') {
            Write-Host "$TimeNow : Profitbot Pro is set to static mode. Profit Mananager is disabled." -ForegroundColor DarkGray
        }
    }
    else {
        Write-Host "$TimeNow : Waiting on worker to display hashrate." -ForegroundColor Yellow
    }
    # Clear variables
    Remove-Variable count -ErrorAction SilentlyContinue
    Remove-Variable start_thread -ErrorAction SilentlyContinue
    Remove-Variable thread_count -ErrorAction SilentlyContinue
    Remove-Variable a -ErrorAction SilentlyContinue
    Remove-Variable i -ErrorAction SilentlyContinue
    Remove-Variable get_coin -ErrorAction SilentlyContinue
    Remove-Variable last_updated -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $set_sleep
}
While ($best_coin -eq $best_coin_check)

# Write to the log.
if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
    Write-Output "$TimeNow : Profit has changed, switcing to $best_coin_check." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
}
if ($enable_voice -eq 'yes') {
    # Speak the symbol of the coin when switching.
    $speak_coin = ("$best_coin_check" -split "([a-z0-9]{1})"  | Where-Object { $_.length -ne 0 }) -join " "
    Add-Type -AssemblyName System.Speech
    $synthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
    $synthesizer.Speak("$pc is switching to $speak_coin") | Out-Null
}
If ( Test-Path -Path $Path\$pc\$symbol.conf ) {
    Write-Host "$TimeNow : Diffuculty config for $symbol is present, no need to create a new config." -ForegroundColor Green
}
else {
    Write-Host "$TimeNow : Creating difficulty config file for $symbol on this worker." -ForegroundColor Green
    Write-Host "$TimeNow : We've calulated the fixed difficulty to be $suggested_diff ." -ForegroundColor Green
    
    # Create Diff/Hashrate objects in json
    [hashtable]$build_json = @{}
    $build_json.difficulty = "$suggested_diff"
    $build_json.worker_hashrate = "$worker_hashrate"
    $build_json | convertto-json | Set-Content "$path\$pc\$symbol.conf"
}
if ($static_mode -eq 'no') {
    Write-Host "$TimeNow : Profitability has changed, switching coins now." -ForegroundColor yellow
}
else {
    Write-Host "$TimeNow : Mining $best_coin for another $mine_minutes minutes." -ForegroundColor yellow
    Start-Sleep -Seconds $mine_seconds
}
Write-Host "$TimeNow : Shutting down worker, please wait....."   -ForegroundColor yellow

# Mining statistics for log file.
$Time_End = GET-DATE
$timespan = $Time_End - $TimeStart
$mined_minutes = $timespan.minutes
$mined_hours = $timespan.hours

# Write to log
if ($enable_log -eq 'yes') {
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Output "$TimeNow : Finished mining $best_coin, switching to $best_coin_check" | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
        Write-Output "$TimeNow : Mined $best_coin for: $mined_hours : $mined_minutes minutes" | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
        Write-Output "$TimeNow : $best_coin worker hashrate: $worker_hashrate H/s, Accepted Shares: $my_results"  | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
}
# Wait for the executable to stop before continuing.
$worker_running = Get-Process $miner_type -ErrorAction SilentlyContinue
if ($worker_running) {
    # Write to the log.
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Output "$TimeNow : Attempting to stop $miner_type for coin-switch." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
    Write-Host "$TimeNow : Stopping Worker process." -ForegroundColor Red
    # try gracefully first
    $worker_running.CloseMainWindow() | Out-Null
    # kill after five seconds
    Write-Host "$TimeNow : Worker already running, stopping process." -ForegroundColor Yellow
    Sleep $stop_worker_delay
    if (!$worker_running.HasExited) {
        Write-Host "$TimeNow : Worker process has not halted, forcing process to stop." -ForegroundColor Red
        $worker_running | Stop-Process -Force | Out-Null
    }
}
Write-Host "$TimeNow : Successfully stopped miner process, reloading." -ForegroundColor Yellow

# Write to the log.
if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
    Write-Output "$TimeNow : The worker is now restarting." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
}

# Clear all variables
Remove-Variable * -ErrorAction SilentlyContinue

# Reload the worker.
.\profit_manager.ps1