const express = require('express');
const router = express.Router();

// Mock data
let users = [
  { id: 1, name: 'Alice Johnson', email: 'alice@example.com', role: 'admin' },
  { id: 2, name: 'Bob Smith', email: 'bob@example.com', role: 'user' },
  { id: 3, name: 'Charlie Brown', email: 'charlie@example.com', role: 'user' }
];

let tasks = [
  { id: 1, title: 'Complete DevX Demo', status: 'in-progress', priority: 'high' },
  { id: 2, title: 'Write Documentation', status: 'completed', priority: 'medium' },
  { id: 3, title: 'Code Review', status: 'pending', priority: 'high' }
];

// API Info
router.get('/info', (req, res) => {
  res.json({
    api: 'Demo Node.js API',
    version: '1.0.0',
    description: 'Demonstrating DevX reusable workflows',
    features: [
      'REST API',
      'Unit Tests',
      'Docker Support',
      'Security Scanning',
      'CI/CD Pipeline'
    ]
  });
});

// Users endpoints
router.get('/users', (req, res) => {
  res.json({
    success: true,
    count: users.length,
    data: users
  });
});

router.get('/users/:id', (req, res) => {
  const user = users.find(u => u.id === parseInt(req.params.id));
  if (!user) {
    return res.status(404).json({
      success: false,
      error: 'User not found'
    });
  }
  res.json({
    success: true,
    data: user
  });
});

router.post('/users', (req, res) => {
  const { name, email, role } = req.body;
  
  if (!name || !email) {
    return res.status(400).json({
      success: false,
      error: 'Name and email are required'
    });
  }

  const newUser = {
    id: users.length + 1,
    name,
    email,
    role: role || 'user'
  };

  users.push(newUser);
  
  res.status(201).json({
    success: true,
    message: 'User created successfully',
    data: newUser
  });
});

// Tasks endpoints
router.get('/tasks', (req, res) => {
  const { status, priority } = req.query;
  let filteredTasks = tasks;

  if (status) {
    filteredTasks = filteredTasks.filter(t => t.status === status);
  }

  if (priority) {
    filteredTasks = filteredTasks.filter(t => t.priority === priority);
  }

  res.json({
    success: true,
    count: filteredTasks.length,
    data: filteredTasks
  });
});

router.get('/tasks/:id', (req, res) => {
  const task = tasks.find(t => t.id === parseInt(req.params.id));
  if (!task) {
    return res.status(404).json({
      success: false,
      error: 'Task not found'
    });
  }
  res.json({
    success: true,
    data: task
  });
});

router.post('/tasks', (req, res) => {
  const { title, priority } = req.body;
  
  if (!title) {
    return res.status(400).json({
      success: false,
      error: 'Title is required'
    });
  }

  const newTask = {
    id: tasks.length + 1,
    title,
    status: 'pending',
    priority: priority || 'medium'
  };

  tasks.push(newTask);
  
  res.status(201).json({
    success: true,
    message: 'Task created successfully',
    data: newTask
  });
});

router.patch('/tasks/:id', (req, res) => {
  const task = tasks.find(t => t.id === parseInt(req.params.id));
  
  if (!task) {
    return res.status(404).json({
      success: false,
      error: 'Task not found'
    });
  }

  const { title, status, priority } = req.body;
  
  if (title) task.title = title;
  if (status) task.status = status;
  if (priority) task.priority = priority;

  res.json({
    success: true,
    message: 'Task updated successfully',
    data: task
  });
});

module.exports = router;