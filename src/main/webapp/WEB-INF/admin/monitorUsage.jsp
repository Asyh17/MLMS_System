<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.mycompany.mlms_system.database.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%
    if (session.getAttribute("userToken") == null || !"ADMIN".equalsIgnoreCase((String) session.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    int totalLabs = 0;
    int activeLabsCount = 0;
    int maintenanceLabsCount = 0;

    StringBuilder labCardsHtml = new StringBuilder();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();

        // Fetch all laboratories from the database
        String sqlLabs = "SELECT labId, labName, capacity, location, status FROM laboratory";
        ps = conn.prepareStatement(sqlLabs);
        rs = ps.executeQuery();

        while (rs.next()) {
            totalLabs++;
            String labId = rs.getString("labId");
            String labName = rs.getString("labName");
            int capacity = rs.getInt("capacity");
            String location = rs.getString("location");
            String dbStatus = rs.getString("status"); // e.g., 'Operational', 'Maintenance', 'Closed'
            
            if (dbStatus == null) dbStatus = "Operational";

            String badgeClass = "status-active";
            String statusLabel = "Active";
            
            if ("Maintenance".equalsIgnoreCase(dbStatus)) {
                badgeClass = "status-maintenance";
                statusLabel = "Maintenance";
                maintenanceLabsCount++;
            } else if ("Closed".equalsIgnoreCase(dbStatus)) {
                badgeClass = "status-closed";
                statusLabel = "Closed";
            } else {
                activeLabsCount++;
            }

            // Determine data-stream filter category based on labId or name
            String streamAttr = "Other";
            String upperId = labId != null ? labId.toUpperCase() : "";
            if (upperId.contains("CS")) streamAttr = "CS";
            else if (upperId.contains("PHYS") || upperId.contains("PHY")) streamAttr = "Physics";
            else if (upperId.contains("CHEM") || upperId.contains("CHM")) streamAttr = "Chemistry";
            else if (upperId.contains("BIO")) streamAttr = "Biology";

            // Check current occupancy from active bookings/attendance for today
            int currentOccupancy = 0;
            PreparedStatement psOcc = null;
            ResultSet rsOcc = null;
            try {
                String occSql = "SELECT COUNT(DISTINCT a.studentId) FROM attendancelog a JOIN booking b ON a.bookingId = b.bookingId " +
                                "WHERE b.labId = ? AND b.bookingDate = CURRENT_DATE() AND a.exitTime IS NULL";
                psOcc = conn.prepareStatement(occSql);
                psOcc.setString(1, labId);
                rsOcc = psOcc.executeQuery();
                if (rsOcc.next()) {
                    currentOccupancy = rsOcc.getInt(1);
                }
            } catch (Exception e) {
                // Fallback if occupancy query fails
            } finally {
                if (rsOcc != null) try { rsOcc.close(); } catch (SQLException e) {}
                if (psOcc != null) try { psOcc.close(); } catch (SQLException e) {}
            }

            int occupancyPercent = capacity > 0 ? (int) Math.min(100, Math.round(((double) currentOccupancy / capacity) * 100)) : 0;
            String fillClass = occupancyPercent >= 80 ? "fill-high" : (occupancyPercent >= 40 ? "fill-mid" : "fill-low");

            // Build card markup dynamically
            labCardsHtml.append("<div class=\"lab-card\" data-stream=\"").append(streamAttr).append("\">");
            labCardsHtml.append("  <div class=\"lab-card-header\">");
            labCardsHtml.append("    <div>");
            labCardsHtml.append("      <p class=\"lab-name\">").append(labId).append(" &mdash; ").append(labName).append("</p>");
            labCardsHtml.append("      <p class=\"lab-meta\">").append(location).append(" &middot; Capacity: ").append(capacity).append(" seats</p>");
            labCardsHtml.append("    </div>");
            labCardsHtml.append("    <span class=\"status-badge ").append(badgeClass).append("\">").append(statusLabel).append("</span>");
            labCardsHtml.append("  </div>");
            labCardsHtml.append("  <div class=\"occupancy-row\"><span>Current Occupancy</span><span>").append(currentOccupancy).append(" / ").append(capacity).append(" (").append(occupancyPercent).append("%)</span></div>");
            labCardsHtml.append("  <div class=\"progress-track\"><div class=\"progress-fill ").append(fillClass).append("\" style=\"width: ").append(occupancyPercent).append("%;\"></div></div>");
            labCardsHtml.append("  <div class=\"lab-footer-row\">");
            labCardsHtml.append("    <span>Location: ").append(location).append("</span>");
            labCardsHtml.append("    <span>Status: ").append(dbStatus).append("</span>");
            labCardsHtml.append("  </div>");
            labCardsHtml.append("</div>");
        }
        rs.close();
        ps.close();

    } catch (SQLException e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (ps != null) try { ps.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Monitor Lab Usage | MLMS Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --admin-amber: #d97706;
            --admin-amber-dark: #b45309;
            --sidebar-bg: #0f172a;
            --main-bg: #f8fafc;
            --text-dark: #0f172a;
            --text-muted: #64748b;
            --border-color: #e2e8f0;
            --white: #ffffff;
            --success-green: #10b981;
            --warn-yellow: #f59e0b;
            --danger-red: #ef4444;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', -apple-system, sans-serif;
            background-color: var(--main-bg); color: var(--text-dark);
            display: flex; min-height: 100vh;
        }

        aside {
            width: 280px; background-color: var(--sidebar-bg); color: var(--white);
            display: flex; flex-direction: column; flex-shrink: 0; min-height: 100vh;
        }
        .sidebar-header { padding: 26px 24px; font-size: 20px; font-weight: 800; border-bottom: 1px solid #1e293b; }
        .sidebar-header span { color: var(--admin-amber); }
        .sidebar-menu { list-style: none; padding: 20px 0; margin: 0; flex-grow: 1; }
        .menu-label { padding: 0 24px 10px 24px; font-size: 11px; font-weight: 700; text-transform: uppercase; color: #475569; letter-spacing: 1px; }
        .sidebar-item a { display: flex; align-items: center; padding: 13px 24px; color: #94a3b8; text-decoration: none; font-weight: 500; font-size: 14.5px; border-left: 4px solid transparent; }
        .sidebar-item.active a, .sidebar-item a:hover { background-color: rgba(217, 119, 6, 0.1); color: var(--white); border-left-color: var(--admin-amber); }
        .sidebar-item svg { width: 18px; height: 18px; margin-right: 14px; fill: none; stroke: currentColor; stroke-width: 2; }
        .sidebar-footer { padding: 20px 24px; border-top: 1px solid #1e293b; font-size: 12px; color: #475569; }

        .app-wrapper { flex-grow: 1; display: flex; flex-direction: column; min-width: 0; }
        main { flex-grow: 1; padding: 35px 30px; max-width: 1400px; width: 100%; box-sizing: border-box; }
        .top-navbar { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 20px; margin-bottom: 30px; }
        .page-title h1 { margin: 0; font-size: 24px; font-weight: 800; }
        .page-title p { margin: 4px 0 0 0; color: var(--text-muted); font-size: 13.5px; }
        .user-profile { display: flex; align-items: center; background: var(--white); padding: 8px 14px; border-radius: 20px; border: 1px solid var(--border-color); font-size: 13px; font-weight: 600; }
        .live-dot { display: inline-block; width: 8px; height: 8px; border-radius: 50%; background-color: var(--success-green); margin-right: 6px; box-shadow: 0 0 0 0 rgba(16,185,129, 0.6); animation: pulse 1.6s infinite; }
        @keyframes pulse { 0% { box-shadow: 0 0 0 0 rgba(16,185,129, 0.5); } 70% { box-shadow: 0 0 0 7px rgba(16,185,129, 0); } 100% { box-shadow: 0 0 0 0 rgba(16,185,129, 0); } }

        .kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 25px; }
        .kpi-card { background-color: var(--white); border-radius: 12px; border: 1px solid var(--border-color); padding: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.01); }
        .kpi-card .kpi-label { font-size: 11.5px; color: var(--text-muted); font-weight: 700; text-transform: uppercase; letter-spacing: 0.4px; margin-bottom: 8px; }
        .kpi-card .kpi-value { font-size: 26px; font-weight: 800; color: var(--text-dark); }

        .filter-bar { display: flex; align-items: center; gap: 10px; margin-bottom: 20px; flex-wrap: wrap; }
        .filter-chip { padding: 7px 14px; border-radius: 20px; border: 1px solid var(--border-color); background-color: var(--white); font-size: 13px; font-weight: 600; color: var(--text-muted); cursor: pointer; transition: all 0.15s ease; }
        .filter-chip:hover { border-color: var(--admin-amber); color: var(--admin-amber-dark); }
        .filter-chip.active { background-color: var(--admin-amber); color: var(--white); border-color: var(--admin-amber); }

        .usage-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; }
        .lab-card { background-color: var(--white); border-radius: 14px; border: 1px solid var(--border-color); padding: 22px; box-shadow: 0 1px 3px rgba(0,0,0,0.01); }
        .lab-card-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 14px; }
        .lab-name { font-size: 15.5px; font-weight: 700; margin: 0 0 4px 0; }
        .lab-meta { font-size: 12.5px; color: var(--text-muted); }
        .status-badge { padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; white-space: nowrap; text-transform: uppercase; }
        .status-active { background-color: #ecfdf5; color: #047857; }
        .status-maintenance { background-color: #fffbeb; color: #b45309; }
        .status-closed { background-color: #fef2f2; color: #b91c1c; }

        .occupancy-row { display: flex; justify-content: space-between; font-size: 13px; font-weight: 600; margin-bottom: 6px; }
        .progress-track { width: 100%; height: 8px; background-color: #f1f5f9; border-radius: 5px; overflow: hidden; margin-bottom: 14px; }
        .progress-fill { height: 100%; border-radius: 5px; }
        .fill-high { background-color: var(--danger-red); }
        .fill-mid { background-color: var(--admin-amber); }
        .fill-low { background-color: var(--success-green); }

        .lab-footer-row { display: flex; justify-content: space-between; font-size: 12px; color: var(--text-muted); border-top: 1px solid #f1f5f9; padding-top: 12px; }

        .mobile-topbar, #mobile-drawer { display: none; }
        @media (max-width: 1000px) {
            .kpi-grid { grid-template-columns: repeat(2, 1fr); }
            .usage-grid { grid-template-columns: 1fr; }
        }
        @media (max-width: 900px) {
            body { flex-direction: column; }
            aside { display: none; }
            .mobile-topbar {
                display: flex; justify-content: space-between; align-items: center;
                background-color: var(--sidebar-bg); color: var(--white); padding: 16px 20px;
                position: sticky; top: 0; z-index: 50;
            }
            .mobile-brand { font-size: 18px; font-weight: 800; }
            .mobile-brand span { color: var(--admin-amber); }
            .mobile-menu-btn { background: none; border: none; color: white; font-size: 24px; cursor: pointer; }
            
            #mobile-drawer {
                background-color: #020617; padding: 12px 0; border-bottom: 1px solid #1e293b;
            }
            #mobile-drawer a { display: block; padding: 12px 24px; color: #cbd5e1; text-decoration: none; font-size: 14px; font-weight: 500; }
            #mobile-drawer a:hover, #mobile-drawer a.active { background: rgba(217, 119, 6, 0.15); color: var(--admin-amber); font-weight: 700; }

            main { padding: 20px 16px; }
            .top-navbar { flex-direction: column; align-items: flex-start; gap: 10px; }
            .kpi-grid { grid-template-columns: 1fr; gap: 12px; }
        }
    </style>
</head>
<body>

    <!-- Desktop Sidebar -->
    <aside>
        <div class="sidebar-header"><span>MLMS</span>.Admin</div>
        <ul class="sidebar-menu">
            <li class="menu-label">Oversight</li>
            <li class="sidebar-item">
                <a href="<%= request.getContextPath() %>/admin/dashboard">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="3" width="7" height="9"></rect>
                        <rect x="14" y="3" width="7" height="5"></rect>
                        <rect x="14" y="12" width="7" height="9"></rect>
                        <rect x="3" y="16" width="7" height="5"></rect>
                    </svg>
                    <span>Dashboard Overview</span>
                </a>
            </li>

            <li class="sidebar-item">
                <a href="<%= request.getContextPath() %>/admin/manage-lecturers">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                        <circle cx="9" cy="7" r="4"></circle>
                        <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                        <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                    </svg>
                    <span>Manage Lecturers</span>
                </a>
            </li>

            <li class="sidebar-item">
                <a href="<%= request.getContextPath() %>/admin/reports">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                        <polyline points="14 2 14 8 20 8"></polyline>
                        <line x1="16" y1="13" x2="8" y2="13"></line>
                        <line x1="16" y1="17" x2="8" y2="17"></line>
                    </svg>
                    <span>Generate Reports</span>
                </a>
            </li>

            <li class="sidebar-item active">
                <a href="<%= request.getContextPath() %>/admin/monitor-usage">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
                    </svg>
                    <span>Monitor Lab Usage</span>
                </a>
            </li>

            <li class="sidebar-item" style="margin-top: 30px; border-top: 1px solid #1e293b; padding-top: 15px;">
                <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round" style="stroke: #ef4444;">
                        <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                        <polyline points="16 17 21 12 16 7"></polyline>
                        <line x1="21" y1="12" x2="9" y2="12"></line>
                    </svg>
                    <span>Sign Out</span>
                </a>
            </li>
        </ul>
    </aside>

    <!-- Main Workspace Container -->
    <div class="app-wrapper">
        <div class="mobile-topbar">
            <div class="mobile-brand"><span>MLMS</span>.Admin</div>
            <button class="mobile-menu-btn" onclick="toggleMobileNav()">☰</button>
        </div>
        <div id="mobile-drawer">
            <a href="<%= request.getContextPath() %>/admin/dashboard">📊 Dashboard Overview</a>
            <a href="<%= request.getContextPath() %>/admin/manage-lecturers">👨‍🏫 Manage Lecturers</a>
            <a href="<%= request.getContextPath() %>/admin/reports">📑 Generate Reports</a>
            <a href="<%= request.getContextPath() %>/admin/monitor-usage" class="active">📈 Monitor Lab Usage</a>
            <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">🚪 Sign Out</a>
        </div>

        <main>
            <div class="top-navbar">
                <div class="page-title">
                    <h1>Live Laboratory Usage Monitor</h1>
                    <p>Real-time room status and occupancy across all registered laboratory spaces.</p>
                </div>
                <div class="user-profile"><span class="live-dot"></span>Live &middot; Updated just now</div>
            </div>

            <div class="kpi-grid">
                <div class="kpi-card">
                    <div class="kpi-label">Total Registered Labs</div>
                    <div class="kpi-value"><%= totalLabs %></div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-label">Active Right Now</div>
                    <div class="kpi-value"><%= activeLabsCount %></div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-label">Under Maintenance</div>
                    <div class="kpi-value"><%= maintenanceLabsCount %></div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-label">System Status</div>
                    <div class="kpi-value" style="font-size: 18px; color: var(--success-green); padding-top: 4px;">Operational</div>
                </div>
            </div>

            <div class="filter-bar">
                <span style="font-size:13px; color:var(--text-muted); font-weight:600;">Filter by stream:</span>
                <button class="filter-chip active" data-stream="all" onclick="filterLabs('all', this)">All</button>
                <button class="filter-chip" data-stream="CS" onclick="filterLabs('CS', this)">Computer Science</button>
                <button class="filter-chip" data-stream="Physics" onclick="filterLabs('Physics', this)">Physics</button>
                <button class="filter-chip" data-stream="Chemistry" onclick="filterLabs('Chemistry', this)">Chemistry</button>
                <button class="filter-chip" data-stream="Biology" onclick="filterLabs('Biology', this)">Biology</button>
            </div>

            <div class="usage-grid" id="usageGrid">
                <%= labCardsHtml.toString() %>
            </div>
        </main>
    </div>

    <script>
        function toggleMobileNav() {
            const drawer = document.getElementById("mobile-drawer");
            drawer.style.display = (drawer.style.display === "block") ? "none" : "block";
        }

        function filterLabs(stream, btn) {
            document.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
            btn.classList.add('active');

            document.querySelectorAll('.lab-card').forEach(card => {
                if (stream === 'all' || card.dataset.stream === stream) {
                    card.style.display = '';
                } else {
                    card.style.display = 'none';
                }
            });
        }
    </script>
</body>
</html>