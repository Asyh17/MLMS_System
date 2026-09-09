<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.mycompany.mlms_system.database.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.List"%>
<%@page import="java.util.HashMap"%>
<%@page import="java.util.Map"%>

<%
    // Session Guard Check
    String userRole = (String) session.getAttribute("userRole");
    if (session.getAttribute("userToken") == null || 
        (!"TECHNICIAN".equalsIgnoreCase(userRole) && !"LAB TECHNICIAN".equalsIgnoreCase(userRole))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    List<Map<String, String>> labList = new ArrayList<>();
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        String sql = "SELECT labId, labName, capacity, status, location FROM laboratory ORDER BY labId ASC";
        stmt = conn.prepareStatement(sql);
        rs = stmt.executeQuery();

        while (rs.next()) {
            Map<String, String> lab = new HashMap<>();
            lab.put("id", rs.getString("labId"));
            lab.put("name", rs.getString("labName"));
            lab.put("capacity", String.valueOf(rs.getInt("capacity")));
            lab.put("status", rs.getString("status"));
            lab.put("location", rs.getString("location"));
            labList.add(lab);
        }
    } catch (SQLException e) {
        e.printStackTrace();
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (stmt != null) stmt.close(); } catch (SQLException e) {}
        try { if (conn != null) conn.close(); } catch (SQLException e) {}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Lab Profiles | MLMS Technician</title>
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
        
        .header-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; gap: 15px; }
        .header-title h1 { margin: 0; font-size: 24px; font-weight: 800; }
        .header-title p { margin: 4px 0 0 0; color: var(--text-muted); font-size: 13.5px; }

        .btn-add {
            background-color: var(--accent-color); color: white; border: none;
            padding: 11px 18px; font-size: 13.5px; font-weight: 600; border-radius: 8px;
            cursor: pointer; display: inline-flex; align-items: center; gap: 8px; white-space: nowrap;
        }
        .btn-add:hover { opacity: 0.9; }

        .card-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 20px; }
        .lab-card { background: var(--white); border-radius: 14px; border: 1px solid var(--border-color); padding: 22px; box-shadow: 0 2px 4px rgba(0,0,0,0.01); }
        .lab-card-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 12px; }
        .lab-title { font-size: 16px; font-weight: 700; color: var(--primary-color); margin: 0; }
        .lab-id { font-size: 12px; font-family: 'JetBrains Mono', monospace; color: var(--text-muted); }

        .status-badge { padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
        .status-OPERATIONAL { background-color: #d1fae5; color: #065f46; }
        .status-MAINTENANCE { background-color: #fef3c7; color: #92400e; }

        .lab-meta { font-size: 13px; color: var(--text-muted); margin-bottom: 18px; line-height: 1.6; }
        .action-row { display: flex; gap: 10px; border-top: 1px solid var(--border-color); padding-top: 14px; }
        .select-status { padding: 8px 12px; font-size: 13px; border-radius: 6px; border: 1px solid var(--border-color); flex-grow: 1; outline: none; }
        .btn-update { background-color: var(--primary-color); color: white; border: none; padding: 8px 14px; border-radius: 6px; font-size: 13px; font-weight: 600; cursor: pointer; }

        /* Modal Styles */
        .modal-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(15, 23, 42, 0.6); display: none; align-items: center; justify-content: center; z-index: 1000; padding: 16px; }
        .modal-body { background: white; border-radius: 14px; padding: 26px; width: 100%; max-width: 440px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); }
        .modal-title { font-size: 18px; font-weight: 700; margin-bottom: 18px; }
        .form-group { margin-bottom: 14px; }
        .form-group label { display: block; font-size: 12.5px; font-weight: 600; margin-bottom: 5px; color: #334155; text-transform: uppercase; }
        .form-control { width: 100%; padding: 10px 12px; border: 1px solid var(--border-color); border-radius: 8px; box-sizing: border-box; font-size: 14px; outline: none; }
        .modal-actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 20px; }
        .btn-cancel { background: #e2e8f0; border: none; padding: 10px 16px; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 13px; }

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
            .mobile-brand span { color: var(--accent-color); }
            .mobile-menu-btn { background: none; border: none; color: white; font-size: 24px; cursor: pointer; }
            
            #mobile-drawer {
                background-color: #0f172a; padding: 12px 0; border-bottom: 1px solid #334155;
            }
            #mobile-drawer a { display: block; padding: 12px 24px; color: #cbd5e1; text-decoration: none; font-size: 14px; font-weight: 500; }
            #mobile-drawer a:hover, #mobile-drawer a.active { background: rgba(16, 185, 129, 0.15); color: var(--accent-color); font-weight: 700; }

            main { padding: 20px 16px; }
            .header-row { flex-direction: column; align-items: flex-start; }
            .btn-add { width: 100%; justify-content: center; }
            .card-grid { grid-template-columns: 1fr; }
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
            <li class="sidebar-item">
                <a href="<%= request.getContextPath() %>/technician/verify-labs">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line></svg>
                    <span>Verify Lab Status</span>
                </a>
            </li>
            <li class="sidebar-item active">
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
            <a href="<%= request.getContextPath() %>/technician/verify-labs">✅ Verify Lab Status</a>
            <a href="<%= request.getContextPath() %>/technician/lab-profile" class="active">🔬 Lab Profiles</a>
            <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">🚪 Sign Out</a>
        </div>

        <main>
            <div class="header-row">
                <div class="header-title">
                    <h1>Laboratory Profiles &amp; Configuration</h1>
                    <p>Register new facilities, update maintenance status, and configure lab capacities.</p>
                </div>
                <button class="btn-add" onclick="openModal()">+ Insert New Laboratory</button>
            </div>

            <div class="card-grid">
                <% for (Map<String, String> lab : labList) { %>
                    <div class="lab-card">
                        <div class="lab-card-header">
                            <div>
                                <h3 class="lab-title"><%= lab.get("name") %></h3>
                                <span class="lab-id">ID: <%= lab.get("id") %></span>
                            </div>
                            <span class="status-badge status-<%= lab.get("status") %>"><%= lab.get("status") %></span>
                        </div>

                        <div class="lab-meta">
                            📍 <b>Location:</b> <%= lab.get("location") %><br>
                            👥 <b>Student Capacity:</b> <%= lab.get("capacity") %> Seats
                        </div>

                        <form action="<%= request.getContextPath() %>/ManageLabServlet" method="POST" class="action-row">
                            <input type="hidden" name="action" value="UPDATE_STATUS">
                            <input type="hidden" name="labId" value="<%= lab.get("id") %>">
                            <select name="status" class="select-status">
                                <option value="OPERATIONAL" <%= "OPERATIONAL".equals(lab.get("status")) ? "selected" : "" %>>Operational</option>
                                <option value="MAINTENANCE" <%= "MAINTENANCE".equals(lab.get("status")) ? "selected" : "" %>>Under Maintenance</option>
                            </select>
                            <button type="submit" class="btn-update">Update</button>
                        </form>
                    </div>
                <% } %>
            </div>
        </main>
    </div>

    <!-- Insert Modal -->
    <div class="modal-overlay" id="addModal">
        <div class="modal-body">
            <div class="modal-title">Register New Laboratory</div>
            <form action="<%= request.getContextPath() %>/ManageLabServlet" method="POST">
                <input type="hidden" name="action" value="ADD">
                
                <div class="form-group">
                    <label>Lab Code / ID</label>
                    <input type="text" name="labId" class="form-control" placeholder="LAB_NET_01" required>
                </div>
                
                <div class="form-group">
                    <label>Laboratory Name</label>
                    <input type="text" name="labName" class="form-control" placeholder="Networking Lab" required>
                </div>

                <div class="form-group">
                    <label>Student Capacity</label>
                    <input type="number" name="capacity" class="form-control" value="30" required>
                </div>

                <div class="form-group">
                    <label>Location / Block</label>
                    <input type="text" name="location" class="form-control" placeholder="Block D, Level 1" required>
                </div>

                <div class="form-group">
                    <label>Initial Status</label>
                    <select name="status" class="form-control">
                        <option value="OPERATIONAL">Operational</option>
                        <option value="MAINTENANCE">Under Maintenance</option>
                    </select>
                </div>

                <div class="modal-actions">
                    <button type="button" class="btn-cancel" onclick="closeModal()">Cancel</button>
                    <button type="submit" class="btn-add">Save Laboratory</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function toggleMobileNav() {
            const drawer = document.getElementById("mobile-drawer");
            drawer.style.display = (drawer.style.display === "block") ? "none" : "block";
        }
        function openModal() { document.getElementById('addModal').style.display = 'flex'; }
        function closeModal() { document.getElementById('addModal').style.display = 'none'; }
    </script>
</body>
</html>