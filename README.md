# Profibot-Pro

Welcome to Profitbot Pro 4.7.2

<b>What's new?</b>

- Added USD and Base Coin Pair (BTC/ETH/LTC/XNR) to worker.
- Additional error handling
- Profitbot_Pro.bat now starts the software
- PBP Icon is included for desktop shortcut

Check out our twitter page!

https://twitter.com/profitbotpro

![image](https://user-images.githubusercontent.com/8581255/44957972-ca7c2700-ae9e-11e8-9953-7e400dae50d1.png)

![image](https://user-images.githubusercontent.com/8581255/44958135-45464180-aea1-11e8-9695-c62bf227d127.png)


<b>Quick Setup</b>

Settings.conf file:

Most of these are pretty obvious, but I'll explain:

![image](https://user-images.githubusercontent.com/8581255/44958455-1f6f6b80-aea6-11e8-987e-d39c8db9d65b.png)

- Version: Leave this alone. If you want to force a fresh download, you can change it to a lower version, which will trigger a new download.

 - Path: When you enter the path to your install folder, please make sure to use double slashes \\. eg. c:\\profitbot_pro

- Static Mode: Yes or No. Yes means you are only going to mine whatever your default coin is in coin_settings.conf. No means you are in profit mode, and will mine whatever matches the API, and your list of coins.

- Update_check: Yes or no. Yes will check for software updates, no will not.

- Allow_automatic_updates: Yes or no. Yes allows the software to update itself, no does not. If you allow automatic updates, the software will import your settings in to the new version.

- Update_URL: Changing this will break the software, please do not change.

- Enable_logging: Yes or no. If you want logs, change to yes.

- Log_age: This is the number of days to you want to keep old log files.

- Delete_CPU_text: Yes or no. Some algo's can use more threads than others. If you experience issues, turn this feature off, and adjust the threads manually in cpu.txt. I like to use it, so that XMR Stak chooses the appropriate number of threads.

- Mining_timer: Number of minutes you want to mine before checking for a more profitable coin. 10 minutes is a good number to begin with. Too low, and you spend more time restarting the worker than actual mining. Too long and you may miss out. I keep mine between 5 and 10 minutes, personally.

- Sleep_seconds: Number of seconds between updates to the worker screen. Please do not go below 30 seconds, it's unnecessary, and causes a strain on your system and mine. 30 seconds to 1 minute is optimal.

- Voice: Yes or no. Yes enables speech when you switch coins. No turns it off. I like to hear what my rigs are doing when I'm in the another room in my house. 

- Stop_worker_delay: Number of seconds to wait after the software stops XMR Stak. Helps reduce system crashes by waiting for the worker to fully stop before switching to a new config. I would not set this less than 5 seconds. 

- Benchmark_time: Number of minutes to benchmark each currency. The screenshot shows 1 minute, this is not the most accurate amount of time, but it does get you operational quickly. Preferred time would be 3 to 5 mins per currency -- although this is up to you.

- Enable_coin_data: Yes or no. Allows you to see the estimated fruits of your labors. If you do not care to see the estimated rewards, or other coin data, you can turn this off.

- Coin_data_age: Options are current, 1hr, 24hr, and 1wk. I suggest you use the 24hr setting as it's a better average of the coin, and weeds out severe peaks. 1wk will give you a nice average value of the coin over a 7 day period. This ensure you are truly mining a top coin.

Coin_settings.conf file:

![image](https://user-images.githubusercontent.com/8581255/44958738-f6e97080-aea9-11e8-9e5d-85747fd52bbf.png)

- Version: Leave this alone.

- Default_coin: This is the coin you want to mine if all other coins are not profitable. It's also the coin you set for static mining mode.

- My_coins: This is a list of all the coins you want to mine. IT IS IMPORTANT to have a wallet for each of the coins in this list, or you will run in to errors. This file needs to be in JSON format, like in the example.

- mining_params: This sections contains the information your worker needs to connect to the pool and mine. This needs to remain in JSON format.

- Symbol: The symbol of the coin you want to mine. XTL, CCX, ELYA. You get the idea.

- Software: Please do not change this from xmr-stak. I added this in the event that I support more types of mining software. I used to support 2 other versions of XMR that were tailored to oddball coins, but it became a nightmare to support. 

- Static_param: This is a number 1-5. The value tells the software how you would like the fixed difficulty to be appended to the wallet value. The pool will tell you the symbol they accept. If the pool does not support fixed difficulty, set the value to 5. Here's a definition of the values: 

<b> 1 = "wallet+diff_value" 2 = "wallet.diff_value" 3 = "wallet.worker_name+diff_value" 4 = "wallet.worker_name" 5 = No fixed diff config setting used. </b>

PLEASE PAY ATTENTION TO THE VALUES ABOVE! If you choose the wrong value, you may not be paid for your mining efforts!

This is an example from one of the pools I mine:

![image](https://user-images.githubusercontent.com/8581255/44958883-f05bf880-aeab-11e8-8085-0ae6b0ba39ec.png)

- Algo: This is very important. If you do not match the algo with the pool, you will get nothing but rejected results. Here's a list of all the algo's XMR Stak currently supports:

![image](https://user-images.githubusercontent.com/8581255/44958895-3618c100-aeac-11e8-83a6-82f185b28208.png)

Pool: Enter the mining address, and port for the pool that matches the coin you intend to mine.

Here's an example:

![image](https://user-images.githubusercontent.com/8581255/44958905-7415e500-aeac-11e8-8e57-ac3adebbc5b4.png)

- Wallet: You will find this address in the wallet you downloaded for a particular coin. Please make sure you remove my address, and enter your own. Otherwise, you will be mining for me, and that's not my intention. :)

![image](https://user-images.githubusercontent.com/8581255/44958917-b5a69000-aeac-11e8-89a3-68210b94cfc4.png)

- AMD_config_file: I wrote the software to allow granular configurations. This means you can have a separate config file for each coin, or algo. I personally group all the CN7 coins in to 1 file, Heavy/TUBE in to another, and light in to a 3rd. This allows me to adjust the intensity for different algo strengths.

I use multithread on all my AMD GPU's, here's an example of 2 RX580 GPU's with multithread configured, for CN7. I highlighted the pairs in 2 different colors so you can see that there are 2 threads for each GPU.

![image](https://user-images.githubusercontent.com/8581255/44958960-3c5b6d00-aead-11e8-86d0-2914075b1a25.png)

If you find any bugs, or have general feedback, please create an issue in my GIT:

https://github.com/randygrolemund/Profitbot-Pro/issues

Our website is being designed right now, and will be available at:

https://www.profitbotpro.com


I hope you enjoy my software and have much success mining!

Randy G (Bearlyhealz)

You can use any of the addresses in the default files to send a donation if you so feel inclined! I'm a 1 man show, and all my non-work hours are dedicated to this project (and to my Fiancee).
