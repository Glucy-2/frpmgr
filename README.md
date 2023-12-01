# frpmgr

Shell(bash) script [frp](https://github.com/fatedier/frp) manager for linux.

```
    ____                         
   / __/________  ____ ___  ____ ______
  / /_/ ___/ __ \/ __ `__ \/ __ `/ ___/
 / __/ /  / /_/ / / / / / / /_/ / /  
/_/ /_/  / .___/_/ /_/ /_/\__, /_/   
        /_/              /____/  
```

## Features

- install and (auto) upgrade frp server and client
- installs systemd services for easy management
- manage single and/or multiple frp services and configurations
- download from ghproxy.com if in China

Main menu:

```yml
MENU:
[0] Exit
[1] Manage frp
[2] Install/Upgrade frp
[3] Edit/Create a frp config file
[4] Edit a frp service file
[5] Uninstall services
[6] Uninstall frp
```

Single config mode:

```yml
MENU:
[0] Back
[1] Switch to multi config mode
[2] Show frps(/frpc) service status
[3] View frps(/frpc) service logs in reverse order
[4] Restart frps(/frpc) service
[5] Start frps(/frpc) service
[6] Stop frps(/frpc) service
[7] Reload frps(/frpc) service
[8] Enable frps(/frpc) service
[9] Disable frps(/frpc) service
```

Multi config mode:

```yml
MENU:
[ 0] Back
[ 1] Switch to single config mode
[ 2] Show all frps(/frpc) services status
[ 3] View logs of a frps(/frpc) service in reverse order
[ 4] Restart a frps(/frpc) service
[ 5] Start a frps(/frpc) service
[ 6] Stop a frps(/frpc) service
[ 7] Reload a frps(/frpc) service
[ 8] Enable a frps(/frpc) service
[ 9] Disable a frps(/frpc) service
[10] Restart all frps(/frpc) services
[11] Start all frps(/frpc) services
[12] Stop all frps(/frpc) services
[13] Reload all frps(/frpc) services
[14] Enable all frps(/frpc) services
[15] Disable all frps(/frpc) services
```

## Installation

Dependencies:

- `systemd`
- `bash`
- `curl`
- `readline`

```shell
sudo curl -o /usr/local/bin/frpmgr -fsSL https://raw.githubusercontent.com/Glucy-2/frpmgr/main/frpmgr.sh
```

If in China, use ghproxy.com:

```shell
sudo curl -o /usr/local/bin/frpmgr -fsSL https://ghproxy.com/https://raw.githubusercontent.com/Glucy-2/frpmgr/main/frpmgr.sh
```

## Usage

*You need root/sudo to install and run frpmgr*

```shell
sudo frpmgr
```

Then you will see the main menu as shown above

frpmgr will install frps and frpc binary files into `/usr/bin/` and use `toml` frp config by default, can be changed in head of the script (line 5-6) before installing

Uncommenting the lines in `upgradeFrp()` function will restart all running frp services after upgrading frp.
