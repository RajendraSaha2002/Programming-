package resources;/*
 QuizApp.java
 A simple Online Quiz Application using Swing + SQLite (JDBC).
 - Admin panel to add/edit/delete questions (password: admin)
 - User quiz-taking panel that saves scores to DB
 - Uses sqlite JDBC (org.xerial:sqlite-jdbc) via Maven or jar on classpath

 How to run with Maven:
 1) Save this file under src/main/java (no package) in a Maven project with the provided pom.xml
 2) mvn compile
 3) mvn exec:java -Dexec.mainClass=QuizApp

 Or compile/run with sqlite-jdbc jar:
  javac -cp sqlite-jdbc-<ver>.jar QuizApp.java
  java -cp .;sqlite-jdbc-<ver>.jar QuizApp   (Windows)
  java -cp .:sqlite-jdbc-<ver>.jar QuizApp   (mac/linux)
*/

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.*;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class QuizApp {
    // DB file
    private static final String DB_URL = "jdbc:sqlite:quiz.db";
    // Admin password (simple default)
    private static final String ADMIN_PASSWORD = "admin";

    // Swing main frame
    private final JFrame frame = new JFrame("Online Quiz Application");
    private final CardLayout cardLayout = new CardLayout();
    private final JPanel cards = new JPanel(cardLayout);

    // panels
    private final MainPanel mainPanel = new MainPanel();
    private final AdminPanel adminPanel = new AdminPanel();
    private final QuizPanel quizPanel = new QuizPanel();

    public static void main(String[] args) {
        // Ensure DB exists + seed
        try {
            DB.init();
        } catch (SQLException ex) {
            ex.printStackTrace();
            JOptionPane.showMessageDialog(null, "Failed to initialize DB: " + ex.getMessage());
            return;
        }

        SwingUtilities.invokeLater(() -> {
            QuizApp app = new QuizApp();
            app.show();
        });
    }

    private void show() {
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setSize(900, 600);
        frame.setLocationRelativeTo(null);

        cards.add(mainPanel, "MAIN");
        cards.add(adminPanel, "ADMIN");
        cards.add(quizPanel, "QUIZ");
        frame.setContentPane(cards);
        frame.setVisible(true);

        cardLayout.show(cards, "MAIN");
    }

    // ---------- DB helper ----------
    static class DB {
        static void init() throws SQLException {
            try (Connection c = DriverManager.getConnection(DB_URL)) {
                try (Statement s = c.createStatement()) {
                    // questions table
                    s.execute("CREATE TABLE IF NOT EXISTS questions (" +
                            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                            "question TEXT NOT NULL," +
                            "optA TEXT NOT NULL," +
                            "optB TEXT NOT NULL," +
                            "optC TEXT NOT NULL," +
                            "optD TEXT NOT NULL," +
                            "correct CHAR(1) NOT NULL CHECK (correct IN ('A','B','C','D'))" +
                            ");");
                    // scores table
                    s.execute("CREATE TABLE IF NOT EXISTS scores (" +
                            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                            "player TEXT NOT NULL," +
                            "score INTEGER NOT NULL," +
                            "total INTEGER NOT NULL," +
                            "taken_on TEXT NOT NULL" +
                            ");");
                }
                // seed some sample questions if empty
                long qcount = countQuestions(c);
                if (qcount == 0) seedSampleQuestions(c);
            }
        }

        static long countQuestions(Connection c) throws SQLException {
            try (Statement s = c.createStatement();
                 ResultSet rs = s.executeQuery("SELECT COUNT(*) FROM questions")) {
                if (rs.next()) return rs.getLong(1);
            }
            return 0;
        }

        static void seedSampleQuestions(Connection c) throws SQLException {
            String insert = "INSERT INTO questions (question,optA,optB,optC,optD,correct) VALUES (?,?,?,?,?,?)";
            try (PreparedStatement ps = c.prepareStatement(insert)) {
                // 1
                ps.setString(1, "What is the output of: 1 + 1 in Java?");
                ps.setString(2, "1");
                ps.setString(3, "2");
                ps.setString(4, "\"1+1\"");
                ps.setString(5, "Compilation error");
                ps.setString(6, "B");
                ps.executeUpdate();

                // 2
                ps.setString(1, "Which of these is not a Java primitive type?");
                ps.setString(2, "int");
                ps.setString(3, "boolean");
                ps.setString(4, "String");
                ps.setString(5, "double");
                ps.setString(6, "C");
                ps.executeUpdate();

                // 3
                ps.setString(1, "Which collection allows duplicate elements?");
                ps.setString(2, "Set");
                ps.setString(3, "Map");
                ps.setString(4, "List");
                ps.setString(5, "Tree");
                ps.setString(6, "C");
                ps.executeUpdate();

                // 4
                ps.setString(1, "What keyword is used to inherit a class in Java?");
                ps.setString(2, "implements");
                ps.setString(3, "extends");
                ps.setString(4, "inherits");
                ps.setString(5, "super");
                ps.setString(6, "B");
                ps.executeUpdate();

                // 5
                ps.setString(1, "Which method signature is entry point for Java applications?");
                ps.setString(2, "public void main()");
                ps.setString(3, "public static void main(String[] args)");
                ps.setString(4, "void main(String args)");
                ps.setString(5, "public static int main(String[] args)");
                ps.setString(6, "B");
                ps.executeUpdate();
            }
        }

        // CRUD operations
        static List<Question> listQuestions() throws SQLException {
            List<Question> list = new ArrayList<>();
            try (Connection c = DriverManager.getConnection(DB_URL);
                 Statement s = c.createStatement();
                 ResultSet rs = s.executeQuery("SELECT id,question,optA,optB,optC,optD,correct FROM questions")) {
                while (rs.next()) {
                    Question q = new Question();
                    q.id = rs.getInt("id");
                    q.question = rs.getString("question");
                    q.optA = rs.getString("optA");
                    q.optB = rs.getString("optB");
                    q.optC = rs.getString("optC");
                    q.optD = rs.getString("optD");
                    q.correct = rs.getString("correct").charAt(0);
                    list.add(q);
                }
            }
            return list;
        }

        static void addQuestion(Question q) throws SQLException {
            String sql = "INSERT INTO questions (question,optA,optB,optC,optD,correct) VALUES (?,?,?,?,?,?)";
            try (Connection c = DriverManager.getConnection(DB_URL);
                 PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, q.question);
                ps.setString(2, q.optA);
                ps.setString(3, q.optB);
                ps.setString(4, q.optC);
                ps.setString(5, q.optD);
                ps.setString(6, String.valueOf(q.correct));
                ps.executeUpdate();
            }
        }

        static void updateQuestion(Question q) throws SQLException {
            String sql = "UPDATE questions SET question=?,optA=?,optB=?,optC=?,optD=?,correct=? WHERE id=?";
            try (Connection c = DriverManager.getConnection(DB_URL);
                 PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, q.question);
                ps.setString(2, q.optA);
                ps.setString(3, q.optB);
                ps.setString(4, q.optC);
                ps.setString(5, q.optD);
                ps.setString(6, String.valueOf(q.correct));
                ps.setInt(7, q.id);
                ps.executeUpdate();
            }
        }

        static void deleteQuestion(int id) throws SQLException {
            try (Connection c = DriverManager.getConnection(DB_URL);
                 PreparedStatement ps = c.prepareStatement("DELETE FROM questions WHERE id=?")) {
                ps.setInt(1, id);
                ps.executeUpdate();
            }
        }

        static void saveScore(String player, int score, int total) throws SQLException {
            String sql = "INSERT INTO scores (player,score,total,taken_on) VALUES (?,?,?,?)";
            try (Connection c = DriverManager.getConnection(DB_URL);
                 PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, player);
                ps.setInt(2, score);
                ps.setInt(3, total);
                ps.setString(4, LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                ps.executeUpdate();
            }
        }

        static List<String> listScores() throws SQLException {
            List<String> out = new ArrayList<>();
            try (Connection c = DriverManager.getConnection(DB_URL);
                 Statement s = c.createStatement();
                 ResultSet rs = s.executeQuery("SELECT player,score,total,taken_on FROM scores ORDER BY id DESC LIMIT 50")) {
                while (rs.next()) {
                    out.add(String.format("%s — %d/%d on %s", rs.getString("player"), rs.getInt("score"),
                            rs.getInt("total"), rs.getString("taken_on")));
                }
            }
            return out;
        }
    }

    // ---------- Data ----------
    static class Question {
        int id;
        String question;
        String optA, optB, optC, optD;
        char correct; // 'A'..'D'
    }

    // ---------- Main (home) panel ----------
    class MainPanel extends JPanel {
        MainPanel() {
            setLayout(new BorderLayout(8,8));
            JLabel title = new JLabel("Online Quiz Application", SwingConstants.CENTER);
            title.setFont(new Font("SansSerif", Font.BOLD, 26));
            add(title, BorderLayout.NORTH);

            JTextArea desc = new JTextArea();
            desc.setText("Welcome! Choose an action:\n\n"
                    + "• Take Quiz — start a new quiz as a player.\n"
                    + "• Admin Login — manage questions (password required).\n\n"
                    + "This app stores questions and scores in quiz.db (SQLite).");
            desc.setEditable(false);
            desc.setWrapStyleWord(true);
            desc.setLineWrap(true);
            desc.setBackground(getBackground());
            desc.setBorder(BorderFactory.createEmptyBorder(12,12,12,12));
            add(desc, BorderLayout.CENTER);

            JPanel buttons = new JPanel(new FlowLayout());
            JButton take = new JButton("Take Quiz");
            JButton admin = new JButton("Admin Login");
            JButton viewScores = new JButton("View Scores");

            take.addActionListener(e -> {
                quizPanel.prepareAndShow();
                cardLayout.show(cards, "QUIZ");
            });

            admin.addActionListener(e -> {
                String pass = JOptionPane.showInputDialog(frame, "Enter admin password:");
                if (pass != null && pass.equals(ADMIN_PASSWORD)) {
                    adminPanel.refreshTable();
                    cardLayout.show(cards, "ADMIN");
                } else {
                    JOptionPane.showMessageDialog(frame, "Invalid password.", "Access denied", JOptionPane.ERROR_MESSAGE);
                }
            });

            viewScores.addActionListener(e -> {
                try {
                    List<String> items = DB.listScores();
                    if (items.isEmpty()) JOptionPane.showMessageDialog(frame, "No scores yet.");
                    else {
                        JTextArea ta = new JTextArea(String.join("\n", items));
                        ta.setEditable(false);
                        ta.setLineWrap(true);
                        ta.setWrapStyleWord(true);
                        JScrollPane sp = new JScrollPane(ta);
                        sp.setPreferredSize(new Dimension(600, 300));
                        JOptionPane.showMessageDialog(frame, sp, "Recent Scores", JOptionPane.INFORMATION_MESSAGE);
                    }
                } catch (SQLException ex) {
                    JOptionPane.showMessageDialog(frame, "Failed to load scores: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                }
            });

            buttons.add(take);
            buttons.add(admin);
            buttons.add(viewScores);
            add(buttons, BorderLayout.SOUTH);
        }
    }

    // ---------- Admin panel ----------
    class AdminPanel extends JPanel {
        private final DefaultTableModel tableModel = new DefaultTableModel(new Object[]{"ID","Question","A","B","C","D","Correct"}, 0);
        private final JTable table = new JTable(tableModel);

        AdminPanel() {
            setLayout(new BorderLayout(8,8));
            JLabel lbl = new JLabel("Admin — Manage Questions", SwingConstants.CENTER);
            lbl.setFont(new Font("SansSerif", Font.BOLD, 20));
            add(lbl, BorderLayout.NORTH);

            table.setAutoResizeMode(JTable.AUTO_RESIZE_LAST_COLUMN);
            JScrollPane sp = new JScrollPane(table);
            add(sp, BorderLayout.CENTER);

            JPanel controls = new JPanel(new FlowLayout(FlowLayout.LEFT));
            JButton addBtn = new JButton("Add");
            JButton editBtn = new JButton("Edit");
            JButton delBtn = new JButton("Delete");
            JButton backBtn = new JButton("Back");

            addBtn.addActionListener(e -> showAddDialog());
            editBtn.addActionListener(e -> showEditDialog());
            delBtn.addActionListener(e -> deleteSelected());
            backBtn.addActionListener(e -> cardLayout.show(cards, "MAIN"));

            controls.add(addBtn);
            controls.add(editBtn);
            controls.add(delBtn);
            controls.add(Box.createHorizontalStrut(20));
            controls.add(backBtn);
            add(controls, BorderLayout.SOUTH);

            refreshTable();
        }

        void refreshTable() {
            SwingUtilities.invokeLater(() -> {
                try {
                    List<Question> list = DB.listQuestions();
                    tableModel.setRowCount(0);
                    for (Question q : list) {
                        tableModel.addRow(new Object[]{q.id, q.question, q.optA, q.optB, q.optC, q.optD, String.valueOf(q.correct)});
                    }
                } catch (SQLException ex) {
                    JOptionPane.showMessageDialog(frame, "Failed to load questions: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                }
            });
        }

        private void showAddDialog() {
            Question q = showQuestionEditor(null);
            if (q != null) {
                try {
                    DB.addQuestion(q);
                    refreshTable();
                } catch (SQLException ex) {
                    JOptionPane.showMessageDialog(frame, "Failed to add: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                }
            }
        }

        private void showEditDialog() {
            int r = table.getSelectedRow();
            if (r == -1) { JOptionPane.showMessageDialog(frame, "Select a row first."); return; }
            Question q = new Question();
            q.id = (int) tableModel.getValueAt(r, 0);
            q.question = (String) tableModel.getValueAt(r, 1);
            q.optA = (String) tableModel.getValueAt(r, 2);
            q.optB = (String) tableModel.getValueAt(r, 3);
            q.optC = (String) tableModel.getValueAt(r, 4);
            q.optD = (String) tableModel.getValueAt(r, 5);
            q.correct = ((String) tableModel.getValueAt(r, 6)).charAt(0);

            Question edited = showQuestionEditor(q);
            if (edited != null) {
                try {
                    DB.updateQuestion(edited);
                    refreshTable();
                } catch (SQLException ex) {
                    JOptionPane.showMessageDialog(frame, "Failed to update: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                }
            }
        }

        private void deleteSelected() {
            int r = table.getSelectedRow();
            if (r == -1) { JOptionPane.showMessageDialog(frame, "Select a row first."); return; }
            int id = (int) tableModel.getValueAt(r, 0);
            int conf = JOptionPane.showConfirmDialog(frame, "Delete question ID " + id + " ?", "Confirm", JOptionPane.YES_NO_OPTION);
            if (conf == JOptionPane.YES_OPTION) {
                try {
                    DB.deleteQuestion(id);
                    refreshTable();
                } catch (SQLException ex) {
                    JOptionPane.showMessageDialog(frame, "Failed to delete: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                }
            }
        }
    }

    // show dialog for adding/editing question; supply existing to edit or null to add
    private Question showQuestionEditor(Question existing) {
        JTextField qField = new JTextField();
        JTextField aField = new JTextField();
        JTextField bField = new JTextField();
        JTextField cField = new JTextField();
        JTextField dField = new JTextField();
        JComboBox<String> correctCb = new JComboBox<>(new String[]{"A","B","C","D"});

        if (existing != null) {
            qField.setText(existing.question);
            aField.setText(existing.optA);
            bField.setText(existing.optB);
            cField.setText(existing.optC);
            dField.setText(existing.optD);
            correctCb.setSelectedItem(String.valueOf(existing.correct));
        }

        JPanel p = new JPanel(new GridLayout(0,1,6,6));
        p.add(new JLabel("Question:")); p.add(qField);
        p.add(new JLabel("Option A:")); p.add(aField);
        p.add(new JLabel("Option B:")); p.add(bField);
        p.add(new JLabel("Option C:")); p.add(cField);
        p.add(new JLabel("Option D:")); p.add(dField);
        p.add(new JLabel("Correct option:")); p.add(correctCb);

        int res = JOptionPane.showConfirmDialog(frame, p, existing == null ? "Add Question" : "Edit Question", JOptionPane.OK_CANCEL_OPTION);
        if (res == JOptionPane.OK_OPTION) {
            String qtext = qField.getText().trim();
            if (qtext.isEmpty()) { JOptionPane.showMessageDialog(frame, "Question cannot be empty."); return null; }
            Question q = existing == null ? new Question() : existing;
            q.question = qtext;
            q.optA = aField.getText().trim();
            q.optB = bField.getText().trim();
            q.optC = cField.getText().trim();
            q.optD = dField.getText().trim();
            q.correct = ((String) correctCb.getSelectedItem()).charAt(0);
            // Basic validation
            if (q.optA.isEmpty() || q.optB.isEmpty() || q.optC.isEmpty() || q.optD.isEmpty()) {
                JOptionPane.showMessageDialog(frame, "All options must be filled.");
                return null;
            }
            return q;
        }
        return null;
    }

    // ---------- Quiz taker panel ----------
    class QuizPanel extends JPanel {
        private final JTextField nameField = new JTextField();
        private final JSpinner countSpinner = new JSpinner(new SpinnerNumberModel(5, 1, 100, 1));
        private final JButton startBtn = new JButton("Start Quiz");
        private final JButton backBtn = new JButton("Back");
        private final JPanel quizArea = new JPanel(new BorderLayout(6,6));

        // runtime quiz state
        private List<Question> questions = new ArrayList<>();
        private int currentIndex = 0;
        private int correctCount = 0;
        private final ButtonGroup optionsGroup = new ButtonGroup();
        private final JRadioButton optA = new JRadioButton();
        private final JRadioButton optB = new JRadioButton();
        private final JRadioButton optC = new JRadioButton();
        private final JRadioButton optD = new JRadioButton();
        private final JLabel qLabel = new JLabel("", SwingConstants.LEFT);
        private final JButton nextBtn = new JButton("Next");

        QuizPanel() {
            setLayout(new BorderLayout(8,8));
            JLabel lbl = new JLabel("Take Quiz", SwingConstants.CENTER);
            lbl.setFont(new Font("SansSerif", Font.BOLD, 20));
            add(lbl, BorderLayout.NORTH);

            JPanel top = new JPanel(new FlowLayout(FlowLayout.LEFT, 8,8));
            top.add(new JLabel("Player name:")); nameField.setColumns(16);
            top.add(nameField);
            top.add(new JLabel("Number of questions (1..):")); top.add(countSpinner);
            top.add(startBtn);
            top.add(backBtn);
            add(top, BorderLayout.SOUTH);

            quizArea.setBorder(BorderFactory.createEmptyBorder(12,12,12,12));
            add(quizArea, BorderLayout.CENTER);

            startBtn.addActionListener(e -> startQuiz());
            backBtn.addActionListener(e -> {
                cardLayout.show(cards, "MAIN");
            });

            // quiz question layout
            JPanel qpanel = new JPanel(new BorderLayout(6,6));
            qLabel.setVerticalAlignment(SwingConstants.TOP);
            qLabel.setFont(new Font("SansSerif", Font.PLAIN, 16));
            qpanel.add(qLabel, BorderLayout.NORTH);

            JPanel opts = new JPanel(new GridLayout(4,1,6,6));
            optionsGroup.add(optA); optionsGroup.add(optB); optionsGroup.add(optC); optionsGroup.add(optD);
            opts.add(optA); opts.add(optB); opts.add(optC); opts.add(optD);
            qpanel.add(opts, BorderLayout.CENTER);

            JPanel bottom = new JPanel(new FlowLayout(FlowLayout.RIGHT));
            bottom.add(nextBtn);

            quizArea.setLayout(new BorderLayout());
            quizArea.add(qpanel, BorderLayout.CENTER);
            quizArea.add(bottom, BorderLayout.SOUTH);

            nextBtn.addActionListener(e -> nextQuestion());
            setQuizInactive();
        }

        void prepareAndShow() {
            // reset fields
            nameField.setText("");
            int totalQ = 1;
            try { totalQ = DB.listQuestions().size(); } catch (SQLException ignored) {}
            countSpinner.setModel(new SpinnerNumberModel(Math.min(5, Math.max(1, totalQ)), 1, Math.max(1, totalQ), 1));
            optionsGroup.clearSelection();
            setQuizInactive();
        }

        private void setQuizInactive() {
            quizArea.setVisible(false);
            nextBtn.setEnabled(false);
        }

        private void setQuizActive() {
            quizArea.setVisible(true);
            nextBtn.setEnabled(true);
        }

        private void startQuiz() {
            String player = nameField.getText().trim();
            if (player.isEmpty()) {
                JOptionPane.showMessageDialog(frame, "Enter your name first.");
                return;
            }
            int count = (int) countSpinner.getValue();
            try {
                List<Question> all = DB.listQuestions();
                if (all.isEmpty()) { JOptionPane.showMessageDialog(frame, "No questions available. Ask admin to add questions."); return; }
                questions = pickRandom(all, Math.min(count, all.size()));
                currentIndex = 0;
                correctCount = 0;
                showCurrentQuestion();
                setQuizActive();
            } catch (SQLException ex) {
                JOptionPane.showMessageDialog(frame, "Failed to load questions: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            }
        }

        private List<Question> pickRandom(List<Question> list, int k) {
            Random rnd = new Random();
            List<Question> copy = new ArrayList<>(list);
            List<Question> picked = new ArrayList<>();
            for (int i = 0; i < k; i++) {
                int idx = rnd.nextInt(copy.size());
                picked.add(copy.remove(idx));
            }
            return picked;
        }

        private void showCurrentQuestion() {
            Question q = questions.get(currentIndex);
            qLabel.setText("<html><b>Q" + (currentIndex + 1) + ".</b> " + q.question + "</html>");
            optA.setText("A. " + q.optA); optB.setText("B. " + q.optB); optC.setText("C. " + q.optC); optD.setText("D. " + q.optD);
            optionsGroup.clearSelection();
            if (currentIndex == questions.size() - 1) nextBtn.setText("Finish");
            else nextBtn.setText("Next");
        }

        private void nextQuestion() {
            // evaluate current selection
            Question q = questions.get(currentIndex);
            char selected = 'X';
            if (optA.isSelected()) selected = 'A';
            if (optB.isSelected()) selected = 'B';
            if (optC.isSelected()) selected = 'C';
            if (optD.isSelected()) selected = 'D';
            if (selected == q.correct) correctCount++;

            currentIndex++;
            if (currentIndex >= questions.size()) {
                finishQuiz();
            } else {
                showCurrentQuestion();
            }
        }

        private void finishQuiz() {
            setQuizInactive();
            String player = nameField.getText().trim();
            int total = questions.size();
            try {
                DB.saveScore(player, correctCount, total);
            } catch (SQLException ex) {
                JOptionPane.showMessageDialog(frame, "Failed to save score: " + ex.getMessage(), "Warning", JOptionPane.WARNING_MESSAGE);
            }
            JOptionPane.showMessageDialog(frame, String.format("Quiz finished!\nPlayer: %s\nScore: %d/%d", player, correctCount, total));
            cardLayout.show(cards, "MAIN");
        }
    }
}
