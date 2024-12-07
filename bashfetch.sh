#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

COLOR_RESET=$'\033[0m'
COLOR_CYAN=$'\033[0;36m'
COLOR_MAGENTA=$'\033[0;35m'

# Section line drawing function
print_section_line() {
    # Prints a colored horizontal line for visual separation
    printf "%s%s%s\n" "${COLOR_CYAN}" "----------------------------------------------------" "${COLOR_RESET}"
}

IMAGE="
 +-+-+-+-+-+-+-+-+-+
 |b|a|s|h|f|e|t|c|h|
 +-+-+-+-+-+-+-+-+-+
"

display_error() {
    printf "Error: %s\n" "$1" >&2
    exit 1
}

printf "%s\n\n" "$IMAGE"

check_command() {
    command -v "$1" >/dev/null 2>&1 || display_error "'$1' command not found"
}

check_command hostname
check_command uname
check_command awk
check_command df
check_command grep

hostname_val="$(hostname -f 2>/dev/null || true)"
[ -n "$hostname_val" ] || hostname_val="Unknown Hostname"

if command -v lsb_release >/dev/null 2>&1; then
    os="$(lsb_release -ds 2>/dev/null || true)"
else
    if [ -f /etc/os-release ]; then
        os="$(. /etc/os-release && printf "%s" "$PRETTY_NAME")"
    else
        os="Unknown Operating System"
    fi
fi
[ -n "$os" ] || os="Unknown Operating System"

kernel="$(uname -r 2>/dev/null || true)"
[ -n "$kernel" ] || kernel="Unknown Kernel Version"

architecture="$(uname -m 2>/dev/null || true)"
[ -n "$architecture" ] || architecture="Unknown Architecture"

if command -v uptime >/dev/null 2>&1; then
    uptime_str="$(uptime -p 2>/dev/null | sed 's/up //')" || uptime_str="N/A"
else
    uptime_str="N/A"
fi
[ -n "$uptime_str" ] || uptime_str="N/A"

load_averages="$(awk '{print $1" "$2" "$3}' /proc/loadavg 2>/dev/null || echo "N/A")"
[ -n "$load_averages" ] || load_averages="N/A"

if command -v nproc >/dev/null 2>&1; then
    cpu_cores="$(nproc)"
else
    cpu_cores="$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1)"
fi
[ -n "$cpu_cores" ] || cpu_cores="Unknown"

cpu_model="$(awk -F': ' '/^model name/ {print $2}' /proc/cpuinfo 2>/dev/null | head -n1 || true)"
[ -n "$cpu_model" ] || cpu_model="Unknown CPU Model"

CPU_freq="$(awk -F'[: ]+' '/^cpu MHz/ {printf("%.2f MHz", $4); exit}' /proc/cpuinfo 2>/dev/null || echo "N/A")"

ram="$(awk '/MemTotal:/ {printf("%.1f GB", $2 / 1024 / 1024)}' /proc/meminfo 2>/dev/null || echo "N/A")"
[ -n "$ram" ] || ram="N/A"

Mem_available="$(awk '/MemAvailable:/ {printf("%.1f GB", $2 / 1024 / 1024); exit}' /proc/meminfo 2>/dev/null || echo "N/A")"

disk_space="$(df -h / 2>/dev/null | awk 'NR>1 {print $4}' || true)"
[ -n "$disk_space" ] || disk_space="N/A"

if command -v dpkg-query >/dev/null 2>&1; then
    num_packages="$(dpkg-query -f '${Status}\n' -W 2>/dev/null | grep -c 'install ok installed' || echo "N/A")"
else
    num_packages="N/A"
fi
[ -n "$num_packages" ] || num_packages="N/A"

user_val="$(whoami 2>/dev/null || echo "Unknown User")"
[ -n "$user_val" ] || user_val="Unknown User"
shell_val="${SHELL:-unknown}"
[ -n "$shell_val" ] || shell_val="Unknown Shell"

if command -v lspci >/dev/null 2>&1; then
    gpu="$(lspci -nn | grep -Ei 'VGA|3D|2D' | head -n1 | sed 's/.*: //' || echo "N/A")"
    [ -n "$gpu" ] || gpu="N/A"
else
    gpu="N/A"
fi

ip_address="$(hostname -I 2>/dev/null | awk '{print $1}' || echo "N/A")"
[ -n "$ip_address" ] || ip_address="N/A"

desktop_env="${XDG_CURRENT_DESKTOP:-N/A}"
window_mgr="${XDG_SESSION_DESKTOP:-N/A}"

if command -v sensors >/dev/null 2>&1; then
    cpu_temp="$(sensors 2>/dev/null | awk -F': +' '/Core 0/ {print $2; exit}' || echo "N/A")"
else
    cpu_temp="N/A"
fi

if command -v timedatectl >/dev/null 2>&1; then
    timezone="$(timedatectl 2>/dev/null | awk -F': ' '/Time zone:/ {print $2}' | awk '{print $1}' || echo "N/A")"
else
    timezone="${TZ:-N/A}"
fi

current_datetime="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "N/A")"

if command -v locale >/dev/null 2>&1; then
    default_locale="$(locale | awk -F= '/^LANG=/{gsub(/"/,"",$2); print $2; exit}' || echo "N/A")"
else
    default_locale="N/A"
fi

logged_in_users="$(who | wc -l 2>/dev/null || echo "N/A")"

if command -v systemd >/dev/null 2>&1; then
    systemd_version="$(systemd --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "N/A")"
else
    systemd_version="N/A"
fi

print_section() {
    section_name="$1"
    print_section_line
    printf "%s%s%s\n" "${COLOR_CYAN}" "$section_name" "${COLOR_RESET}"
    print_section_line
    printf "\n"
}

print_info() {
    label="$1"
    value="$2"
    printf "%-25s : %s\n" "$label" "$value"
}

print_section "System Information"
print_info "Hostname" "$hostname_val"
print_info "Operating System" "$os"
print_info "Kernel Version" "$kernel"
print_info "Architecture" "$architecture"
print_info "Uptime" "$uptime_str"
print_info "Load Averages" "$load_averages"
print_info "IP Address" "$ip_address"
print_info "Date & Time" "$current_datetime"
print_info "Time Zone" "$timezone"
print_info "Locale" "$default_locale"

print_section "Hardware Information"
print_info "CPU Model" "$cpu_model"
print_info "CPU Frequency" "$CPU_freq"
print_info "CPU Cores" "$cpu_cores"
print_info "CPU Temperature" "$cpu_temp"
print_info "GPU" "$gpu"
print_info "Total RAM" "$ram"
print_info "Available RAM" "$Mem_available"
print_info "Available Disk Space" "$disk_space"

print_section "System Environment"
print_info "Installed Packages" "$num_packages"
print_info "Current User" "$user_val"
print_info "Shell" "$shell_val"
print_info "Desktop Env" "$desktop_env"
print_info "Window Manager" "$window_mgr"
print_info "Logged-in Users" "$logged_in_users"
print_info "systemd Version" "$systemd_version"

printf "\n%sAll data has been retrieved successfully.%s\n" "${COLOR_MAGENTA}" "${COLOR_RESET}"
