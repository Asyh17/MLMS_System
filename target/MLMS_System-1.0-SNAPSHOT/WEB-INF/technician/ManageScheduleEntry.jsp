<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.mycompany.mlms_system.database.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>

<%
    // Session Protection Gate Check
    String userRole = (String) session.getAttribute("userRole");
    if (session.getAttribute("userToken") == null || 
        (!"TECHNICIAN".equalsIgnoreCase(userRole) && !"LAB TECHNICIAN".equalsIgnoreCase(userRole))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp"); 
        return;
    }

    String filterLab = request.getParameter("filterLab");
    String filterDate = request.getParameter("filterDate");

    if (filterLab == null) filterLab = "ALL";
    if (filterDate == null) filterDate = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Manage Schedule Entries | MLMS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
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

        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Inter', -apple-system, sans-serif;
            margin: 0; background-color: var(--main-bg);
            color: var(--text-dark); display: flex; min-height: 100vh;
        }

        /* Desktop Sidebar */
        aside {
            width: 280px; background-color: var(--sidebar-bg); color: var(--white);
            display: flex; flex-direction: column; flex-shrink: 0; min-height: 100vh;
        }
        .sidebar-header { padding: 26px 24px; font-size: 20px; font-weight: 800; border-bottom: 1px solid #334155; }
        .sidebar-header span { color: var(--technician-green); }
        .sidebar-menu { list-style: none; padding: 20px 0; margin: 0; flex-grow: 1; }
        .menu-label { padding: 0 24px 10px 24px; font-size: 11px; font-weight: 700; text-transform: uppercase; color: #475569; letter-spacing: 1px; }
        .sidebar-item a { display: flex; align-items: center; padding: 13px 24px; color: #94a3b8; text-decoration: none; font-weight: 500; font-size: 14.5px; border-left: 4px solid transparent; }
        .sidebar-item.active a, .sidebar-item a:hover { background-color: rgba(0, 166, 90, 0.08); color: var(--white); border-left-color: var(--technician-green); }
        .sidebar-item svg { width: 18px; height: 18px; margin-right: 14px; fill: none; stroke: #94a3b8; stroke-width: 2; }
        .sidebar-item.active svg, .sidebar-item a:hover svg { stroke: #ffffff; }

        .app-wrapper { flex-grow: 1; display: flex; flex-direction: column; min-width: 0; }
        main { flex-grow: 1; padding: 35px 30px; box-sizing: border-box; width: 100%; max-width: 1400px; }
        .container { background: var(--white); padding: 26px; border-radius: 14px; border: 1px solid var(--border-color); box-shadow: 0 1px 3px rgba(0,0,0,0.01); border-top: 4px solid var(--technician-green); }
        h1 { color: var(--text-dark); margin-bottom: 4px; font-size: 24px; font-weight: 800; }
        
        .filter-panel-card { background-color: #f8fafc; border: 1px solid var(--border-color); padding: 18px; border-radius: 10px; margin-top: 18px; margin-bottom: 22px; }
        .filter-flex-row { display: flex; align-items: center; gap: 16px; flex-wrap: wrap; }
        .filter-group { display: flex; flex-direction: column; }
        .filter-group label { font-size: 11.5px; font-weight: 700; color: #475569; text-transform: uppercase; margin-bottom: 5px; }
        .filter-control { padding: 9px 12px; font-size: 13.5px; border: 1px solid #cbd5e1; border-radius: 8px; background-color: var(--white); outline: none; min-width: 200px; color: var(--text-dark); font-weight: 500; }
        .btn-filter-submit { background-color: var(--technician-green); color: white; border: none; padding: 10px 18px; font-size: 13.5px; font-weight: 600; border-radius: 8px; cursor: pointer; align-self: flex-end; margin-top: auto; }

        .table-responsive { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; text-align: left; }
        th, td { padding: 13px 12px; border-bottom: 1px solid var(--border-color); font-size: 13.5px; vertical-align: middle; }
        th { background-color: #f8fafc; color: #475569; font-weight: 700; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }

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

            main { padding: 20px 16px; }
            .container { padding: 18px 14px; }
            .filter-flex-row { flex-direction: column; align-items: stretch; }
            .filter-control { width: 100%; }
            .btn-filter-submit { width: 100%; }

            /* Table-to-Cards Transformation */
            table, thead, tbody, th, td, tr { display: block; }
            thead tr { position: absolute; top: -9999px; left: -9999px; }
            tbody tr {
                background: #ffffff; border: 1px solid var(--border-color);
                border-radius: 12px; margin-bottom: 12px; padding: 12px;
            }
            td { border: none; padding: 6px 0; display: flex; justify-content: space-between; align-items: center; }
            td::before { content: attr(data-label); font-weight: 700; color: #64748b; font-size: 11px; text-transform: uppercase; }
            td.empty-row { display: block; text-align: center; padding: 16px 0; }
            td.empty-row::before { display: none; }
        }
    </style>
</head>
<body>

    <!-- Desktop Sidebar -->
    <aside>
        <div class="sidebar-header"><span>MLMS</span>.Technician</div>
        <ul class="sidebar-menu">
            <li class="menu-label">Main Tasks</li>
            <li class="sidebar-item">
                <a href="<%= request.getContextPath() %>/technician/dashboard">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="9"></rect><rect x="14" y="3" width="7" height="5"></rect><rect x="14" y="12" width="7" height="9"></rect><rect x="3" y="16" width="7" height="5"></rect></svg>
                    <span>Dashboard Overview</span>
                </a>
            </li>
            <li class="sidebar-item active">
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

    <!-- Main Workspace Container -->
    <div class="app-wrapper">
        <div class="mobile-topbar">
            <div class="mobile-brand"><span>MLMS</span>.Technician</div>
            <button class="mobile-menu-btn" onclick="toggleMobileNav()">☰</button>
        </div>
        <div id="mobile-drawer">
            <a href="<%= request.getContextPath() %>/technician/dashboard">📊 Dashboard Overview</a>
            <a href="<%= request.getContextPath() %>/technician/schedules" class="active">📅 Schedule Entries</a>
            <a href="<%= request.getContextPath() %>/technician/verify-labs">✅ Verify Lab Status</a>
            <a href="<%= request.getContextPath() %>/technician/lab-profile">🔬 Lab Profiles</a>
            <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">🚪 Sign Out</a>
        </div>

        <main>
            <div class="container">
                <h1>Master Laboratory Timetable Ledger</h1>
                <p style="color: var(--text-muted); font-size: 13.5px; margin-top: 2px;">Search and query comprehensive approved course allocations across multi-department facility spaces.</p>

                <div class="filter-panel-card">
                    <form action="<%= request.getContextPath() %>/technician/schedules" method="GET">
                        <div class="filter-flex-row">
                            <div class="filter-group">
                                <label for="filterLab">Filter By Lab Facility</label>
                                <select name="filterLab" id="filterLab" class="filter-control">
                                    <option value="ALL" <%= "ALL".equals(filterLab) ? "selected" : "" %>>All Environments Combined</option>
                                    <option value="LAB_CS_04" <%= "LAB_CS_04".equals(filterLab) ? "selected" : "" %>>Computer Science Lab (CS 04)</option>
                                    <option value="LAB_PHYS_01" <%= "LAB_PHYS_01".equals(filterLab) ? "selected" : "" %>>Physics Lab (PHYS 01)</option>
                                    <option value="LAB_CHEM_01" <%= "LAB_CHEM_01".equals(filterLab) ? "selected" : "" %>>Chemistry Lab (CHEM 01)</option>
                                    <option value="LAB_BIO_01" <%= "LAB_BIO_01".equals(filterLab) ? "selected" : "" %>>Biology Lab (BIO 01)</option>
                                </select>
                            </div>

                            <div class="filter-group">
                                <label for="filterDate">Filter By Specific Date</label>
                                <input type="date" name="filterDate" id="filterDate" class="filter-control" value="<%= filterDate %>">
                            </div>

                            <button type="submit" class="btn-filter-submit">Search</button>
                        </div>
                    </form>
                </div>

                <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Booking ID</th>
                                <th>Faculty Lecturer Reference</th>
                                <th>Target Lab Space</th>
                                <th>Reservation Date</th>
                                <th>Selected Time Window</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                            Connection conn = null;
                            PreparedStatement stmt = null;
                            ResultSet rs = null;
                            
                            try {
                                conn = DBConnection.getConnection();
                                String sql = "SELECT bookingId, labId, lecturerId, DATE_FORMAT(bookingDate, '%d/%m/%Y') AS b_date, timeSlot " +
                                             "FROM Booking WHERE LOWER(status) = 'approved' ";
                                
                                if (!"ALL".equals(filterLab)) {
                                    sql += " AND labId = ? ";
                                }
                                if (!filterDate.isBlank()) {
                                    sql += " AND bookingDate = ? ";
                                }
                                sql += " ORDER BY bookingDate ASC, timeSlot ASC";
                                
                                stmt = conn.prepareStatement(sql);
                                
                                int bindIndex = 1;
                                if (!"ALL".equals(filterLab)) {
                                    stmt.setString(bindIndex++, filterLab);
                                }
                                if (!filterDate.isBlank()) {
                                    stmt.setString(bindIndex++, filterDate);
                                }
                                
                                rs = stmt.executeQuery();
                                boolean hasRecords = false;
                                
                                while(rs.next()) {
                                    hasRecords = true;
                                    String labCode = rs.getString("labId");
                                    if ("LAB_CS_04".equals(labCode)) labCode = "Computer Science Lab (CS 04)";
                                    else if ("LAB_PHYS_01".equals(labCode)) labCode = "Physics Lab (PHY 01)";
                                    else if ("LAB_CHEM_01".equals(labCode)) labCode = "Chemistry Lab (CHM 01)";
                                    else if ("LAB_BIO_01".equals(labCode)) labCode = "Biology Lab (BIO 01)";

                                    String rawTime = rs.getString("timeSlot");
                                    if ("10:00:00".equals(rawTime)) rawTime = "10:00 AM - 12:00 PM";
                                    else if ("14:00:00".equals(rawTime)) rawTime = "02:00 PM - 04:00 PM";
                        %>
                            <tr>
                                <td data-label="Booking ID"><strong style="font-family: 'JetBrains Mono', monospace;"><%= rs.getString("bookingId") %></strong></td>
                                <td data-label="Supervisor">Supervisor Faculty #<%= rs.getInt("lecturerId") %></td>
                                <td data-label="Target Lab"><%= labCode %></td>
                                <td data-label="Date"><%= rs.getString("b_date") %></td>
                                <td data-label="Time Window" style="font-family: 'JetBrains Mono', monospace;"><%= rawTime %></td>
                            </tr>
                        <%
                                }
                                if(!hasRecords) {
                        %>
                            <tr><td colspan="5" class="empty-row" style="text-align:center; color: var(--text-muted); padding:20px;">No matching timetable logs match the active query parameters.</td></tr>
                        <%
                                }
                            } catch(SQLException e) {
                                e.printStackTrace();
                            } finally {
                                if (rs != null) rs.close();
                                if (stmt != null) stmt.close();
                                if (conn != null) conn.close();
                            }
                        %>
                        </tbody>
                    </table>
                </div>
            </div>
        </main>
    </div>

    <script>
        function toggleMobileNav() {
            const drawer = document.getElementById("mobile-drawer");
            drawer.style.display = (drawer.style.display === "block") ? "none" : "block";
        }
    </script>
</body>
</html>