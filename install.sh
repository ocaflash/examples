#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOG_SCRIPT="${SCRIPT_DIR}/log.sh"

if [[ ! -f "$LOG_SCRIPT" ]]; then
    echo "ERROR: log.sh not found: $LOG_SCRIPT"
    exit 1
fi

source "$LOG_SCRIPT"

trap 'fatal "Installation failed at line $LINENO."' ERR

if [[ $EUID -ne 0 ]]; then
    fatal "This script must be run as root. Try using sudo."
    exit 1
fi

if [[ $# -ne 0 ]]; then
    fatal "Invalid arguments."
    info "Usage: $0"
    exit 1
fi

INSTALL_DIR="/var/www/linguard"
APP_DIR="${INSTALL_DIR}/linguard"
DATA_DIR="${INSTALL_DIR}/data"
SERVICE_NAME="linguard"

info "Preparing installation directory..."

if [[ -d "$INSTALL_DIR" ]]; then
    while true; do
        warn -n "'$INSTALL_DIR' already exists. Overwrite it? [y/n] "

        read -r yn

        case "$yn" in
            [Yy]*)
                if [[ "$INSTALL_DIR" != "/var/www/linguard" ]]; then
                    fatal "Unexpected INSTALL_DIR value: $INSTALL_DIR"
                    exit 1
                fi

                rm -rf "$INSTALL_DIR"
                break
                ;;
            [Nn]*)
                info "Installation aborted."
                exit 0
                ;;
            *)
                echo "Please answer y or n."
                ;;
        esac
    done
fi

mkdir -p "$INSTALL_DIR"
mkdir -p "$DATA_DIR"

info "Copying application files..."

cp -a "${SCRIPT_DIR}/linguard" "$INSTALL_DIR"
cp "${SCRIPT_DIR}/requirements.txt" "$INSTALL_DIR"
cp "${SCRIPT_DIR}/config/uwsgi.sample.yaml" "$DATA_DIR/uwsgi.yaml"

info "Updating package index..."

apt-get -qq update

dependencies=(
    sudo
    python3
    python3-venv
    wireguard
    iptables
    libpcre3
    libpcre3-dev
    uwsgi
    uwsgi-plugin-python3
    iproute2
)

debug "Installing dependencies: ${dependencies[*]}"

apt-get install -y "${dependencies[@]}"

info "Creating Python virtual environment..."

python3 -m venv "${INSTALL_DIR}/venv"

source "${INSTALL_DIR}/venv/bin/activate"

python3 -m pip install --upgrade pip
python3 -m pip install -r "${INSTALL_DIR}/requirements.txt"

deactivate

info "Creating service account..."

if ! getent group linguard >/dev/null; then
    groupadd --system linguard
fi

if ! id linguard >/dev/null 2>&1; then
    useradd \
        --system \
        --gid linguard \
        --home-dir "$INSTALL_DIR" \
        --shell /usr/sbin/nologin \
        linguard
fi

info "Setting permissions..."

chown -R linguard:linguard "$INSTALL_DIR"

if [[ -d "${APP_DIR}/core/tools" ]]; then
    find "${APP_DIR}/core/tools" \
        -type f \
        -name "*.sh" \
        -exec chmod 755 {} \;
fi

info "Configuring sudo permissions..."

cat > /etc/sudoers.d/linguard <<EOF
linguard ALL=(root) NOPASSWD: /usr/bin/wg
linguard ALL=(root) NOPASSWD: /usr/bin/wg-quick
EOF

chmod 440 /etc/sudoers.d/linguard

if ! visudo -cf /etc/sudoers.d/linguard >/dev/null; then
    fatal "Invalid sudoers configuration."
    rm -f /etc/sudoers.d/linguard
    exit 1
fi

info "Installing systemd service..."

cp "${SCRIPT_DIR}/systemd/linguard.service" \
   "/etc/systemd/system/${SERVICE_NAME}.service"

chmod 644 "/etc/systemd/system/${SERVICE_NAME}.service"

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.service"

info "Installation completed successfully."

info "Next steps:"
info "  systemctl start ${SERVICE_NAME}.service"
info "  systemctl status ${SERVICE_NAME}.service"
