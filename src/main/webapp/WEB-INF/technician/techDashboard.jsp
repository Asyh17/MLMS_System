<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.mycompany.mlms_system.database.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%
    // 1. Session Protection Gate Check
    String userRole = (String) session.getAttribute("userRole");
    if (session.getAttribute("userToken") == null || 
        (!"TECHNICIAN".equalsIgnoreCase(userRole) && !"LAB TECHNICIAN".equalsIgnoreCase(userRole))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String techName = (String) session.getAttribute("userName");

    // 2. Safely extract metrics passed from TechnicianDashboardServlet
    int totalCount = request.getAttribute("totalActiveQueue") != null ? (Integer) request.getAttribute("totalActiveQueue") : 0;
    int pending = request.getAttribute("awaitingVerification") != null ? (Integer) request.getAttribute("awaitingVerification") : 0;
    int approved = request.getAttribute("verifiedCommits") != null ? (Integer) request.getAttribute("verifiedCommits") : 0;

    int monCount = 0, tueCount = 0, wedCount = 0, thuCount = 0, friCount = 0;

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        String sql = "SELECT DAYNAME(bookingDate) AS day_name, COUNT(*) AS day_count " +
                     "FROM Booking GROUP BY DAYNAME(bookingDate)";
        stmt = conn.prepareStatement(sql);
        rs = stmt.executeQuery();

        while (rs.next()) {
            String dayName = rs.getString("day_name");
            int count = rs.getInt("day_count");

            if ("Monday".equalsIgnoreCase(dayName)) monCount = count;
            else if ("Tuesday".equalsIgnoreCase(dayName)) tueCount = count;
            else if ("Wednesday".equalsIgnoreCase(dayName)) wedCount = count;
            else if ("Thursday".equalsIgnoreCase(dayName)) thuCount = count;
            else if ("Friday".equalsIgnoreCase(dayName)) friCount = count;
        }
    } catch (SQLException e) {
        e.printStackTrace();
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (stmt != null) stmt.close(); } catch (SQLException e) {}
        try { if (conn != null) conn.close(); } catch (SQLException e) {}
    }

    int monHeight = totalCount > 0 ? (int)((monCount * 100.0) / totalCount) : 0;
    int tueHeight = totalCount > 0 ? (int)((tueCount * 100.0) / totalCount) : 0;
    int wedHeight = totalCount > 0 ? (int)((wedCount * 100.0) / totalCount) : 0;
    int thuHeight = totalCount > 0 ? (int)((thuCount * 100.0) / totalCount) : 0;
    int friHeight = totalCount > 0 ? (int)((friCount * 100.0) / totalCount) : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>MLMS | Technician Control Console</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --technician-green: #00a65a;
            --sidebar-bg: #1e293b;
            --main-bg: #f8fafc;
            --text-dark: #0f172a;
            --text-muted: #64748b;
            --border-color: #e2e8f0;
            --white: #ffffff;
            --danger-red: #ef4444;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            display: flex; 
            background-color: var(--main-bg); 
            min-height: 100vh; 
            font-family: 'Inter', -apple-system, sans-serif; 
            color: var(--text-dark);
        }

        /* Desktop Sidebar */
        aside { 
            width: 280px; 
            background-color: var(--sidebar-bg); 
            color: var(--white); 
            display: flex; 
            flex-direction: column; 
            flex-shrink: 0; 
            min-height: 100vh;
        }
        .sidebar-header { padding: 26px 24px; font-size: 20px; font-weight: 800; border-bottom: 1px solid #334155; }
        .sidebar-header span { color: var(--technician-green); }
        .sidebar-menu { list-style: none; padding: 20px 0; margin: 0; flex-grow: 1; }
        .menu-label { padding: 0 24px 10px 24px; font-size: 11px; font-weight: 700; text-transform: uppercase; color: #475569; letter-spacing: 1px; }
        .sidebar-item a { display: flex; align-items: center; padding: 13px 24px; color: #94a3b8; text-decoration: none; font-weight: 500; font-size: 14.5px; border-left: 4px solid transparent; }
        .sidebar-item.active a, .sidebar-item a:hover { background-color: rgba(0, 166, 90, 0.08); color: var(--white); border-left-color: var(--technician-green); }
        .sidebar-item svg { width: 18px; height: 18px; margin-right: 14px; fill: none; stroke: #94a3b8; stroke-width: 2; }
        .sidebar-item.active svg, .sidebar-item a:hover svg { stroke: #ffffff; }

        /* Main Wrapper */
        .app-wrapper { flex-grow: 1; display: flex; flex-direction: column; min-width: 0; }
        .main-content { flex: 1; padding: 35px 30px; box-sizing: border-box; max-width: 1400px; width: 100%; }
        .header-panel { display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; border-bottom: 1px solid var(--border-color); padding-bottom: 20px; }
        .header-panel h1 { font-size: 24px; color: #0f172a; font-weight: 800; }
        .header-panel .role-badge { background-color: #1e282c; color: var(--technician-green); border: 1px solid var(--technician-green); padding: 5px 14px; border-radius: 20px; font-size: 11px; font-weight: 700; }

        .metrics-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin-bottom: 25px; }
        .info-box { background: var(--white); padding: 22px; border-radius: 12px; border: 1px solid var(--border-color); border-top: 4px solid var(--technician-green); box-shadow: 0 2px 4px rgba(0,0,0,0.01); }
        .info-box p { color: var(--text-muted); font-size: 12px; font-weight: 700; text-transform: uppercase; }
        .info-box h3 { font-size: 24px; color: #0f172a; margin-top: 6px; font-weight: 800; }

        .chart-container { background: var(--white); border-radius: 12px; border: 1px solid var(--border-color); padding: 26px; border-left: 4px solid var(--technician-green); box-shadow: 0 2px 4px rgba(0,0,0,0.01); }
        .chart-title { font-size: 16px; color: #0f172a; font-weight: 700; }
        .chart-subtitle { font-size: 13px; color: var(--text-muted); margin-bottom: 28px; margin-top: 2px; }
        
        .bar-chart { display: flex; justify-content: space-around; align-items: flex-end; height: 220px; border-bottom: 2px solid #eaedf1; margin-bottom: 15px; padding-top: 20px; }
        .bar-group { display: flex; flex-direction: column; align-items: center; flex: 1; }
        .bar { width: 44px; background: linear-gradient(to top, var(--technician-green), #4ade80); border-radius: 6px 6px 0 0; transition: all 0.4s ease; position: relative; min-height: 15px; }
        .bar-val { position: absolute; top: -22px; left: 50%; transform: translateX(-50%); font-size: 11px; font-weight: 700; color: #333; }
        .bar-label { margin-top: 10px; font-size: 12px; color: var(--text-muted); font-weight: 700; }

        /* Mobile Breakpoint */
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
            .mobile-brand span { color: var(--technician-green); }
            .mobile-menu-btn { background: none; border: none; color: white; font-size: 24px; cursor: pointer; }
            
            #mobile-drawer {
                background-color: #0f172a; padding: 12px 0; border-bottom: 1px solid #334155;
            }
            #mobile-drawer a { display: block; padding: 12px 24px; color: #cbd5e1; text-decoration: none; font-size: 14px; font-weight: 500; }
            #mobile-drawer a:hover, #mobile-drawer a.active { background: rgba(0, 166, 90, 0.15); color: var(--technician-green); font-weight: 700; }

            .main-content { padding: 20px 16px; }
            .header-panel { flex-direction: column; align-items: flex-start; gap: 10px; }
            .metrics-grid { grid-template-columns: 1fr; gap: 14px; }
            .bar { width: 30px; }
        }
    </style>
</head>
<body>

    <!-- Desktop Sidebar -->
    <aside>
        <div class="sidebar-header"><span>MLMS</span>.Technician</div>
        <ul class="sidebar-menu">
            <li class="menu-label">Main Tasks</li>
            <li class="sidebar-item active">
                <a href="<%= request.getContextPath() %>/technician/dashboard">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="9"></rect><rect x="14" y="3" width="7" height="5"></rect><rect x="14" y="12" width="7" height="9"></rect><rect x="3" y="16" width="7" height="5"></rect></svg>
                    <span>Dashboard Overview</span>
                </a>
            </li>
            <li class="sidebar-item">
                <a href="<%= request.getContextPath() %>/technician/schedules">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                    <span>Schedule Entries</span>
                </a>
            </li>
            <li class="sidebar-item">
                <a href="<%= request.getContextPath() %>/technician/verify-labs">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line></svg>
                    <span>Verify Lab Status</span>
                </a>
            </li>
            <li class="sidebar-item">
                <a href="<%= request.getContextPath() %>/technician/lab-profile">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>
                    <span>Lab Profiles</span>
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
            <div class="mobile-brand"><span>MLMS</span>.Technician</div>
            <button class="mobile-menu-btn" onclick="toggleMobileNav()">☰</button>
        </div>
        <div id="mobile-drawer">
            <a href="<%= request.getContextPath() %>/technician/dashboard" class="active">📊 Dashboard Overview</a>
            <a href="<%= request.getContextPath() %>/technician/schedules">📅 Schedule Entries</a>
            <a href="<%= request.getContextPath() %>/technician/verify-labs">✅ Verify Lab Status</a>
            <a href="<%= request.getContextPath() %>/technician/lab-profile">🔬 Lab Profiles</a>
            <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">🚪 Sign Out</a>
        </div>

        <div class="main-content">
            <div class="header-panel">
                <div>
                    <h1>Technician Analytics Dashboard</h1>
                    <p style="color: var(--text-muted); font-size: 13.5px; margin-top: 2px;">Multidisciplinary Laboratory Management System Control Space</p>
                </div>
                <span class="role-badge">OPERATOR: <%= techName != null ? techName : "TECH" %></span>
            </div>

            <div class="metrics-grid">
                <div class="info-box" style="border-top-color: #00c0ef;">
                    <p>Total Active Queue</p>
                    <h3><%= totalCount %> Records</h3>
                </div>
                <div class="info-box" style="border-top-color: #f39c12;">
                    <p>Awaiting Verification</p>
                    <h3><%= pending %> Pending</h3>
                </div>
                <div class="info-box" style="border-top-color: #00a65a;">
                    <p>Verified Content Commits</p>
                    <h3><%= approved %> Confirmed</h3>
                </div>
            </div>

            <div class="chart-container">
                <div class="chart-title">Weekly Laboratory Verification Statistics</div>
                <div class="chart-subtitle">Real-time status analysis of verified resource distributions across the operational timeline.</div>
                
                <div class="bar-chart">
                    <div class="bar-group"><div class="bar" style="height: <%= monHeight %>%;"><span class="bar-val"><%= monHeight %>%</span></div><div class="bar-label">MON</div></div>
                    <div class="bar-group"><div class="bar" style="height: <%= tueHeight %>%;"><span class="bar-val"><%= tueHeight %>%</span></div><div class="bar-label">TUE</div></div>
                    <div class="bar-group"><div class="bar" style="height: <%= wedHeight %>%;"><span class="bar-val"><%= wedHeight %>%</span></div><div class="bar-label">WED</div></div>
                    <div class="bar-group"><div class="bar" style="height: <%= thuHeight %>%;"><span class="bar-val"><%= thuHeight %>%</span></div><div class="bar-label">THU</div></div>
                    <div class="bar-group"><div class="bar" style="height: <%= friHeight %>%;"><span class="bar-val"><%= friHeight %>%</span></div><div class="bar-label">FRI</div></div>
                </div>
            </div>
        </div>
    </div>

    <script>
        function toggleMobileNav() {
            const drawer = document.getElementById("mobile-drawer");
            drawer.style.display = (drawer.style.display === "block") ? "none" : "block";
        }
    </script>
</body>
</html>