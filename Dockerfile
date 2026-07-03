FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Menginstal OpenSSH Server, Python3, dan sudo
RUN apt-get update && apt-get install -y \
    openssh-server \
    python3 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Membuat direktori yang dibutuhkan oleh daemon SSH
RUN mkdir /var/run/sshd

# Menyalin skrip entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Mengekspos port 80 untuk lalu lintas WebSocket (Non-TLS)
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]