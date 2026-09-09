<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.mycompany.mlms_system.database.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>

<%
    // Session Protection Gate Check
    if (session.getAttribute("userToken") == null || !"LECTURER".equalsIgnoreCase((String) session.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    int lecturerId = (Integer) session.getAttribute("userId");
    String lecturerDept = "";

    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement("SELECT department FROM lecturer WHERE userId = ?")) {
        ps.setInt(1, lecturerId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                lecturerDept = rs.getString("department");
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    if (lecturerDept == null) lecturerDept = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Book Laboratory | MLMS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --lecturer-blue: #3498db;
            --dark-blue: #2c3e50;
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

        /* Desktop Sidebar */
        aside {
            width: 280px; background-color: var(--sidebar-bg); color: var(--white);
            display: flex; flex-direction: column; flex-shrink: 0;
            box-shadow: 4px 0 10px rgba(0, 0, 0, 0.05); min-height: 100vh;
        }
        .sidebar-header { padding: 26px 24px; font-size: 20px; font-weight: 800; letter-spacing: 0.5px; border-bottom: 1px solid #334155; }
        .sidebar-header span { color: var(--lecturer-blue); }
        .sidebar-menu { list-style: none; padding: 20px 0; margin: 0; flex-grow: 1; }
        .menu-label { padding: 0 24px 10px 24px; font-size: 11px; font-weight: 700; text-transform: uppercase; color: #475569; letter-spacing: 1px; }

        .sidebar-item a {
            display: flex; align-items: center; padding: 13px 24px; color: #94a3b8;
            text-decoration: none; font-weight: 500; font-size: 14.5px;
            transition: all 0.2s ease; border-left: 4px solid transparent;
        }
        .sidebar-item.active a, .sidebar-item a:hover {
            background-color: rgba(52, 152, 219, 0.08); color: var(--white);
            border-left-color: var(--lecturer-blue);
        }
        .sidebar-item svg {
            width: 18px; height: 18px; margin-right: 14px; fill: none;
            stroke: #94a3b8; stroke-width: 2; display: inline-block; vertical-align: middle;
        }
        .sidebar-item.active svg, .sidebar-item a:hover svg { stroke: #ffffff; }

        /* Main Workspace Wrapper */
        .app-wrapper {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
            min-width: 0;
        }

        main { flex-grow: 1; padding: 35px 30px; max-width: 1100px; width: 100%; box-sizing: border-box; }
        .top-navbar { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 20px; margin-bottom: 30px; }
        .page-title h1 { margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.02em; }
        .page-title p { margin: 4px 0 0 0; color: var(--text-muted); font-size: 13.5px; }
        .user-profile { display: flex; align-items: center; background: var(--white); padding: 8px 14px; border-radius: 20px; border: 1px solid var(--border-color); font-size: 13px; font-weight: 600; color: #334155; }

        .form-card { background-color: var(--white); border-radius: 14px; border: 1px solid var(--border-color); padding: 32px; box-shadow: 0 4px 6px rgba(0,0,0,0.01); }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 22px; margin-bottom: 25px; }

        .form-group { display: flex; flex-direction: column; gap: 6px; }
        .full-width { grid-column: span 2; }

        .form-group label { font-size: 13px; font-weight: 700; color: #334155; text-transform: uppercase; letter-spacing: 0.4px; }
        .form-control { width: 100%; padding: 12px 14px; font-size: 14.5px; border: 1px solid var(--border-color); border-radius: 8px; background-color: #f8fafc; box-sizing: border-box; transition: all 0.2s ease; color: var(--text-dark); font-family: inherit; }
        .form-control:focus { outline: none; border-color: var(--lecturer-blue); background-color: var(--white); box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.15); }

        .btn-submit { background-color: var(--lecturer-blue); color: var(--white); border: none; padding: 14px 28px; font-size: 15px; font-weight: 600; border-radius: 8px; cursor: pointer; transition: background-color 0.2s; box-shadow: 0 4px 12px rgba(52, 152, 219, 0.25); }
        .btn-submit:hover { background-color: #2980b9; }
        .form-actions { display: flex; justify-content: flex-end; border-top: 1px solid #f1f5f9; padding-top: 22px; }

        .dept-badge { display: inline-flex; align-items: center; gap: 6px; background-color: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; padding: 6px 12px; border-radius: 8px; font-size: 12px; font-weight: 600; margin-bottom: 18px; }

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
            .top-navbar { flex-direction: column; align-items: flex-start; gap: 10px; }
            .form-grid { grid-template-columns: 1fr; gap: 16px; }
            .full-width { grid-column: span 1; }
            .form-card { padding: 22px 16px; }
            .btn-submit { width: 100%; }
        }
    </style>
</head>
<body>

    <!-- Desktop Sidebar -->
    <aside>
        <div class="sidebar-header"><span>MLMS</span>.Lecturer</div>
        <ul class="sidebar-menu">
            <li class="menu-label">Main Tasks</li>
            <li class="sidebar-item active">
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
            <li class="sidebar-item">
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
            <a href="<%= request.getContextPath() %>/lecturer/dashboard" class="active">📊 Dashboard Overview</a>
            <a href="<%= request.getContextPath() %>/lecturer/book-lab">📅 Book Laboratory Space</a>
            <a href="<%= request.getContextPath() %>/lecturer/my-bookings">📋 Manage My Bookings</a>
            <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">🚪 Sign Out</a>
        </div>

        <main>
            <div class="top-navbar">
                <div class="page-title">
                    <h1>Automated Reservation Request</h1>
                    <p>Submit parameters below to reserve a processing environment space.</p>
                </div>
                <div class="user-profile">
                    💻 Faculty Account: <%= session.getAttribute("userName") != null ? session.getAttribute("userName") : "Lecturer" %>
                </div>
            </div>

            <div class="form-card">
                <div class="dept-badge">
                    🏛️ Assigned Faculty Department: <strong><%= !lecturerDept.isEmpty() ? lecturerDept : "Unassigned Department" %></strong>
                </div>

                <form action="<%= request.getContextPath() %>/BookingServlet" method="POST">
                    <div class="form-grid">
                        <div class="form-group">
                            <label for="lecturerId">Lecturer ID Reference</label>
                            <input type="text" id="lecturerId" name="lecturerId" class="form-control" value="<%= lecturerId %>" required readonly>
                        </div>
                        <div class="form-group">
                            <label for="bookingDate">Target Booking Date</label>
                            <input type="date" id="bookingDate" name="bookingDate" class="form-control" min="<%= java.time.LocalDate.now().toString() %>" required>
                        </div>
                        <div class="form-group">
                            <label for="academicStream">Academic Target Stream</label>
                            <select id="academicStream" name="academicStream" class="form-control" onchange="filterLaboratories()">
                                <option value="Engineering Stream">Engineering Stream</option>
                                <option value="Science Stream">Science Stream</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label for="laboratoryId">Select Laboratory Environment</label>
                            <select id="laboratoryId" name="laboratoryId" class="form-control" required></select>
                        </div>
                        <div class="form-group full-width">
                            <label for="timeSlot">Allocated Hours Window</label>
                            <select id="timeSlot" name="timeSlot" class="form-control">
                                <option value="10:00:00">10:00 AM - 12:00 PM (Morning Window)</option>
                                <option value="14:00:00">02:00 PM - 04:00 PM (Afternoon Window)</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-actions">
                        <button type="submit" class="btn-submit">Process Reservation Request</button>
                    </div>
                </form>
            </div>
        </main>
    </div>

    <script>
        const lecturerDepartment = "<%= lecturerDept %>";

        function toggleMobileNav() {
            const drawer = document.getElementById("mobile-drawer");
            drawer.style.display = (drawer.style.display === "block") ? "none" : "block";
        }

        function filterLaboratories() {
            const streamSelect = document.getElementById("academicStream");
            const labSelect = document.getElementById("laboratoryId");
            const selectedStream = streamSelect.value;
            labSelect.innerHTML = "";

            const csOption = '<option value="LAB_CS_04">Computer Science Lab (CS 04)</option>';
            const physOption = '<option value="LAB_PHYS_01">Physics Lab (PHY 01)</option>';
            const chemOption = '<option value="LAB_CHEM_01">Chemistry Lab (CHM 01)</option>';
            const bioOption = '<option value="LAB_BIO_01">Biology Lab (BIO 01)</option>';

            let optionsHtml = "";

            if (lecturerDepartment.includes("Computer Science")) {
                if (selectedStream === "Engineering Stream") {
                    optionsHtml = csOption;
                } else {
                    optionsHtml = '<option value="" disabled selected>CS Lab not permitted for Science Stream</option>';
                }
            } else if (lecturerDepartment.includes("Biology")) {
                if (selectedStream === "Science Stream") {
                    optionsHtml = bioOption;
                } else {
                    optionsHtml = '<option value="" disabled selected>Biology Lab not permitted for Engineering Stream</option>';
                }
            } else if (lecturerDepartment.includes("Physics")) {
                optionsHtml = physOption;
            } else if (lecturerDepartment.includes("Chemistry")) {
                optionsHtml = chemOption;
            } else {
                if (selectedStream === "Engineering Stream") {
                    optionsHtml = csOption + physOption + chemOption;
                } else if (selectedStream === "Science Stream") {
                    optionsHtml = bioOption + physOption + chemOption;
                }
            }

            labSelect.innerHTML = optionsHtml;
        }

        window.onload = filterLaboratories;
    </script>
</body>
</html>