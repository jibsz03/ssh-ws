#!/bin/bash

USER_NAME="${SSH_USER:-j1btnl}"
USER_PASS="${SSH_PASSWORD:-j1btnl}"
WS_PORT="${PORT:-80}"

echo "[*] Menyiapkan Akun SSH..."
if ! id "$USER_NAME" &>/dev/null; then
    useradd -m -s /bin/bash "$USER_NAME"
    usermod -aG sudo "$USER_NAME"
fi
echo "$USER_NAME:$USER_PASS" | chpasswd

echo "[*] Membuat Python WebSocket Proxy (Optimized)..."
cat << 'EOF' > /usr/local/bin/ws-proxy.py
import socket, threading, sys

def forward(src, dst):
    try:
        while True:
            data = src.recv(8192)
            if not data: break
            dst.send(data)
    except:
        pass
    finally:
        src.close()
        dst.close()

def handle_client(client_socket):
    remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        remote_socket.connect(('127.0.0.1', 22))
        request = client_socket.recv(8192).decode('utf-8', errors='ignore')
        
        # Merespons 101 Switching Protocols untuk payload HTTP/WebSocket
        if 'HTTP' in request or 'Upgrade' in request:
            response = (
                "HTTP/1.1 101 Switching Protocols\r\n"
                "Upgrade: websocket\r\n"
                "Connection: Upgrade\r\n\r\n"
            )
            client_socket.send(response.encode('utf-8'))
        else:
            remote_socket.send(request.encode('utf-8'))
            
        threading.Thread(target=forward, args=(client_socket, remote_socket), daemon=True).start()
        threading.Thread(target=forward, args=(remote_socket, client_socket), daemon=True).start()
    except:
        client_socket.close()

if __name__ == '__main__':
    port = int(sys.argv[1])
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', port))
    server.listen(100)
    print(f"[*] Proxy WebSocket Listening di Port {port}...")
    
    while True:
        client, addr = server.accept()
        threading.Thread(target=handle_client, args=(client,), daemon=True).start()
EOF

echo "[*] Memulai Dropbear SSH Server di Port 22..."
# Opsi -R untuk membuat host key otomatis, -p 22 untuk port lokal
dropbear -R -p 127.0.0.1:22

echo "[*] Memulai WebSocket Proxy..."
exec python3 /usr/local/bin/ws-proxy.py $WS_PORT