const fs = require('fs');
const path = require('path');

// --- CONFIGURATION ---
// 1. Where do you want the components? (Update this path)
const BASE_PATH = path.join(process.cwd(), 'src', 'components');

// 2. List your component names here
const componentNames = [
    'Header',
    'Footer',
    'UserProfile',
    'SettingsModal',
    'NotificationBadge'
];

// 3. The Template
const generateTemplate = (name) => `
import React from 'react';

export const ${name} = () => {
    return (
        <div className="${name.toLowerCase()}-container">
            ${name} Component
        </div>
    );
};
`;

// --- EXECUTION ---
if (!fs.existsSync(BASE_PATH)) {
    console.log(`Creating directory: ${BASE_PATH}`);
    fs.mkdirSync(BASE_PATH, { recursive: true });
}

componentNames.forEach(name => {
    const filePath = path.join(BASE_PATH, `${name}.tsx`);
    if (!fs.existsSync(filePath)) {
        fs.writeFileSync(filePath, generateTemplate(name));
        console.log(`✅ Created: ${name}.tsx`);
    } else {
        console.log(`⚠️ Skipped: ${name}.tsx (Already exists)`);
    }
});