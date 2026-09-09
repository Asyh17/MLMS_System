<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.mycompany.mlms_system.database.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.List"%>

<%
    if (session.getAttribute("userToken") == null || !"LECTURER".equals(session.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    Integer currentLecturerIdObj = (Integer) session.getAttribute("userId");
    if (currentLecturerIdObj == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    int currentLecturerId = currentLecturerIdObj;
    String currentLecturerName = (String) session.getAttribute("userName");
    if (currentLecturerName == null) currentLecturerName = "Lecturer";

    Connection conn = null;
    List<String> sessionLabels = new ArrayList<>();
    List<Integer> attendanceRates = new ArrayList<>();

    String activeBookingId = null;
    String activeLabCode = null;
    String activeLabName = "No Upcoming Department Session";
    String activeTimeSlot = "—";
    String activeDate = "—";
    boolean hasActiveSession = false;
    String lecturerDept = "";

    try {
        conn = DBConnection.getConnection();

        // Fetch lecturer's assigned department
        String deptSQL = "SELECT department FROM lecturer WHERE userId = ?";
        try (PreparedStatement psDept = conn.prepareStatement(deptSQL)) {
            psDept.setInt(1, currentLecturerId);
            try (ResultSet rsDept = psDept.executeQuery()) {
                if (rsDept.next()) {
                    lecturerDept = rsDept.getString("department");
                }
            }
        }
        if (lecturerDept == null) lecturerDept = "";

        // Fetch the earliest upcoming/ongoing session matching their department lab
        String activeSessionSQL = "SELECT b.bookingId, b.labId, DATE_FORMAT(b.bookingDate, '%d/%m/%Y') AS b_date, b.timeSlot " +
                                  "FROM Booking b " +
                                  "WHERE b.lecturerId = ? AND LOWER(b.status) = 'approved' " +
                                  "AND ( " +
                                  "    (? LIKE '%Computer Science%' AND b.labId = 'LAB_CS_04') OR " +
                                  "    (? LIKE '%Physics%' AND b.labId = 'LAB_PHYS_01') OR " +
                                  "    (? LIKE '%Chemistry%' AND b.labId = 'LAB_CHEM_01') OR " +
                                  "    (? LIKE '%Biology%' AND b.labId = 'LAB_BIO_01') " +
                                  ") " +
                                  "AND (b.bookingDate > CURRENT_DATE() OR (b.bookingDate = CURRENT_DATE() AND ADDTIME(b.timeSlot, '02:00:00') >= CURRENT_TIME())) " +
                                  "ORDER BY b.bookingDate ASC, b.timeSlot ASC LIMIT 1";

        try (PreparedStatement stmtActive = conn.prepareStatement(activeSessionSQL)) {
            stmtActive.setInt(1, currentLecturerId);
            stmtActive.setString(2, lecturerDept);
            stmtActive.setString(3, lecturerDept);
            stmtActive.setString(4, lecturerDept);
            stmtActive.setString(5, lecturerDept);

            try (ResultSet rsActive = stmtActive.executeQuery()) {
                if (rsActive.next()) {
                    hasActiveSession = true;
                    activeBookingId = rsActive.getString("bookingId");
                    activeLabCode = rsActive.getString("labId");
                    activeDate = rsActive.getString("b_date");
                    String rawSlot = rsActive.getString("timeSlot");

                    if ("LAB_CS_04".equalsIgnoreCase(activeLabCode)) activeLabName = "Computer Science Lab (CS 04)";
                    else if ("LAB_PHYS_01".equalsIgnoreCase(activeLabCode)) activeLabName = "Physics Lab (Advanced Mechanics)";
                    else if ("LAB_CHEM_01".equalsIgnoreCase(activeLabCode)) activeLabName = "Chemistry Lab (Organic Molecular)";
                    else if ("LAB_BIO_01".equalsIgnoreCase(activeLabCode)) activeLabName = "Biology Lab (Genetics & Micro)";
                    else activeLabName = activeLabCode;

                    if ("10:00:00".equals(rawSlot)) activeTimeSlot = "10:00 AM - 12:00 PM";
                    else if ("14:00:00".equals(rawSlot)) activeTimeSlot = "02:00 PM - 04:00 PM";
                    else activeTimeSlot = rawSlot;
                }
            }
        }

        // Attendance analytics chart for this lecturer's sessions
        String chartSQL = "SELECT b.bookingId, " +
                          "IFNULL(ROUND((COUNT(CASE WHEN a.status IN ('PRESENT', 'COMPLETED') THEN 1 END) / " +
                          "(SELECT COUNT(*) FROM student s WHERE s.studentStream = (" +
                          "  CASE " +
                          "    WHEN b.labId = 'LAB_CS_04' THEN 'Engineering Stream' " +
                          "    WHEN b.labId = 'LAB_BIO_01' THEN 'Science Stream' " +
                          "    ELSE s.studentStream " +
                          "  END" +
                          "))) * 100), 0) AS rate " +
                          "FROM Booking b " +
                          "LEFT JOIN AttendanceLog a ON b.bookingId = a.bookingId " +
                          "WHERE b.lecturerId = ? AND LOWER(b.status) = 'approved' " +
                          "GROUP BY b.bookingId, b.bookingDate " +
                          "ORDER BY b.bookingDate ASC LIMIT 6";
        
        try (PreparedStatement stmtChart = conn.prepareStatement(chartSQL)) {
            stmtChart.setInt(1, currentLecturerId);
            try (ResultSet rsChart = stmtChart.executeQuery()) {
                while (rsChart.next()) {
                    sessionLabels.add("'" + rsChart.getString("bookingId") + "'");
                    attendanceRates.add(rsChart.getInt("rate"));
                }
            }
        }
        
        if (sessionLabels.isEmpty()) {
            sessionLabels.add("'No Data'");
            attendanceRates.add(0);
        }

    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Lecturer Portal | MLMS</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --lecturer-blue: #3498db;
            --dark-blue: #2c3e50;
            --sidebar-bg: #1e293b;
            --main-bg: #f8fafc;
            --text-dark: #0f172a;
            --text-muted: #64748b;
            --border-color: #e2e8f0;
            --white: #ffffff;
            --success-green: #10b981;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }
        
        body {
            font-family: 'Inter', -apple-system, sans-serif;
            background-color: var(--main-bg); 
            color: var(--text-dark);
            min-height: 100vh;
            margin: 0;
            display: flex;
        }

        aside {
            width: 280px; 
            background-color: var(--sidebar-bg); 
            color: var(--white);
            display: flex; 
            flex-direction: column; 
            flex-shrink: 0;
            box-shadow: 4px 0 10px rgba(0, 0, 0, 0.05); 
            min-height: 100vh;
        }
        .sidebar-header { padding: 26px 24px; font-size: 20px; font-weight: 800; border-bottom: 1px solid #334155; }
        .sidebar-header span { color: var(--lecturer-blue); }
        .sidebar-menu { list-style: none; padding: 20px 0; margin: 0; flex-grow: 1; }
        .menu-label { padding: 0 24px 10px 24px; font-size: 11px; font-weight: 700; text-transform: uppercase; color: #475569; letter-spacing: 1px; }
        
        .sidebar-item a { display: flex; align-items: center; padding: 13px 24px; color: #94a3b8; text-decoration: none; font-weight: 500; font-size: 14.5px; border-left: 4px solid transparent; }
        .sidebar-item.active a, .sidebar-item a:hover { background-color: rgba(52, 152, 219, 0.08); color: var(--white); border-left-color: var(--lecturer-blue); }
        .sidebar-item svg { width: 18px; height: 18px; margin-right: 14px; fill: none; stroke: #94a3b8; stroke-width: 2; }
        .sidebar-item.active svg, .sidebar-item a:hover svg { stroke: #ffffff; }

        .app-wrapper {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
            min-width: 0;
        }

        main { flex-grow: 1; padding: 35px 30px; max-width: 1400px; width: 100%; box-sizing: border-box; }
        .top-navbar { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 20px; margin-bottom: 25px; }
        .page-title h1 { margin: 0; font-size: 24px; font-weight: 800; }
        .page-title p { margin: 4px 0 0 0; color: var(--text-muted); font-size: 13.5px; }
        .user-profile { display: flex; align-items: center; background: var(--white); padding: 8px 14px; border-radius: 20px; border: 1px solid var(--border-color); font-size: 13px; font-weight: 600; color: #334155; }

        .live-gate-hero {
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            border: 1px solid #334155;
            border-radius: 16px;
            padding: 22px 26px;
            margin-bottom: 25px;
            color: #ffffff;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 10px 25px rgba(15, 23, 42, 0.15);
            gap: 20px;
        }
        .live-status-pill {
            display: inline-flex; align-items: center; gap: 6px;
            background: rgba(16, 185, 129, 0.15); border: 1px solid #10b981;
            color: #34d399; padding: 4px 12px; border-radius: 20px;
            font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 8px;
        }
        .live-dot { width: 7px; height: 7px; border-radius: 50%; background-color: #34d399; box-shadow: 0 0 8px #34d399; }
        .btn-launch-qr {
            background: linear-gradient(135deg, #3498db, #2980b9);
            color: #ffffff; text-decoration: none; padding: 12px 20px;
            border-radius: 10px; font-size: 13.5px; font-weight: 700;
            display: inline-flex; align-items: center; gap: 8px;
            box-shadow: 0 4px 15px rgba(52, 152, 219, 0.35);
            white-space: nowrap; transition: transform 0.15s ease;
        }
        .btn-launch-qr:hover { transform: translateY(-2px); }

        .desktop-grid { display: grid; grid-template-columns: 1.8fr 1fr; gap: 24px; align-items: start; }
        .left-column-stack { display: flex; flex-direction: column; gap: 24px; }
        
        .dashboard-card { background-color: var(--white); border-radius: 14px; border: 1px solid var(--border-color); padding: 22px; box-shadow: 0 4px 6px rgba(0,0,0,0.01); }
        .card-header-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px; border-bottom: 1px solid #f1f5f9; padding-bottom: 12px; }
        .card-title { font-size: 15.5px; font-weight: 700; margin: 0; color: #1e293b; }
        
        .btn-blue-outline { text-decoration: none; font-size: 12px; font-weight: 700; color: var(--lecturer-blue); border: 1px solid var(--lecturer-blue); padding: 5px 12px; border-radius: 6px; transition: all 0.2s; }
        .btn-blue-outline:hover { background-color: var(--lecturer-blue); color: var(--white); }

        .table-responsive { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; }
        table { width: 100%; border-collapse: collapse; text-align: left; }
        th, td { padding: 12px 10px; font-size: 13.5px; border-bottom: 1px solid var(--border-color); vertical-align: middle; }
        th { background-color: #f8fafc; color: #475569; font-weight: 600; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
        .badge-active { padding: 4px 9px; border-radius: 6px; font-size: 11px; font-weight: 700; background-color: #ecfdf5; color: var(--success-green); border: 1px solid #a7f3d0; text-transform: uppercase; }

        .attendance-row { display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid #f1f5f9; }
        .attendance-row:last-child { border-bottom: none; }
        .attendance-info .class-name { font-weight: 700; font-size: 13.5px; display: block; color: #1e293b; }
        .attendance-info .class-meta { font-size: 11.5px; color: var(--text-muted); display: block; margin-top: 2px;}
        .counter-badge { font-size: 12px; font-weight: 700; color: var(--success-green); background-color: #ecfdf5; padding: 5px 10px; border-radius: 8px; }

        .chart-container { position: relative; width: 100%; height: 250px; }

        .mobile-topbar, #mobile-drawer { display: none; }

        @media (max-width: 900px) {
            body { flex-direction: column; }
            aside { display: none; }
            .mobile-topbar {
                display: flex; justify-content: space-between; align-items: center;
                background-color: var(--sidebar-bg); color: var(--white); padding: 16px 20px;
                position: sticky; top: 0; z-index: 50;
            }
            .mobile-brand { font-size: 18px; font-weight: 800; }
            .mobile-brand span { color: var(--lecturer-blue); }
            .mobile-menu-btn { background: none; border: none; color: white; font-size: 24px; cursor: pointer; }
            
            #mobile-drawer { background-color: #0f172a; padding: 12px 0; border-bottom: 1px solid #334155; }
            #mobile-drawer a { display: block; padding: 12px 24px; color: #cbd5e1; text-decoration: none; font-size: 14px; font-weight: 500; }
            #mobile-drawer a:hover, #mobile-drawer a.active { background: rgba(52, 152, 219, 0.15); color: var(--lecturer-blue); font-weight: 700; }

            main { padding: 20px 16px; }
            .live-gate-hero { flex-direction: column; align-items: flex-start; padding: 18px; }
            .btn-launch-qr { width: 100%; justify-content: center; }
            .top-navbar { flex-direction: column; align-items: flex-start; gap: 10px; }
            .desktop-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

    <!-- Desktop Sidebar -->
    <aside>
        <div class="sidebar-header"><span>MLMS</span>.Lecturer</div>
        <ul class="sidebar-menu">
            <li class="menu-label">Main Tasks</li>
            <li class="sidebar-item active">
                <a href="<%= request.getContextPath() %>/lecturer/dashboard">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="9"></rect><rect x="14" y="3" width="7" height="5"></rect><rect x="14" y="12" width="7" height="9"></rect><rect x="3" y="16" width="7" height="5"></rect></svg>
                    <span>Dashboard Overview</span>
                </a>
            </li>
            <li class="sidebar-item">
                <a href="<%= request.getContextPath() %>/lecturer/book-lab">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                    <span>Book Laboratory Space</span>
                </a>
            </li>
            <li class="sidebar-item">
                <a href="<%= request.getContextPath() %>/lecturer/my-bookings">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
                    <span>Manage My Bookings</span>
                </a>
            </li>
            <li class="sidebar-item" style="margin-top: 30px; border-top: 1px solid #334155; padding-top: 15px;">
                <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round" style="stroke: #ef4444;"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
                    <span>Sign Out</span>
                </a>
            </li>
        </ul>
    </aside>

    <!-- Main Body Container -->
    <div class="app-wrapper">
        <div class="mobile-topbar">
            <div class="mobile-brand"><span>MLMS</span>.Lecturer</div>
            <button class="mobile-menu-btn" onclick="toggleMobileNav()">☰</button>
        </div>
        <div id="mobile-drawer">
            <a href="<%= request.getContextPath() %>/lecturer/dashboard" class="active">📊 Dashboard Overview</a>
            <a href="<%= request.getContextPath() %>/lecturer/book-lab">📅 Book Laboratory Space</a>
            <a href="<%= request.getContextPath() %>/lecturer/my-bookings">📋 Manage My Bookings</a>
            <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">🚪 Sign Out</a>
        </div>

        <main>
            <div class="top-navbar">
                <div class="page-title">
                    <h1>Lecturer Control Center</h1>
                    <p>Welcome back, <%= currentLecturerName %>. Review room allocations and active attendance monitors across channels.</p>
                </div>
                <div class="user-profile">💻 Faculty: <%= currentLecturerName %></div>
            </div>

            <!-- LIVE QR GATE HERO CARD -->
            <div class="live-gate-hero">
                <div>
                    <div class="live-status-pill">
                        <span class="live-dot"></span> <%= hasActiveSession ? "Active Allocation Ready" : "No Upcoming Session" %>
                    </div>
                    <h2 style="font-size: 19px; font-weight: 800; margin-bottom: 5px;">
                        <%= activeLabName %>
                    </h2>
                    <p style="font-size: 13px; color: #94a3b8; margin: 0;">
                        <% if (hasActiveSession) { %>
                            Ref ID: <strong style="font-family: 'JetBrains Mono', monospace; color: #38bdf8;"><%= activeBookingId %></strong> &bull; Date: <%= activeDate %> &bull; Slot: <%= activeTimeSlot %>
                        <% } else { %>
                            Reserve a laboratory room to initialize the live projection station.
                        <% } %>
                    </p>
                </div>
                
                <% if (hasActiveSession) { %>
                    <a href="<%= request.getContextPath() %>/terminal-gate?bookingId=<%= activeBookingId %>" 
                        target="_blank" 
                            class="btn-launch-qr">
                        📺 Project Station QR Code →
                    </a>
                <% } else { %>
                    <a href="<%= request.getContextPath() %>/lecturer/book-lab" 
                       class="btn-launch-qr" style="background: #475569;">
                        + Book Laboratory Space
                    </a>
                <% } %>
            </div>

            <div class="desktop-grid">
                <div class="left-column-stack">
                    
                    <!-- Chart Card -->
                    <div class="dashboard-card">
                        <div class="card-header-row">
                            <h2 class="card-title">Lab Session Attendance Analytics</h2>
                        </div>
                        <div class="chart-container">
                            <canvas id="labTrafficChart"></canvas>
                        </div>
                    </div>

                    <!-- Active Schedule Reservations -->
                    <div class="dashboard-card">
                        <div class="card-header-row">
                            <h2 class="card-title">Upcoming Schedule Reservations</h2>
                            <a href="<%= request.getContextPath() %>/lecturer/my-bookings" class="btn-blue-outline">Manage All →</a>
                        </div>
                        <div class="table-responsive">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Laboratory</th>
                                        <th>Date Block</th>
                                        <th>Time Window</th>
                                        <th>System Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                <%
                                    PreparedStatement stmtBookings = null;
                                    ResultSet rsBookings = null;
                                    try {
                                        String bookingSQL = "SELECT labId, DATE_FORMAT(bookingDate, '%d/%m/%Y') AS b_date, timeSlot " +
                                                            "FROM Booking " +
                                                            "WHERE lecturerId = ? AND LOWER(status) = 'approved' " +
                                                            "AND (bookingDate > CURRENT_DATE() OR (bookingDate = CURRENT_DATE() AND ADDTIME(timeSlot, '02:00:00') >= CURRENT_TIME())) " +
                                                            "ORDER BY bookingDate ASC, timeSlot ASC LIMIT 5";
                                        stmtBookings = conn.prepareStatement(bookingSQL);
                                        stmtBookings.setInt(1, currentLecturerId);
                                        rsBookings = stmtBookings.executeQuery();

                                        boolean hasBookings = false;
                                        while (rsBookings.next()) {
                                            hasBookings = true;
                                            String rawTime = rsBookings.getString("timeSlot");
                                            String displayTime = rawTime;
                                            if ("10:00:00".equals(rawTime)) displayTime = "10:00 AM - 12:00 PM";
                                            else if ("14:00:00".equals(rawTime)) displayTime = "02:00 PM - 04:00 PM";
                                            
                                            String rawLabId = rsBookings.getString("labId");
                                            String displayLabName = rawLabId;
                                            if ("LAB_CS_04".equals(rawLabId)) displayLabName = "Computer Science Lab (CS 04)";
                                            else if ("LAB_PHYS_01".equals(rawLabId)) displayLabName = "Physics Lab (PSY 01)";
                                            else if ("LAB_CHEM_01".equals(rawLabId)) displayLabName = "Chemistry Lab (CHM 01)";
                                            else if ("LAB_BIO_01".equals(rawLabId)) displayLabName = "Biology Lab (BIO 01)";
                                %>
                                    <tr>
                                        <td><%= displayLabName %></td>
                                        <td><%= rsBookings.getString("b_date") %></td>
                                        <td style="font-family: monospace;"><%= displayTime %></td>
                                        <td><span class="badge-active">Approved</span></td>
                                    </tr>
                                <%
                                        }
                                        if (!hasBookings) {
                                %>
                                    <tr><td colspan="4" style="text-align:center; color:var(--text-muted); padding: 20px;">No upcoming reservations found.</td></tr>
                                <%
                                        }
                                    } catch (SQLException e) {
                                        e.printStackTrace();
                                    } finally {
                                        if (rsBookings != null) rsBookings.close();
                                        if (stmtBookings != null) stmtBookings.close();
                                    }
                                %>
                                </tbody>
                            </table>
                        </div>
                    </div>

                </div> 
                
                <!-- Student Scan Feeds Card -->
                <div class="dashboard-card">
                    <div class="card-header-row">
                        <h2 class="card-title">Student Check-In Feed</h2>
                    </div>
                    <p style="color: var(--text-muted); font-size: 12.5px; margin: 0 0 15px 0;">Live verified unique QR scan tokens processed.</p>

                    <%
                        PreparedStatement stmtTracker = null;
                        ResultSet rsTracker = null;
                        try {
                            String trackerSQL = "SELECT b.bookingId, b.labId, " +
                                                "COUNT(CASE WHEN UPPER(a.status) IN ('PRESENT', 'COMPLETED') THEN 1 END) AS present_count " +
                                                "FROM Booking b " +
                                                "LEFT JOIN AttendanceLog a ON b.bookingId = a.bookingId " +
                                                "WHERE b.lecturerId = ? AND LOWER(b.status) = 'approved' " +
                                                "GROUP BY b.bookingId, b.labId, b.bookingDate " +
                                                "ORDER BY b.bookingDate DESC LIMIT 4";
                            
                            stmtTracker = conn.prepareStatement(trackerSQL);
                            stmtTracker.setInt(1, currentLecturerId);
                            rsTracker = stmtTracker.executeQuery();

                            boolean hasLogs = false;
                            while (rsTracker.next()) {
                                hasLogs = true;
                                String trackLabId = rsTracker.getString("labId");
                    %>
                    <div class="attendance-row">
                        <div class="attendance-info">
                            <span class="class-name">Session: <%= rsTracker.getString("bookingId") %></span>
                            <span class="class-meta">Venue: <%= trackLabId %></span>
                        </div>
                        <div class="counter-badge"><%= rsTracker.getInt("present_count") %> Present</div>
                    </div>
                    <%
                            }
                            if (!hasLogs) {
                    %>
                        <p style="text-align:center; color: var(--text-muted); font-size:13px; padding: 20px;">No tracking feeds processed yet.</p>
                    <%
                            }
                        } catch (SQLException e) {
                            e.printStackTrace();
                        } finally {
                            if (rsTracker != null) rsTracker.close();
                            if (stmtTracker != null) stmtTracker.close();
                            if (conn != null) conn.close(); 
                        }
                    %>
                </div>

            </div> 
        </main>
    </div>

    <script>
        function toggleMobileNav() {
            const drawer = document.getElementById("mobile-drawer");
            drawer.style.display = (drawer.style.display === "block") ? "none" : "block";
        }

        const ctx = document.getElementById('labTrafficChart').getContext('2d');
        new Chart(ctx, {
            type: 'line', 
            data: {
                labels: [<%= String.join(",", sessionLabels) %>],
                datasets: [{
                    label: 'Attendance Rate (%)',
                    data: <%= attendanceRates.toString() %>, 
                    backgroundColor: 'rgba(52, 152, 219, 0.15)', 
                    borderColor: '#3498db', 
                    borderWidth: 3, 
                    tension: 0.3, 
                    pointBackgroundColor: '#2c3e50', 
                    pointRadius: 4
                }]
            },
            options: {
                responsive: true, 
                maintainAspectRatio: false, 
                plugins: { legend: { display: false } },
                scales: {
                    y: {
                        beginAtZero: true, max: 100, 
                        grid: { color: '#f1f5f9' },
                        ticks: { color: '#64748b', callback: function(value) { return value + '%'; } }
                    },
                    x: {
                        grid: { display: false },
                        ticks: { color: '#64748b', font: { weight: '500' } }
                    }
                }
            }
        });
    </script>
</body>
</html>