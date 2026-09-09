<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String userRole = (String) session.getAttribute("userRole"); 
    String userName = (String) session.getAttribute("userName");
    
    if (session.getAttribute("userToken") == null || userRole == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    boolean isStudent = "STUDENT".equalsIgnoreCase(userRole);

    String lastScanTime = (String) session.getAttribute("lastScanTime");
    if (lastScanTime == null) {
        java.time.ZonedDateTime malaysiaTime = java.time.ZonedDateTime.now(java.time.ZoneId.of("Asia/Kuala_Lumpur"));
        lastScanTime = malaysiaTime.format(java.time.format.DateTimeFormatter.ofPattern("hh:mm:ss a"));
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Transaction Success | MLMS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-purple: #6c5ce7;
            --main-bg: #f8f9fd;
            --text-dark: #2d3436;
            --border-color: #e2e8f0;
            --white: #ffffff;
            --uitm-blue: #3498db;
            --sidebar-bg: #1e293b;
            --lecturer-blue: #3498db;
            --success-green: #10b981;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Inter', -apple-system, sans-serif;
            background-color: var(--main-bg);
            color: var(--text-dark);
            display: flex;
            min-height: 100vh;
        }

        /* Desktop Sidebar (Lecturer Only) */
        aside {
            width: 280px; 
            background-color: var(--sidebar-bg); 
            color: var(--white);
            display: <%= isStudent ? "none" : "flex" %>; 
            flex-direction: column; 
            flex-shrink: 0;
            box-shadow: 4px 0 10px rgba(0, 0, 0, 0.05);
            min-height: 100vh;
        }
        .sidebar-header { padding: 26px 24px; font-size: 20px; font-weight: 800; border-bottom: 1px solid #334155; }
        .sidebar-header span { color: var(--lecturer-blue); }
        .sidebar-menu { list-style: none; padding: 20px 0; margin: 0; flex-grow: 1; }
        .sidebar-item a { display: flex; align-items: center; padding: 13px 24px; color: #94a3b8; text-decoration: none; font-weight: 500; font-size: 14.5px; }
        .sidebar-item a:hover { background-color: rgba(52, 152, 219, 0.08); color: var(--white); }

        .app-wrapper {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
            min-width: 0;
        }

        main {
            flex-grow: 1;
            padding: 30px 16px;
            display: flex;
            justify-content: center;
            align-items: center;
            width: 100%;
            margin-bottom: <%= isStudent ? "80px" : "0px" %>; 
        }

        .success-card {
            background-color: var(--white);
            border-radius: 14px;
            border: 1px solid var(--border-color);
            padding: 36px 28px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.02);
            max-width: 480px;
            width: 100%;
        }

        .success-header-row {
            display: flex;
            align-items: center;
            gap: 14px;
            margin-bottom: 22px;
            border-bottom: 1px solid #f1f5f9;
            padding-bottom: 18px;
        }

        .success-icon-circle {
            width: 48px; height: 48px;
            background-color: #ecfdf5;
            color: var(--success-green);
            border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            border: 1px solid #d1fae5;
            flex-shrink: 0;
        }
        .success-icon-circle svg { width: 22px; height: 22px; fill: none; stroke: currentColor; stroke-width: 3; }

        .success-title h1 { font-size: 18px; font-weight: 800; margin: 0; color: #1e293b; text-align: left; }
        .success-title p { font-size: 12.5px; color: #64748b; margin: 3px 0 0 0; line-height: 1.4; text-align: left; }

        .data-summary-list { margin-bottom: 24px; }
        .data-row { display: flex; justify-content: space-between; padding: 11px 0; border-bottom: 1px dashed #f1f5f9; font-size: 13.5px; }
        .data-label { color: #64748b; font-weight: 500; }
        .data-value { color: #1e293b; font-weight: 600; text-align: right; }

        .btn-action {
            display: block; width: 100%; text-align: center;
            background: <%= isStudent ? "linear-gradient(135deg, #6c5ce7, #4834d4)" : "#3498db" %>;
            color: var(--white); text-decoration: none;
            padding: 13px 20px; font-size: 14.5px; font-weight: 600;
            border-radius: 10px; box-shadow: 0 4px 12px rgba(108, 92, 231, 0.15);
            transition: opacity 0.15s ease;
        }
        .btn-action:hover { opacity: 0.95; }

        /* Bottom Navigation Bar (Student Only) */
        .bottom-nav {
            position: fixed; bottom: 0; left: 0; right: 0; height: 70px;
            background-color: var(--white); border-top: 1px solid var(--border-color);
            display: <%= isStudent ? "flex" : "none" %>; justify-content: space-around; align-items: center;
            z-index: 999; box-shadow: 0 -4px 10px rgba(0, 0, 0, 0.03);
        }
        .nav-item { display: flex; flex-direction: column; align-items: center; justify-content: center; color: #718096; text-decoration: none; font-size: 11px; font-weight: 500; width: 80px; }
        .nav-item svg { width: 22px; height: 22px; margin-bottom: 4px; fill: currentColor; }
        .qr-center-wrapper { position: relative; height: 100%; display: flex; align-items: center; justify-content: center; width: 80px; }
        .qr-btn-circle { width: 60px; height: 60px; background: linear-gradient(135deg, #3498db, #2980b9); border-radius: 50%; display: flex; align-items: center; justify-content: center; position: absolute; top: -22px; border: 4px solid var(--white); color: var(--white); }
        .qr-btn-circle svg { width: 26px; height: 26px; fill: none; stroke: currentColor; stroke-width: 2.5; }
        .qr-label { margin-top: 44px; font-size: 11px; font-weight: 600; color: var(--uitm-blue); }

        @media (max-width: 900px) {
            aside { display: none; }
        }
    </style>
</head>
<body>

    <% if (!isStudent) { %>
    <aside>
        <div class="sidebar-header"><span>MLMS</span>.Lecturer</div>
        <ul class="sidebar-menu">
            <li class="sidebar-item"><a href="<%= request.getContextPath() %>/lecturer/dashboard">Dashboard Overview</a></li>
            <li class="sidebar-item"><a href="<%= request.getContextPath() %>/lecturer/book-lab">Book Laboratory Space</a></li>
            <li class="sidebar-item"><a href="<%= request.getContextPath() %>/lecturer/my-bookings">Manage My Bookings</a></li>
        </ul>
    </aside>
    <% } %>

    <div class="app-wrapper">
        <main>
            <div class="success-card">
                <div class="success-header-row">
                    <div class="success-icon-circle">
                        <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                    </div>
                    <div class="success-title">
                        <h1><%= isStudent ? "Attendance Logged" : "Reservation Confirmed" %></h1>
                        <p>Your record has been verified and committed to the registry logs.</p>
                    </div>
                </div>

                <div class="data-summary-list">
                    <div class="data-row">
                        <span class="data-label">Account Profile Holder</span>
                        <span class="data-value"><%= userName %></span>
                    </div>
                    
                    <div class="data-row">
                        <span class="data-label">Target Venue Allocation</span>
                        <span class="data-value">Computer Science Lab (CS 04)</span>
                    </div>

                    <div class="data-row" style="border-bottom: none;">
                        <span class="data-label">Real-Time Scan Stamp</span>
                        <span class="data-value" style="font-family: 'JetBrains Mono', monospace; color: var(--primary-purple);"><%= lastScanTime %></span>
                    </div>
                </div>

                <a href="<%= request.getContextPath() %>/<%= isStudent ? "student/dashboard" : "lecturer/dashboard" %>" class="btn-action">
                    <%= isStudent ? "Return to Student Workspace" : "Return to Dashboard Overview" %>
                </a>
            </div>
        </main>
    </div>

    <% if (isStudent) { %>
    <nav class="bottom-nav">
        <a href="<%= request.getContextPath() %>/student/dashboard" class="nav-item">
            <svg viewBox="0 0 24 24"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>
            <span>Workspace</span>
        </a>
        <div class="qr-center-wrapper">
            <a href="<%= request.getContextPath() %>/student/scan" class="qr-btn-circle">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M3 7V5a2 2 0 0 1 2-2h2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2" />
                </svg>
            </a>
            <span class="qr-label">Scan QR</span>
        </div>
        <a href="<%= request.getContextPath() %>/student/my-attendance" class="nav-item">
            <svg viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/></svg>
            <span>History Logs</span>
        </a>
    </nav>
    <% } %>

</body>
</html>