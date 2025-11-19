import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';

const app = express();
const PORT = 4000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.text({ type: 'text/csv' }));

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
    status: 'active',
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
    status: 'active',
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
    status: 'active',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    userId: 'employee-2',
    email: 'john.doe@insighthr.com',
    password: 'Employee1234',
    name: 'John Doe',
    role: 'Employee',
    employeeId: 'EMP004',
    department: 'Engineering',
    status: 'active',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    userId: 'employee-3',
    email: 'jane.smith@insighthr.com',
    password: 'Employee1234',
    name: 'Jane Smith',
    role: 'Employee',
    employeeId: 'EMP005',
    department: 'Sales',
    status: 'active',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    userId: 'employee-4',
    email: 'bob.wilson@insighthr.com',
    password: 'Employee1234',
    name: 'Bob Wilson',
    role: 'Employee',
    employeeId: 'EMP006',
    department: 'IT',
    status: 'disabled',
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

// Helper function to extract user from token
const getUserFromToken = (authHeader) => {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  
  // Mock: Extract userId from token (format: mock-jwt-token-{userId}-{timestamp})
  const token = authHeader.replace('Bearer ', '');
  const parts = token.split('-');
  
  if (parts.length >= 4) {
    // Reconstruct userId (could be "admin-1", "employee-1", etc.)
    const userIdParts = [];
    for (let i = 3; i < parts.length - 1; i++) {
      userIdParts.push(parts[i]);
    }
    const userId = userIdParts.join('-');
    return users.find(u => u.userId === userId);
  }
  
  return null;
};

// Helper function to check if user is admin
const isAdmin = (user) => {
  return user && user.role === 'Admin';
};

// Helper function to find user by ID
const findUserById = (userId) => {
  return users.find(u => u.userId === userId);
};

// Helper function to parse CSV data
const parseCSV = (csvData) => {
  const lines = csvData.trim().split('\n');
  if (lines.length < 2) {
    throw new Error('CSV must have header and at least one data row');
  }
  
  const headers = lines[0].split(',').map(h => h.trim());
  const rows = [];
  
  for (let i = 1; i < lines.length; i++) {
    const values = lines[i].split(',').map(v => v.trim());
    const row = {};
    headers.forEach((header, index) => {
      row[header] = values[index] || '';
    });
    rows.push(row);
  }
  
  return rows;
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
    status: 'active',
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

// PUT /users/me
app.put('/users/me', (req, res) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
    });
  }

  const { name, department } = req.body;

  // Get current user from token
  const currentUser = getUserFromToken(authHeader);
  
  if (!currentUser) {
    return res.status(401).json({
      success: false,
      message: 'Invalid token',
    });
  }

  if (name !== undefined) {
    currentUser.name = name;
  }

  if (department !== undefined) {
    currentUser.department = department;
  }

  currentUser.updatedAt = new Date().toISOString();

  res.json({
    success: true,
    message: 'Profile updated successfully',
    data: createUserResponse(currentUser),
  });
});

// GET /users (Admin only)
app.get('/users', (req, res) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
    });
  }

  const currentUser = getUserFromToken(authHeader);
  
  if (!isAdmin(currentUser)) {
    return res.status(403).json({
      success: false,
      message: 'Forbidden: Admin access required',
    });
  }

  // Apply filters
  const { search, department, role, status } = req.query;
  let filteredUsers = [...users];

  if (search) {
    const searchLower = search.toLowerCase();
    filteredUsers = filteredUsers.filter(u => 
      u.name.toLowerCase().includes(searchLower) || 
      u.email.toLowerCase().includes(searchLower)
    );
  }

  if (department) {
    filteredUsers = filteredUsers.filter(u => u.department === department);
  }

  if (role) {
    filteredUsers = filteredUsers.filter(u => u.role === role);
  }

  if (status) {
    filteredUsers = filteredUsers.filter(u => u.status === status);
  }

  res.json({
    success: true,
    data: filteredUsers.map(createUserResponse),
  });
});

// POST /users (Admin only)
app.post('/users', (req, res) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
    });
  }

  const currentUser = getUserFromToken(authHeader);
  
  if (!isAdmin(currentUser)) {
    return res.status(403).json({
      success: false,
      message: 'Forbidden: Admin access required',
    });
  }

  const { email, name, role, department, employeeId } = req.body;

  if (!email || !name || !role) {
    return res.status(400).json({
      success: false,
      message: 'Email, name, and role are required',
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
    password: 'DefaultPassword123', // Default password
    name,
    role,
    employeeId: employeeId || `EMP${Date.now()}`,
    department: department || '',
    status: 'active',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  users.push(newUser);

  res.status(201).json({
    success: true,
    message: 'User created successfully',
    data: createUserResponse(newUser),
  });
});

// PUT /users/:userId (Admin only)
app.put('/users/:userId', (req, res) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
    });
  }

  const currentUser = getUserFromToken(authHeader);
  
  if (!isAdmin(currentUser)) {
    return res.status(403).json({
      success: false,
      message: 'Forbidden: Admin access required',
    });
  }

  const { userId } = req.params;
  const { name, role, department, employeeId } = req.body;

  const user = findUserById(userId);

  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found',
    });
  }

  // Update user fields
  if (name !== undefined) {
    user.name = name;
  }

  if (role !== undefined) {
    user.role = role;
  }

  if (department !== undefined) {
    user.department = department;
  }

  if (employeeId !== undefined) {
    user.employeeId = employeeId;
  }

  user.updatedAt = new Date().toISOString();

  res.json({
    success: true,
    message: 'User updated successfully',
    data: createUserResponse(user),
  });
});

// PUT /users/:userId/disable (Admin only)
app.put('/users/:userId/disable', (req, res) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
    });
  }

  const currentUser = getUserFromToken(authHeader);
  
  if (!isAdmin(currentUser)) {
    return res.status(403).json({
      success: false,
      message: 'Forbidden: Admin access required',
    });
  }

  const { userId } = req.params;
  const user = findUserById(userId);

  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found',
    });
  }

  user.status = 'disabled';
  user.updatedAt = new Date().toISOString();

  res.json({
    success: true,
    message: 'User disabled successfully',
    data: createUserResponse(user),
  });
});

// PUT /users/:userId/enable (Admin only)
app.put('/users/:userId/enable', (req, res) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
    });
  }

  const currentUser = getUserFromToken(authHeader);
  
  if (!isAdmin(currentUser)) {
    return res.status(403).json({
      success: false,
      message: 'Forbidden: Admin access required',
    });
  }

  const { userId } = req.params;
  const user = findUserById(userId);

  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found',
    });
  }

  user.status = 'active';
  user.updatedAt = new Date().toISOString();

  res.json({
    success: true,
    message: 'User enabled successfully',
    data: createUserResponse(user),
  });
});

// DELETE /users/:userId (Admin only)
app.delete('/users/:userId', (req, res) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
    });
  }

  const currentUser = getUserFromToken(authHeader);
  
  if (!isAdmin(currentUser)) {
    return res.status(403).json({
      success: false,
      message: 'Forbidden: Admin access required',
    });
  }

  const { userId } = req.params;
  const userIndex = users.findIndex(u => u.userId === userId);

  if (userIndex === -1) {
    return res.status(404).json({
      success: false,
      message: 'User not found',
    });
  }

  // Prevent deleting yourself
  if (userId === currentUser.userId) {
    return res.status(400).json({
      success: false,
      message: 'Cannot delete your own account',
    });
  }

  users.splice(userIndex, 1);

  res.json({
    success: true,
    message: 'User deleted successfully',
    data: { userId },
  });
});

// POST /users/bulk (Admin only)
app.post('/users/bulk', (req, res) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
    });
  }

  const currentUser = getUserFromToken(authHeader);
  
  if (!isAdmin(currentUser)) {
    return res.status(403).json({
      success: false,
      message: 'Forbidden: Admin access required',
    });
  }

  // Get CSV data from body (either as text/csv or JSON)
  const csvData = typeof req.body === 'string' ? req.body : req.body.csvData;

  if (!csvData) {
    return res.status(400).json({
      success: false,
      message: 'CSV data is required',
    });
  }

  try {
    const rows = parseCSV(csvData);
    const results = {
      success: [],
      failed: [],
    };

    rows.forEach((row, index) => {
      const { email, name, role, department, employeeId } = row;

      // Validate required fields
      if (!email || !name || !role) {
        results.failed.push({
          row: index + 2, // +2 because index 0 is row 2 (after header)
          email: email || 'N/A',
          reason: 'Missing required fields (email, name, role)',
        });
        return;
      }

      // Check if user already exists
      if (findUserByEmail(email)) {
        results.failed.push({
          row: index + 2,
          email,
          reason: 'User with this email already exists',
        });
        return;
      }

      // Create new user
      const newUser = {
        userId: `user-${Date.now()}-${index}`,
        email,
        password: 'DefaultPassword123',
        name,
        role,
        employeeId: employeeId || `EMP${Date.now()}${index}`,
        department: department || '',
        status: 'active',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      users.push(newUser);
      results.success.push({
        row: index + 2,
        email,
        userId: newUser.userId,
      });
    });

    res.status(201).json({
      success: true,
      message: `Bulk import completed: ${results.success.length} succeeded, ${results.failed.length} failed`,
      data: {
        success: results.success.length,
        failed: results.failed.length,
        errors: results.failed.map(f => ({
          row: f.row,
          email: f.email,
          error: f.reason,
        })),
      },
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: `CSV parsing error: ${error.message}`,
    });
  }
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
