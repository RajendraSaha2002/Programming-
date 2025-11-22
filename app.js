// ==================== Enhanced Task Manager Application ====================
// Features: CRUD, LocalStorage, Chart.js, Dark Mode, Drag-Drop, Import/Export, 
// Categories, Browser Notifications

// ==================== Global Variables ====================
let tasks = [];
let editingTaskId = null;
let taskChart = null;
let currentFilter = 'all';
let currentCategoryFilter = 'all';
let deleteTaskId = null;
let importData = null;
let draggedElement = null;

// Category colors
const categoryColors = [
    '#f56565', '#ed8936', '#ecc94b', '#48bb78', '#38b2ac',
    '#4299e1', '#667eea', '#9f7aea', '#ed64a6'
];

// ==================== DOM Elements ====================
const taskForm = document.getElementById('taskForm');
const taskTitle = document.getElementById('taskTitle');
const taskDescription = document.getElementById('taskDescription');
const taskCategory = document.getElementById('taskCategory');
const taskPriority = document.getElementById('taskPriority');
const taskDueDate = document.getElementById('taskDueDate');
const taskList = document.getElementById('taskList');
const submitButtonText = document.getElementById('submitButtonText');
const cancelEditBtn = document.getElementById('cancelEdit');
const searchInput = document.getElementById('searchInput');
const categoryFilter = document.getElementById('categoryFilter');
const filterButtons = document.querySelectorAll('.filter-btn');
const deleteModal = document.getElementById('deleteModal');
const confirmDeleteBtn = document.getElementById('confirmDelete');
const cancelDeleteBtn = document.getElementById('cancelDelete');
const themeToggle = document.getElementById('themeToggle');
const exportBtn = document.getElementById('exportBtn');
const importBtn = document.getElementById('importBtn');
const importFile = document.getElementById('importFile');
const importModal = document.getElementById('importModal');
const confirmImportBtn = document.getElementById('confirmImport');
const cancelImportBtn = document.getElementById('cancelImport');
const toast = document.getElementById('toast');

// ==================== Initialize App ====================
document.addEventListener('DOMContentLoaded', () => {
    loadTasksFromStorage();
    loadThemePreference();
    renderTasks();
    updateAnalytics();
    initializeChart();
    attachEventListeners();
    setMinDate();
    updateCategoryFilter();
    requestNotificationPermission();
    checkOverdueTasks();
});

// ==================== Event Listeners ====================
function attachEventListeners() {
    taskForm.addEventListener('submit', handleFormSubmit);
    cancelEditBtn.addEventListener('click', cancelEdit);
    searchInput.addEventListener('input', handleSearch);
    categoryFilter.addEventListener('change', handleCategoryFilter);
    
    filterButtons.forEach(btn => {
        btn.addEventListener('click', handleFilter);
    });
    
    confirmDeleteBtn.addEventListener('click', confirmDelete);
    cancelDeleteBtn.addEventListener('click', closeDeleteModal);
    
    deleteModal.addEventListener('click', (e) => {
        if (e.target === deleteModal) closeDeleteModal();
    });
    
    // Dark mode toggle
    themeToggle.addEventListener('click', toggleTheme);
    
    // Export/Import
    exportBtn.addEventListener('click', exportTasks);
    importBtn.addEventListener('click', () => importFile.click());
    importFile.addEventListener('change', handleFileSelect);
    confirmImportBtn.addEventListener('click', confirmImport);
    cancelImportBtn.addEventListener('click', closeImportModal);
    
    importModal.addEventListener('click', (e) => {
        if (e.target === importModal) closeImportModal();
    });
}

// ==================== CRUD Operations ====================

function createTask(taskData) {
    const task = {
        id: Date.now().toString(),
        title: taskData.title,
        description: taskData.description || '',
        category: taskData.category || 'Uncategorized',
        priority: taskData.priority || 'medium',
        dueDate: taskData.dueDate || null,
        completed: false,
        createdAt: new Date().toISOString(),
        order: tasks.length
    };
    
    tasks.unshift(task);
    reorderTasks();
    saveTasksToStorage();
    return task;
}

function getAllTasks() {
    return tasks;
}

function getTaskById(id) {
    return tasks.find(task => task.id === id);
}

function updateTask(id, updates) {
    const taskIndex = tasks.findIndex(task => task.id === id);
    if (taskIndex !== -1) {
        tasks[taskIndex] = { ...tasks[taskIndex], ...updates };
        saveTasksToStorage();
        return tasks[taskIndex];
    }
    return null;
}

function deleteTask(id) {
    tasks = tasks.filter(task => task.id !== id);
    reorderTasks();
    saveTasksToStorage();
}

function reorderTasks() {
    tasks.forEach((task, index) => {
        task.order = index;
    });
}

// ==================== Form Handling ====================
function handleFormSubmit(e) {
    e.preventDefault();
    
    const taskData = {
        title: taskTitle.value.trim(),
        description: taskDescription.value.trim(),
        category: taskCategory.value.trim() || 'Uncategorized',
        priority: taskPriority.value,
        dueDate: taskDueDate.value
    };
    
    if (!taskData.title) {
        showToast('Please enter a task title', 'error');
        return;
    }
    
    if (editingTaskId) {
        updateTask(editingTaskId, taskData);
        showToast('Task updated successfully!', 'success');
        cancelEdit();
    } else {
        createTask(taskData);
        showToast('Task added successfully!', 'success');
    }
    
    taskForm.reset();
    renderTasks();
    updateAnalytics();
    updateCategoryFilter();
}

// ==================== Edit Task ====================
function startEdit(id) {
    const task = getTaskById(id);
    if (!task) return;
    
    editingTaskId = id;
    taskTitle.value = task.title;
    taskDescription.value = task.description;
    taskCategory.value = task.category;
    taskPriority.value = task.priority;
    taskDueDate.value = task.dueDate || '';
    
    submitButtonText.textContent = 'Update Task';
    cancelEditBtn.style.display = 'inline-block';
    
    window.scrollTo({ top: 0, behavior: 'smooth' });
    taskTitle.focus();
}

function cancelEdit() {
    editingTaskId = null;
    taskForm.reset();
    submitButtonText.textContent = 'Add Task';
    cancelEditBtn.style.display = 'none';
}

// ==================== Delete Task ====================
function initiateDelete(id) {
    deleteTaskId = id;
    deleteModal.style.display = 'block';
}

function confirmDelete() {
    if (deleteTaskId) {
        deleteTask(deleteTaskId);
        showToast('Task deleted successfully!', 'success');
        renderTasks();
        updateAnalytics();
        updateCategoryFilter();
    }
    closeDeleteModal();
}

function closeDeleteModal() {
    deleteModal.style.display = 'none';
    deleteTaskId = null;
}

// ==================== Toggle Task Completion ====================
function toggleTaskCompletion(id) {
    const task = getTaskById(id);
    if (task) {
        updateTask(id, { completed: !task.completed });
        renderTasks();
        updateAnalytics();
        
        if (!task.completed) {
            showToast('Task completed! 🎉', 'success');
            showNotification('Task Completed!', `You completed: ${task.title}`);
        } else {
            showToast('Task marked as pending!', 'success');
        }
    }
}

// ==================== Render Tasks ====================
function renderTasks(tasksToRender = null) {
    const displayTasks = tasksToRender || getFilteredTasks();
    
    document.getElementById('taskCount').textContent = displayTasks.length;
    
    if (displayTasks.length === 0) {
        taskList.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">📝</div>
                <p>${getEmptyMessage()}</p>
            </div>
        `;
        return;
    }
    
    // Sort by order
    displayTasks.sort((a, b) => a.order - b.order);
    
    taskList.innerHTML = displayTasks.map(task => createTaskHTML(task)).join('');
    
    // Attach event listeners
    displayTasks.forEach(task => {
        const taskItem = document.querySelector(`[data-task-id="${task.id}"]`);
        const checkbox = taskItem.querySelector('.task-checkbox');
        const editBtn = taskItem.querySelector('.edit-btn');
        const deleteBtn = taskItem.querySelector('.delete-btn');
        
        checkbox.addEventListener('change', () => toggleTaskCompletion(task.id));
        editBtn.addEventListener('click', () => startEdit(task.id));
        deleteBtn.addEventListener('click', () => initiateDelete(task.id));
        
        // Drag and drop
        taskItem.draggable = true;
        taskItem.addEventListener('dragstart', handleDragStart);
        taskItem.addEventListener('dragend', handleDragEnd);
        taskItem.addEventListener('dragover', handleDragOver);
        taskItem.addEventListener('drop', handleDrop);
        taskItem.addEventListener('dragleave', handleDragLeave);
    });
}

function getEmptyMessage() {
    if (searchInput.value.trim()) {
        return 'No tasks found matching your search.';
    }
    if (currentCategoryFilter !== 'all') {
        return `No ${currentFilter} tasks in this category.`;
    }
    if (currentFilter !== 'all') {
        return `No ${currentFilter} tasks found.`;
    }
    return 'No tasks yet. Add your first task to get started!';
}

// ==================== Create Task HTML ====================
function createTaskHTML(task) {
    const isOverdue = task.dueDate && new Date(task.dueDate) < new Date() && !task.completed;
    const priorityClass = `priority-${task.priority}`;
    const categoryColor = getCategoryColor(task.category);
    
    return `
        <div class="task-item ${task.completed ? 'completed' : ''}" data-task-id="${task.id}">
            <input 
                type="checkbox" 
                class="task-checkbox" 
                ${task.completed ? 'checked' : ''}
            >
            <div class="task-content">
                <div class="task-title">${escapeHTML(task.title)}</div>
                ${task.description ? `<div class="task-description">${escapeHTML(task.description)}</div>` : ''}
                <div class="task-meta">
                    <span class="task-category" style="background: ${categoryColor}">
                        ${escapeHTML(task.category)}
                    </span>
                    <span class="task-priority ${priorityClass}">${task.priority}</span>
                    ${task.dueDate ? `
                        <span class="task-due-date ${isOverdue ? 'overdue' : ''}">
                            📅 ${formatDate(task.dueDate)}
                            ${isOverdue ? ' (Overdue!)' : ''}
                        </span>
                    ` : ''}
                </div>
            </div>
            <div class="task-actions">
                <button class="task-btn edit-btn">Edit</button>
                <button class="task-btn delete-btn">Delete</button>
            </div>
        </div>
    `;
}

// ==================== Drag and Drop ====================
function handleDragStart(e) {
    draggedElement = e.target;
    e.target.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
}

function handleDragEnd(e) {
    e.target.classList.remove('dragging');
    document.querySelectorAll('.task-item').forEach(item => {
        item.classList.remove('drag-over');
    });
}

function handleDragOver(e) {
    if (e.preventDefault) {
        e.preventDefault();
    }
    e.dataTransfer.dropEffect = 'move';
    
    const afterElement = getDragAfterElement(taskList, e.clientY);
    const dragging = document.querySelector('.dragging');
    
    if (afterElement == null) {
        taskList.appendChild(dragging);
    } else {
        taskList.insertBefore(dragging, afterElement);
    }
    
    return false;
}

function handleDrop(e) {
    if (e.stopPropagation) {
        e.stopPropagation();
    }
    
    // Update task order
    const taskElements = Array.from(taskList.querySelectorAll('.task-item'));
    taskElements.forEach((element, index) => {
        const taskId = element.dataset.taskId;
        const task = getTaskById(taskId);
        if (task) {
            task.order = index;
        }
    });
    
    saveTasksToStorage();
    showToast('Task order updated!', 'success');
    
    return false;
}

function handleDragLeave(e) {
    e.target.classList.remove('drag-over');
}

function getDragAfterElement(container, y) {
    const draggableElements = [...container.querySelectorAll('.task-item:not(.dragging)')];
    
    return draggableElements.reduce((closest, child) => {
        const box = child.getBoundingClientRect();
        const offset = y - box.top - box.height / 2;
        
        if (offset < 0 && offset > closest.offset) {
            return { offset: offset, element: child };
        } else {
            return closest;
        }
    }, { offset: Number.NEGATIVE_INFINITY }).element;
}

// ==================== Filter & Search ====================
function getFilteredTasks() {
    let filteredTasks = tasks;
    
    // Apply status filter
    if (currentFilter === 'completed') {
        filteredTasks = filteredTasks.filter(task => task.completed);
    } else if (currentFilter === 'pending') {
        filteredTasks = filteredTasks.filter(task => !task.completed);
    }
    
    // Apply category filter
    if (currentCategoryFilter !== 'all') {
        filteredTasks = filteredTasks.filter(task => task.category === currentCategoryFilter);
    }
    
    // Apply search
    const searchTerm = searchInput.value.toLowerCase().trim();
    if (searchTerm) {
        filteredTasks = filteredTasks.filter(task =>
            task.title.toLowerCase().includes(searchTerm) ||
            task.description.toLowerCase().includes(searchTerm) ||
            task.category.toLowerCase().includes(searchTerm)
        );
    }
    
    return filteredTasks;
}

function handleFilter(e) {
    filterButtons.forEach(btn => btn.classList.remove('active'));
    e.target.classList.add('active');
    currentFilter = e.target.dataset.filter;
    renderTasks();
}

function handleSearch() {
    renderTasks();
}

function handleCategoryFilter() {
    currentCategoryFilter = categoryFilter.value;
    renderTasks();
}

function updateCategoryFilter() {
    const categories = getUniqueCategories();
    const currentValue = categoryFilter.value;
    
    categoryFilter.innerHTML = '<option value="all">All Categories</option>';
    categories.forEach(cat => {
        const option = document.createElement('option');
        option.value = cat;
        option.textContent = cat;
        categoryFilter.appendChild(option);
    });
    
    // Update datalist for input
    const datalist = document.getElementById('categoryList');
    datalist.innerHTML = '';
    categories.forEach(cat => {
        const option = document.createElement('option');
        option.value = cat;
        datalist.appendChild(option);
    });
    
    // Restore previous selection if still valid
    if (categories.includes(currentValue)) {
        categoryFilter.value = currentValue;
    }
}

function getUniqueCategories() {
    const categories = [...new Set(tasks.map(task => task.category))];
    return categories.sort();
}

// ==================== Analytics & Chart ====================
function updateAnalytics() {
    const total = tasks.length;
    const completed = tasks.filter(task => task.completed).length;
    const pending = total - completed;
    const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0;
    
    document.getElementById('totalTasks').textContent = total;
    document.getElementById('completedTasks').textContent = completed;
    document.getElementById('pendingTasks').textContent = pending;
    document.getElementById('completionRate').textContent = `${completionRate}%`;
    
    updateChart(completed, pending);
    updateCategoryStats();
}

function initializeChart() {
    const ctx = document.getElementById('taskChart').getContext('2d');
    
    taskChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Completed', 'Pending'],
            datasets: [{
                data: [0, 0],
                backgroundColor: [
                    'rgba(72, 187, 120, 0.8)',
                    'rgba(237, 137, 54, 0.8)'
                ],
                borderColor: [
                    'rgba(72, 187, 120, 1)',
                    'rgba(237, 137, 54, 1)'
                ],
                borderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        padding: 15,
                        font: {
                            size: 12,
                            weight: '600'
                        },
                        color: getComputedStyle(document.documentElement)
                            .getPropertyValue('--text-primary')
                    }
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            const label = context.label || '';
                            const value = context.parsed || 0;
                            const total = context.dataset.data.reduce((a, b) => a + b, 0);
                            const percentage = total > 0 ? Math.round((value / total) * 100) : 0;
                            return `${label}: ${value} (${percentage}%)`;
                        }
                    }
                }
            }
        }
    });
}

function updateChart(completed, pending) {
    if (taskChart) {
        taskChart.data.datasets[0].data = [completed, pending];
        taskChart.update();
    }
}

function updateCategoryStats() {
    const categoryStats = document.getElementById('categoryStats');
    const categories = getUniqueCategories();
    
    if (categories.length === 0) {
        categoryStats.innerHTML = '';
        return;
    }
    
    const stats = categories.map(cat => {
        const count = tasks.filter(t => t.category === cat).length;
        return { category: cat, count };
    }).sort((a, b) => b.count - a.count);
    
    categoryStats.innerHTML = `
        <h3 style="margin-bottom: 10px; font-size: 1rem; color: var(--text-primary);">
            Tasks by Category
        </h3>
        ${stats.map(stat => `
            <div class="category-stat-item">
                <span class="category-stat-name">
                    <span class="category-dot" style="background: ${getCategoryColor(stat.category)}"></span>
                    ${escapeHTML(stat.category)}
                </span>
                <strong>${stat.count}</strong>
            </div>
        `).join('')}
    `;
}

// ==================== Dark Mode ====================
function toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    
    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    
    const themeIcon = document.querySelector('.theme-icon');
    themeIcon.textContent = newTheme === 'dark' ? '☀️' : '🌙';
    
    showToast(`${newTheme === 'dark' ? 'Dark' : 'Light'} mode enabled`, 'success');
}

function loadThemePreference() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    document.documentElement.setAttribute('data-theme', savedTheme);
    
    const themeIcon = document.querySelector('.theme-icon');
    themeIcon.textContent = savedTheme === 'dark' ? '☀️' : '🌙';
}

// ==================== Export/Import ====================
function exportTasks() {
    if (tasks.length === 0) {
        showToast('No tasks to export!', 'warning');
        return;
    }
    
    const dataStr = JSON.stringify(tasks, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    
        const url = URL.createObjectURL(dataBlob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `tasks-backup-${new Date().toISOString().split('T')[0]}.json`;
        
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
        
        showToast('Tasks exported successfully!', 'success');
    }
    
    function handleFileSelect(e) {
        const file = e.target.files[0];
        if (!file) return;
        
        const reader = new FileReader();
        reader.onload = (event) => {
            try {
                importData = JSON.parse(event.target.result);
                if (!Array.isArray(importData)) {
                    throw new Error('Invalid format');
                }
                importModal.style.display = 'block';
            } catch (error) {
                showToast('Invalid file format!', 'error');
            }
        };
        reader.readAsText(file);
        importFile.value = '';
    }
    
    function confirmImport() {
        if (importData) {
            tasks = importData;
            saveTasksToStorage();
            renderTasks();
            updateAnalytics();
            updateCategoryFilter();
            showToast('Tasks imported successfully!', 'success');
        }
        closeImportModal();
    }
    
    function closeImportModal() {
        importModal.style.display = 'none';
        importData = null;
    }
    
    // ==================== LocalStorage ====================
    function saveTasksToStorage() {
        localStorage.setItem('tasks', JSON.stringify(tasks));
    }
    
    function loadTasksFromStorage() {
        const storedTasks = localStorage.getItem('tasks');
        if (storedTasks) {
            tasks = JSON.parse(storedTasks);
        }
    }
    
    // ==================== Notifications ====================
    function requestNotificationPermission() {
        if ('Notification' in window && Notification.permission === 'default') {
            Notification.requestPermission();
        }
    }
    
    function showNotification(title, body) {
        if ('Notification' in window && Notification.permission === 'granted') {
            new Notification(title, { body, icon: '📝' });
        }
    }
    
    function checkOverdueTasks() {
        const now = new Date();
        tasks.forEach(task => {
            if (!task.completed && task.dueDate) {
                const dueDate = new Date(task.dueDate);
                if (dueDate < now) {
                    showNotification('Overdue Task!', `Task "${task.title}" is overdue!`);
                }
            }
        });
    }
    
    // ==================== Utility Functions ====================
    function showToast(message, type = 'info') {
        toast.textContent = message;
        toast.className = `toast ${type} show`;
        
        setTimeout(() => {
            toast.classList.remove('show');
        }, 3000);
    }
    
    function formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    }
    
    function escapeHTML(str) {
        const div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    }
    
    function setMinDate() {
        const today = new Date().toISOString().split('T')[0];
        taskDueDate.setAttribute('min', today);
    }
    
    function getCategoryColor(category) {
        const index = getUniqueCategories().indexOf(category);
        return categoryColors[index % categoryColors.length];
    }