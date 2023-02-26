# Evil-Webserver-Payload-and-Metasploit-Automator
Bash script that generates a payload using msfvenom, hosts it for download on the web server, opens up a corresponding listener in Metasploit, and logs website visitors to a separate file in a new terminal
This script generates a payload using msfvenom and hosts it for download on the web server, just like the previous version of the script. It also sets the lhost and lport variables to the IP address and port of the listener.

The script then sets up a Metasploit listener using a resource file. The listener is set to use the same payload type (windows/meterpreter/reverse_tcp) and IP address and port as the payload. The -j flag tells Metasploit to run the exploit in the background, allowing the script to continue running.

The script starts the Metasploit console with the resource file, which automatically sets up the listener. Metasploit will now be listening for incoming connections from the payload that was generated earlier.
