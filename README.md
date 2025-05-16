# pfSense Backup Script

This repository contains a Bash script to automate the backup of a pfSense firewall configuration via HTTPS. The script logs in to the pfSense web interface, retrieves the configuration file, and saves it locally. It supports various options such as RRD data backup, SSH key backup, encrypted backups, and more.

---

## ⚠️ Disclaimer

- **This script is provided for educational and demonstration purposes only.**
- **Use at your own risk.**
- Always review and understand scripts before running them on production systems.
- Ensure you comply with your organization's security policies and pfSense's best practices.
- The maintainers of this repository are not responsible for any loss, damage, or security issues caused by the use of this script.

---

## Features

- Backs up pfSense configuration via HTTPS.
- Supports encrypted backups.
- Optionally includes RRD data, SSH keys, package information, and extra data.
- Allows for custom backup directory and connection port.
- Handles self-signed certificates (optional).
- Verbose mode for debugging.

---

## Requirements

- Bash shell (Linux or macOS)
- `curl` utility
- Access to a pfSense host with backup privileges

---

## Usage

```
./pfsense-backup.sh --host  --user  --password  [OPTIONS]
```

### **Mandatory Arguments**
- `--host `: pfSense target hostname or IP address
- `--user `: pfSense username with backup privileges
- `--password `: Password for the specified user

### **Options**
- `--directory `: Directory to store backups (default: ./conf_backup)
- `--port `: HTTPS port for pfSense (default: 443)
- `--verbose`: Enable verbose output
- `--rrd`: Include RRD data in the backup
- `--ssh`: Include SSH keys in the backup
- `--insecure`: Ignore SSL certificate validation (for self-signed certs)
- `--skip-packages`: Do not include package information in the backup
- `--extra-data`: Include extra data in the backup
- `--backup-password `: Encrypt the backup with the specified password

### **Example**

```
./pfsense-backup.sh \
  --host 192.168.1.1 \
  --user backupuser \
  --password mySecretPassword \
  --directory /backups/pfsense \
  --rrd --ssh --backup-password myBackupPass --verbose
```

---

## Security Considerations

- **Credentials** are passed via command line arguments. Use caution to avoid exposing sensitive information (e.g., in shell history or process lists).
- **Backups may contain sensitive configuration data** (including passwords and keys). Store and handle backup files securely.
- If using `--insecure`, SSL certificate validation is disabled, which may expose you to man-in-the-middle attacks. Use only when necessary and in trusted environments.
- For best security, use the `--backup-password` option to encrypt your backup files.

---

## Troubleshooting

- Ensure the pfSense user has sufficient privileges to perform backups.
- If you encounter SSL errors, try using the `--insecure` flag.
- For debugging, use the `--verbose` flag to see detailed output.

---

## License

This script is released under the MIT License. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- Inspired by the pfSense documentation and community scripts.
- Contributions and improvements are welcome!
