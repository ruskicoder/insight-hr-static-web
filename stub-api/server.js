import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';

const app = express();
const PORT = 4000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// In-memory user store
const users = [
  {
    userId: 'admin-1',
    email: 'admin@insighthr.com',
    password: 'Admin1234',
    name: 'Admin User',
    role: 'Admin',
    employeeId: 'EMP001',
    department: 'IT',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    userId: 'manager-1',
    email: 'manager@insighthr.com',
    password: 'Manager1234',
    name: 'Manager User',
    role: 'Manager',
    employeeId: 'EMP002',
    department: 'Sales',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    userId: 'employee-1',
    email: 'employee@insighthr.com',
    password: 'Employee1234',
    name: 'Employee User',
    role: 'Employee',
    employeeId: 'EMP003',
    department: 'Engineering',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
];

// Helper function to generate mock JWT token
const generateMockToken = (userId) => {
  return `mock-jwt-token-${userId}-${Date.now()}`;
};

// Helper function to find user by email
const findUserByEmail = (email) => {
  return users.find((u) => u.email === email);
};

// Helper function to create user response (without password)
const createUserResponse = (user) => {
  const { password, ...userWithoutPassword } = user;
  return userWithoutPassword;
};

// ============================================
// Authentication Endpoints
// ============================================

// POST /auth/login
app.post('/auth/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Email and password are required',
    });
  }

  const user = findUserByEmail(email);

  if (!user || user.password !== password) {
    return res.status(401).json({
      success: false,
      message: 'Invalid email or password',
    });
  }

  const tokens = {
    accessToken: generateMockToken(user.userId),
    refreshToken: generateMockToken(user.userId),
    idToken: generateMockToken(user.userId),
    expiresIn: 3600,
  };

  res.json({
    success: true,
    message: 'Login successful',
    data: {
      user: createUserResponse(user),
      tokens,
    },
  });
});

// POST /auth/register
app.post('/auth/register', (req, res) => {
  const { email, password, name } = req.body;

  if (!email || !password || !name) {
    return res.status(400).json({
      success: false,
      message: 'Email, password, and name are required',
    });
  }

  // Check if user already exists
  if (findUserByEmail(email)) {
    return res.status(409).json({
      success: false,
      message: 'User with this email already exists',
    });
  }

  // Create new user
  const newUser = {
    userId: `user-${Date.now()}`,
    email,
    password,
    name,
    role: 'Employee',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  users.push(newUser);

  const tokens = {
    accessToken: generateMockToken(newUser.userId),
    refreshToken: generateMockToken(newUser.userId),
    idToken: generateMockToken(newUser.userId),
    expiresIn: 3600,
  };

  res.status(201).json({
    success: true,
    message: 'Registration successful',
    data: {
      user: createUserResponse(newUser),
      tokens,
    },
  });
});

// POST /auth/google
app.post('/auth/google', (req, res) => {
  const { googleToken } = req.body;

  if (!googleToken) {
    return res.status(400).json({
      success: false,
      message: 'Google token is required',
    });
  }

  // Mock Google OAuth user
  const googleUser = {
    userId: 'google-user-1',
    email: 'google.user@example.com',
    name: 'Google User',
    role: 'Employee',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  const tokens = {
    accessToken: generateMockToken(googleUser.userId),
    refreshToken: generateMockToken(googleUser.userId),
    idToken: generateMockToken(googleUser.userId),
    expiresIn: 3600,
  };

  res.json({
    success: true,
    message: 'Google authentication successful',
    data: {
      user: googleUser,
      tokens,
    },
  });
});

// POST /auth/refresh
app.post('/auth/refresh', (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(400).json({
      success: false,
      message: 'Refresh token is required',
    });
  }

  const tokens = {
    accessToken: generateMockToken('refreshed'),
    refreshToken: generateMockToken('refreshed'),
    idToken: generateMockToken('refreshed'),
    expiresIn: 3600,
  };

  res.json({
    success: true,
    message: 'Token refreshed successfully',
    data: { tokens },
  });
});

// POST /auth/forgot-password
app.post('/auth/forgot-password', (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({
      success: false,
      message: 'Email is required',
    });
  }

  const user = findUserByEmail(email);

  if (!user) {
    // Don't reveal if user exists for security
    return res.json({
      success: true,
      message: 'If the email exists, a password reset link has been sent',
      data: { message: 'Password reset email sent' },
    });
  }

  res.json({
    success: true,
    message: 'Password reset email sent',
    data: { message: 'Password reset email sent' },
  });
});

// POST /auth/reset-password
app.post('/auth/reset-password', (req, res) => {
  const { email, code, newPassword } = req.body;

  if (!email || !code || !newPassword) {
    return res.status(400).json({
      success: false,
      message: 'Email, code, and new password are required',
    });
  }

  const user = findUserByEmail(email);

  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found',
    });
  }

  // Mock password reset (in real app, verify code)
  user.password = newPassword;
  user.updatedAt = new Date().toISOString();

  res.json({
    success: true,
    message: 'Password reset successful',
    data: { message: 'Password reset successful' },
  });
});

// ============================================
// User Endpoints
// ============================================

// GET /users/me
app.get('/users/me', (req, res) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
    });
  }

  // Mock: Return first admin user
  const user = users[0];

  res.json({
    success: true,
    data: createUserResponse(user),
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Stub API is running' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Stub API server running on http://localhost:${PORT}`);
  console.log(`📝 Demo users:`);
  console.log(`   Admin: admin@insighthr.com / Admin1234`);
  console.log(`   Manager: manager@insighthr.com / Manager1234`);
  console.log(`   Employee: employee@insighthr.com / Employee1234`);
});
