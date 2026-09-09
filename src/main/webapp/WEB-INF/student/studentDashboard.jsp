<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.mycompany.mlms_system.database.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.List"%>

<%
    if (session.getAttribute("userToken") == null || !"STUDENT".equalsIgnoreCase((String) session.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    int currentStudentId = (Integer) session.getAttribute("userId");
    String currentStudentName = (String) session.getAttribute("userName");
    if (currentStudentName == null) currentStudentName = "Student";

    class SubjectMetric {
        String labCode;
        String courseCode;
        String subjectName;
        int presentCount = 0;
        int lateCount = 0;
        int absentCount = 0;
        int mcCount = 0;
        int totalTarget;
        
        SubjectMetric(String code, String course, String name, int target) {
            this.labCode = code;
            this.courseCode = course;
            this.subjectName = name;
            this.totalTarget = target;
        }

        int getAttendedTotal() {
            return presentCount + lateCount;
        }

        int getPercentage() {
            return totalTarget > 0 ? (int)(((double)getAttendedTotal() / totalTarget) * 100) : 0;
        }
    }

    Connection conn = null;
    PreparedStatement stmtStream = null;
    ResultSet rsStream = null;
    PreparedStatement stmtMetrics = null;
    ResultSet rsMetrics = null;

    String currentStream = (String) session.getAttribute("userDisplayRole");
    List<SubjectMetric> subjectList = new ArrayList<>();

    try {
        conn = DBConnection.getConnection();

        // Fetch exact student stream from Student table if not yet resolved
        if (currentStream == null || "STUDENT".equalsIgnoreCase(currentStream) || "Computer Science Student".equalsIgnoreCase(currentStream)) {
            String fetchStreamSQL = "SELECT studentStream FROM Student WHERE userId = ?";
            stmtStream = conn.prepareStatement(fetchStreamSQL);
            stmtStream.setInt(1, currentStudentId);
            rsStream = stmtStream.executeQuery();
            if (rsStream.next()) {
                currentStream = rsStream.getString("studentStream");
                session.setAttribute("userDisplayRole", currentStream);
            } else {
                currentStream = "Science Stream"; // Fallback stream
            }
        }

        // Filter subjects strictly between Engineering and Science with updated foundation names
        if ("Engineering Stream".equalsIgnoreCase(currentStream)) {
            subjectList.add(new SubjectMetric("LAB_PHYS_01", "PHY401", "Foundation of Physics", 10));
            subjectList.add(new SubjectMetric("LAB_CS_04", "CSC520", "Foundation of Computer Science", 12));
            subjectList.add(new SubjectMetric("LAB_CHEM_01", "CHM421", "Foundation of Chemistry", 10));
        } else {
            // Science Stream (Default)
            currentStream = "Science Stream";
            subjectList.add(new SubjectMetric("LAB_BIO_01", "BIO411", "Foundation of Biology", 10));
            subjectList.add(new SubjectMetric("LAB_PHYS_01", "PHY401", "Foundation of Physics", 10));
            subjectList.add(new SubjectMetric("LAB_CHEM_01", "CHM421", "Foundation of Chemistry", 10));
        }

        // Query status breakdown per lab for this student
        String metricsSQL = "SELECT b.labId, a.status, COUNT(a.logId) AS status_count " +
                            "FROM AttendanceLog a " +
                            "JOIN Booking b ON a.bookingId = b.bookingId " +
                            "WHERE a.studentId = ? " +
                            "GROUP BY b.labId, a.status";
        
        stmtMetrics = conn.prepareStatement(metricsSQL);
        stmtMetrics.setInt(1, currentStudentId);
        rsMetrics = stmtMetrics.executeQuery();

        while (rsMetrics.next()) {
            String dbLabId = rsMetrics.getString("labId");
            String status = rsMetrics.getString("status");
            int count = rsMetrics.getInt("status_count");

            for (SubjectMetric metric : subjectList) {
                if (metric.labCode.equalsIgnoreCase(dbLabId) || 
                   (metric.labCode.equals("LAB_PHYS_01") && "LAB_PHY_01".equalsIgnoreCase(dbLabId))) {
                    if ("PRESENT".equalsIgnoreCase(status) || "COMPLETED".equalsIgnoreCase(status) || "AUTO_CLOSED".equalsIgnoreCase(status)) {
                        metric.presentCount += count;
                    } else if ("LATE".equalsIgnoreCase(status)) {
                        metric.lateCount += count;
                    } else if ("ABSENT".equalsIgnoreCase(status)) {
                        metric.absentCount += count;
                    } else if ("MC".equalsIgnoreCase(status)) {
                        metric.mcCount += count;
                    }
                }
            }
        }

    } catch (SQLException e) {
        e.printStackTrace();
    } finally {
        try { if (rsStream != null) rsStream.close(); } catch (SQLException e) {}
        try { if (stmtStream != null) stmtStream.close(); } catch (SQLException e) {}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Student Workspace | MLMS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-purple: #6c5ce7;
            --dark-purple: #4834d4;
            --main-bg: #f8f9fd;
            --text-dark: #2d3436;
            --text-muted: #718096;
            --border-color: #e2e8f0;
            --white: #ffffff;
            --uitm-blue: #3498db;
            
            --present-green: #10b981;
            --late-orange: #f59e0b;
            --absent-red: #ef4444;
            --mc-blue: #3b82f6;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Inter', -apple-system, sans-serif; background-color: var(--main-bg); color: var(--text-dark); min-height: 100vh; padding-bottom: 90px; }
        
        main { padding: 24px 16px; max-width: 800px; margin: 0 auto 90px auto; width: 100%; box-sizing: border-box; }

        .header-banner {
            display: flex; justify-content: space-between; align-items: center;
            background: var(--white); padding: 14px 18px; border-radius: 12px;
            border: 1px solid var(--border-color); margin-bottom: 24px;
        }
        .brand-logo { font-size: 20px; font-weight: 800; letter-spacing: 0.5px; color: var(--text-dark); }
        .brand-logo span { color: var(--primary-purple); }
        .user-profile-badge { font-size: 13px; font-weight: 600; background: #f1f5f9; padding: 6px 14px; border-radius: 20px; color: #475569; }

        .dashboard-panel {
            background-color: var(--white); border-radius: 14px; border: 1px solid var(--border-color);
            padding: 22px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.01); margin-bottom: 24px;
        }
        .panel-header { font-size: 16px; font-weight: 700; margin-bottom: 18px; color: var(--text-dark); border-bottom: 1px solid var(--main-bg); padding-bottom: 10px; }

        .stream-tag {
            display: inline-block;
            background: #ede9fe;
            color: var(--primary-purple);
            font-size: 12px;
            font-weight: 700;
            padding: 4px 10px;
            border-radius: 8px;
            margin-bottom: 16px;
        }

        .subject-grid { display: grid; grid-template-columns: 1fr; gap: 16px; }
        @media (min-width: 640px) {
            .subject-grid { grid-template-columns: 1fr 1fr; }
        }

        .subject-card {
            background: #ffffff; border: 1px solid var(--border-color);
            border-radius: 14px; padding: 18px; display: flex; flex-direction: column; justify-content: space-between;
            box-shadow: 0 2px 4px rgba(0,0,0,0.02); transition: transform 0.15s ease, border-color 0.15s ease;
        }
        .subject-card:hover { border-color: var(--primary-purple); }

        .subject-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 10px; }
        .subject-code { font-family: 'JetBrains Mono', monospace; font-size: 11px; font-weight: 700; background: #f1f5f9; color: #475569; padding: 3px 8px; border-radius: 6px; }
        .subject-title { font-size: 14.5px; font-weight: 700; color: #1e293b; line-height: 1.3; margin-top: 4px; }
        
        .ratio-badge { font-size: 12px; font-weight: 700; color: #475569; }
        
        .progress-track { width: 100%; height: 8px; background-color: #e2e8f0; border-radius: 999px; overflow: hidden; margin: 12px 0; }
        .progress-fill { height: 100%; border-radius: 999px; transition: width 0.6s ease; }

        .status-pill-row {
            display: grid; grid-template-columns: repeat(4, 1fr); gap: 6px;
            margin-top: 8px; padding-top: 10px; border-top: 1px dashed var(--border-color);
            text-align: center;
        }
        .status-pill-item { display: flex; flex-direction: column; }
        .status-pill-num { font-size: 13px; font-weight: 700; font-family: 'JetBrains Mono', monospace; }
        .status-pill-label { font-size: 9.5px; font-weight: 600; text-transform: uppercase; color: var(--text-muted); }

        .bottom-nav {
            position: fixed; bottom: 0; left: 0; right: 0; height: 70px;
            background-color: var(--white); border-top: 1px solid var(--border-color);
            display: flex; justify-content: space-around; align-items: center; z-index: 999;
            box-shadow: 0 -4px 10px rgba(0, 0, 0, 0.03);
        }
        .nav-item { display: flex; flex-direction: column; align-items: center; justify-content: center; color: #718096; text-decoration: none; font-size: 11px; font-weight: 500; width: 80px; }
        .nav-item.active, .nav-item:hover { color: var(--primary-purple); font-weight: 700; }
        .nav-item svg { width: 22px; height: 22px; margin-bottom: 4px; fill: currentColor; }
        .qr-center-wrapper { position: relative; height: 100%; display: flex; align-items: center; justify-content: center; width: 80px; }
        .qr-btn-circle {
            width: 60px; height: 60px; background: linear-gradient(135deg, #3498db, #2980b9);
            border-radius: 50%; display: flex; align-items: center; justify-content: center;
            position: absolute; top: -22px; box-shadow: 0 4px 12px rgba(52, 152, 219, 0.35);
            border: 4px solid var(--white); color: var(--white); text-decoration: none;
        }
        .qr-btn-circle svg { width: 26px; height: 26px; fill: none; stroke: currentColor; stroke-width: 2.5; }
        .qr-label { margin-top: 44px; font-size: 11px; font-weight: 600; color: var(--uitm-blue); }

        table { width: 100%; border-collapse: collapse; text-align: left; }
        th, td { padding: 12px 10px; font-size: 13.5px; border-bottom: 1px solid var(--border-color); }
        th { color: #718096; font-weight: 600; background-color: #f8fafc; font-size: 11px; text-transform: uppercase; }
        .status-pill { padding: 3px 8px; border-radius: 12px; font-size: 11px; font-weight: 700; background-color: #e6fffa; color: #319795; }
    </style>
</head>
<body>

    <main>
        <!-- Header -->
        <div class="header-banner">
            <div class="brand-logo">MLMS<span>.Workspace</span></div>
            <div style="display: flex; align-items: center; gap: 10px;">
                <div class="user-profile-badge">👤 <%= currentStudentName %></div>
                <a href="<%= request.getContextPath() %>/login.jsp" 
                   style="font-size: 12.5px; font-weight: 700; color: #ef4444; text-decoration: none; background: #fdf2f2; border: 1px solid #fbd5d5; padding: 6px 12px; border-radius: 20px; transition: all 0.2s ease;"
                   onclick="return confirm('Are you sure you want to sign out?');">
                    🚪 Sign Out
                </a>
            </div>
        </div>

        <div class="stream-tag">🎓 <%= currentStream %></div>

        <h2 style="margin: 0 0 4px 0; font-size: 20px; font-weight: 800;">Registered Syllabus Labs</h2>
        <p style="color: #718096; margin: 0 0 24px 0; font-size: 13.5px;">Detailed progress metrics and quota verification tailored to your academic stream.</p>

        <!-- Dynamic Filtered Subject Cards -->
        <div class="subject-grid" style="margin-bottom: 24px;">
            <%
                for (SubjectMetric sub : subjectList) {
                    int percent = sub.getPercentage();
                    String barColor = percent >= 80 ? "var(--present-green)" : (percent >= 50 ? "var(--late-orange)" : "var(--absent-red)");
            %>
                <div class="subject-card">
                    <div>
                        <div class="subject-top">
                            <span class="subject-code"><%= sub.courseCode %> &bull; <%= sub.labCode %></span>
                            <span class="ratio-badge"><%= sub.getAttendedTotal() %> / <%= sub.totalTarget %> Sessions</span>
                        </div>
                        <h3 class="subject-title"><%= sub.subjectName %></h3>
                        
                        <!-- Progress Bar & Percentage -->
                        <div class="progress-track">
                            <div class="progress-fill" style="width: <%= percent %>%; background-color: <%= barColor %>;"></div>
                        </div>
                        <div style="display: flex; justify-content: space-between; font-size: 11.5px; color: var(--text-muted); font-weight: 600;">
                            <span>Attendance Compliance</span>
                            <span style="color: <%= barColor %>; font-weight: 700;"><%= percent %>%</span>
                        </div>
                    </div>

                    <!-- Individual Counters -->
                    <div class="status-pill-row">
                        <div class="status-pill-item">
                            <span class="status-pill-num" style="color: var(--present-green);"><%= sub.presentCount %></span>
                            <span class="status-pill-label">Present</span>
                        </div>
                        <div class="status-pill-item">
                            <span class="status-pill-num" style="color: var(--late-orange);"><%= sub.lateCount %></span>
                            <span class="status-pill-label">Late</span>
                        </div>
                        <div class="status-pill-item">
                            <span class="status-pill-num" style="color: var(--absent-red);"><%= sub.absentCount %></span>
                            <span class="status-pill-label">Absent</span>
                        </div>
                        <div class="status-pill-item">
                            <span class="status-pill-num" style="color: var(--mc-blue);"><%= sub.mcCount %></span>
                            <span class="status-pill-label">MC</span>
                        </div>
                    </div>
                </div>
            <%
                }
            %>
        </div>

        <!-- Recent Verification Logs -->
        <div class="dashboard-panel">
            <div class="panel-header">Recent Session Verifications</div>
            <div style="overflow-x: auto;">
                <table>
                    <thead>
                        <tr><th>Date</th><th>Lab Allocation</th><th>Status</th></tr>
                    </thead>
                    <tbody>
                    <%
                        PreparedStatement stmtLogs = null;
                        ResultSet rsLogs = null;
                        try {
                            String logsSQL = "SELECT DATE_FORMAT(a.entryTime, '%d/%m/%Y') AS formatted_date, b.labId, a.status " +
                                             "FROM AttendanceLog a " +
                                             "JOIN Booking b ON a.bookingId = b.bookingId " +
                                             "WHERE a.studentId = ? " +
                                             "ORDER BY a.entryTime DESC LIMIT 5";
                            
                            stmtLogs = conn.prepareStatement(logsSQL);
                            stmtLogs.setInt(1, currentStudentId);
                            rsLogs = stmtLogs.executeQuery();

                            boolean recordsFound = false;
                            while (rsLogs.next()) {
                                recordsFound = true;
                                String logDate = rsLogs.getString("formatted_date");
                                String rawLabId = rsLogs.getString("labId");
                                String status = rsLogs.getString("status");
                    %>
                        <tr>
                            <td><%= logDate %></td>
                            <td><%= rawLabId %></td>
                            <td><span class="status-pill"><%= status %></span></td>
                        </tr>
                    <%
                            }
                            if (!recordsFound) {
                    %>
                        <tr><td colspan="3" style="text-align: center; color: var(--text-muted); padding: 18px;">No attendance records found.</td></tr>
                    <%
                            }
                        } catch (SQLException e) {
                            e.printStackTrace();
                        } finally {
                            try { if (rsLogs != null) rsLogs.close(); } catch (SQLException e) {}
                            try { if (stmtLogs != null) stmtLogs.close(); } catch (SQLException e) {}
                            try { if (rsMetrics != null) rsMetrics.close(); } catch (SQLException e) {}
                            try { if (stmtMetrics != null) stmtMetrics.close(); } catch (SQLException e) {}
                            try { if (conn != null) conn.close(); } catch (SQLException e) {}
                        }
                    %>
                    </tbody>
                </table>
            </div>
        </div>
    </main>

    <!-- Bottom App Navigation Bar -->
    <nav class="bottom-nav">
        <a href="<%= request.getContextPath() %>/student/dashboard" class="nav-item active">
            <svg viewBox="0 0 24 24"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>
            <span>Workspace</span>
        </a>
        <div class="qr-center-wrapper">
            <a href="<%= request.getContextPath() %>/student/scan" class="qr-btn-circle">
                <svg viewBox="0 0 24 24">
                    <path d="M3 7V5a2 2 0 0 1 2-2h2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2" />
                    <rect x="7" y="7" width="3" height="3" style="fill:currentColor; stroke:none;" />
                    <rect x="14" y="7" width="3" height="3" style="fill:currentColor; stroke:none;" />
                    <rect x="7" y="14" width="3" height="3" style="fill:currentColor; stroke:none;" />
                </svg>
            </a>
            <span class="qr-label">Scan QR</span>
        </div>
        <a href="<%= request.getContextPath() %>/student/my-attendance" class="nav-item">
            <svg viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/></svg>
            <span>History Logs</span>
        </a>
    </nav>

</body>
</html>