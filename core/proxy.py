import socket
import threading
import subprocess
import os

# Función mejorada para leer toda la información del usuario en Linux
def get_user_data(username):
    data = {"exp": "Ilimitado", "dias": "Ilimitado", "limite": "Desconocido"}
    try:
        # Buscar expiración en el sistema
        chage_out = subprocess.check_output(f"chage -l {username}", shell=True, stderr=subprocess.STDOUT).decode('utf-8')
        for line in chage_out.split('\n'):
            if "Account expires" in line or "La cuenta caduca" in line:
                date_str = line.split(':')[1].strip()
                if date_str != "never":
                    data["exp"] = date_str
                    # Calcular días restantes
                    try:
                        dias_restantes = subprocess.check_output(f"echo $(( ($(date -d '{date_str}' +%s) - $(date +%s)) / 86400 ))", shell=True, stderr=subprocess.STDOUT).decode().strip()
                        data["dias"] = dias_restantes
                    except:
                        data["dias"] = "?"
    except:
        data["exp"] = "No encontrado"
        
    # Buscar límite de IPs (Asumiendo ruta de panel estándar, ajusta si es diferente)
    try:
        if os.path.exists(f"/root/usuarios/{username}.limit"):
            with open(f"/root/usuarios/{username}.limit", "r") as f:
                data["limite"] = f.read().strip()
    except:
        pass
        
    return data

def handle_client(client_socket):
    try:
        raw_request = client_socket.recv(4096)
        if not raw_request:
            client_socket.close()
            return

        request_text = raw_request.decode('utf-8', errors='ignore')
        request_lower = request_text.lower()

        # Buscar el usuario oculto en el Payload
        ssh_user = None
        for line in request_text.split('\r\n'):
            if line.lower().startswith('x-user:') or line.lower().startswith('ssh-user:'):
                ssh_user = line.split(':')[1].strip()
                break

        # Conectar al daemon SSH local (INTACTO)
        ssh_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh_socket.connect(('127.0.0.1', 22))

        # =======================================================
        # LÓGICA DUAL: Toma de decisión según el tipo de Payload
        # =======================================================
        
        if "upgrade: websocket" in request_lower:
            response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
            
            # --- NUEVO MOTOR INYECTOR DE BANNER ---
            try:
                if os.path.exists("/etc/issue.net"):
                    with open("/etc/issue.net", "r", encoding="utf-8", errors="ignore") as f:
                        banner_text = f.read()
                    
                    # Si detectamos al usuario en el payload, reemplazamos sus variables reales
                    if ssh_user:
                        u_data = get_user_data(ssh_user)
                        banner_text = banner_text.replace("%USER%", ssh_user)
                        banner_text = banner_text.replace("%EXP%", u_data["exp"])
                        banner_text = banner_text.replace("%DIAS%", u_data["dias"])
                        banner_text = banner_text.replace("%LIMITE%", u_data["limite"])
                        banner_text = banner_text.replace("%CONSUMO%", "Monitor Activo") # Requiere vnstat
                    
                    response += banner_text + "\r\n"
            except:
                pass
            # --------------------------------------
        else:
            # 2. RESPUESTA DIRECTA CUSTOM (Engaño ISP / Bug Host) (INTACTO)
            response = "HTTP/2.0 1299\r\nHost: survey.tigo.com\nContent-Length: 55555555\n\r\n"

        # Enviar la respuesta decidida al cliente (HTTP Injector) (INTACTO)
        client_socket.sendall(response.encode('utf-8'))

        # Función de túnel bidireccional (INTACTA)
        def transfer(src, dst):
            try:
                while True:
                    data = src.recv(8192)
                    if not data: break
                    dst.sendall(data)
            except:
                pass
            finally:
                try: src.close()
                except: pass
                try: dst.close()
                except: pass

        t1 = threading.Thread(target=transfer, args=(client_socket, ssh_socket))
        t2 = threading.Thread(target=transfer, args=(ssh_socket, client_socket))
        t1.daemon = True
        t2.daemon = True
        t1.start()
        t2.start()
    except:
        try: client_socket.close()
        except: pass

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    server.bind(('0.0.0.0', 8080))
    server.listen(500) 
    print("Proxy Dual (WS + Direct Custom) iniciado en puerto 8080...")
    
    while True:
        try:
            client, addr = server.accept()
            t = threading.Thread(target=handle_client, args=(client,))
            t.daemon = True
            t.start()
        except:
            continue

if __name__ == '__main__':
    main()
                        
