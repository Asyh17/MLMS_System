<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="MLMSModel.ReportBean"%>
<%@page import="MLMSModel.ReportRowBean"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%
    if (session.getAttribute("userToken") == null || !"ADMIN".equalsIgnoreCase((String) session.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    ReportBean report = (ReportBean) request.getAttribute("reportData");
    String noRecordsMessage = (String) request.getAttribute("noRecordsMessage");

    String selectedReportType = (String) request.getAttribute("submittedReportType");
    String selectedDateFrom = (String) request.getAttribute("submittedDateFrom");
    String selectedDateTo = (String) request.getAttribute("submittedDateTo");
    String selectedLabType = (String) request.getAttribute("submittedLabType");

    if (selectedReportType == null) selectedReportType = "Attendance";
    if (selectedLabType == null) selectedLabType = "All";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>View Report | MLMS Admin</title>
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
            --warn-yellow: #f59e0b;
            --danger-red: #ef4444;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', -apple-system, sans-serif;
            background-color: var(--main-bg); color: var(--text-dark);
            display: flex; min-height: 100vh;
        }

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

        .app-wrapper { flex-grow: 1; display: flex; flex-direction: column; min-width: 0; }
        main { flex-grow: 1; padding: 35px 30px; max-width: 1400px; width: 100%; box-sizing: border-box; }
        .top-navbar { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 20px; margin-bottom: 30px; }
        .page-title h1 { margin: 0; font-size: 24px; font-weight: 800; }
        .page-title p { margin: 4px 0 0 0; color: var(--text-muted); font-size: 13.5px; }
        .user-profile { display: flex; align-items: center; background: var(--white); padding: 8px 14px; border-radius: 20px; border: 1px solid var(--border-color); font-size: 13px; font-weight: 600; }

        /* Filter Controls */
        .filter-card { background-color: var(--white); border-radius: 14px; border: 1px solid var(--border-color); padding: 25px; box-shadow: 0 1px 3px rgba(0,0,0,0.01); margin-bottom: 25px; }
        .filter-grid { display: grid; grid-template-columns: 1.4fr 1fr 1fr 1fr auto; gap: 16px; align-items: end; }
        .form-group { display: flex; flex-direction: column; }
        .form-group label { font-size: 12px; font-weight: 700; color: var(--text-dark); margin-bottom: 6px; text-transform: uppercase; }
        .form-control { width: 100%; padding: 10px 12px; font-size: 14px; border: 1px solid var(--border-color); border-radius: 8px; background-color: #f8fafc; box-sizing: border-box; color: var(--text-dark); }
        .form-control:focus { outline: none; border-color: var(--admin-amber); background-color: var(--white); box-shadow: 0 0 0 3px rgba(217, 119, 6, 0.12); }
        .btn-generate { background-color: var(--admin-amber); color: var(--white); border: none; padding: 11px 20px; font-size: 14px; font-weight: 700; border-radius: 8px; cursor: pointer; white-space: nowrap; }
        .btn-generate:hover { background-color: var(--admin-amber-dark); }

        .alert { padding: 14px 18px; border-radius: 8px; font-size: 13.5px; margin-bottom: 22px; border: 1px solid; }
        .alert-warning { background-color: #fff7ed; color: #9a3412; border-color: #fed7aa; }

        /* Results */
        .report-results { background-color: var(--white); border-radius: 14px; border: 1px solid var(--border-color); padding: 25px; box-shadow: 0 1px 3px rgba(0,0,0,0.01); }
        .report-meta-row { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 1px solid var(--border-color); padding-bottom: 16px; margin-bottom: 22px; gap: 10px; }
        .report-meta-row h2 { margin: 0 0 4px 0; font-size: 18px; font-weight: 800; }
        .report-meta-row p { margin: 0; font-size: 13px; color: var(--text-muted); }
        .btn-export { display: inline-flex; align-items: center; gap: 8px; text-decoration: none; background-color: var(--sidebar-bg); color: var(--white); padding: 9px 16px; border-radius: 8px; font-size: 13px; font-weight: 600; border: none; cursor: pointer; white-space: nowrap; }
        .btn-export:hover { background-color: #1e293b; }

        .summary-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-bottom: 25px; }
        .summary-card { background-color: #fffaf0; border: 1px solid #fde9c8; border-radius: 10px; padding: 16px; }
        .summary-card .summary-label { font-size: 11px; font-weight: 700; color: #92400e; text-transform: uppercase; letter-spacing: 0.4px; margin-bottom: 6px; }
        .summary-card .summary-value { font-size: 22px; font-weight: 800; color: var(--text-dark); }

        .chart-container { position: relative; width: 100%; height: 260px; margin-bottom: 25px; }

        .table-responsive { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; }
        table { width: 100%; border-collapse: collapse; text-align: left; }
        th, td { padding: 12px 10px; font-size: 13.5px; border-bottom: 1px solid var(--border-color); }
        th { background-color: #f8fafc; color: #475569; font-weight: 700; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
        .status-pill { padding: 4px 9px; border-radius: 6px; font-size: 11px; font-weight: 700; }
        .status-good { background-color: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; }
        .status-warn { background-color: #fffbeb; color: #b45309; border: 1px solid #fde68a; }
        .status-bad { background-color: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; }

        .empty-state { text-align: center; padding: 40px 20px; color: var(--text-muted); font-size: 13.5px; }

        /* Mobile Breakpoint */
        .mobile-topbar, #mobile-drawer { display: none; }
        @media (max-width: 1000px) {
            .filter-grid { grid-template-columns: 1fr 1fr; }
            .btn-generate { width: 100%; }
        }
        @media (max-width: 900px) {
            body { flex-direction: column; }
            aside { display: none; }
            .mobile-topbar {
                display: flex; justify-content: space-between; align-items: center;
                background-color: var(--sidebar-bg); color: var(--white); padding: 16px 20px;
                position: sticky; top: 0; z-index: 50;
            }
            .mobile-brand { font-size: 18px; font-weight: 800; }
            .mobile-brand span { color: var(--admin-amber); }
            .mobile-menu-btn { background: none; border: none; color: white; font-size: 24px; cursor: pointer; }
            
            #mobile-drawer {
                background-color: #020617; padding: 12px 0; border-bottom: 1px solid #1e293b;
            }
            #mobile-drawer a { display: block; padding: 12px 24px; color: #cbd5e1; text-decoration: none; font-size: 14px; font-weight: 500; }
            #mobile-drawer a:hover, #mobile-drawer a.active { background: rgba(217, 119, 6, 0.15); color: var(--admin-amber); font-weight: 700; }

            main { padding: 20px 16px; }
            .top-navbar { flex-direction: column; align-items: flex-start; gap: 10px; }
            .filter-grid { grid-template-columns: 1fr; }
            .summary-grid { grid-template-columns: 1fr; }
            .report-meta-row { flex-direction: column; align-items: flex-start; }
            .btn-export { width: 100%; justify-content: center; }
        }

        @media print {
            aside, .filter-card, .btn-export, .top-navbar, .mobile-topbar { display: none !important; }
            main { padding: 0; max-width: 100%; }
            .report-results { border: none; box-shadow: none; padding: 0; }
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

            <li class="sidebar-item active">
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

    <!-- Main Workspace Container -->
    <div class="app-wrapper">
        <div class="mobile-topbar">
            <div class="mobile-brand"><span>MLMS</span>.Admin</div>
            <button class="mobile-menu-btn" onclick="toggleMobileNav()">☰</button>
        </div>
        <div id="mobile-drawer">
            <a href="<%= request.getContextPath() %>/admin/dashboard">📊 Dashboard Overview</a>
            <a href="<%= request.getContextPath() %>/admin/manage-lecturers">👨‍🏫 Manage Lecturers</a>
            <a href="<%= request.getContextPath() %>/admin/reports" class="active">📑 Generate Reports</a>
            <a href="<%= request.getContextPath() %>/admin/monitor-usage">📈 Monitor Lab Usage</a>
            <a href="<%= request.getContextPath() %>/login.jsp" style="color: #ef4444;">🚪 Sign Out</a>
        </div>

        <main>
            <div class="top-navbar">
                <div class="page-title">
                    <h1>Compliance &amp; Utilization Reports</h1>
                    <p>Filter, generate, and export aggregated lab activity reports for academic management.</p>
                </div>
                <div class="user-profile">🛡️ Admin Account: <%= session.getAttribute("userName") != null ? session.getAttribute("userName") : session.getAttribute("userToken") %></div>
            </div>

            <div class="filter-card">
                <form action="<%= request.getContextPath() %>/ReportServlet" method="POST">
                    <div class="filter-grid">
                        <div class="form-group">
                            <label for="reportType">Report Type</label>
                            <select id="reportType" name="reportType" class="form-control">
                                <option value="Attendance" <%= "Attendance".equals(selectedReportType) ? "selected" : "" %>>Attendance Report</option>
                                <option value="Utilization" <%= "Utilization".equals(selectedReportType) ? "selected" : "" %>>Lab Utilization Report</option>
                                <option value="ContactHours" <%= "ContactHours".equals(selectedReportType) ? "selected" : "" %>>Contact Hours Summary</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label for="dateFrom">Date From</label>
                            <input type="date" id="dateFrom" name="dateFrom" class="form-control"
                                   value="<%= selectedDateFrom != null ? selectedDateFrom : "2026-06-01" %>" required>
                        </div>
                        <div class="form-group">
                            <label for="dateTo">Date To</label>
                            <input type="date" id="dateTo" name="dateTo" class="form-control"
                                   value="<%= selectedDateTo != null ? selectedDateTo : "2026-06-22" %>" required>
                        </div>
                        <div class="form-group">
                            <label for="labType">Lab Type</label>
                            <select id="labType" name="labType" class="form-control">
                                <option value="All" <%= "All".equals(selectedLabType) ? "selected" : "" %>>All</option>
                                <option value="CS" <%= "CS".equals(selectedLabType) ? "selected" : "" %>>Computer Science (CS)</option>
                                <option value="Physics" <%= "Physics".equals(selectedLabType) ? "selected" : "" %>>Physics</option>
                                <option value="Chemistry" <%= "Chemistry".equals(selectedLabType) ? "selected" : "" %>>Chemistry</option>
                                <option value="Biology" <%= "Biology".equals(selectedLabType) ? "selected" : "" %>>Biology</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <button type="submit" class="btn-generate">Generate Report</button>
                        </div>
                    </div>
                </form>
            </div>

            <% if (noRecordsMessage != null) { %>
            <div class="alert alert-warning">
                ⚠️ <%= noRecordsMessage %>
            </div>
            <% } %>

            <%
                if (report != null) {
                    List<ReportRowBean> rows = report.getDataRows();
                    List<String> headers = report.getColumnHeaders();
            %>
            <div class="report-results">
                <div class="report-meta-row">
                    <div>
                        <h2><%= report.getChartTitle() != null ? report.getChartTitle().replace(" by Room (%)", "").replace(" by Room", "") : "Report Summary" %></h2>
                        <p>Period: <%= report.getDateFrom() %> to <%= report.getDateTo() %> &middot; Lab Filter: <%= report.getLabTypeFilter() %> &middot; Generated <%= report.getGeneratedOn() %></p>
                    </div>
                    <button type="button" class="btn-export" onclick="window.print()">
                        <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9V2h12v7"></path><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><rect x="6" y="14" width="12" height="8"></rect></svg>
                        Export PDF
                    </button>
                </div>

                <div class="summary-grid">
                    <% for (Map.Entry<String, String> entry : report.getSummaryMetrics().entrySet()) { %>
                    <div class="summary-card">
                        <div class="summary-label"><%= entry.getKey() %></div>
                        <div class="summary-value"><%= entry.getValue() %></div>
                    </div>
                    <% } %>
                </div>

                <div class="chart-container">
                    <canvas id="reportChart"></canvas>
                </div>

                <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <% for (String h : headers) { %>
                                <th><%= h %></th>
                                <% } %>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (ReportRowBean row : rows) { %>
                            <tr>
                                <td><%= row.getColumn1() %></td>
                                <td><%= row.getColumn2() %></td>
                                <td><%= row.getColumn3() %></td>
                                <td><span class="status-pill status-<%= row.getStatusVariant() %>"><%= row.getColumn4() %></span></td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>

            <script>
                const ctx = document.getElementById('reportChart').getContext('2d');
                new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: [<% for (String l : report.getChartLabels()) { %>'<%= l %>',<% } %>],
                        datasets: [{
                            label: '<%= report.getChartTitle() %>',
                            data: [<% for (Double v : report.getChartValues()) { %><%= v %>,<% } %>],
                            backgroundColor: '#d97706',
                            borderRadius: 6,
                            maxBarThickness: 48
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: { legend: { display: false } },
                        scales: {
                            y: { beginAtZero: true, grid: { color: '#f1f5f9' }, ticks: { color: '#64748b' } },
                            x: { grid: { display: false }, ticks: { color: '#64748b', font: { weight: '500' } } }
                        }
                    }
                });
            </script>
            <% } else if (noRecordsMessage == null) { %>
            <div class="report-results">
                <div class="empty-state">
                    <p>Select a report type and date range above, then click <strong>Generate Report</strong> to view aggregated lab activity.</p>
                </div>
            </div>
            <% } %>

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