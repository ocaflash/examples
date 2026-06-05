# Linguard Installation Script

## Overview

This installation script automates the deployment of the Linguard application on Ubuntu-based Linux servers.

The script performs the following tasks:

* Creates the application directory structure
* Installs required system packages
* Creates and configures a Python virtual environment
* Installs Python dependencies
* Creates a dedicated system user and group
* Configures application permissions
* Creates sudo rules required for WireGuard integration
* Installs and enables a systemd service
* Prepares the application for production use

## Requirements

* Ubuntu 22.04+ (recommended)
* Root privileges (`sudo`)
* Internet access for package installation
* Python 3

## Directory Structure

After installation, the application is deployed to:

```text
/var/www/linguard
├── linguard/
├── data/
├── requirements.txt
└── venv/
```

## Installation

Run the installer as root:

```bash
sudo ./install.sh
```

The script will:

1. Install required packages.
2. Create a Python virtual environment.
3. Install Python dependencies.
4. Create the `linguard` service account.
5. Configure required permissions.
6. Register the systemd service.

## Installed Dependencies

The installer automatically installs:

* python3
* python3-venv
* wireguard
* iptables
* uwsgi
* uwsgi-plugin-python3
* iproute2
* libpcre3
* libpcre3-dev

## Service Management

Start the service:

```bash
sudo systemctl start linguard
```

Stop the service:

```bash
sudo systemctl stop linguard
```

Restart the service:

```bash
sudo systemctl restart linguard
```

Check status:

```bash
sudo systemctl status linguard
```

View logs:

```bash
sudo journalctl -u linguard -f
```

## Configuration

Default configuration file:

```text
/var/www/linguard/data/uwsgi.yaml
```

Review and modify the configuration before starting the service in a production environment.

## Security Notes

The installer creates a dedicated system account:

```text
User:  linguard
Group: linguard
```

The following commands are granted through sudo without a password:

```text
/usr/bin/wg
/usr/bin/wg-quick
```

The sudo configuration is validated during installation using `visudo`.

## Reinstallation

If the target directory already exists:

```text
/var/www/linguard
```

the installer will ask for confirmation before removing the existing installation.

## Troubleshooting

Verify service status:

```bash
systemctl status linguard
```

Check logs:

```bash
journalctl -xeu linguard
```

Verify the virtual environment:

```bash
source /var/www/linguard/venv/bin/activate
pip list
```

Verify WireGuard installation:

```bash
wg --version
```

## License

See the project license file for licensing information.

