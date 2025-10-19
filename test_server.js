const express = require('express');
const cors = require('cors');
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Test ping endpoint
app.get('/api/ping', (req, res) => {
  res.json({ message: 'Server is running!' });
});

// Test login endpoint
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  
  console.log('Login attempt:', { email, password });
  
  // Simulate authentication
  if (email && password) {
    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: 1,
          name: 'Test User',
          email: email,
          profile_photo: null,
          cities: ['Dakar', 'Thiès'],
          display_name: 'Test User',
          display_role: 'Admin',
          roles: ['admin'],
          permissions: ['manage_users', 'manage_buses']
        },
        token: 'test-token-123456789',
        token_type: 'Bearer'
      }
    });
  } else {
    res.status(401).json({
      success: false,
      message: 'Invalid credentials',
      errors: {
        email: ['The email field is required.'],
        password: ['The password field is required.']
      }
    });
  }
});

// Start server
const PORT = 8001;
app.listen(PORT, '127.0.0.1', () => {
  console.log(`🚀 Test server running at http://127.0.0.1:${PORT}`);
  console.log('📧 Test login: any email/password combo works');
});
