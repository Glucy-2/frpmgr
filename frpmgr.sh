#!/bin/bash
# author: Glucy2<glucy-2@outlook.com>
# repo: https://github.com/Glucy-2/frpmgr

binDict="/usr/bin/"
frpConfigType="toml"
yes=false
inChina=false

usage() {
    echo "Usage: [sudo] frpmgr [OPTION]"
    echo "Manage frp"
    echo ""
    echo "  -h, --help          display this help and exit"
    echo "  -i, --install       install frp services"
    echo "  -u, --upgrade       upgrade frp"
    echo "  -y                  answer yes to all questions"
    echo "will enter main menu if no option is specified"
    exit 0
}

checkRoot() {
    [[ $EUID -ne 0 ]] && echo "This script must be run as root or using sudo" && exit 1
}

checkScriptPath() {
    if [ "$(readlink -f "$0")" != "/usr/local/bin/frpmgr" ]; then
        echo "WARNING: Please install this script to /usr/local/bin/frpmgr"
    fi
}

checkCurl() {
    if ! command -v curl &> /dev/null
    then
        echo "curl is not installed. Please install curl to run this script." >&2
        exit 1
    fi
}

checkSystemArch() {
    arch=$(uname -m)
    if [[ $arch == "x86_64" ]]; then
        archParam="amd64"
    elif [[ $arch == "arm"* ]]; then
        archParam="arm"
    elif [[ $arch == "aarch64" ]]; then
        archParam="arm64"
    elif [[ $arch == "mips" ]]; then
        archParam="mips"
    elif [[ $arch == "mipsle" ]]; then
        archParam="mipsle"
    elif [[ $arch == "mips64" ]]; then
        archParam="mips64"
    elif [[ $arch == "mips64le" ]]; then
        archParam="mips64le"
    elif [[ $arch == "riscv64" ]]; then
        archParam="riscv64"
    else
        echo "Unsupported system architecture: $arch" 1>&2
        exit 1
    fi
}

checkInChina() {
    if curl -s https://ipinfo.io/country | grep -q "CN"; then
        inChina=true
        echo "Dectcted China network, will use ghproxy.com to download files from GitHub"
    fi
}

checkEditor() {
    if ls "$HOME/.selected_editor" &> /dev/null; then
        source "$HOME/.selected_editor"
        if [ -n "$SELECTED_EDITOR" ]; then
            return
        fi
    fi
    if command -v select-editor >/dev/null 2>&1; then
        select-editor
    else
        read -p "No editor set in $HOME/.selected_editor, please input your preferred editor: " -r SELECTED_EDITOR
        until command -v "$SELECTED_EDITOR" >/dev/null 2>&1;
        do
            read -p "Command $SELECTED_EDITOR not found. Please input another: " -r SELECTED_EDITOR
        done
        read -p "Set $SELECTED_EDITOR as your default editor? [Y/n]" -r
        if [[ $REPLY =~ ^[Yy]?$ ]]; then
            echo "SELECTED_EDITOR=\"$SELECTED_EDITOR\"" > "$HOME/.selected_editor"
        fi
    fi
}

checkLatestFrpVersion() {
    echo "Checking for latest frp version..."
    if $inChina; then
        checkUrl="https://ghproxy.com/https://github.com/fatedier/frp/releases/latest"
    else
        checkUrl="https://github.com/fatedier/frp/releases/latest"
    fi
    redirectUrl=$(curl -s -L -I -o /dev/null -w '%{url_effective}' $checkUrl)
    latestFrpVersion=$(echo "$redirectUrl" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | tail -1)
    echo "Latest frp version is $latestFrpVersion"
}

installServices() {
    echo "Installing frp services..."
    skip=false
    if ls /usr/lib/systemd/system/frpc.service &> /dev/null; then
        read -p "/usr/lib/systemd/system/frpc.service already exists, overwrite it? [Y/n]" -r
        if [[ $yes == true || $REPLY =~ ^[Yy]?$ ]]; then
            rm -f /usr/lib/systemd/system/frpc.service
        else
            skip=true
        fi
    fi
    if [[ $skip != true ]]; then
        cat << EOF > /usr/lib/systemd/system/frpc.service
[Unit]
Description=Frp Client Service
After=network.target
Wants=network.target

[Service]
Type=simple
DynamicUser=yes
Restart=on-failure
RestartSec=5s
ExecStart=${binDict}frpc -c /etc/frp/frpc.${frpConfigType}
ExecReload=${binDict}frpc reload -c /etc/frp/frpc.${frpConfigType}

[Install]
WantedBy=multi-user.target
EOF
        echo "Use /etc/frp/frpc.${frpConfigType} as config file for frpc.service"
    fi
    skip=false
    if ls /usr/lib/systemd/system/frpc@.service &> /dev/null; then
        read -p "/usr/lib/systemd/system/frpc@.service already exists, overwrite it? [Y/n]" -r
        if [[ $yes == true || $REPLY =~ ^[Yy]?$ ]]; then
            rm -f /usr/lib/systemd/system/frpc@.service
        else
            skip=true
        fi
    fi
    if [[ $skip != true ]]; then
        cat << EOF > /usr/lib/systemd/system/frpc@.service
[Unit]
Description=Frp Client Service for %i
After=network.target
Wants=network.target

[Service]
Type=simple
DynamicUser=yes
Restart=on-failure
RestartSec=5s
ExecStart=${binDict}frpc -c /etc/frp/%i.${frpConfigType}
ExecReload=${binDict}frpc reload -c /etc/frp/%i.${frpConfigType}

[Install]
WantedBy=multi-user.target
EOF
        echo "Use /etc/frp/xxxx.${frpConfigType} as config file for frpc@xxxx.service"
    fi
    skip=false
    if ls /usr/lib/systemd/system/frps.service &> /dev/null; then
        read -p "/usr/lib/systemd/system/frps.service already exists, overwrite it? [Y/n]" -r
        if [[ $yes == true || $REPLY =~ ^[Yy]?$ ]]; then
            rm -f /usr/lib/systemd/system/frps.service
        else
            skip=true
        fi
    fi
    if [[ $skip != true ]]; then
        cat << EOF > /usr/lib/systemd/system/frps.service
[Unit]
Description=Frp Server Service
After=network.target
Wants=network.target

[Service]
Type=simple
DynamicUser=yes
Restart=on-failure
RestartSec=5s
ExecStart=${binDict}frps -c /etc/frp/frps.${frpConfigType}
ExecReload=${binDict}frps reload -c /etc/frp/frps.${frpConfigType}

[Install]
WantedBy=multi-user.target
EOF
    echo "Use /etc/frp/frps.${frpConfigType} as config file for frps.service"
    fi
    skip=false
    if ls /usr/lib/systemd/system/frps@.service &> /dev/null; then
        read -p "/usr/lib/systemd/system/frps@.service already exists, overwrite it? [Y/n]" -r
        if [[ $yes == true || $REPLY =~ ^[Yy]?$ ]]; then
            rm -f /usr/lib/systemd/system/frps@.service
        else
            skip=true
        fi
    fi
    if [[ $skip != true ]]; then
        cat << EOF > /usr/lib/systemd/system/frps@.service
[Unit]
Description=Frp Server Service for %i
After=network.target
Wants=network.target

[Service]
Type=simple
DynamicUser=yes
Restart=on-failure
RestartSec=5s
ExecStart=${binDict}frps -c /etc/frp/%i.${frpConfigType}
ExecReload=${binDict}frps reload -c /etc/frp/%i.${frpConfigType}

[Install]
WantedBy=multi-user.target
EOF
        echo "Use /etc/frp/xxxx.${frpConfigType} as config file for frps@xxxx.service"
    fi
    systemctl daemon-reload
    read -p "Set a timer to automatically check for updates every day at 4:00? [Y/n]" -r
    if [[ $yes == true || $REPLY =~ ^[Yy]?$ ]]; then
        cat << EOF > /usr/lib/systemd/system/upgrade-frp.timer
[Unit]
Description=Timer for upgrading frp

[Timer]
OnCalendar=*-*-* 04:00:00
Persistent=true

[Install]
WantedBy=timers.target

EOF
        cat << EOF > /usr/lib/systemd/system/upgrade-frp.service
[Unit]
Description=Service for upgrading frp
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/frpmgr -u -y

EOF
        systemctl daemon-reload
        read -p "Enable the timer now? [Y/n]" -r
        [[ $yes == true || $REPLY =~ ^[Yy]?$ ]] && systemctl enable --now upgrade-frp.timer
    fi
}

downloadFrp(){
    fileName="frp_${latestFrpVersion}_linux_${archParam}.tar.gz"
    if $inChina; then
        downloadUrl="https://ghproxy.com/https://github.com/fatedier/frp/releases/download/v${latestFrpVersion}/${fileName}"
        checksumsUrl="https://ghproxy.com/https://github.com/fatedier/frp/releases/download/v${latestFrpVersion}/frp_sha256_checksums.txt"
    else
        downloadUrl="https://github.com/fatedier/frp/releases/download/v${latestFrpVersion}/${fileName}"
        checksumsUrl="https://github.com/fatedier/frp/releases/download/v${latestFrpVersion}/frp_sha256_checksums.txt"
    fi
    echo "Downloading frp_sha256_checksums.txt..."
    i=1
    while [ $i -le 3 ];
    do
        if sha256=$(curl -fSL "$checksumsUrl" | grep -E "^([a-fA-F0-9]{64}) +$fileName" | awk '{print $1}'); then
            break
        fi
        if [ $i -ge 3 ]; then
            echo "frp_sha256_checksums.txt download failed too many times, exiting..."
            exit 1
        else
            echo "frp_sha256_checksums.txt download failed, trying again..."
            curl -fSL "$downloadUrl" -o "$tempFile"
            ((i++))
        fi
    done
    tempFile=$(mktemp)
    echo "Downloading $fileName..."
    curl -fSL "$downloadUrl" -o "$tempFile"
    i=1
    while [ $i -le 3 ];
    do
        curl -fSL "$downloadUrl" -o "$tempFile"
        if [ "$(sha256sum "$tempFile" | cut -d ' ' -f 1)" == "$sha256" ]; then
            break
        fi
        if [ $i -ge 3 ]; then
            echo "sha256sum of downloaded file does not match, exiting..."
            exit 1
        else
            echo "sha256sum of downloaded file does not match, trying again..."
            ((i++))
        fi
    done
}

upgradeFrp() {
    checkLatestFrpVersion
    if [ "$(${binDict}frps -v 2>/dev/null)" != "$latestFrpVersion" ]; then
        read -p "frps is not updated or installed, install latest version? [Y/n]" -r
        if [[ $yes == true || $REPLY =~ ^[Yy]?$ ]]; then
            installFrps=true
        fi
    else
        echo "frpc is already the latest version"
    fi
    if [ "$(${binDict}frpc -v 2>/dev/null)" != "$latestFrpVersion" ]; then
        read -p "frpc is not updated or installed, install latest version? [Y/n]" -r
        if [[ $yes == true || $REPLY =~ ^[Yy]?$ ]]; then
            installFrpc=true
        fi
    else
        echo "frpc is already the latest version"
    fi
    if [[ $installFrps == true ]] || [[ $installFrpc == true ]]; then
        downloadFrp
    fi
    if [[ $installFrps == true ]]; then
        tar -xzf "$tempFile" -C "$binDict" --strip-components=1 "frp_${latestFrpVersion}_linux_${archParam}/frps"
        echo -e "Installed frps version: $("$binDict"frps -v)"
        # Uncomment the following lines if you want to restart running frps services after upgrade
        # WARNING: This can break you services if there are breaking changes in new frp version
        # if systemctl is-active --quiet frps; then
        #     systemctl restart frps.service
        # fi
        # systemctl list-units -t service --state running --all --full --no-legend frps@* | awk '{print $1}' | xargs -I {} systemctl restart {}
    fi
    if [[ $installFrpc == true ]]; then
        tar -xzf "$tempFile" -C "$binDict" --strip-components=1 "frp_${latestFrpVersion}_linux_${archParam}/frpc"
        echo -e "Installed frpc version: $("$binDict"frpc -v)"
        # Uncomment the following lines if you want to restart running frpc services after upgrade
        # WARNING: This can break you services if there are breaking changes in new frp version
        # if systemctl is-active --quiet frpc; then
        #     systemctl restart frpc.service
        # fi
        # systemctl list-units -t service --state running --all --full --no-legend frpc@* | awk '{print $1}' | xargs -I {} systemctl restart {}
    fi
}

manageFrp() {
    multiconfigMode=false
    while :
    do
    echo "What to manage?"
    echo "[0] Back"
    echo "[1] frps"
    echo "[2] frpc"
    read -p "Your option: " -r option
    case "$option" in
        0)
            return 0
            ;;
        1)
            manage="frps"
            ;;
        2)
            manage="frpc"
            ;;
        *)
            echo "Invalid input"
            ;;
    esac
    while :
    do
    echo "MENU:"
    if [[ $multiconfigMode == false ]]; then
        echo "[0] Back"
        echo "[1] Switch to multi config mode"
        echo "[2] Show $manage service status"
        echo "[3] View $manage service logs in reverse order"
        echo "[4] Restart $manage service"
        echo "[5] Start $manage service"
        echo "[6] Stop $manage service"
        echo "[7] Reload $manage service"
        echo "[8] Enable $manage service"
        echo "[9] Disable $manage service"
        read -p "Your option: " -r option
        case "$option" in
            0)
                break
                ;;
            1)
                multiconfigMode=true
                ;;
            2)
                systemctl status "$manage"
                ;;
            3)
                journalctl -u "$manage" -r
                ;;
            4)
                read -p "Will restart $manage service, continue? [Y/n]" -r
                if [[ $REPLY =~ ^[Yy]?$ ]]; then
                    systemctl restart "$manage"
                fi
                ;;
            5)
                read -p "Will start $manage service, continue? [Y/n]" -r
                if [[ $REPLY =~ ^[Yy]?$ ]]; then
                    systemctl start "$manage"
                fi
                ;;
            6)
                read -p "Will stop $manage service, continue? [Y/n]" -r
                if [[ $REPLY =~ ^[Yy]?$ ]]; then
                    systemctl stop "$manage"
                fi
                ;;
            7)
                read -p "Will reload $manage services, continue? [Y/n]" -r
                if [[ $REPLY =~ ^[Yy]?$ ]]; then
                    systemctl reload "$manage"
                fi
                ;;
            8)
                systemctl enable "$manage"
                ;;
            9)
                systemctl disable "$manage"
                ;;
            *)
                echo "Invalid input"
                ;;
        esac
    else
        echo "[ 0] Back"
        echo "[ 1] Switch to single config mode"
        echo "[ 2] Show all $manage services status"
        echo "[ 3] View logs of a $manage service in reverse order"
        echo "[ 4] Restart a $manage service"
        echo "[ 5] Start a $manage service"
        echo "[ 6] Stop a $manage service"
        echo "[ 7] Reload a $manage service"
        echo "[ 8] Enable a $manage service"
        echo "[ 9] Disable a $manage service"
        echo "[10] Restart all $manage services"
        echo "[11] Start all $manage services"
        echo "[12] Stop all $manage services"
        echo "[13] Reload all $manage services"
        echo "[14] Enable all $manage services"
        echo "[15] Disable all $manage services"
        echo ""
        echo "Note: all $manage services mean $manage@*.service, "
        echo "      don't include $manage.service"
        read -p "Your option: " -r option
        case "$option" in
            0)
                break
                ;;
            1)
                multiconfigMode=false
                ;;
            2)
                systemctl list-units -t service --all --full "$manage@*"
                ;;
            3)
                read -p "Input service name: $manage@" -r serviceName
                journalctl -u "$manage@$serviceName" -r
                ;;
            4)
                read -p "Input service name: $manage@" -r serviceName
                read -p "Will restart $manage@${serviceName}, continue? [Y/n]" -r
                [[ $REPLY =~ ^[Yy]?$ ]] && systemctl restart "$manage@$serviceName"
                ;;
            5)
                read -p "Input service name: $manage@" -r serviceName
                read -p "Will start $manage@${serviceName}, continue? [Y/n]" -r
                [[ $REPLY =~ ^[Yy]?$ ]] && systemctl start "$manage@$serviceName"
                ;;
            6)
                read -p "Input service name: $manage@" -r serviceName
                read -p "Will stop $manage@${serviceName}, continue? [Y/n]" -r
                [[ $REPLY =~ ^[Yy]?$ ]] && systemctl stop "$manage@$serviceName"
                ;;
            7)
                read -p "Input service name: $manage@" -r serviceName
                read -p "Will reload $manage@${serviceName}, continue? [Y/n]" -r
                [[ $REPLY =~ ^[Yy]?$ ]] && systemctl reload "$manage@$serviceName"
                ;;
            8)
                read -p "Input service name: $manage@" -r serviceName
                systemctl enable "$manage@$serviceName"
                ;;
            9)
                read -p "Input service name: $manage@" -r serviceName
                systemctl disable "$manage@$serviceName"
                ;;
            10)
                read -p "Will restart all $manage services, continue? [Y/n]" -r
                [[ $REPLY =~ ^[Yy]?$ ]] && systemctl restart "$manage@*"
                ;;
            11)
                read -p "Will start all $manage services, continue? [Y/n]" -r
                [[ $REPLY =~ ^[Yy]?$ ]] && systemctl start "$manage@*"
                ;;
            12)
                read -p "Will stop all $manage services, continue? [Y/n]" -r
                [[ $REPLY =~ ^[Yy]?$ ]] && systemctl stop "$manage@*"
                ;;
            13)
                read -p "Will reload all $manage services, continue? [Y/n]" -r
                [[ $REPLY =~ ^[Yy]?$ ]] && systemctl reload "$manage@*"
                ;;
            14)
                read -p "Will enable all $manage services, continue? [Y/n]" -r
                [[ $REPLY =~ ^[Yy]?$ ]] && systemctl enable "$manage@*"
                ;;
            15)
                read -p "Will disable all $manage services, continue? [Y/n]" -r
                [[ $REPLY =~ ^[Yy]?$ ]] && systemctl disable "$manage@*"
                ;;
            *)
                echo "Invalid input"
                ;;
        esac
    fi
    done
    done
}

manage() {
    frpsVersion=$(${binDict}frps -v 2>/dev/null)
    frpcVersion=$(${binDict}frpc -v 2>/dev/null)
    if [ -z "$frpsVersion" ] && [ -z "$frpsVersion" ]; then
        read -p "Neither frps and frpc are not installed, install now? [Y/n]" -r
        if [[ $yes == true || $REPLY =~ ^[Yy]?$ ]]; then
            upgradeFrp
            frpsVersion=$(${binDict}frps -v 2>/dev/null)
            frpcVersion=$(${binDict}frpc -v 2>/dev/null)
        fi
    fi
    if [ -z "$frpsVersion" ]; then
        echo "frps is not installed"
    else
        echo "Installed frps version: $frpsVersion"
    fi
    if [ -z "$frpsVersion" ]; then
        echo "frpc is not installed"
    else
        echo "Installed frpc version: $frpcVersion"
    fi
    checkLatestFrpVersion
    while :
    do
    echo "MENU:"
    echo "[0] Exit"
    echo "[1] Manage frp"
    echo "[2] Install/Upgrade frp"
    echo "[3] Install frp services"
    echo "[4] Enable frp auto-upgrade timer"
    echo "[5] Disable frp auto-upgrade timer"
    echo "[6] Edit/Create a frp config file"
    echo "[7] Edit a frp service file"
    echo "[8] Uninstall services"
    echo "[9] Uninstall frp"
    read -p "Your option: " -r option
    case "$option" in
        0)
            exit 0
            ;;
        1)
            manageFrp
            ;;
        2)
            upgradeFrp
            ;;
        3)
            installServices
            ;;
        4)
            systemctl enable --now upgrade-frp.timer
            ;;
        5)
            systemctl disable --now upgrade-frp.timer
            ;;
        6)
            echo "Tip: use Tab to autocomplete file name"
            read -e -i "/etc/frp/" -p "Input config name: " -r fileName
            "$SELECTED_EDITOR" "$fileName"
            ;;
        7)
            echo "MENU:"
            echo "[0] Back"
            echo "[1] frps.service"
            echo "[2] frps@.service"
            echo "[3] frpc.service"
            echo "[4] frpc@.service"
            read -p "Your option: " -r option
            case "$option" in
                0)
                    break
                    ;;
                1)
                    "$SELECTED_EDITOR" /usr/lib/systemd/system/frps.service
                    ;;
                2)
                    "$SELECTED_EDITOR" /usr/lib/systemd/system/frps@.service
                    ;;
                3)
                    "$SELECTED_EDITOR" /usr/lib/systemd/system/frpc.service
                    ;;
                4)
                    "$SELECTED_EDITOR" /usr/lib/systemd/system/frpc@.service
                    ;;
                *)
                    echo "Invalid input"
                    ;;
            esac
            ;;
        8)
            read -p "Uninstall frp services? [Y/n]" -r
            if [[ $REPLY =~ ^[Yy]?$ ]]; then
                systemctl disable --now frps
                systemctl disable --now frps@*
                systemctl disable --now frpc
                systemctl disable --now frpc@*
                rm -f /usr/lib/systemd/system/frpc.service
                rm -f /usr/lib/systemd/system/frpc@.service
                rm -f /usr/lib/systemd/system/frps.service
                rm -f /usr/lib/systemd/system/frps@.service
                systemctl daemon-reload
            fi
            ;;
        9)
            read -p "Uninstall frp? [Y/n]" -r
            if [[ $REPLY =~ ^[Yy]?$ ]]; then
                rm -f ${binDict}frpc
                rm -f ${binDict}frps
            fi
            ;;
        *)
            echo "Invalid input"
            ;;
    esac
    done
}


echo '    ____                               '
echo '   / __/________  ____ ___  ____ ______'
echo '  / /_/ ___/ __ \/ __ `__ \/ __ `/ ___/'
echo ' / __/ /  / /_/ / / / / / / /_/ / /    '
echo '/_/ /_/  / .___/_/ /_/ /_/\__, /_/     '
echo '        /_/              /____/        '
echo '    frpmgr - frp manager               '
echo 'repo: https://github.com/Glucy-2/frpmgr'
echo 'author: Glucy2<glucy-2@outlook.com>    '
echo ''
echo 'Initiating...'

checkScriptPath

while getopts 'yihu' arg;
do
    case $arg in
        h)
            usage
            ;;
        i)
            checkRoot
            installServices
            exit 0
            ;;
        u)
            checkRoot
            checkCurl
            checkSystemArch
            checkInChina
            upgradeFrp
            exit 0
            ;;
        y)
            yes=true
            ;;
        ?)
            echo "Invalid argument. Check usage by $0 -h" 1>&2
            exit 1
            ;;
    esac
done

checkRoot
checkCurl
checkSystemArch
checkInChina
checkEditor
manage
