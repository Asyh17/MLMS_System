<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String userRole = (String) session.getAttribute("userRole");
    String userName = (String) session.getAttribute("userName");

    if (session.getAttribute("userToken") == null || userRole == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String errorMessage = (String) request.getAttribute("exceptionMessage");
    if (errorMessage == null) {
        errorMessage = "An unexpected validation exception halted your application pipeline.";
    }
    
    boolean isStudent = "STUDENT".equalsIgnoreCase(userRole);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>System Exception | MLMS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
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
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Inter', -apple-system, sans-serif;
            background-color: var(--main-bg);
            color: var(--text-dark);
            display: flex;
            min-height: 100vh;
        }

        /* Desktop Sidebar (Non-Student Only) */
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
        .menu-label { padding: 0 24px 10px 24px; font-size: 11px; font-weight: 700; text-transform: uppercase; color: #475569; letter-spacing: 1px; }
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

        .error-card {
            background-color: var(--white);
            border-radius: 14px;
            border: 1px solid var(--border-color);
            padding: 36px 28px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.02);
            max-width: 440px;
            width: 100%;
            text-align: center;
        }

        .error-icon-circle {
            width: 58px; height: 58px;
            background-color: #fef2f2;
            color: #ef4444;
            border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 18px auto;
            border: 1px solid #fee2e2;
            flex-shrink: 0;
        }
        .error-icon-circle svg { width: 26px; height: 26px; fill: none; stroke: currentColor; stroke-width: 2.5; }

        .error-title { font-size: 20px; font-weight: 800; margin: 0 0 10px 0; color: #1e293b; }
        .error-desc { font-size: 13.5px; color: #64748b; line-height: 1.5; margin: 0 0 24px 0; }

        .btn-action {
            display: inline-block; width: 100%; text-align: center;
            background: linear-gradient(135deg, #ef4444, #dc2626);
            color: var(--white); text-decoration: none;
            padding: 13px 20px; font-size: 14.5px; font-weight: 600;
            border-radius: 10px; box-shadow: 0 4px 12px rgba(239, 68, 68, 0.2);
            transition: opacity 0.15s ease;
        }
        .btn-action:hover { opacity: 0.95; }

        /* Bottom Nav (Student Only) */
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
            <li class="menu-label">Main Tasks</li>
            <li class="sidebar-item"><a href="<%= request.getContextPath() %>/lecturer/dashboard">Dashboard Overview</a></li>
            <li class="sidebar-item"><a href="<%= request.getContextPath() %>/lecturer/book-lab">Book Laboratory Space</a></li>
            <li class="sidebar-item"><a href="<%= request.getContextPath() %>/lecturer/my-bookings">Manage My Bookings</a></li>
        </ul>
    </aside>
    <% } %>

    <div class="app-wrapper">
        <main>
            <div class="error-card">
                <div class="error-icon-circle">
                    <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                        <line x1="12" y1="9" x2="12" y2="13"></line>
                        <line x1="12" y1="17" x2="12.01" y2="17"></line>
                    </svg>
                </div>
                <h1 class="error-title">Schedule Conflict</h1>
                <p class="error-desc"><%= errorMessage %></p>
                
                <a href="<%= request.getContextPath() %>/<%= isStudent ? "student/scan" : "lecturer/dashboard" %>" class="btn-action">
                    <%= isStudent ? "Try Different Slot" : "Return to Control Center" %>
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