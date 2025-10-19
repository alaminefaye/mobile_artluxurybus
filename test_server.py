#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import urllib.parse

class TestAPIHandler(BaseHTTPRequestHandler):
    def _set_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Accept')
    
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
            response = {"message": "Test server is running!"}
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
                email = data.get('email', '')
                password = data.get('password', '')
                
                print(f"Login attempt: {email} / {password}")
                
                if email and password:
                    # Success response
                    response = {
                        "success": True,
                        "message": "Login successful",
                        "data": {
                            "user": {
                                "id": 1,
                                "name": "Test User",
                                "email": email,
                                "profile_photo": None,
                                "cities": ["Dakar", "Thiès"],
                                "display_name": "Test User",
                                "display_role": "Admin",
                                "roles": ["admin"],
                                "permissions": ["manage_users", "manage_buses"]
                            },
                            "token": "test-token-123456789",
                            "token_type": "Bearer"
                        }
                    }
                    self.send_response(200)
                else:
                    # Error response
                    response = {
                        "success": False,
                        "message": "Invalid credentials",
                        "errors": {
                            "email": ["The email field is required."],
                            "password": ["The password field is required."]
                        }
                    }
                    self.send_response(401)
                
                self.send_header('Content-type', 'application/json')
                self._set_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps(response).encode())
                
            except Exception as e:
                print(f"Error: {e}")
                self.send_response(400)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8001), TestAPIHandler)
    print("🚀 Test server running at http://0.0.0.0:8001")
    print("📱 For Android emulator: http://10.0.2.2:8001")
    print("📧 Test login: any email/password combo works")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped")
        server.server_close()
