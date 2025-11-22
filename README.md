# To-Do App With Task Analytics - Enhanced Edition 📊✨

A feature-rich task management application with real-time analytics dashboard, dark mode, drag-and-drop, categories, and data import/export capabilities built with vanilla JavaScript, LocalStorage persistence, and Chart.js visualizations.

## 🌟 Features

### Core Features
- **Full CRUD Operations**
  - ✅ Create new tasks with titles, descriptions, categories, and priorities
  - 📖 Read and display all tasks
  - ✏️ Update existing tasks
  - 🗑️ Delete tasks with confirmation

- **Task Management**
  - Mark tasks as complete/incomplete
  - Filter tasks (All, Pending, Completed)
  - Search functionality
  - Priority levels (Low, Medium, High)
  - Due date tracking with overdue indicators
  - **Task categories/tags** with color coding

### Advanced Features
- **🌙 Dark Mode Toggle** - Seamless theme switching with localStorage persistence
- **🎨 Drag-and-Drop Reordering** - Reorder tasks by dragging
- **📥 Export to JSON** - Download all tasks as JSON file
- **📤 Manual Import from JSON** - Upload and import tasks from JSON file
- **🔔 Browser Notifications** - Get notified for completed tasks and overdue reminders
- **📊 Real-time Analytics** - Interactive Chart.js visualizations

### Analytics Dashboard
- Real-time chart showing completed vs pending tasks
- Task statistics (total, completed, pending, completion rate)
- Category-based task distribution
- Visual progress indicators

### Data Management
- **LocalStorage synchronization** - Data persists across browser sessions
- **Auto-save functionality** - Never lose your work
- **JSON Export** - Backup your tasks
- **JSON Import** - Restore or transfer tasks between devices

## 🚀 Getting Started

### Prerequisites

- Modern web browser (Chrome, Firefox, Safari, Edge)
- **VS Code Extensions:**
  - Live Server
  - JavaScript Debugger (built-in)

### Installation

1. Clone or download this repository
2. Open the project folder in VS Code
3. Right-click on `index.html` and select "Open with Live Server"
4. The app will open in your default browser at `http://127.0.0.1:5500`

### Manual Setup (Without Live Server)

Simply open `index.html` in your web browser.

## 💻 Usage

### Adding a Task

1. Enter task title in the input field
2. (Optional) Add a description
3. (Optional) Select or create a category
4. (Optional) Set priority level
5. (Optional) Set due date
6. Click "Add Task" button or press Enter

### Managing Tasks

- **Complete Task:** Click the checkbox next to the task
- **Edit Task:** Click the "Edit" button, modify details, and save
- **Delete Task:** Click the "Delete" button and confirm
- **Reorder Tasks:** Drag and drop tasks to reorder them

### Categories

- **Add Category:** Type a new category name when adding a task
- **Use Existing:** Select from dropdown of existing categories
- **Color Coded:** Each category gets a unique color

### Dark Mode

- Click the **🌙/☀️ toggle button** in the header
- Preference is saved automatically
- Smooth transition between themes

### Export & Import

#### Export Tasks
1. Click the **"Export JSON"** button
2. Tasks are downloaded as `tasks-backup-YYYY-MM-DD.json`
3. Save the file to your preferred location

#### Import Tasks
1. Click the **"Import JSON"** button
2. Select your previously exported JSON file
3. Choose import option:
   - **Merge:** Add imported tasks to existing ones
   - **Replace:** Replace all existing tasks with imported ones
4. Click "Import" to confirm

### Browser Notifications

- Enable notifications when prompted
- Get notified when tasks are completed
- Receive reminders for overdue tasks (daily check)

### Filtering & Searching

- Use the filter buttons to view All, Pending, or Completed tasks
- Use the search bar to find specific tasks by title or description
- Filter by category using the category dropdown

### Analytics

- View the pie chart showing task distribution
- Monitor completion rate and statistics
- See category-based breakdown
- Analytics update in real-time

## 🛠️ Technical Details

### Technologies Used

- **HTML5** - Structure
- **CSS3** - Styling with modern features (Grid, Flexbox, Custom Properties, Animations)
- **JavaScript (ES6+)** - Core functionality
- **Chart.js (v3.9.1)** - Data visualization
- **LocalStorage API** - Data persistence
- **Drag and Drop API** - Task reordering
- **Notifications API** - Browser notifications
- **File API** - JSON import/export

### Project Structure

```
todo-app-enhanced/
│
├── index.html          # Main HTML file
├── styles.css          # Stylesheet with dark mode
├── app.js             # JavaScript logic
└── README.md          # Documentation
```

### Key JavaScript Concepts Demonstrated

- ES6+ syntax (arrow functions, destructuring, template literals, spread operator)
- DOM manipulation and event delegation
- Event handling (drag & drop, file upload)
- LocalStorage API for persistence
- Array methods (map, filter, reduce, sort)
- Object-oriented patterns
- Async operations (File reading)
- Chart.js integration
- Notifications API
- Import/Export functionality

## 🎨 Customization

### Changing Colors

Edit the CSS custom properties in `styles.css`:

```css
:root {
    --primary-color: #667eea;
    --secondary-color: #764ba2;
    --success-color: #48bb78;
    /* ... more colors ... */
}
```

### Dark Mode Colors

```css
[data-theme="dark"] {
    --background: #1a202c;
    --card-background: #2d3748;
    /* ... more dark theme colors ... */
}
```

### Modifying Chart Appearance

Edit the chart configuration in `app.js` within the `updateChart()` function.

## 🔔 Browser Notifications Setup

1. When you first complete a task, the browser will ask for notification permission
2. Click "Allow" to enable notifications
3. You'll receive notifications for:
   - Task completions
   - Overdue task reminders (checked daily)

## 📦 JSON Import/Export Format

### JSON Structure

```json
[
  {
    "id": "1637571234567",
    "title": "Sample Task",
    "description": "This is a sample task",
    "priority": "high",
    "category": "Work",
    "dueDate": "2025-12-31",
    "completed": false,
    "createdAt": "2025-11-22T09:34:20.000Z",
    "order": 0
  }
]
```

### Import Options

- **Merge:** Combines imported tasks with existing tasks (preserves current data)
- **Replace:** Removes all existing tasks and replaces with imported tasks

### Export Features

- Automatically named with timestamp
- Preserves all task data including order
- Compatible with import functionality

## 🐛 Debugging

### Using JavaScript Debugger in VS Code

1. Open the Debug panel (Ctrl+Shift+D / Cmd+Shift+D)
2. Set breakpoints by clicking left of line numbers in `app.js`
3. Use "JavaScript Debug Terminal" or attach to browser
4. Inspect variables, step through code, and monitor call stack

### Browser DevTools

- Press F12 to open DevTools
- Check Console for errors
- Use Application tab to inspect LocalStorage
- Use Sources tab to debug JavaScript
- Check Network tab for file operations

## 📱 Browser Compatibility

- ✅ Chrome (recommended)
- ✅ Firefox
- ✅ Safari
- ✅ Edge
- ⚠️ IE11 (not supported)

### Feature Support

- Drag & Drop: All modern browsers
- Notifications: Requires user permission
- File API: All modern browsers
- LocalStorage: All modern browsers

## 🔒 Data Privacy

- All data is stored locally in your browser's LocalStorage
- No data is sent to external servers
- Notifications are local to your device
- Exported JSON files are stored locally on your computer

## 🚀 Future Enhancements

- [x] Dark mode toggle
- [x] Export/Import tasks (JSON)
- [x] Task categories/tags
- [x] Drag-and-drop reordering
- [x] Browser notifications
- [ ] Cloud sync option
- [ ] Recurring tasks
- [ ] Task templates
- [ ] Collaboration features
- [ ] Mobile app (PWA)

## 📄 License

This project is open source and available for personal and educational use.

## 🤝 Contributing

Feel free to fork, modify, and enhance this project!

## 📞 Support

For issues or questions:
1. Check the browser console for error messages
2. Ensure LocalStorage is enabled
3. Verify browser supports required APIs
4. Check file permissions for import/export

## 🎯 Tips & Tricks

1. **Backup Regularly:** Export your tasks periodically
2. **Use Categories:** Organize tasks by project or context
3. **Set Due Dates:** Stay on top of deadlines
4. **Drag to Prioritize:** Reorder tasks by importance
5. **Dark Mode:** Easier on eyes during night work
6. **Search:** Quickly find tasks with keywords

---

**Happy Task Managing! 🎯✨**

Made with ❤️ for productivity enthusiasts