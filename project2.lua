import tkinter as tk
from tkinter import messagebox, simpledialog, Listbox, Scrollbar, END
import requests

# ==== KONFIGURASI LOGIN ====
USERNAME = "admin123"  # Jangan kasih tau ke orang
PASSWORD = "pass123"   # Jangan kasih tau ke orang

# ==== KONFIGURASI PASTEBIN ====
PASTEBIN_API_KEY = "1whRCEY7X8SQXRWnet8gvBlGbk5K4zzQ"
PASTEBIN_API_URL = "https://pastebin.com/api/api_post.php"

# Data Template Lokal
templates = {}

# Fungsi upload ke Pastebin
def save_to_pastebin(title, content):
    payload = {
        'api_dev_key': PASTEBIN_API_KEY,
        'api_option': 'paste',
        'api_paste_code': content,
        'api_paste_name': title,
        'api_paste_expire_date': 'N',
        'api_paste_private': '1'  # 1 = Unlisted
    }
    response = requests.post(PASTEBIN_API_URL, data=payload)
    if response.status_code == 200 and "pastebin.com" in response.text:
        return response.text
    else:
        return None

# Fungsi Login
def login():
    user = username_entry.get()
    pwd = password_entry.get()
    if user == USERNAME and pwd == PASSWORD:
        login_frame.pack_forget()
        main_menu()
    else:
        messagebox.showerror("Login Gagal", "Username atau password salah!")

# Fungsi Tambah Template
def add_template():
    name = simpledialog.askstring("Nama Template", "Masukkan nama template:")
    if not name:
        return
    content = simpledialog.askstring("Isi Template", "Masukkan isi template:")
    if content:
        templates[name] = content
        refresh_list()

# Fungsi Hapus Template
def delete_template():
    selected = template_list.curselection()
    if not selected:
        messagebox.showwarning("Pilih Template", "Pilih template yang ingin dihapus!")
        return
    name = template_list.get(selected[0])
    if messagebox.askyesno("Hapus Template", f"Yakin ingin hapus '{name}'?"):
        del templates[name]
        refresh_list()

# Fungsi Simpan Template ke Pastebin
def save_template():
    selected = template_list.curselection()
    if not selected:
        messagebox.showwarning("Pilih Template", "Pilih template yang ingin disimpan!")
        return
    name = template_list.get(selected[0])
    new_name = simpledialog.askstring("Nama Paste", "Masukkan nama paste di Pastebin:", initialvalue=name)
    if not new_name:
        return
    url = save_to_pastebin(new_name, templates[name])
    if url:
        messagebox.showinfo("Berhasil", f"Template disimpan di Pastebin:\n{url}")
    else:
        messagebox.showerror("Gagal", "Gagal menyimpan ke Pastebin!")

# Refresh daftar template
def refresh_list():
    template_list.delete(0, END)
    for t in templates:
        template_list.insert(END, t)

# Menu utama
def main_menu():
    main_frame.pack(fill="both", expand=True)

# ==== GUI ====
root = tk.Tk()
root.title("Template Manager - Pastebin")
root.geometry("400x350")

# Frame Login
login_frame = tk.Frame(root)
login_frame.pack(fill="both", expand=True)

tk.Label(login_frame, text="Username:").pack(pady=5)
username_entry = tk.Entry(login_frame)
username_entry.pack()

tk.Label(login_frame, text="Password:").pack(pady=5)
password_entry = tk.Entry(login_frame, show="*")
password_entry.pack()

tk.Button(login_frame, text="Login", command=login).pack(pady=10)

# Frame Menu Utama
main_frame = tk.Frame(root)

scrollbar = Scrollbar(main_frame)
scrollbar.pack(side="right", fill="y")

template_list = Listbox(main_frame, yscrollcommand=scrollbar.set)
template_list.pack(fill="both", expand=True)
scrollbar.config(command=template_list.yview)

btn_frame = tk.Frame(main_frame)
btn_frame.pack(pady=10)

tk.Button(btn_frame, text="Tambah Template", command=add_template).grid(row=0, column=0, padx=5)
tk.Button(btn_frame, text="Hapus Template", command=delete_template).grid(row=0, column=1, padx=5)
tk.Button(btn_frame, text="Simpan ke Pastebin", command=save_template).grid(row=0, column=2, padx=5)

root.mainloop()
