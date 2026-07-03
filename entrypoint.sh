#!/bin/bash

# Mengambil environment variables atau menggunakan nilai default
USER_NAME="${SSH_USER:-j1btnl}"
USER_PASS="${SSH_PASSWORD:-j1btnl}"
WS_PORT="${PORT:-80}"

echo "[*] Mengonfigurasi Server Message (Banner Pra-Login)..."
cat << 'EOF' > /etc/issue.net
<p align="center">
<font color="#00FFFF"><b>✦ WELCOME TO JIBSZZ SERVER (WEBSOCKET) ✦</b></font><br>
<font color="#FF00A0">❖═════════════════════════════════❖</font><br>
<font color="#00FF00"><b>ℹ️ SERVER NOTICES ℹ️</b></font><br>
<font color="#FFFFFF">Proxy: WebSocket / HTTP Upgrade</font><br>
<font color="#FF00A0">❖═════════════════════════════════❖</font>
</p>
EOF

echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
sed -i 's/PrintMotd no/PrintMotd yes/g' /etc/ssh/sshd_config
rm -f /etc/update-motd.d/*
cp /etc/issue.net /etc/motd

echo "[*] Mengonfigurasi Respon Server (Pasca-Login)..."
cat << 'EOF' > /etc/profile.d/99-respon-server.sh
#!/bin/bash
clear
echo -e "\e[1;36m=================================================\e[0m"
echo -e "\e[1;32m       [✓] BERHASIL TERHUBUNG KE SERVER WS!      \e[0m"
echo -e "\e[1;36m=================================================\e[0m"
echo -e "\e[1;37m Username     : \e[1;33m$USER\e[0m"
echo -e "\e[1;37m Mode         : \e[1;33mSSH over WebSocket (Port 80)\e[0m"
echo -e "\e[1;36m=================================================\e[0m"
EOF
chmod +x /etc/profile.d/99-respon-server.sh

echo "[*] Mengonfigurasi User SSH..."
if ! id "$USER_NAME" &>/dev/null; then
    useradd -m -s /bin/bash "$USER_NAME"
    usermod -aG sudo "$USER_NAME"
fi
echo "$USER_NAME:$USER_PASS" | chpasswd

echo "[*] Membuat Python WebSocket Proxy Script..."
cat << 'EOF' > /usr/local/bin/ws-proxy.py
import socket
import threading
import sys

def forward(src, dst):
    try:
        while True:
            data = src.recv(4096)
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
        
        # Membaca request HTTP dari klien untuk proses handshake
        request = client_socket.recv(4096).decode('utf-8', errors='ignore')
        
        # Merespons dengan HTTP 101 jika ada indikasi HTTP/WebSocket payload
        if 'HTTP/1.1' in request or 'Upgrade: websocket' in request:
            response = (
                "HTTP/1.1 101 Switching Protocols\r\n"
                "Upgrade: websocket\r\n"
                "Connection: Upgrade\r\n\r\n"
            )
            client_socket.send(response.encode('utf-8'))
        else:
            # Jika tidak ada payload HTTP, asumsikan raw TCP dan langsung kirim datanya
            remote_socket.send(request.encode('utf-8'))
        
        # Memulai bridging dua arah
        threading.Thread(target=forward, args=(client_socket, remote_socket)).start()
        threading.Thread(target=forward, args=(remote_socket, client_socket)).start()
    except Exception as e:
        client_socket.close()

port = int(sys.argv[1])
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('0.0.0.0', port))
server.listen(100)
print(f"[*] WebSocket Proxy berjalan di port {port}...")

while True:
    client, addr = server.accept()
    threading.Thread(target=handle_client, args=(client,)).start()
EOF

echo "[*] Memulai OpenSSH Server di Port 22 (Latar Belakang)..."
/usr/sbin/sshd

echo "[*] Memulai WebSocket Proxy (Foreground)..."
exec python3 /usr/local/bin/ws-proxy.py $WS_PORT