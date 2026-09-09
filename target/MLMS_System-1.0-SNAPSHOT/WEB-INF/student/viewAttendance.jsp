<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.mycompany.mlms_system.database.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>

<%
    if (session.getAttribute("userToken") == null || !"STUDENT".equalsIgnoreCase((String) session.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }    
    
    int currentStudentId = (Integer) session.getAttribute("userId");
    String currentStudentName = (String) session.getAttribute("userName");
    if (currentStudentName == null) {
        currentStudentName = "Student Profile";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Attendance History | MLMS</title>
    <style>
        :root {
            --primary-purple: #6c5ce7;
            --main-bg: #f8f9fd;
            --text-dark: #2d3436;
            --border-color: #e2e8f0;
            --white: #ffffff;
            --uitm-blue: #3498db;
            
            --color-present: #319795;
            --bg-present: #e6fffa;
            --border-present: #b2f5ea;
            
            --color-late: #dd6b20;
            --bg-late: #fffaf0;
            --border-late: #ffe3c3;
            
            --color-absent: #e53e3e;
            --bg-absent: #fff5f5;
            --border-absent: #fed7d7;
            
            --color-mc: #3182ce;
            --bg-mc: #ebf8ff;
            --border-mc: #bee3f8;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background-color: var(--main-bg);
            color: var(--text-dark);
            min-height: 100vh;
        }

        main {
            padding: 24px 16px;
            max-width: 800px;
            margin: 0 auto 90px auto;
            width: 100%;
            box-sizing: border-box;
        }

        .header-banner {
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: var(--white);
            padding: 14px 18px;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            margin-bottom: 24px;
            gap: 10px;
        }

        .brand-logo { font-size: 20px; font-weight: 800; letter-spacing: 0.5px; color: var(--text-dark); }
        .brand-logo span { color: var(--primary-purple); }
        .user-profile-badge { font-size: 13px; font-weight: 600; background: #f1f5f9; padding: 6px 12px; border-radius: 20px; color: #475569; white-space: nowrap; }

        .dashboard-panel {
            background-color: var(--white);
            border-radius: 12px;
            border: 1px solid var(--border-color);
            padding: 24px 20px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.01);
        }

        .panel-header { font-size: 18px; font-weight: 700; margin: 0; color: var(--text-dark); }
        .panel-subheader { color: #718096; margin: 6px 0 22px 0; font-size: 13.5px; line-height: 1.4; }

        .table-responsive-wrapper {
            width: 100%;
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
        }

        table { 
            width: 100%; 
            border-collapse: collapse; 
            text-align: left; 
            min-width: 550px;
        }

        th, td { padding: 14px 12px; font-size: 14px; border-bottom: 1px solid var(--border-color); }
        th { color: #4a5568; font-weight: 600; background-color: #f8fafc; text-transform: uppercase; font-size: 11.5px; letter-spacing: 0.5px; }
        
        .status-pill { 
            padding: 5px 11px; 
            border-radius: 20px; 
            font-size: 11px; 
            font-weight: 700; 
            text-transform: uppercase; 
            letter-spacing: 0.5px; 
            display: inline-block; 
        }

        @media (max-width: 600px) {
            .header-banner {
                flex-direction: column;
                align-items: flex-start;
                gap: 12px;
            }
            .header-banner > div:last-child {
                width: 100%;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            .dashboard-panel {
                padding: 18px 14px;
            }
            
            table, thead, tbody, th, td, tr { 
                display: block; 
            }
            table {
                min-width: 100%;
            }
            thead tr { 
                position: absolute;
                top: -9999px;
                left: -9999px;
            }
            tbody tr { 
                background: #ffffff;
                border: 1px solid var(--border-color);
                border-radius: 12px;
                margin-bottom: 14px;
                padding: 14px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.02);
            }
            tbody tr:last-child {
                margin-bottom: 0;
            }
            td { 
                border: none;
                padding: 6px 0;
                position: relative;
                display: flex;
                justify-content: space-between;
                align-items: center;
                font-size: 13.5px;
            }
            td::before { 
                content: attr(data-label);
                font-weight: 600;
                color: #718096;
                font-size: 11.5px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
            td.empty-row {
                display: block;
                text-align: center;
                padding: 20px 0;
            }
            td.empty-row::before { 
                display: none;
            }
        }

        .bottom-nav {
            position: fixed; bottom: 0; left: 0; right: 0; height: 70px;
            background-color: var(--white); border-top: 1px solid var(--border-color);
            display: flex; justify-content: space-around; align-items: center;
            z-index: 999; box-shadow: 0 -4px 10px rgba(0, 0, 0, 0.03);
        }

        .nav-item {
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            color: #718096; text-decoration: none; font-size: 11px; font-weight: 500; width: 80px;
        }
        .nav-item:hover, .nav-item.active { color: var(--primary-purple); }
        .nav-item svg { width: 22px; height: 22px; margin-bottom: 4px; fill: currentColor; }

        .qr-center-wrapper { position: relative; height: 100%; display: flex; align-items: center; justify-content: center; width: 80px; }
        .qr-btn-circle {
            width: 60px; height: 60px;
            background: linear-gradient(135deg, #3498db, #2980b9);
            border-radius: 50%; display: flex; align-items: center; justify-content: center;
            position: absolute; top: -22px; box-shadow: 0 4px 12px rgba(52, 152, 219, 0.35);
            border: 4px solid var(--white); color: var(--white); text-decoration: none;
        }
        .qr-btn-circle svg { width: 26px; height: 26px; fill: none; stroke: currentColor; stroke-width: 2.5; stroke-linecap: round; stroke-linejoin: round; }
        .qr-label { margin-top: 44px; font-size: 11px; font-weight: 600; color: var(--uitm-blue); }
    </style>
</head>
<body>

    <main>
        <div class="header-banner">
            <div class="brand-logo">MLMS<span>.System</span></div>
            <div style="display: flex; align-items: center; gap: 10px;">
                <div class="user-profile-badge">👤 <%= currentStudentName %></div>
                <a href="<%= request.getContextPath() %>/login.jsp" 
                   style="font-size: 12.5px; font-weight: 700; color: #ef4444; text-decoration: none; background: #fdf2f2; border: 1px solid #fbd5d5; padding: 6px 12px; border-radius: 20px; transition: all 0.2s ease; display: inline-flex; align-items: center; gap: 4px;"
                   onclick="return confirm('Are you sure you want to sign out?');">
                    🚪 Sign Out
                </a>
            </div>
        </div>

        <div class="dashboard-panel">
            <h2 class="panel-header">Attendance Verification History</h2>
            <p class="panel-subheader">Review your formal academic lab check-in timestamps and system verification histories.</p>
            
            <div class="table-responsive-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>Date Block</th>
                            <th>Laboratory Space</th>
                            <th>Time Window</th>
                            <th>Status Badge</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        Connection conn = null;
                        PreparedStatement stmt = null;
                        ResultSet rs = null;
                        try {
                            conn = DBConnection.getConnection();
                            
                            String sql = "SELECT DATE_FORMAT(b.bookingDate, '%d/%m/%Y') AS b_date, b.labId, b.timeSlot, a.status " +
                                         "FROM AttendanceLog a " +
                                         "JOIN Booking b ON a.bookingId = b.bookingId " +
                                         "WHERE a.studentId = ? " +
                                         "ORDER BY b.bookingDate DESC";
                                         
                            stmt = conn.prepareStatement(sql);
                            stmt.setInt(1, currentStudentId);
                            rs = stmt.executeQuery();
                            
                            boolean hasLogs = false;
                            while(rs.next()) {
                                hasLogs = true;
                                String labCode = rs.getString("labId");
                                String rawTime = rs.getString("timeSlot");
                                String currentStatus = rs.getString("status");
                                String displayLabName = labCode;
                                if ("LAB_CS_04".equals(labCode)) displayLabName = "Computer Science Lab (CS 04)";
                                else if ("LAB_PHYS_01".equals(labCode)) displayLabName = "Physics Lab (Advanced Mechanics)";
                                else if ("LAB_CHEM_01".equals(labCode)) displayLabName = "Chemistry Lab (Organic Molecular)";
                                else if ("LAB_BIO_01".equals(labCode)) displayLabName = "Biology Lab (Genetics & Micro)";
                                
                                String displayTime = rawTime;
                                if ("10:00:00".equals(rawTime)) displayTime = "10:00 AM - 12:00 PM";
                                else if ("14:00:00".equals(rawTime)) displayTime = "02:00 PM - 04:00 PM";
                                
                                String textStyle = "var(--color-present)";
                                String bgStyle = "var(--bg-present)";
                                String borderStyle = "var(--border-present)";
                                
                                if("LATE".equalsIgnoreCase(currentStatus)) {
                                    textStyle = "var(--color-late)"; bgStyle = "var(--bg-late)"; borderStyle = "var(--border-late)";
                                } else if("ABSENT".equalsIgnoreCase(currentStatus)) {
                                    textStyle = "var(--color-absent)"; bgStyle = "var(--bg-absent)"; borderStyle = "var(--border-absent)";
                                } else if("MC".equalsIgnoreCase(currentStatus)) {
                                    textStyle = "var(--color-mc)"; bgStyle = "var(--bg-mc)"; borderStyle = "var(--border-mc)";
                                }
                    %>
                        <tr>
                            <td data-label="Date Block" style="font-weight: 500;"><%= rs.getString("b_date") %></td>
                            <td data-label="Laboratory Space"><%= displayLabName %></td>
                            <td data-label="Time Window" style="font-family: monospace;"><%= displayTime %></td>
                            <td data-label="Status Badge">
                                <span class="status-pill" style="color: <%= textStyle %>; background-color: <%= bgStyle %>; border: 1px solid <%= borderStyle %>;">
                                    <%= currentStatus %>
                                </span>
                            </td>
                        </tr>
                    <%
                            }
                            if(!hasLogs) {
                    %>
                        <tr>
                            <td colspan="4" class="empty-row" style="text-align: center; color: #a0aec0; padding: 30px;">
                                No verification logs found for this account.
                            </td>
                        </tr>
                    <%
                            }
                        } catch(SQLException e) {
                            e.printStackTrace();
                        } finally {
                            try { if (rs != null) rs.close(); } catch (SQLException e) {}
                            try { if (stmt != null) stmt.close(); } catch (SQLException e) {}
                            try { if (conn != null) conn.close(); } catch (SQLException e) {}
                        }
                    %>
                    </tbody>
                </table>
            </div>
        </div>
    </main>

    <nav class="bottom-nav">
        <a href="<%= request.getContextPath() %>/student/dashboard" class="nav-item">
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
        <a href="<%= request.getContextPath() %>/student/my-attendance" class="nav-item active">
            <svg viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/></svg>
            <span>History Logs</span>
        </a>
    </nav>

</body>
</html>