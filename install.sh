#!/bin/sh

echo "Log output to /tmp/install.log"
touch /tmp/install.log
chmod a+rw /tmp/install.log
exec 2>/tmp/install.log || true
set -x

# Online URL
URL_PREFIX="https://"
UNINSTALL_DOWNLOAD_URL="router.uu.163.com/api/script/uninstall?type="
MONITOR_DOWNLOAD_URL="router.uu.163.com/api/script/monitor?type="

ROUTER="${1:-pandavan}"
MODEL="${2:-"$(uname -m)"}"

BASEDIR=$(dirname "$0")
UNINSTALL_FILE="${BASEDIR}/uninstall.sh"
INSTALL_DIR=""
MONITOR_FILE=""
MONITOR_CONFIG=""

ASUSWRT_MERLIN="asuswrt-merlin"
XIAOMI="xiaomi"
HIWIFI="hiwifi"
OPENWRT="openwrt"
STEAM_DECK_PLUGIN="steam-deck-plugin"
PANDAVAN="pandavan"

init_param() {
    local router="${ROUTER}"
    local monitor_filename="uuplugin_monitor.sh"

    case "${router}" in
    ${ASUSWRT_MERLIN})
        INSTALL_DIR="/jffs/uu"
        MONITOR_FILE="${INSTALL_DIR}/${monitor_filename}"
        MONITOR_CONFIG="${INSTALL_DIR}/uuplugin_monitor.config"
        UNINSTALL_DOWNLOAD_URL="${URL_PREFIX}${UNINSTALL_DOWNLOAD_URL}${ASUSWRT_MERLIN}"
        MONITOR_DOWNLOAD_URL="${URL_PREFIX}${MONITOR_DOWNLOAD_URL}${ASUSWRT_MERLIN}"
        return 0
        ;;
    ${XIAOMI})
        URL_PREFIX="http://"
        INSTALL_DIR="/data/uu"
        MONITOR_FILE="${INSTALL_DIR}/${monitor_filename}"
        MONITOR_CONFIG="${INSTALL_DIR}/uuplugin_monitor.config"
        UNINSTALL_DOWNLOAD_URL="${URL_PREFIX}${UNINSTALL_DOWNLOAD_URL}${XIAOMI}"
        MONITOR_DOWNLOAD_URL="${URL_PREFIX}${MONITOR_DOWNLOAD_URL}${XIAOMI}"
        return 0
        ;;
    ${HIWIFI})
        INSTALL_DIR="/plugins/uu"
        MONITOR_FILE="${INSTALL_DIR}/${monitor_filename}"
        MONITOR_CONFIG="${INSTALL_DIR}/uuplugin_monitor.config"
        UNINSTALL_DOWNLOAD_URL="${URL_PREFIX}${UNINSTALL_DOWNLOAD_URL}${HIWIFI}"
        MONITOR_DOWNLOAD_URL="${URL_PREFIX}${MONITOR_DOWNLOAD_URL}${HIWIFI}"
        return 0
        ;;
    ${OPENWRT})
        URL_PREFIX="http://"
        INSTALL_DIR="/usr/sbin/uu/"
        MONITOR_FILE="${INSTALL_DIR}/${monitor_filename}"
        MONITOR_CONFIG="${INSTALL_DIR}/uuplugin_monitor.config"
        UNINSTALL_DOWNLOAD_URL="${URL_PREFIX}${UNINSTALL_DOWNLOAD_URL}${OPENWRT}"
        MONITOR_DOWNLOAD_URL="${URL_PREFIX}${MONITOR_DOWNLOAD_URL}${OPENWRT}"
        return 0
        ;;
    ${STEAM_DECK_PLUGIN})
        URL_PREFIX="https://"
        INSTALL_DIR="/home/deck/uu/"
        MONITOR_FILE="${INSTALL_DIR}/${monitor_filename}"
        MONITOR_CONFIG="${INSTALL_DIR}/uuplugin_monitor.config"
        UNINSTALL_DOWNLOAD_URL="${URL_PREFIX}${UNINSTALL_DOWNLOAD_URL}${STEAM_DECK_PLUGIN}"
        MONITOR_DOWNLOAD_URL="${URL_PREFIX}${MONITOR_DOWNLOAD_URL}${STEAM_DECK_PLUGIN}"
        return 0
        ;;
    ${PANDAVAN})
        URL_PREFIX="http://"
        INSTALL_DIR="/etc/storage/uu"
        MONITOR_FILE="${INSTALL_DIR}/${monitor_filename}"
        MONITOR_CONFIG="${INSTALL_DIR}/uuplugin_monitor.config"
        UNINSTALL_DOWNLOAD_URL="${URL_PREFIX}${UNINSTALL_DOWNLOAD_URL}${OPENWRT}"
        MONITOR_DOWNLOAD_URL="${URL_PREFIX}${MONITOR_DOWNLOAD_URL}${OPENWRT}"
        return 0
        ;;
    *)
        return 1
        ;;
    esac
}

# Return: 0 means success.
config_asuswrt() {
    # Config jffs file system
    nvram set jffs2_enable=1
    nvram set jffs2_scripts=1
    nvram commit &
    return 0
}

# Return: 0 means success.
check_dir() {
    if [ ! -d "${INSTALL_DIR}" ];then
        mkdir -p "${INSTALL_DIR}"
        [ "$?" != "0" ] && return 1
    fi

    return 0
}

clean_up() {
    [ ! -f "${UNINSTALL_FILE}" ] && return 1

    chmod u+x "${UNINSTALL_FILE}"
    if [ "${ROUTER}" = "${PANDAVAN}" ];then
        /bin/sh "${UNINSTALL_FILE}" "${OPENWRT}" "${MODEL}" 1>/dev/null 2>&1
    else
        /bin/sh "${UNINSTALL_FILE}" "${ROUTER}" "${MODEL}" 1>/dev/null 2>&1
    fi
    [ "$?" != "0" ] && return 1

    return 0
}

# Return: 0 means success.
download() {
    local url="$1"
    local file="$2"
    local plugin_info=$(curl -L -s -k -H "Accept:text/plain" "${url}" || \
        wget -q --no-check-certificate -O - "${url}&output=text" || \
        wget -q -O - "${url}&output=text" || \
        curl -s -k -H "Accept:text/plain" "${url}"
    )

    [ "$?" != "0" ] && return 1
    [ -z "$plugin_info" ] && return 1

    local plugin_url=$(echo "$plugin_info" | cut  -d ',' -f 1)
    local plugin_md5=$(echo "$plugin_info" | cut  -d ',' -f 2)

    [ -z "${plugin_url}" ] && return 1
    [ -z "${plugin_md5}" ] && return 1

    curl -L -s -k "$plugin_url" -o "${file}" >/dev/null 2>&1 || \
        wget -q --no-check-certificate "$plugin_url" -O "${file}" >/dev/null 2>&1 || \
        wget -q "$plugin_url" -O "${file}" >/dev/null 2>&1 || \
        curl -s -k "$plugin_url" -o "${file}" >/dev/null 2>&1

    if [ "$?" != "0" ];then
        [ -f "${file}" ] && rm "${file}"
        return 1
    fi

    if [ -f "${file}" ];then
        local download_md5=$(md5sum "${file}")
        local download_md5=$(echo "$download_md5" | sed 's/[ ][ ]*/ /g' | cut -d' ' -f1)
        if [ "$download_md5" != "$plugin_md5" ];then
            rm "${file}"
            return 1
        fi
        return 0
    else
        return 1
    fi
}

# Return: 0 means success.
start_monitor() {
    [ ! -f  "${MONITOR_FILE}" ] && return 1

    router=${ROUTER}
    if [ "${ROUTER}" = "${PANDAVAN}" ];then
        router="${OPENWRT}"
    fi
    {
        echo "router=${router}";
        echo "model=${MODEL}"
    } > ${MONITOR_CONFIG}

    [ "$?" != "0" ] && return 1

    chmod u+x "${MONITOR_FILE}"
    /bin/sh "${MONITOR_FILE}" 1>/dev/null 2>&1 &
    return 0
}

# Return: 0 means running.
check_running() {
    local PID_FILE="/var/run/uuplugin.pid"
    local PLUGIN_EXE="uuplugin"
    local TIMES="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25"
    TIMES=${TIMES}" 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45"
    TIMES=${TIMES}" 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65"
    TIMES=${TIMES}" 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85"
    TIMES=${TIMES}" 86 87 88 89 90"
    for i in ${TIMES};do
        if [ -f "$PID_FILE" ];then
            local pid=$(cat $PID_FILE)
            local running_pid=$(ps | sed 's/^[ \t]*//g;s/[ \t]*$//g' | \
                sed 's/[ ][ ]*/#/g' | grep "${PLUGIN_EXE}" | \
                grep -v "grep" | cut -d'#' -f1 | grep -e "^${pid}$")

            if [ "${running_pid}" = "" ];then
                running_pid=$(ps -ax -o pid,cmd | sed 's/^[ \t]*//g;s/[ \t]*$//g' | \
                    sed 's/[ ][ ]*/#/g' | grep "${PLUGIN_EXE}" | \
                    grep -v "grep" | cut -d'#' -f1 | grep -e "^${pid}$")
            fi

            if [ "$pid" = "${running_pid}" ];then
                return 0
            else
                sleep 1
            fi
        else
            sleep 1
        fi
    done

    return 1
}

# Return: 0 means it is merlin.
check_merlin() {
    # Check to see if it is merlin
    local br0=$(ip -4 a s br0 | grep inet | grep -v 'grep' | \
        sed 's/^[ \t]*//g;s/[ \t]*$//g' | sed 's/[ ][ ]*/#/g' | cut -d'#' -f2 | cut -d/ -f1)
    [ -z "${br0}" ] && return 1

    local code=$(curl -s -o /dev/null -w "%{http_code}" "http://${br0}/images/merlin-logo.png")
    [ "$code" = "200" ] && return 0

    code=$(wget -Sq -O - "http://${br0}/images/merlin-logo.png" 2>&1 | grep 'HTTP' | \
        sed 's/^[ \t]*//g;s/[ \t]*$//g' | sed 's/[ ][ ]*/#/g' | cut -d'#' -f2)
    [ "$code" = "200" ] && return 0
    return 1
}

config_asuswrt_bootup() {
    check_merlin
    if [ "$?" = "0" ];then
        config_services_start
        return $?
    else
        config_exec_start
        return $?
    fi
}

# Return: 0 means success.
config_exec_start() {
    local bootup_script="${INSTALL_DIR}/uuplugin_bootup.sh"
    {
        echo "#!/bin/sh"
        echo "nohup /bin/sh ${MONITOR_FILE} &"
    } > ${bootup_script}

    chmod u+x ${bootup_script}
    nvram set jffs2_exec="${bootup_script}"
    nvram commit &
    return 0
}

# Return: 0 means success.
# Config ${MONITOR_FILE} starts on boot.
config_services_start() {
    local SERVICES_START_FILE="/jffs/scripts/services-start"
    if [ ! -e "${SERVICES_START_FILE}" ];then
        mkdir -p /jffs/scripts
        [ "$?" != "0" ] && return 1

        touch "${SERVICES_START_FILE}"
        [ "$?" != "0" ] && return 1

        { echo "#!/bin/sh"; echo ""; echo ""; } >> "${SERVICES_START_FILE}"
        [ "$?" != "0" ] && return 1
    fi

    chmod u+x "${SERVICES_START_FILE}"
    grep "${MONITOR_FILE}" "${SERVICES_START_FILE}" 1>/dev/null 2>&1
    if [ "$?" != "0" ];then
        echo "/bin/sh ${MONITOR_FILE} &" >> "${SERVICES_START_FILE}"
        [ "$?" != "0" ] && return 1
    fi

    return 0
}

# Return: 0 means success.
config_xiaomi_bootup() {
    config_bootup_implemention
    return $?
}

# Return: 0 means success.
config_hiwifi_bootup() {
    config_bootup_implemention
    return $?
}

# Return: 0 means success.
config_openwrt_bootup() {
    config_bootup_implemention
    return $?
}

# Return: 0 means success.
config_steam_deck_bootup() {
    config_steam_deck_systemd
    return $?
}

# Return: 0 means success.
config_pandavan_bootup() {
    config_pandavan_bootup_implemention
    return $?
}


config_steam_deck_systemd() {
    local uuplugin_service="/etc/systemd/system/uuplugin.service"

    {
        echo "[Unit]"
        echo "Description=UU Plugin"
        echo ""
        echo "[Service]"
        echo "ExecStart=/home/deck/uu/uuplugin_monitor.sh"
        echo ""
        echo "[Install]"
        echo "WantedBy=default.target"
    } > "${uuplugin_service}"

    systemctl enable uuplugin
    systemctl start uuplugin
}

config_bootup_implemention() {
    local init_script="${INSTALL_DIR}/S99uuplugin"
    local link_script="/etc/rc.d/S99uuplugin"

    {
        echo "#!/bin/sh /etc/rc.common";
        echo "";
        echo "";
        echo "START=99";
        echo "start() {"
        echo "    /bin/sh ${MONITOR_FILE} &";
        echo "}"
    } > "${init_script}"

    [ "$?" != "0" ] && return 1
    [ ! -f "${init_script}" ] && return 1
    chmod u+x ${init_script}

    ln -sf ${init_script} ${link_script}
    if [ "$?" != "0" ];then
        [ -f "${init_script}" ] && rm ${init_script}
        return 1
    fi
    return 0
}

config_pandavan_bootup_implemention() {
    local init_script="${INSTALL_DIR}/S99uuplugin"
    local started_script="/etc/storage/started_script.sh"

    {
        echo "#!/bin/sh";
        echo "nohup /bin/sh ${MONITOR_FILE} &";
    } > "${init_script}"

    [ "$?" != "0" ] && return 1
    [ ! -f "${init_script}" ] && return 1
    chmod u+x ${init_script}

    if ! grep -q ${init_script} $started_script;then
        echo "# Netease UU Game Booster Plugin" >> $started_script
        echo "$init_script" >> $started_script
    fi
    return $?
}

# Return: 0 means success.
config_bootup() {
    local router="${ROUTER}"
    case "${router}" in
    ${ASUSWRT_MERLIN})
        config_asuswrt_bootup
        return $?
        ;;
    ${XIAOMI})
        config_xiaomi_bootup
        return $?
        ;;
    ${HIWIFI})
        config_hiwifi_bootup
        return $?
        ;;
    ${OPENWRT})
        config_openwrt_bootup
        return $?
        ;;
    ${STEAM_DECK_PLUGIN})
        config_steam_deck_bootup
        return $?
        ;;
    ${PANDAVAN})
        config_pandavan_bootup
        return $?
        ;;
    *)
        return 1
        ;;
    esac
}

# Return: 0 means success.
config_router() {
    local router="${ROUTER}"
    case "${router}" in
    ${ASUSWRT_MERLIN})
        config_asuswrt
        return $?
        ;;
    ${XIAOMI} | ${HIWIFI} | ${OPENWRT} | ${PANDAVAN})
        return 0
        ;;
    ${STEAM_DECK_PLUGIN})
        return 0
        ;;
    *)
        return 1
        ;;
    esac
}

print_sn() {
    local interface=""
    case "${ROUTER}" in
        ${ASUSWRT_MERLIN} | ${PANDAVAN})
            interface="br0"
            ;;
        ${XIAOMI} | ${HIWIFI} | ${OPENWRT})
            interface="br-lan"
            ;;
        *)
            return 1
            ;;
    esac

    local info=$(ip addr show ${interface})
    local mac=$(echo "${info}" | grep "link/ether" | awk '{print $2}')
    echo "sn=${mac}"
    return 0
}

install() {
    init_param
    [ "$?" != "0" ] && return 9

    config_router
    [ "$?" != "0" ] && return 1

    check_dir
    [ "$?" != "0" ] && return 2

    download "${UNINSTALL_DOWNLOAD_URL}" "${UNINSTALL_FILE}"
    [ "$?" != "0" ] && return 3

    clean_up
    [ "$?" != "0" ] && return 4

    download "${MONITOR_DOWNLOAD_URL}" "${MONITOR_FILE}"
    if [ "${ROUTER}" = "${PANDAVAN}" ];then
        # Update monitoring file install directory of pandavan
        sed -i 's/\/usr\/sbin/\/etc\/storage\/uu/g' ${MONITOR_FILE}
    fi
    if [ "$?" != "0" ];then
        [ -f "${MONITOR_FILE}" ] && rm "${MONITOR_FILE}"
        return 5
    fi
    chmod a+x ${MONITOR_FILE}

    if [ "${ROUTER}" = "${STEAM_DECK_PLUGIN}" ];then
        {
            echo "router=${ROUTER}";
            echo "model=x86_64"
        } > ${MONITOR_CONFIG}
        config_bootup
        check_running
        [ "$?" != "0" ] && return 6
        return 0
    fi

    start_monitor
    [ "$?" != "0" ] && return 6

    check_running
    [ "$?" != "0" ] && return 7

    config_bootup
    [ "$?" != "0" ] && return 8

    print_sn
    [ "$?" != "0" ] && return 10
    return 0
}

# Start to install.
install
status_code=$?

if [ ${status_code} -gt 4 ];then
    if [ -f "${UNINSTALL_FILE}" ];then
        clean_up
    fi
fi

[ -f "${UNINSTALL_FILE}" ] && rm "${UNINSTALL_FILE}"
return $status_code
