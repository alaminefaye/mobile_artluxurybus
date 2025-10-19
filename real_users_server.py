#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import urllib.parse

# Base de données des vrais utilisateurs (simulée)
REAL_USERS = {
    "admin@admin.com": {
        "password": "passer123",
        "user": {
            "id": 1,
            "name": "Administrator",
            "email": "admin@admin.com",
            "profile_photo": None,
            "cities": ["Dakar", "Thiès", "Saint-Louis", "Kaolack"],
            "display_name": "Administrateur",
            "display_role": "Administrateur Système",
            "roles": ["admin", "super_admin"],
            "permissions": ["manage_users", "manage_buses", "manage_tickets", "view_reports", "manage_settings"]
        }
    },
    "manager@artluxurybus.com": {
        "password": "manager123",
        "user": {
            "id": 2,
            "name": "Manager Transport",
            "email": "manager@artluxurybus.com",
            "profile_photo": None,
            "cities": ["Dakar", "Thiès"],
            "display_name": "Manager Transport",
            "display_role": "Responsable Transport",
            "roles": ["manager"],
            "permissions": ["manage_buses", "manage_tickets", "view_reports"]
        }
    },
    "chauffeur@artluxurybus.com": {
        "password": "chauffeur123",
        "user": {
            "id": 3,
            "name": "Mamadou Diop",
            "email": "chauffeur@artluxurybus.com",
            "profile_photo": None,
            "cities": ["Dakar"],
            "display_name": "Mamadou Diop",
            "display_role": "Chauffeur",
            "roles": ["driver"],
            "permissions": ["view_schedule", "update_status"]
        }
    },
    "agent@artluxurybus.com": {
        "password": "agent123",
        "user": {
            "id": 4,
            "name": "Fatou Sall",
            "email": "agent@artluxurybus.com",
            "profile_photo": None,
            "cities": ["Thiès"],
            "display_name": "Fatou Sall",
            "display_role": "Agent de Vente",
            "roles": ["agent"],
            "permissions": ["sell_tickets", "view_passengers"]
        }
    }
}

class RealUsersAPIHandler(BaseHTTPRequestHandler):
    def _set_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Accept, Authorization')
    
    def do_OPTIONS(self):
        self.send_response(200)
        self._set_cors_headers()
        self.end_headers()
    
    def do_GET(self):
        if self.path == '/api/ping':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self._set_cors_headers()
            self.end_headers()
            response = {
                "message": "Art Luxury Bus API - Real Users",
                "version": "1.0",
                "users_count": len(REAL_USERS)
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        if self.path == '/api/auth/login':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode('utf-8'))
                email = data.get('email', '').lower().strip()
                password = data.get('password', '')
                
                print(f"🔐 Tentative de connexion: {email}")
                
                # Vérifier les identifiants
                if email in REAL_USERS and REAL_USERS[email]['password'] == password:
                    # Connexion réussie
                    user_data = REAL_USERS[email]['user']
                    token = f"real-token-{user_data['id']}-{hash(email) % 10000}"
                    
                    response = {
                        "success": True,
                        "message": f"Connexion réussie! Bienvenue {user_data['display_name']}",
                        "data": {
                            "user": user_data,
                            "token": token,
                            "token_type": "Bearer"
                        }
                    }
                    
                    print(f"✅ Connexion réussie: {user_data['display_name']} ({user_data['display_role']})")
                    self.send_response(200)
                else:
                    # Échec de la connexion
                    response = {
                        "success": False,
                        "message": "Identifiants incorrects",
                        "errors": {
                            "email": ["Ces identifiants ne correspondent pas à nos enregistrements."]
                        }
                    }
                    
                    print(f"❌ Échec de connexion pour: {email}")
                    self.send_response(401)
                
                self.send_header('Content-type', 'application/json')
                self._set_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps(response, ensure_ascii=False).encode('utf-8'))
                
            except Exception as e:
                print(f"🚨 Erreur: {e}")
                self.send_response(400)
                self.send_header('Content-type', 'application/json')
                self._set_cors_headers()
                self.end_headers()
                error_response = {
                    "success": False,
                    "message": "Erreur de traitement de la requête",
                    "errors": {"server": [str(e)]}
                }
                self.wfile.write(json.dumps(error_response).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        # Supprime les logs automatiques pour garder la console propre
        pass

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8001), RealUsersAPIHandler)
    print("🚀 Art Luxury Bus - Serveur avec vrais utilisateurs")
    print("📡 Serveur démarré sur http://0.0.0.0:8001")
    print("📱 Pour émulateur Android: http://10.0.2.2:8001")
    print()
    print("👥 UTILISATEURS DE TEST:")
    print("=" * 50)
    for email, user_info in REAL_USERS.items():
        user = user_info['user']
        print(f"📧 Email: {email}")
        print(f"🔑 Password: {user_info['password']}")
        print(f"👤 Nom: {user['display_name']}")
        print(f"💼 Rôle: {user['display_role']}")
        print(f"🏙️  Villes: {', '.join(user['cities'])}")
        print("-" * 30)
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Serveur arrêté")
        server.server_close()
