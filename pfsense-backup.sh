#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 --host <host> --user <user> --password <password> [OPTIONS]"
    echo "Options:"
    echo "  --directory <dir>       Backup directory (optional)"
    echo "  --host <host>           pfSense target (mandatory)"
    echo "  --user <user>           pfSense backup user (mandatory)"
    echo "  --password <pass>       pfSense backup user password (mandatory)"
    echo "  --verbose               Enable verbose output"
    echo "  --rrd                   Backup RRD data"
    echo "  --ssh                   Backup SSH keys"
    echo "  --port <port>           Specify host port connection (default: 443)"
    echo "  --insecure              Ignore unsigned SSL certificates"
    echo "  --skip-packages         Do not backup package information"
    echo "  --extra-data            Backup extra data"
    echo "  --backup-password <pw>  Encrypt the backup using the specified password"
    exit 1
}

# Default values
PFSENSE_HOST=""
PFSENSE_USER=""
PFSENSE_PASS=""
BACKUP_DIR="$(pwd)/conf_backup"
VERBOSE=0
BACKUP_RRD=0
BACKUP_SSH=0
PORT=443
INSECURE=0
SKIP_PACKAGES=0
EXTRA_DATA=0
BACKUP_PASSWORD=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --directory) BACKUP_DIR="$2"; shift 2 ;;
        --host) PFSENSE_HOST="$2"; shift 2 ;;
        --user) PFSENSE_USER="$2"; shift 2 ;;
        --password) PFSENSE_PASS="$2"; shift 2 ;;
        --verbose) VERBOSE=1; shift ;;
        --rrd) BACKUP_RRD=1; shift ;;
        --ssh) BACKUP_SSH=1; shift ;;
        --port) PORT="$2"; shift 2 ;;
        --insecure) INSECURE=1; shift ;;
        --skip-packages) SKIP_PACKAGES=1; shift ;;
        --extra-data) EXTRA_DATA=1; shift ;;
        --backup-password) BACKUP_PASSWORD="$2"; shift 2 ;;
        *) usage ;;
    esac
done

# Check mandatory arguments
if [[ -z "$PFSENSE_HOST" || -z "$PFSENSE_USER" || -z "$PFSENSE_PASS" ]]; then
    usage
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d%H%M%S)

# Set up temporary files
COOKIE_FILE=$(mktemp /tmp/pfsbck.XXXXXXXX)
CSRF1_TOKEN=$(mktemp /tmp/csrf1.XXXXXXXX)
CSRF2_TOKEN=$(mktemp /tmp/csrf2.XXXXXXXX)

# Set up backup options
BACKUP_OPTS="download=download"
[[ $BACKUP_RRD -eq 0 ]] && BACKUP_OPTS+="&donotbackuprrd=yes"
[[ $BACKUP_SSH -eq 1 ]] && BACKUP_OPTS+="&backupssh=yes"
[[ $SKIP_PACKAGES -eq 1 ]] && BACKUP_OPTS+="&nopackages=yes"
[[ $EXTRA_DATA -eq 1 ]] && BACKUP_OPTS+="&backupdata=yes"
[[ -n "$BACKUP_PASSWORD" ]] && BACKUP_OPTS+="&encrypt=yes&encrypt_password=${BACKUP_PASSWORD}&encrypt_password_confirm=${BACKUP_PASSWORD}"

# Set up curl options
CURL_OPTS="-Ss"
[[ $INSECURE -eq 1 ]] && CURL_OPTS+=" --insecure"

# Verbose output function
log() {
    [[ $VERBOSE -eq 1 ]] && echo "$@"
}

# Fetch initial CSRF token
log "Fetching initial CSRF token..."
curl $CURL_OPTS --cookie-jar "$COOKIE_FILE" "https://${PFSENSE_HOST}:${PORT}/diag_backup.php" | 
    grep "name='__csrf_magic'" | sed 's/.*value="\(.*\)".*/\1/' > "$CSRF1_TOKEN"

# Submit login and get new CSRF token
log "Logging in and fetching new CSRF token..."
curl $CURL_OPTS --location --cookie-jar "$COOKIE_FILE" --cookie "$COOKIE_FILE" \
    --data "login=Login&usernamefld=${PFSENSE_USER}&passwordfld=${PFSENSE_PASS}&__csrf_magic=$(cat "$CSRF1_TOKEN")" \
    "https://${PFSENSE_HOST}:${PORT}/diag_backup.php" | 
    grep "name='__csrf_magic'" | sed 's/.*value="\(.*\)".*/\1/' > "$CSRF2_TOKEN"

# Download configuration
log "Downloading configuration..."
BACKUP_FILE="${BACKUP_DIR}/backup-${TIMESTAMP}.xml"
curl $CURL_OPTS --cookie-jar "$COOKIE_FILE" --cookie "$COOKIE_FILE" \
    --data "${BACKUP_OPTS}&__csrf_magic=$(head -n 1 "$CSRF2_TOKEN")" \
    "https://${PFSENSE_HOST}:${PORT}/diag_backup.php" > "$BACKUP_FILE"

# Check if backup was successful
if [[ -s "$BACKUP_FILE" ]]; then
    echo "Backup successful: $BACKUP_FILE"
else
    echo "Backup failed!"
    rm -f "$BACKUP_FILE"
fi

# Clean up temporary files
rm -f "$COOKIE_FILE" "$CSRF1_TOKEN" "$CSRF2_TOKEN"

exit 0
