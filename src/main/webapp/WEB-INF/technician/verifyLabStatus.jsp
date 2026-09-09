<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.mycompany.mlms_system.database.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>

<%
    // Session Guard Check
    String userRole = (String) session.getAttribute("userRole");
    if (session.getAttribute("userToken") == null || 
        (!"TECHNICIAN".equalsIgnoreCase(userRole) && !"LAB TECHNICIAN".equalsIgnoreCase(userRole))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String successMsg = (String) session.getAttribute("successMsg");
    if (successMsg != null) {
        session.removeAttribute("successMsg");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Verify Lab Bookings | MLMS Technician</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-color: #2c3e50;
            --accent-color: #10b981;
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
            background-color: var(--main-bg); color: var(--text-dark);
            display: flex; min-height: 100vh;
        }

        aside {
            width: 280px; background-color: var(--sidebar-bg); color: var(--white);
            display: flex; flex-direction: column; flex-shrink: 0; min-height: 100vh;
        }
        .sidebar-header { padding: 26px 24px; font-size: 20px; font-weight: 800; border-bottom: 1px solid #334155; }
        .sidebar-header span { color: var(--accent-color); }
        .sidebar-menu { list-style: none; padding: 20px 0; margin: 0; flex-grow: 1; }
        .menu-label { padding: 0 24px 10px 24px; font-size: 11px; font-weight: 700; text-transform: uppercase; color: #475569; letter-spacing: 1px; }
        .sidebar-item a { display: flex; align-items: center; padding: 13px 24px; color: #94a3b8; text-decoration: none; font-weight: 500; font-size: 14.5px; border-left: 4px solid transparent; }
        .sidebar-item.active a, .sidebar-item a:hover { background-color: rgba(16, 185, 129, 0.08); color: var(--white); border-left-color: var(--accent-color); }
        .sidebar-item svg { width: 18px; height: 18px; margin-right: 14px; fill: none; stroke: #94a3b8; stroke-width: 2; }
        .sidebar-item.active svg, .sidebar-item a:hover svg { stroke: #ffffff; }

        .app-wrapper { flex-grow: 1; display: flex; flex-direction: column; min-width: 0; }
        main { flex-grow: 1; padding: 35px 30px; max-width: 1400px; width: 100%; box-sizing: border-box; }
        
        .header-panel { margin-bottom: 25px; }
        .header-panel h1 { margin: 0; font-size: 24px; font-weight: 800; }
        .header-panel p { margin: 4px 0 0 0; color: var(--text-muted); font-size: 13.5px; }

        .alert-success { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46; padding: 12px 16px; border-radius: 8px; font-size: 13.5px; font-weight: 600; margin-bottom: 20px; }

        .card { background: var(--white); border-radius: 14px; border: 1px solid var(--border-color); padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.01); }
        .table-responsive { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; }
        table { width: 100%; border-collapse: collapse; text-align: left; }
        th, td { padding: 13px 12px; border-bottom: 1px solid var(--border-color); font-size: 13.5px; vertical-align: middle; }
        th { background-color: #f8fafc; color: #475569; font-weight: 700; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }

        .btn-approve { background-color: var(--accent-color); color: white; border: none; padding: 7px 14px; border-radius: 6px; font-size: 12px; font-weight: 700; cursor: pointer; }
        .btn-approve:hover { opacity: 0.9; }
        .btn-reject { background-color: white; color: var(--danger-red); border: 1px solid var(--danger-red); padding: 6px 12px; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; }
        .btn-reject:hover { background-color: var(--danger-red); color: white; }

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
            .mobile-brand span { color: var(--accent-color); }
            .mobile-menu-btn { background: none; border: none; color: white; font-size: 24px; cursor: pointer; }
            
            #mobile-drawer { background-color: #0f172a; padding: 12px 0; border-bottom: 1px solid #334155; }
            #mobile-drawer a { display: block; padding: 12px 24px; color: #cbd5e1; text-decoration: none; font-size: 14px; font-weight: 500; }
            #mobile-drawer a:hover, #mobile-drawer a.active { background: rgba(16, 185, 129, 0.15); color: var(--accent-color); font-weight: 700; }

            main { padding: 20px 16px; }
            table, thead, tbody, th, td, tr { display: block; }
            thead tr { position: absolute; top: -9999px; left: -9999px; }
            tbody tr { background: #ffffff; border: 1px solid var(--border-color); border-radius: 12px; margin-bottom: 12px; padding: 12px; }
            td { border: none; padding: 6px 0; display: flex; justify-content: space-between; align-items: center; }
            td::before { content: attr(data-label); font-weight: 700; color: #64748b; font-size: 11px; text-transform: uppercase; }
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
            <li class="sidebar-item">
                <a href="<%= request.getContextPath() %>/technician/schedules">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                    <span>Schedule Entries</span>
                </a>
            </li>
            <li class="sidebar-item active">
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
            <a href="<%= request.getContextPath() %>/technician/schedules">📅 Schedule Entries</a>
            <a href="<%= request.getContextPath() %>/technician/verify-labs" class="active">✅ Verify Lab Status</a>
            <a href="<%= request.getContextPath() %>/technician/lab-profile">🔬 Lab Profiles</a>
            <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">🚪 Sign Out</a>
        </div>

        <main>
            <div class="header-panel">
                <h1>Verify Pending Lab Requests</h1>
                <p>Review faculty booking submissions and allocate or reject requested lab time slots.</p>
            </div>

            <% if (successMsg != null) { %>
                <div class="alert-success">✅ <%= successMsg %></div>
            <% } %>

            <div class="card">
                <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Booking ID</th>
                                <th>Lecturer</th>
                                <th>Lab</th>
                                <th>Date</th>
                                <th>Time Slot</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                            Connection conn = null;
                            PreparedStatement stmt = null;
                            ResultSet rs = null;
                            try {
                                conn = DBConnection.getConnection();
                                String sql = "SELECT b.bookingId, b.labId, u.name, DATE_FORMAT(b.bookingDate, '%d/%m/%Y') AS b_date, b.timeSlot " +
                                             "FROM Booking b JOIN user u ON b.lecturerId = u.userId " +
                                             "WHERE LOWER(b.status) = 'pending' ORDER BY b.bookingDate ASC";
                                stmt = conn.prepareStatement(sql);
                                rs = stmt.executeQuery();

                                boolean hasRows = false;
                                while (rs.next()) {
                                    hasRows = true;
                                    String bId = rs.getString("bookingId");
                        %>
                            <tr>
                                <td data-label="Booking ID" style="font-family: 'JetBrains Mono', monospace; font-weight: bold;"><%= bId %></td>
                                <td data-label="Lecturer"><%= rs.getString("name") %></td>
                                <td data-label="Lab"><%= rs.getString("labId") %></td>
                                <td data-label="Date"><%= rs.getString("b_date") %></td>
                                <td data-label="Time Slot" style="font-family: 'JetBrains Mono', monospace;"><%= rs.getString("timeSlot") %></td>
                                <td data-label="Actions">
                                    <div style="display: flex; gap: 8px;">
                                        <form action="<%= request.getContextPath() %>/TechnicianControllerServlet" method="POST" style="margin:0;">
                                            <input type="hidden" name="action" value="APPROVE">
                                            <input type="hidden" name="bookingId" value="<%= bId %>">
                                            <button type="submit" class="btn-approve">Approve</button>
                                        </form>
                                        <form action="<%= request.getContextPath() %>/TechnicianControllerServlet" method="POST" style="margin:0;">
                                            <input type="hidden" name="action" value="REJECT">
                                            <input type="hidden" name="bookingId" value="<%= bId %>">
                                            <button type="submit" class="btn-reject">Reject</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        <%
                                }
                                if (!hasRows) {
                        %>
                            <tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 24px;">No pending bookings awaiting verification.</td></tr>
                        <%
                                }
                            } catch (SQLException e) {
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