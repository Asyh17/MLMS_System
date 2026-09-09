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

    int activeBookingsToday = 0;
    int studentsCheckedInToday = 0;
    int overallUtilizationRate = 0;
    int maintenanceCount = 0;
    String maintenanceLabName = "All Labs Operational";

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();

        // 1. Active approved bookings for today
        String sqlBookings = "SELECT COUNT(*) FROM booking WHERE bookingDate = CURRENT_DATE() AND LOWER(status) = 'approved'";
        ps = conn.prepareStatement(sqlBookings);
        rs = ps.executeQuery();
        if (rs.next()) {
            activeBookingsToday = rs.getInt(1);
        }
        rs.close();
        ps.close();

        // 2. Distinct students who checked in today
        String sqlAttendance = "SELECT COUNT(DISTINCT studentId) FROM attendancelog WHERE DATE(entryTime) = CURRENT_DATE()";
        ps = conn.prepareStatement(sqlAttendance);
        rs = ps.executeQuery();
        if (rs.next()) {
            studentsCheckedInToday = rs.getInt(1);
        }
        rs.close();
        ps.close();

        // 3. Overall utilization rate
        int totalDailyCapacity = 8;
        overallUtilizationRate = (int) Math.min(100, Math.round(((double) activeBookingsToday / totalDailyCapacity) * 100));

        // 4. Laboratories currently flagged under maintenance
        String sqlMaintenance = "SELECT labId FROM laboratory WHERE LOWER(status) = 'maintenance' LIMIT 1";
        ps = conn.prepareStatement(sqlMaintenance);
        rs = ps.executeQuery();
        if (rs.next()) {
            maintenanceCount = 1;
            maintenanceLabName = rs.getString("labId");
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
    <title>Administrator Portal | MLMS</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
            --danger-red: #ef4444;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', -apple-system, sans-serif;
            background-color: var(--main-bg); color: var(--text-dark);
            display: flex; min-height: 100vh;
        }

        /* Desktop Sidebar */
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

        /* Workspace Wrapper */
        .app-wrapper { flex-grow: 1; display: flex; flex-direction: column; min-width: 0; }
        main { flex-grow: 1; padding: 35px 30px; max-width: 1400px; width: 100%; box-sizing: border-box; }
        .top-navbar { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 20px; margin-bottom: 30px; }
        .page-title h1 { margin: 0; font-size: 24px; font-weight: 800; }
        .page-title p { margin: 4px 0 0 0; color: var(--text-muted); font-size: 13.5px; }
        .user-profile { display: flex; align-items: center; background: var(--white); padding: 8px 14px; border-radius: 20px; border: 1px solid var(--border-color); font-size: 13px; font-weight: 600; }

        /* KPI Cards Grid */
        .kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 30px; }
        .kpi-card { background-color: var(--white); border-radius: 12px; border: 1px solid var(--border-color); padding: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.01); }
        .kpi-card .kpi-label { font-size: 11.5px; color: var(--text-muted); font-weight: 700; text-transform: uppercase; letter-spacing: 0.4px; margin-bottom: 8px; }
        .kpi-card .kpi-value { font-size: 26px; font-weight: 800; color: var(--text-dark); }
        .kpi-card .kpi-trend { font-size: 12px; margin-top: 6px; font-weight: 600; }
        .trend-up { color: var(--success-green); }
        .trend-down { color: var(--danger-red); }
        .trend-flat { color: var(--text-muted); }

        .desktop-grid { display: grid; grid-template-columns: 2fr 1fr; gap: 24px; align-items: start; }
        .left-column-stack { display: flex; flex-direction: column; gap: 24px; }

        .dashboard-card { background-color: var(--white); border-radius: 14px; border: 1px solid var(--border-color); padding: 22px; box-shadow: 0 1px 3px rgba(0,0,0,0.01); }
        .card-header-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px; border-bottom: 1px solid #f1f5f9; padding-bottom: 12px; }
        .card-title { font-size: 15.5px; font-weight: 700; margin: 0; }

        .btn-amber-outline { text-decoration: none; font-size: 12px; font-weight: 700; color: var(--admin-amber); border: 1px solid var(--admin-amber); padding: 5px 12px; border-radius: 6px; }
        .btn-amber-outline:hover { background-color: var(--admin-amber); color: var(--white); }

        .table-responsive { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; }
        table { width: 100%; border-collapse: collapse; text-align: left; }
        th, td { padding: 12px 10px; font-size: 13.5px; border-bottom: 1px solid var(--border-color); }
        th { background-color: #f8fafc; color: #475569; font-weight: 700; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
        .actor-pill { padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: 700; }
        .actor-tech { background-color: #ecfeff; color: #0e7490; }
        .actor-lecturer { background-color: #eff6ff; color: #2563eb; }
        .actor-system { background-color: #fef3c7; color: #b45309; }

        /* Quick Action Cards */
        .quick-actions { display: flex; flex-direction: column; gap: 12px; }
        .action-link { display: flex; align-items: center; gap: 12px; text-decoration: none; padding: 14px; border-radius: 10px; border: 1px solid var(--border-color); background-color: #fffaf0; transition: all 0.15s ease; }
        .action-link:hover { border-color: var(--admin-amber); background-color: #fef3e2; }
        .action-icon { width: 36px; height: 36px; border-radius: 8px; background-color: var(--admin-amber); color: var(--white); display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
        .action-icon svg { width: 18px; height: 18px; fill: none; stroke: currentColor; stroke-width: 2; }
        .action-text strong { display: block; font-size: 13.5px; color: var(--text-dark); }
        .action-text span { font-size: 12px; color: var(--text-muted); }

        .chart-container { position: relative; width: 100%; height: 240px; }

        /* Mobile Topbar & Drawer Hidden by Default on Desktop */
        .mobile-topbar, #mobile-drawer {
            display: none;
        }

        /* Mobile Breakpoints */
        @media (max-width: 900px) {
            body { flex-direction: column; }
            aside { display: none; }
            .kpi-grid { grid-template-columns: 1fr 1fr; gap: 14px; }
            .desktop-grid { grid-template-columns: 1fr; }
            main { padding: 20px 16px; }

            .mobile-topbar {
                display: flex;
                justify-content: space-between;
                align-items: center;
                background-color: var(--sidebar-bg);
                color: var(--white);
                padding: 16px 20px;
                position: sticky;
                top: 0;
                z-index: 50;
            }
            .mobile-brand { font-size: 18px; font-weight: 800; }
            .mobile-brand span { color: var(--admin-amber); }
            .mobile-menu-btn { background: none; border: none; color: white; font-size: 24px; cursor: pointer; }

            #mobile-drawer {
                background-color: #0f172a;
                padding: 12px 0;
                border-bottom: 1px solid #334155;
            }
            #mobile-drawer a {
                display: block;
                padding: 12px 24px;
                color: #cbd5e1;
                text-decoration: none;
                font-size: 14px;
                font-weight: 500;
            }
            #mobile-drawer a:hover, #mobile-drawer a.active {
                background: rgba(217, 119, 6, 0.15);
                color: var(--admin-amber);
                font-weight: 700;
            }
        }

        @media (max-width: 550px) {
            .kpi-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

    <!-- Desktop Sidebar -->
    <aside>
        <div class="sidebar-header"><span>MLMS</span>.Admin</div>
        <ul class="sidebar-menu">
            <li class="menu-label">Oversight</li>
            <li class="sidebar-item active">
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

            <li class="sidebar-item">
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

    <!-- Main Workspace -->
    <div class="app-wrapper">
        <div class="mobile-topbar">
            <div class="mobile-brand"><span>MLMS</span>.Admin</div>
            <button class="mobile-menu-btn" onclick="toggleMobileNav()">☰</button>
        </div>
        <div id="mobile-drawer">
            <a href="<%= request.getContextPath() %>/admin/dashboard" class="active">📊 Dashboard Overview</a>
            <a href="<%= request.getContextPath() %>/admin/manage-lecturers">👨‍🏫 Manage Lecturers</a>
            <a href="<%= request.getContextPath() %>/admin/reports">📑 Generate Reports</a>
            <a href="<%= request.getContextPath() %>/admin/monitor-usage">📈 Monitor Lab Usage</a>
            <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">🚪 Sign Out</a>
        </div>

        <main>
            <div class="top-navbar">
                <div class="page-title">
                    <h1>Administrator Control Center</h1>
                    <p>Institution-wide oversight of lab utilization, attendance integrity, and compliance reporting.</p>
                </div>
                <div class="user-profile">🛡️ Admin Account: <%= session.getAttribute("userName") != null ? session.getAttribute("userName") : "Super Admin" %></div>
            </div>

            <!-- Dynamic KPI Grid -->
            <div class="kpi-grid">
                <!-- 1. Active Bookings Today -->
                <div class="kpi-card">
                    <div class="kpi-label">Active Bookings Today</div>
                    <div class="kpi-value"><%= activeBookingsToday %></div>
                    <div class="kpi-trend <%= activeBookingsToday > 0 ? "trend-up" : "trend-flat" %>">
                        <%= activeBookingsToday > 0 ? "▲ Sessions scheduled" : "No bookings scheduled" %>
                    </div>
                </div>

                <!-- 2. Students Checked-In Today -->
                <div class="kpi-card">
                    <div class="kpi-label">Students Checked-In Today</div>
                    <div class="kpi-value"><%= studentsCheckedInToday %></div>
                    <div class="kpi-trend <%= studentsCheckedInToday > 0 ? "trend-up" : "trend-flat" %>">
                        <%= studentsCheckedInToday > 0 ? "▲ Active check-ins logged" : "Awaiting student scans" %>
                    </div>
                </div>

                <!-- 3. Overall Lab Utilization -->
                <div class="kpi-card">
                    <div class="kpi-label">Overall Lab Utilization</div>
                    <div class="kpi-value"><%= overallUtilizationRate %>%</div>
                    <div class="kpi-trend <%= overallUtilizationRate >= 50 ? "trend-up" : "trend-flat" %>">
                        <%= overallUtilizationRate >= 50 ? "Healthy utilization" : "Capacity available" %>
                    </div>
                </div>

                <!-- 4. Labs Under Maintenance -->
                <div class="kpi-card">
                    <div class="kpi-label">Labs Under Maintenance</div>
                    <div class="kpi-value"><%= maintenanceCount %></div>
                    <div class="kpi-trend <%= maintenanceCount > 0 ? "trend-down" : "trend-up" %>">
                        <%= maintenanceCount > 0 ? (maintenanceLabName + " &middot; Action Needed") : "All facilities operational" %>
                    </div>
                </div>
            </div>

            <div class="desktop-grid">
                <div class="left-column-stack">

                    <div class="dashboard-card">
                        <div class="card-header-row">
                            <h2 class="card-title">Weekly Lab Utilization Trend</h2>
                            <a href="<%= request.getContextPath() %>/admin/reports" class="btn-amber-outline">Open Full Report →</a>
                        </div>
                        <div class="chart-container">
                            <canvas id="utilizationTrendChart"></canvas>
                        </div>
                    </div>

                    <div class="dashboard-card">
                        <div class="card-header-row">
                            <h2 class="card-title">Recent System &amp; Security Activity</h2>
                        </div>
                        <div class="table-responsive">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Timestamp</th>
                                        <th>Event</th>
                                        <th>Actor</th>
                                    </tr>
                                </thead>
                                <tbody>
                                <%
                                    Connection logConn = null;
                                    PreparedStatement logStmt = null;
                                    ResultSet logRs = null;
                                    try {
                                        logConn = DBConnection.getConnection();
                                        String fetchLogsSQL = "SELECT DATE_FORMAT(timestamp, '%d/%m %H:%i') AS formatted_time, eventDescription, actorType FROM system_activity_log ORDER BY timestamp DESC LIMIT 5";
                                        logStmt = logConn.prepareStatement(fetchLogsSQL);
                                        logRs = logStmt.executeQuery();

                                        boolean hasLogs = false;
                                        while (logRs.next()) {
                                            hasLogs = true;
                                            String time = logRs.getString("formatted_time");
                                            String event = logRs.getString("eventDescription");
                                            String actor = logRs.getString("actorType");
                                            
                                            // Assign appropriate CSS pill class based on actor type
                                            String pillClass = "actor-system";
                                            if ("Technician".equalsIgnoreCase(actor)) pillClass = "actor-tech";
                                            else if ("Lecturer".equalsIgnoreCase(actor)) pillClass = "actor-lecturer";
                                            else if ("System".equalsIgnoreCase(actor)) pillClass = "actor-system";
                                %>
                                    <tr>
                                        <td style="font-family: 'JetBrains Mono', monospace; font-size: 12.5px;"><%= time %></td>
                                        <td><%= event %></td>
                                        <td><span class="actor-pill <%= pillClass %>"><%= actor %></span></td>
                                    </tr>
                                <%
                                        }
                                        if (!hasLogs) {
                                %>
                                    <tr><td colspan="3" style="text-align: center; color: var(--text-muted); padding: 20px;">No recent system activity recorded.</td></tr>
                                <%
                                        }
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    } finally {
                                        if (logRs != null) try { logRs.close(); } catch (SQLException e) {}
                                        if (logStmt != null) try { logStmt.close(); } catch (SQLException e) {}
                                        if (logConn != null) try { logConn.close(); } catch (SQLException e) {}
                                    }
                                %>
                                </tbody>
                            </table>
                        </div>
                    </div>

                </div>

                <div class="dashboard-card">
                    <div class="card-header-row">
                        <h2 class="card-title">Quick Actions</h2>
                    </div>
                    <div class="quick-actions">
                        <!-- Manage Lecturers Quick Action Card -->
                        <a href="<%= request.getContextPath() %>/admin/manage-lecturers" class="action-link">
                            <div class="action-icon">
                                <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                                    <circle cx="9" cy="7" r="4"></circle>
                                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                                    <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                                </svg>
                            </div>
                            <div class="action-text">
                                <strong>Manage Lecturers</strong>
                                <span>Register faculty &amp; assign departments</span>
                            </div>
                        </a>

                        <a href="<%= request.getContextPath() %>/admin/reports" class="action-link">
                            <div class="action-icon">
                                <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
                            </div>
                            <div class="action-text">
                                <strong>Generate Compliance Report</strong>
                                <span>Attendance, utilization, or contact hours</span>
                            </div>
                        </a>

                        <a href="<%= request.getContextPath() %>/admin/monitor-usage" class="action-link">
                            <div class="action-icon">
                                <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"></path></svg>
                            </div>
                            <div class="action-text">
                                <strong>Monitor Live Lab Usage</strong>
                                <span>Real-time occupancy &amp; room status</span>
                            </div>
                        </a>
                    </div>
                </div>

            </div>
        </main>
    </div>

    <script>
        function toggleMobileNav() {
            const drawer = document.getElementById("mobile-drawer");
            drawer.style.display = (drawer.style.display === "block") ? "none" : "block";
        }

        const ctx = document.getElementById('utilizationTrendChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6'],
                datasets: [{
                    label: 'Avg. Utilization Rate (%)',
                    data: [58, 61, 65, 63, 70, 68],
                    backgroundColor: 'rgba(217, 119, 6, 0.12)',
                    borderColor: '#d97706',
                    borderWidth: 3,
                    tension: 0.3,
                    pointBackgroundColor: '#0f172a',
                    pointRadius: 4,
                    fill: true
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
                    x: { grid: { display: false }, ticks: { color: '#64748b', font: { weight: '500' } } }
                }
            }
        });
    </script>
</body>
</html>