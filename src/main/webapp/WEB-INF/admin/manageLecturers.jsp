<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.mycompany.mlms_system.database.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>

<%
    // Strictly block non-admin accounts
    if (session.getAttribute("userToken") == null || !"ADMIN".equalsIgnoreCase((String) session.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String currentUserName = (String) session.getAttribute("userName");
    if (currentUserName == null) currentUserName = "Super Admin";

    String statusMsg = request.getParameter("status");
    String errorMsg = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Manage Lecturers | MLMS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
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

        /* Workspace Wrapper */
        .app-wrapper { flex-grow: 1; display: flex; flex-direction: column; min-width: 0; }
        main { flex-grow: 1; padding: 35px 30px; max-width: 1400px; width: 100%; box-sizing: border-box; }
        
        .top-navbar { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 20px; margin-bottom: 30px; }
        .page-title h1 { margin: 0; font-size: 24px; font-weight: 800; }
        .page-title p { margin: 4px 0 0 0; color: var(--text-muted); font-size: 13.5px; }
        .user-profile { display: flex; align-items: center; background: var(--white); padding: 8px 14px; border-radius: 20px; border: 1px solid var(--border-color); font-size: 13px; font-weight: 600; }

        .layout-grid { display: grid; grid-template-columns: 380px 1fr; gap: 24px; align-items: start; }
        .card { background-color: var(--white); border-radius: 14px; border: 1px solid var(--border-color); padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.01); }
        .card-title { font-size: 16px; font-weight: 700; margin-bottom: 18px; border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; }

        .form-group { display: flex; flex-direction: column; gap: 6px; margin-bottom: 16px; }
        .form-group label { font-size: 11.5px; font-weight: 700; color: #334155; text-transform: uppercase; letter-spacing: 0.5px; }
        .form-control { width: 100%; padding: 11px 13px; font-size: 14px; border: 1px solid var(--border-color); border-radius: 8px; background-color: #f8fafc; }
        .form-control:focus { outline: none; border-color: var(--admin-amber); background-color: var(--white); }

        .btn-submit { background-color: #2563eb; color: var(--white); border: none; padding: 12px; font-size: 14px; font-weight: 700; border-radius: 8px; cursor: pointer; width: 100%; transition: background-color 0.15s; }
        .btn-submit:hover { background-color: #1d4ed8; }

        .alert-box { padding: 12px 16px; border-radius: 8px; font-size: 13px; font-weight: 600; margin-bottom: 20px; }
        .alert-success { background-color: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; }
        .alert-danger { background-color: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }

        .table-responsive { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; }
        table { width: 100%; border-collapse: collapse; text-align: left; }
        th, td { padding: 14px 12px; font-size: 13.5px; border-bottom: 1px solid var(--border-color); }
        th { background-color: #f8fafc; color: #475569; font-weight: 700; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }

        .mobile-topbar, #mobile-drawer { display: none; }

        @media (max-width: 950px) {
            .layout-grid { grid-template-columns: 1fr; }
            body { flex-direction: column; }
            aside { display: none; }
            main { padding: 20px 16px; }

            .mobile-topbar {
                display: flex; justify-content: space-between; align-items: center;
                background-color: var(--sidebar-bg); color: var(--white); padding: 16px 20px;
                position: sticky; top: 0; z-index: 50;
            }
            .mobile-brand { font-size: 18px; font-weight: 800; }
            .mobile-brand span { color: var(--admin-amber); }
            .mobile-menu-btn { background: none; border: none; color: white; font-size: 24px; cursor: pointer; }

            #mobile-drawer { background-color: #0f172a; padding: 12px 0; border-bottom: 1px solid #334155; }
            #mobile-drawer a { display: block; padding: 12px 24px; color: #cbd5e1; text-decoration: none; font-size: 14px; font-weight: 500; }
            #mobile-drawer a:hover, #mobile-drawer a.active { background: rgba(217, 119, 6, 0.15); color: var(--admin-amber); font-weight: 700; }
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

            <li class="sidebar-item active">
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
            <a href="<%= request.getContextPath() %>/admin/dashboard">📊 Dashboard Overview</a>
            <a href="<%= request.getContextPath() %>/admin/manage-lecturers" class="active">👨‍🏫 Manage Lecturers</a>
            <a href="<%= request.getContextPath() %>/admin/reports">📑 Generate Reports</a>
            <a href="<%= request.getContextPath() %>/admin/monitor-usage">📈 Monitor Lab Usage</a>
            <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">🚪 Sign Out</a>
        </div>

        <main>
            <div class="top-navbar">
                <div class="page-title">
                    <h1>Faculty &amp; Lecturer Directory</h1>
                    <p>Register new lecturers and review assigned departmental faculties.</p>
                </div>
                <div class="user-profile">🛡️ Admin: <%= currentUserName %></div>
            </div>

            <% if ("created".equals(statusMsg)) { %>
                <div class="alert-box alert-success">✅ New Lecturer profile created successfully!</div>
            <% } else if (errorMsg != null) { %>
                <div class="alert-box alert-danger">⚠️ <%= errorMsg %></div>
            <% } %>

            <div class="layout-grid">
                
                <!-- Create Lecturer Form -->
                <div class="card">
                    <h2 class="card-title">Register New Lecturer</h2>
                    <form action="<%= request.getContextPath() %>/LecturerManagementServlet" method="POST">
                        <input type="hidden" name="action" value="ADD_LECTURER">

                        <div class="form-group">
                            <label for="name">Full Name</label>
                            <input type="text" id="name" name="name" class="form-control" placeholder="e.g. Prof. Siti Sarah" required>
                        </div>

                        <div class="form-group">
                            <label for="username">System Username</label>
                            <input type="text" id="username" name="username" class="form-control" placeholder="e.g. sitisarah" required>
                        </div>

                        <div class="form-group">
                            <label for="department">Department</label>
                            <select id="department" name="department" class="form-control" required>
                                <option value="" disabled selected>-- Select Department --</option>
                                <option value="Department of Computer Science">Department of Computer Science</option>
                                <option value="Department of Physics">Department of Physics</option>
                                <option value="Department of Chemistry">Department of Chemistry</option>
                                <option value="Department of Biology">Department of Biology</option>
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label for="password">Default Login Password</label>
                            <input type="password" id="password" name="password" class="form-control" placeholder="Default: pass123" required>
                        </div>

                        <button type="submit" class="btn-submit">+ Register Lecturer</button>
                    </form>
                </div>

                <!-- Existing Lecturers Directory Table -->
                <div class="card">
                    <h2 class="card-title">Active Faculty Members</h2>
                    <div class="table-responsive">
                        <table>
                            <thead>
                                <tr>
                                    <th>User ID</th>
                                    <th>Lecturer Name</th>
                                    <th>Username</th>
                                    <th>Department</th>
                                </tr>
                            </thead>
                            <tbody>
                            <%
                                Connection conn = null;
                                PreparedStatement stmt = null;
                                ResultSet rs = null;
                                try {
                                    conn = DBConnection.getConnection();
                                    String sql = "SELECT u.userId, u.name, u.username, l.department "
                                               + "FROM user u "
                                               + "JOIN lecturer l ON u.userId = l.userId "
                                               + "ORDER BY u.userId DESC";
                                    stmt = conn.prepareStatement(sql);
                                    rs = stmt.executeQuery();

                                    boolean hasRows = false;
                                    while (rs.next()) {
                                        hasRows = true;
                            %>
                                <tr>
                                    <td style="font-family: 'JetBrains Mono', monospace; font-weight: bold;"><%= rs.getInt("userId") %></td>
                                    <td style="font-weight: 600;"><%= rs.getString("name") %></td>
                                    <td style="font-family: 'JetBrains Mono', monospace; color: #2563eb;"><%= rs.getString("username") %></td>
                                    <td><%= rs.getString("department") != null ? rs.getString("department") : "Unassigned" %></td>
                                </tr>
                            <%
                                    }
                                    if (!hasRows) {
                            %>
                                <tr><td colspan="4" style="text-align: center; color: var(--text-muted); padding: 20px;">No lecturer records found.</td></tr>
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