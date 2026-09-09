<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.mycompany.mlms_system.database.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>

<%
    // 1. Session Protection Gate Check
    if (session.getAttribute("userToken") == null || !"LECTURER".equalsIgnoreCase((String) session.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    int currentLecturerId = (Integer) session.getAttribute("userId");
    String currentLecturerName = (String) session.getAttribute("userName");
    if (currentLecturerName == null) currentLecturerName = "Lecturer";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Manage My Bookings | MLMS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --lecturer-blue: #3498db;
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
        .sidebar-header span { color: var(--lecturer-blue); }
        .sidebar-menu { list-style: none; padding: 20px 0; margin: 0; }
        
        .menu-label { padding: 0 24px 10px 24px; font-size: 11px; font-weight: 700; text-transform: uppercase; color: #475569; letter-spacing: 1px; }
        .sidebar-item a { display: flex; align-items: center; padding: 13px 24px; color: #94a3b8; text-decoration: none; font-weight: 500; font-size: 14.5px; border-left: 4px solid transparent; }
        .sidebar-item.active a, .sidebar-item a:hover { background-color: rgba(52, 152, 219, 0.08); color: var(--white); border-left-color: var(--lecturer-blue); }
        .sidebar-item svg { width: 18px; height: 18px; margin-right: 14px; fill: none; stroke: #94a3b8; stroke-width: 2; }
        .sidebar-item.active svg, .sidebar-item a:hover svg { stroke: #ffffff; }

        /* Main Viewport Wrapper */
        .app-wrapper {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
            min-width: 0;
        }

        main { flex-grow: 1; padding: 35px 30px; box-sizing: border-box; width: 100%; max-width: 1200px; }
        .dashboard-card { background-color: var(--white); border-radius: 14px; border: 1px solid var(--border-color); padding: 24px; box-shadow: 0 2px 5px rgba(0,0,0,0.01); }
        
        .table-responsive { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; }
        table { width: 100%; border-collapse: collapse; text-align: left; }
        th, td { padding: 13px 12px; font-size: 13.5px; border-bottom: 1px solid var(--border-color); vertical-align: middle; }
        th { background-color: #f8fafc; color: #475569; font-weight: 700; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }

        .btn-delete {
            background-color: var(--white); color: var(--danger-red);
            border: 1px solid var(--danger-red); padding: 6px 12px;
            border-radius: 6px; font-weight: 600; cursor: pointer; font-size: 11.5px;
            transition: all 0.2s ease;
        }
        .btn-delete:hover { background-color: var(--danger-red); color: var(--white); }

        .btn-batch {
            background-color: var(--danger-red); color: var(--white);
            border: none; padding: 6px 12px; border-radius: 6px;
            font-weight: 600; cursor: pointer; font-size: 11.5px;
            transition: opacity 0.2s ease;
        }
        .btn-batch:hover { opacity: 0.9; }

        .badge { padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; text-transform: uppercase; display: inline-block; }
        .badge-pending { background-color: #fef3c7; color: #d97706; border: 1px solid #fde68a; }
        .badge-approved { background-color: #ecfdf5; color: #059669; border: 1px solid #a7f3d0; }
        .badge-rejected { background-color: #fdf2f2; color: #dc2626; border: 1px solid #fbd5d5; }
        .text-locked { color: var(--text-muted); font-size: 12px; font-style: italic; font-weight: 500; }

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
            
            #mobile-drawer {
                background-color: #0f172a; padding: 12px 0; border-bottom: 1px solid #334155;
            }
            #mobile-drawer a {
                display: block; padding: 12px 24px; color: #cbd5e1; text-decoration: none; font-size: 14px; font-weight: 500;
            }
            #mobile-drawer a:hover, #mobile-drawer a.active { background: rgba(52, 152, 219, 0.15); color: var(--lecturer-blue); font-weight: 700; }

            main { padding: 20px 16px; }
            .dashboard-card { padding: 16px 14px; }
            
            table, thead, tbody, th, td, tr { display: block; }
            thead tr { position: absolute; top: -9999px; left: -9999px; }
            tbody tr {
                background: #ffffff; border: 1px solid var(--border-color);
                border-radius: 12px; margin-bottom: 14px; padding: 14px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.01);
            }
            td {
                border: none; padding: 6px 0; display: flex; justify-content: space-between; align-items: center;
            }
            td::before {
                content: attr(data-label); font-weight: 700; color: #64748b; font-size: 11px; text-transform: uppercase;
            }
            td.empty-row { display: block; text-align: center; padding: 20px 0; }
            td.empty-row::before { display: none; }
        }
    </style>
</head>
<body>

    <!-- Desktop Sidebar -->
    <aside>
        <div class="sidebar-header"><span>MLMS</span>.Lecturer</div>
        <ul class="sidebar-menu">
            <li class="menu-label">Main Tasks</li>
            <li class="sidebar-item">
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
            <li class="sidebar-item active">
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
            <a href="<%= request.getContextPath() %>/lecturer/dashboard">📊 Dashboard Overview</a>
            <a href="<%= request.getContextPath() %>/lecturer/book-lab">📅 Book Laboratory Space</a>
            <a href="<%= request.getContextPath() %>/lecturer/my-bookings" class="active">📋 Manage My Bookings</a>
            <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">🚪 Sign Out</a>
        </div>

        <main>
            <div style="margin-bottom: 25px;">
                <h1 style="margin: 0; font-size: 24px; font-weight: 800;">Manage Lab Reservations</h1>
                <p style="color: var(--text-muted); margin: 4px 0 0 0; font-size: 13.5px;">Review or cancel your active workspace allocations below.</p>
            </div>

            <% if (session.getAttribute("errorMsg") != null) { %>
                <div style="background-color: #fde8e7; color: #e74c3c; border: 1px solid #f5c6cb; padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; font-weight: 600; font-size: 13.5px;">
                    ⚠️ <%= session.getAttribute("errorMsg") %>
                </div>
                <% session.removeAttribute("errorMsg"); %>
            <% } %>

            <% if (session.getAttribute("successMsg") != null) { %>
                <div style="background-color: #ecfdf5; color: #10b981; border: 1px solid #a7f3d0; padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; font-weight: 600; font-size: 13.5px;">
                    ✅ <%= session.getAttribute("successMsg") %>
                </div>
                <% session.removeAttribute("successMsg"); %>
            <% } %>

            <div class="dashboard-card">
                <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Booking ID</th>
                                <th>Laboratory Space</th>
                                <th>Date Block</th>
                                <th>Time Window</th>
                                <th>Booking Status</th>
                                <th>Cancel Action</th>
                                <th>Session Control</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                            Connection conn = null;
                            PreparedStatement stmt = null;
                            ResultSet rs = null;
                            try {
                                conn = DBConnection.getConnection();
                                String sql = "SELECT bookingId, labId, DATE_FORMAT(bookingDate, '%d/%m/%Y') AS b_date, timeSlot, status " +
                                             "FROM Booking WHERE lecturerId = ? ORDER BY bookingDate DESC";
                                stmt = conn.prepareStatement(sql);
                                stmt.setInt(1, currentLecturerId);
                                rs = stmt.executeQuery();

                                boolean hasData = false;
                                while(rs.next()) {
                                    hasData = true;
                                    String bId = rs.getString("bookingId");
                                    String labCode = rs.getString("labId");
                                    String rawTime = rs.getString("timeSlot");
                                    
                                    String status = rs.getString("status");
                                    if (status == null || status.isBlank()) {
                                        status = "PENDING";
                                    }

                                    String displayLabName = labCode;
                                    if ("LAB_CS_04".equals(labCode)) displayLabName = "Computer Science Lab (CS 04)";
                                    else if ("LAB_PHYS_01".equals(labCode)) displayLabName = "Physics Lab (Advanced Mechanics)";
                                    else if ("LAB_CHEM_01".equals(labCode)) displayLabName = "Chemistry Lab (Organic Molecular)";
                                    else if ("LAB_BIO_01".equals(labCode)) displayLabName = "Biology Lab (Genetics & Micro)";

                                    String displayTime = rawTime;
                                    if ("10:00:00".equals(rawTime)) displayTime = "10:00 AM - 12:00 PM";
                                    else if ("14:00:00".equals(rawTime)) displayTime = "02:00 PM - 04:00 PM";
                        %>
                            <tr>
                                <td data-label="Booking ID"><strong style="font-family: 'JetBrains Mono', monospace;"><%= bId %></strong></td>
                                <td data-label="Lab Space"><%= displayLabName %></td>
                                <td data-label="Date"><%= rs.getString("b_date") %></td>
                                <td data-label="Window" style="font-family: 'JetBrains Mono', monospace;"><%= displayTime %></td>
                                
                                <td data-label="Status">
                                    <% if ("APPROVED".equalsIgnoreCase(status)) { %>
                                        <span class="badge badge-approved">Approved</span>
                                    <% } else if ("REJECTED".equalsIgnoreCase(status)) { %>
                                        <span class="badge badge-rejected">Rejected</span>
                                    <% } else { %>
                                        <span class="badge badge-pending">Pending</span>
                                    <% } %>
                                </td>
                                
                                <td data-label="Cancel">
                                    <% if ("PENDING".equalsIgnoreCase(status)) { %>
                                        <form action="<%= request.getContextPath() %>/DeleteBookingServlet" method="POST" onsubmit="return confirm('Are you sure you want to cancel this booking?');" style="margin:0;">
                                            <input type="hidden" name="bookingId" value="<%= bId %>">
                                            <button type="submit" class="btn-delete">Cancel</button>
                                        </form>
                                    <% } else { %>
                                        <span class="text-locked">Processed</span>
                                    <% } %>
                                </td>
                                
                                <td data-label="Session Action">
                                    <% if ("APPROVED".equalsIgnoreCase(status)) { %>
                                        <form action="<%= request.getContextPath() %>/BookingServlet" method="POST" style="margin:0;">
                                            <input type="hidden" name="action" value="LECTURER_BATCH_CHECKOUT">
                                            <input type="hidden" name="bookingId" value="<%= bId %>">
                                            <input type="hidden" name="laboratoryId" value="<%= labCode %>">
                                            <button type="submit" class="btn-batch" 
                                                    onclick="return confirm('End class early? This will batch check-out all checked-in students right now.');">
                                                ⏹️ End Class
                                            </button>
                                        </form>
                                    <% } else if ("REJECTED".equalsIgnoreCase(status)) { %>
                                        <span class="text-locked" style="color: var(--danger-red);">Cancelled</span>
                                    <% } else { %>
                                        <span class="text-locked">Awaiting Approval</span>
                                    <% } %>
                                </td>
                            </tr>
                        <%
                                }
                                if(!hasData) {
                        %>
                            <tr><td colspan="7" class="empty-row" style="text-align:center; color:var(--text-muted); padding: 30px;">You have no active laboratory bookings.</td></tr>
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