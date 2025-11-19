/*
 AttendanceSystem.java
 College Attendance System (Swing + SQLite)

 Features:
 - Register students (add/delete/list)
 - Mark attendance per date (present/absent checkboxes)
 - View attendance report (per-student % over date range)
 - Export attendance report as CSV
 - Import students from CSV (simple format: studentId,fullName)
 - Uses SQLite DB file attendance.db in working directory

 How to run with Maven:
  - Place this file in src/main/java in a Maven project (pom.xml provided)
  - mvn compile
  - mvn exec:java -Dexec.mainClass=AttendanceSystem

 Or compile/run with sqlite-jdbc jar on classpath.

 Author: ChatGPT
*/

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.sql.*;
import java.sql.Date;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.List;

public class AttendanceSystem extends JFrame {
    // DB
    private static final String DB_URL = "jdbc:sqlite:attendance.db";

    // UI
    private final DefaultTableModel studentsModel = new DefaultTableModel(new Object[]{"ID", "Full Name"}, 0);
    private final JTable studentsTable = new JTable(studentsModel);

    private final DefaultTableModel attendanceModel = new DefaultTableModel(new Object[]{"ID", "Full Name", "Present"}, 0);
    private final JTable attendanceTable = new JTable(attendanceModel) {
        // make checkbox column editable
        @Override public Class<?> getColumnClass(int column) {
            if (column == 2) return Boolean.class;
            return super.getColumnClass(column);
        }
    };

    // Report model
    private final DefaultTableModel reportModel = new DefaultTableModel(new Object[]{"ID","Full Name","Days Present","Days Total","% Present"}, 0);
    private final JTable reportTable = new JTable(reportModel);

    // Date controls
    private final JSpinner dateSpinner = new JSpinner(new SpinnerDateModel(Date.from(LocalDate.now().atStartOfDay(ZoneId.systemDefault()).toInstant()), null, null, Calendar.DAY_OF_MONTH));
    private final DateTimeFormatter DATE_FMT = DateTimeFormatter.ISO_LOCAL_DATE;

    // report range
    private final JSpinner fromSpinner = new JSpinner(new SpinnerDateModel(Date.from(LocalDate.now().minusMonths(1).atStartOfDay(ZoneId.systemDefault()).toInstant()), null, null, Calendar.DAY_OF_MONTH));
    private final JSpinner toSpinner = new JSpinner(new SpinnerDateModel(Date.from(LocalDate.now().atStartOfDay(ZoneId.systemDefault()).toInstant()), null, null, Calendar.DAY_OF_MONTH));

    public static void main(String[] args) {
        try {
            DB.init();
        } catch (SQLException ex) {
            ex.printStackTrace();
            JOptionPane.showMessageDialog(null, "DB init failed: " + ex.getMessage());
            return;
        }

        SwingUtilities.invokeLater(() -> {
            AttendanceSystem app = new AttendanceSystem();
            app.setVisible(true);
        });
    }

    public AttendanceSystem() {
        setTitle("College Attendance System");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(920, 640);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout(8,8));

        JTabbedPane tabs = new JTabbedPane();
        tabs.add("Students", buildStudentsPanel());
        tabs.add("Mark Attendance", buildAttendancePanel());
        tabs.add("Reports", buildReportsPanel());

        add(tabs, BorderLayout.CENTER);
    }

    // ---------- Students tab ----------
    private JPanel buildStudentsPanel() {
        JPanel p = new JPanel(new BorderLayout(8,8));
        p.setBorder(new EmptyBorder(8,8,8,8));

        JLabel title = new JLabel("Students", SwingConstants.CENTER);
        title.setFont(new Font("SansSerif", Font.BOLD, 18));
        p.add(title, BorderLayout.NORTH);

        JScrollPane sp = new JScrollPane(studentsTable);
        p.add(sp, BorderLayout.CENTER);

        JPanel controls = new JPanel(new FlowLayout(FlowLayout.LEFT, 8,8));
        JTextField idField = new JTextField(8);
        JTextField nameField = new JTextField(20);
        JButton addBtn = new JButton("Add Student");
        JButton deleteBtn = new JButton("Delete Selected");
        JButton importBtn = new JButton("Import CSV");

        controls.add(new JLabel("ID:")); controls.add(idField);
        controls.add(new JLabel("Full name:")); controls.add(nameField);
        controls.add(addBtn); controls.add(deleteBtn);
        controls.add(Box.createHorizontalStrut(10)); controls.add(importBtn);

        p.add(controls, BorderLayout.SOUTH);

        addBtn.addActionListener(e -> {
            String sid = idField.getText().trim();
            String name = nameField.getText().trim();
            if (sid.isEmpty() || name.isEmpty()) {
                JOptionPane.showMessageDialog(this, "Provide both ID and full name.");
                return;
            }
            try {
                DB.addStudent(sid, name);
                refreshStudents();
                idField.setText(""); nameField.setText("");
            } catch (SQLException ex) {
                JOptionPane.showMessageDialog(this, "Failed to add student: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            }
        });

        deleteBtn.addActionListener(e -> {
            int r = studentsTable.getSelectedRow();
            if (r == -1) { JOptionPane.showMessageDialog(this, "Select a student first."); return; }
            String sid = (String) studentsModel.getValueAt(r, 0);
            int conf = JOptionPane.showConfirmDialog(this, "Delete student " + sid + " ? This will remove attendance records.", "Confirm", JOptionPane.YES_NO_OPTION);
            if (conf == JOptionPane.YES_OPTION) {
                try {
                    DB.deleteStudent(sid);
                    refreshStudents();
                } catch (SQLException ex) {
                    JOptionPane.showMessageDialog(this, "Failed to delete: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                }
            }
        });

        importBtn.addActionListener(e -> {
            JFileChooser fc = new JFileChooser();
            int res = fc.showOpenDialog(this);
            if (res == JFileChooser.APPROVE_OPTION) {
                File f = fc.getSelectedFile();
                try {
                    int imported = importStudentsCsv(f.toPath());
                    JOptionPane.showMessageDialog(this, "Imported " + imported + " students (duplicates skipped).");
                    refreshStudents();
                } catch (Exception ex) {
                    JOptionPane.showMessageDialog(this, "Import failed: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                }
            }
        });

        refreshStudents();
        return p;
    }

    // ---------- Attendance tab ----------
    private JPanel buildAttendancePanel() {
        JPanel p = new JPanel(new BorderLayout(8,8));
        p.setBorder(new EmptyBorder(8,8,8,8));

        JLabel title = new JLabel("Mark Attendance", SwingConstants.CENTER);
        title.setFont(new Font("SansSerif", Font.BOLD, 18));
        p.add(title, BorderLayout.NORTH);

        // top controls: date & load
        JPanel top = new JPanel(new FlowLayout(FlowLayout.LEFT, 8,8));
        JSpinner.DateEditor de = new JSpinner.DateEditor(dateSpinner, "yyyy-MM-dd");
        dateSpinner.setEditor(de);
        JButton loadBtn = new JButton("Load For Date");
        JButton saveBtn = new JButton("Save Attendance");

        top.add(new JLabel("Date:")); top.add(dateSpinner);
        top.add(loadBtn);
        top.add(saveBtn);
        p.add(top, BorderLayout.NORTH);

        attendanceTable.setRowHeight(24);
        JScrollPane sp = new JScrollPane(attendanceTable);
        p.add(sp, BorderLayout.CENTER);

        loadBtn.addActionListener(e -> {
            LocalDate date = spinnerToLocalDate(dateSpinner);
            try {
                loadAttendanceForDate(date);
            } catch (SQLException ex) {
                JOptionPane.showMessageDialog(this, "Failed to load: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            }
        });

        saveBtn.addActionListener(e -> {
            LocalDate date = spinnerToLocalDate(dateSpinner);
            try {
                saveAttendanceForDate(date);
                JOptionPane.showMessageDialog(this, "Saved attendance for " + date.format(DATE_FMT));
            } catch (SQLException ex) {
                JOptionPane.showMessageDialog(this, "Failed to save: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            }
        });

        // initially load today's attendance
        try { loadAttendanceForDate(LocalDate.now()); } catch (SQLException ignored) {}
        return p;
    }

    // ---------- Reports tab ----------
    private JPanel buildReportsPanel() {
        JPanel p = new JPanel(new BorderLayout(8,8));
        p.setBorder(new EmptyBorder(8,8,8,8));

        JLabel title = new JLabel("Attendance Reports", SwingConstants.CENTER);
        title.setFont(new Font("SansSerif", Font.BOLD, 18));
        p.add(title, BorderLayout.NORTH);

        JPanel controls = new JPanel(new FlowLayout(FlowLayout.LEFT, 8,8));
        JSpinner.DateEditor fe = new JSpinner.DateEditor(fromSpinner, "yyyy-MM-dd");
        JSpinner.DateEditor te = new JSpinner.DateEditor(toSpinner, "yyyy-MM-dd");
        fromSpinner.setEditor(fe);
        toSpinner.setEditor(te);

        JButton genBtn = new JButton("Generate Report");
        JButton exportBtn = new JButton("Export CSV");

        controls.add(new JLabel("From:")); controls.add(fromSpinner);
        controls.add(new JLabel("To:")); controls.add(toSpinner);
        controls.add(genBtn); controls.add(exportBtn);

        p.add(controls, BorderLayout.NORTH);

        reportTable.setRowHeight(24);
        JScrollPane sp = new JScrollPane(reportTable);
        p.add(sp, BorderLayout.CENTER);

        genBtn.addActionListener(e -> {
            LocalDate a = spinnerToLocalDate(fromSpinner);
            LocalDate b = spinnerToLocalDate(toSpinner);
            if (b.isBefore(a)) { JOptionPane.showMessageDialog(this, "Invalid range: To must be >= From."); return; }
            try {
                generateReport(a,b);
            } catch (SQLException ex) {
                JOptionPane.showMessageDialog(this, "Failed to generate: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            }
        });

        exportBtn.addActionListener(e -> {
            if (reportModel.getRowCount() == 0) { JOptionPane.showMessageDialog(this, "Generate report first."); return; }
            JFileChooser fc = new JFileChooser();
            fc.setSelectedFile(new File("attendance_report_" + LocalDate.now().format(DATE_FMT) + ".csv"));
            int res = fc.showSaveDialog(this);
            if (res == JFileChooser.APPROVE_OPTION) {
                try {
                    Path out = fc.getSelectedFile().toPath();
                    exportReportCsv(out);
                    JOptionPane.showMessageDialog(this, "Exported CSV to " + out);
                } catch (IOException ex) {
                    JOptionPane.showMessageDialog(this, "Export failed: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                }
            }
        });

        // generate default last 30 days
        fromSpinner.setValue(Date.from(LocalDate.now().minusDays(30).atStartOfDay(ZoneId.systemDefault()).toInstant()));
        toSpinner.setValue(Date.from(LocalDate.now().atStartOfDay(ZoneId.systemDefault()).toInstant()));
        try { generateReport(LocalDate.now().minusDays(30), LocalDate.now()); } catch (SQLException ignored) {}

        return p;
    }

    // ---------- Data / DB interactions ----------
    static class DB {
        static void init() throws SQLException {
            try (Connection c = DriverManager.getConnection(DB_URL)) {
                try (Statement s = c.createStatement()) {
                    s.execute("PRAGMA foreign_keys = ON;");
                    s.execute("CREATE TABLE IF NOT EXISTS students (" +
                            "student_id TEXT PRIMARY KEY, full_name TEXT NOT NULL);");
                    s.execute("CREATE TABLE IF NOT EXISTS attendance (" +
                            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                            "student_id TEXT NOT NULL," +
                            "att_date TEXT NOT NULL," + // ISO date
                            "present INTEGER NOT NULL," +
                            "UNIQUE(student_id, att_date)," +
                            "FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE);");
                }
            }
        }

        static List<String[]> listStudents() throws SQLException {
            List<String[]> out = new ArrayList<>();
            try (Connection c = DriverManager.getConnection(DB_URL);
                 PreparedStatement ps = c.prepareStatement("SELECT student_id, full_name FROM students ORDER BY full_name")) {
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) out.add(new String[]{rs.getString(1), rs.getString(2)});
                }
            }
            return out;
        }

        static void addStudent(String id, String name) throws SQLException {
            try (Connection c = DriverManager.getConnection(DB_URL);
                 PreparedStatement ps = c.prepareStatement("INSERT INTO students(student_id, full_name) VALUES(?,?)")) {
                ps.setString(1, id);
                ps.setString(2, name);
                ps.executeUpdate();
            }
        }

        static void deleteStudent(String id) throws SQLException {
            try (Connection c = DriverManager.getConnection(DB_URL);
                 PreparedStatement ps = c.prepareStatement("DELETE FROM students WHERE student_id = ?")) {
                ps.setString(1, id);
                ps.executeUpdate();
            }
        }

        static Map<String, Boolean> loadAttendanceForDate(LocalDate date) throws SQLException {
            Map<String, Boolean> map = new HashMap<>();
            try (Connection c = DriverManager.getConnection(DB_URL);
                 PreparedStatement ps = c.prepareStatement("SELECT student_id, present FROM attendance WHERE att_date = ?")) {
                ps.setString(1, date.toString());
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) map.put(rs.getString(1), rs.getInt(2) == 1);
                }
            }
            return map;
        }

        static void saveAttendance(LocalDate date, Map<String, Boolean> data) throws SQLException {
            try (Connection c = DriverManager.getConnection(DB_URL)) {
                c.setAutoCommit(false);
                try (PreparedStatement upsert = c.prepareStatement("INSERT INTO attendance(student_id, att_date, present) VALUES(?,?,?) ON CONFLICT(student_id,att_date) DO UPDATE SET present=excluded.present")) {
                    for (Map.Entry<String, Boolean> e : data.entrySet()) {
                        upsert.setString(1, e.getKey());
                        upsert.setString(2, date.toString());
                        upsert.setInt(3, e.getValue() ? 1 : 0);
                        upsert.addBatch();
                    }
                    upsert.executeBatch();
                }
                c.commit();
            }
        }

        static List<String[]> attendanceCounts(LocalDate from, LocalDate to) throws SQLException {
            // returns list of [student_id, full_name, presentCount, totalDays]
            List<String[]> out = new ArrayList<>();
            String sql = "SELECT s.student_id, s.full_name, " +
                    "SUM(CASE WHEN a.present=1 THEN 1 ELSE 0 END) as present_count, " +
                    "COUNT(a.att_date) as total_days " +
                    "FROM students s LEFT JOIN attendance a ON s.student_id=a.student_id AND a.att_date BETWEEN ? AND ? " +
                    "GROUP BY s.student_id, s.full_name ORDER BY s.full_name";
            try (Connection c = DriverManager.getConnection(DB_URL);
                 PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, from.toString());
                ps.setString(2, to.toString());
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        out.add(new String[]{rs.getString(1), rs.getString(2), String.valueOf(rs.getInt(3)), String.valueOf(rs.getInt(4))});
                    }
                }
            }
            return out;
        }

        static void importStudents(List<String[]> rows) throws SQLException {
            try (Connection c = DriverManager.getConnection(DB_URL)) {
                c.setAutoCommit(false);
                try (PreparedStatement ps = c.prepareStatement("INSERT OR IGNORE INTO students(student_id, full_name) VALUES(?,?)")) {
                    for (String[] r : rows) {
                        ps.setString(1, r[0]);
                        ps.setString(2, r[1]);
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }
                c.commit();
            }
        }
    }

    // ---------- utility & UI-refresh methods ----------
    private void refreshStudents() {
        SwingUtilities.invokeLater(() -> {
            studentsModel.setRowCount(0);
            try {
                List<String[]> list = DB.listStudents();
                for (String[] r : list) studentsModel.addRow(new Object[]{r[0], r[1]});
            } catch (SQLException ex) {
                JOptionPane.showMessageDialog(this, "Failed to load students: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            }
        });
    }

    private void loadAttendanceForDate(LocalDate date) throws SQLException {
        attendanceModel.setRowCount(0);
        List<String[]> studs = DB.listStudents();
        Map<String, Boolean> existing = DB.loadAttendanceForDate(date);
        for (String[] s : studs) {
            boolean pres = existing.getOrDefault(s[0], false);
            attendanceModel.addRow(new Object[]{s[0], s[1], pres});
        }
    }

    private void saveAttendanceForDate(LocalDate date) throws SQLException {
        Map<String, Boolean> m = new HashMap<>();
        for (int r = 0; r < attendanceModel.getRowCount(); r++) {
            String sid = (String) attendanceModel.getValueAt(r, 0);
            Boolean pres = (Boolean) attendanceModel.getValueAt(r, 2);
            m.put(sid, pres != null && pres);
        }
        DB.saveAttendance(date, m);
    }

    private void generateReport(LocalDate from, LocalDate to) throws SQLException {
        reportModel.setRowCount(0);
        List<String[]> rows = DB.attendanceCounts(from, to);
        for (String[] r : rows) {
            int present = Integer.parseInt(r[2]);
            int total = Integer.parseInt(r[3]);
            double pct = total == 0 ? 0.0 : (present * 100.0) / total;
            reportModel.addRow(new Object[]{r[0], r[1], present, total, String.format("%.1f", pct)});
        }
    }

    private void exportReportCsv(Path out) throws IOException {
        // header
        List<String> lines = new ArrayList<>();
        lines.add("student_id,full_name,days_present,days_total,percent_present");
        for (int r = 0; r < reportModel.getRowCount(); r++) {
            String sid = String.valueOf(reportModel.getValueAt(r,0));
            String name = String.valueOf(reportModel.getValueAt(r,1));
            String present = String.valueOf(reportModel.getValueAt(r,2));
            String total = String.valueOf(reportModel.getValueAt(r,3));
            String pct = String.valueOf(reportModel.getValueAt(r,4));
            String line = String.format("%s,%s,%s,%s,%s", quoteCsv(sid), quoteCsv(name), present, total, pct);
            lines.add(line);
        }
        Files.write(out, lines, StandardCharsets.UTF_8);
    }

    private static String quoteCsv(String s) {
        if (s.contains(",") || s.contains("\"")) {
            return "\"" + s.replace("\"", "\"\"") + "\"";
        }
        return s;
    }

    private static LocalDate spinnerToLocalDate(JSpinner spinner) {
        Date d = (Date) spinner.getValue();
        return d.toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
    }

    private int importStudentsCsv(Path path) throws IOException, SQLException {
        List<String> lines = Files.readAllLines(path, StandardCharsets.UTF_8);
        List<String[]> rows = new ArrayList<>();
        for (String line : lines) {
            line = line.trim();
            if (line.isEmpty()) continue;
            // support optional header — assume if non-numeric ID skip? keep simple: split by comma and take first two
            String[] parts = line.split(",", 2);
            if (parts.length < 2) continue;
            String id = parts[0].trim();
            String name = parts[1].trim();
            if (id.isEmpty() || name.isEmpty()) continue;
            rows.add(new String[]{id, name});
        }
        DB.importStudents(rows);
        return rows.size();
    }

    // ---------- sample CSV & init SQL as text (for convenience) ----------
    // sample_students.csv content:
    // student01,Anita Sharma
    // student02,Rajendra Saha
    // student03,Arun Kumar

    // init.sql content:
    // CREATE TABLE students(student_id TEXT PRIMARY KEY, full_name TEXT NOT NULL);
    // CREATE TABLE attendance(id INTEGER PRIMARY KEY AUTOINCREMENT, student_id TEXT, att_date TEXT, present INTEGER, UNIQUE(student_id, att_date));
}
