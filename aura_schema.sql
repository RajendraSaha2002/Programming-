
-- 1. Create Database (Run separately if needed)
-- CREATE DATABASE aura_chronicles;

-- 2. Create the Table (The Soul)
CREATE TABLE IF NOT EXISTS poetic_lines (
    id SERIAL PRIMARY KEY,
    line_text TEXT NOT NULL,
    mood VARCHAR(50) DEFAULT 'pure',
    display_order INT
);

-- 3. Seed the Initial Thoughts
INSERT INTO poetic_lines (line_text, display_order) VALUES
('Kuch log apni personality se hi purity reflect kar dete hain.', 1),
('January 2026 ki khamosh si shaamon mein ye aur clear lagta hai.', 2),
('Uski aankhon mein depth hai, par ego nahi.', 3),
('Smile mein softness hai, par weakness nahi.', 4),
('Camera ke saamne bhi wo real hi lagti hai.', 5),
('Uska outfit flashy nahi, par uska aura kaafi hai.', 6),
('Winter ke season mein bhi uski warmth alag hi feel hoti hai.', 7),
('Wo impress nahi karti, wo connect karti hai.', 8),
('Uski beauty face tak limited nahi rehti.', 9),
('Wo behaviour aur values mein bhi dikh jaati hai.', 10),
('Dil uske paas loud nahi hota.', 11),
('Bas quietly belong karna chahta hai.', 12);