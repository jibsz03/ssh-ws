from flask import Flask, render_template, request
import subprocess

app = Flask(__name__)

@app.route('/')
def dashboard():
    # Mengambil output dari script listssh untuk ditampilkan di dashboard
    try:
        # Asumsi listssh bisa dijalankan langsung dan menghasilkan teks
        list_users = subprocess.check_output(['./listssh'], text=True)
    except Exception as e:
        list_users = "Gagal memuat daftar user: " + str(e)
        
    return render_template('index.html', list_users=list_users)

@app.route('/action', methods=['POST'])
def action():
    action_type = request.form.get('action')
    
    if action_type == 'add':
        # Logika untuk memanggil ./addssh
        # Perlu disesuaikan dengan parameter yang dibutuhkan script addssh kamu
        pass 
    elif action_type == 'delete':
        # Logika untuk memanggil ./delssh
        pass

    return "Aksi dieksekusi. <a href='/'>Kembali ke Dashboard</a>"

if __name__ == '__main__':
    # Berjalan di port 8080. Pastikan port ini dibuka di firewall VPS.
    app.run(host='0.0.0.0', port=8080)