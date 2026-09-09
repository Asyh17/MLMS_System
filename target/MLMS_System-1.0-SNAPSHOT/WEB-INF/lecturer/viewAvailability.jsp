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
    if (session.getAttribute("userToken") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    Map<String, String> labNames = new HashMap<>();
    labNames.put("LAB_CS_04", "Computer Science Lab (CS 04)");
    labNames.put("LAB_BIO_01", "Biology Lab (Genetics & Micro)");
    labNames.put("LAB_PHYS_01", "Physics Lab (Advanced Mechanics)");
    labNames.put("LAB_CHEM_01", "Chemistry Lab (Organic Molecular)");

    List<String> dynamicLabs = new ArrayList<>();
    List<String> dynamicSlots = new ArrayList<>();
    Map<String, String> activeBookings = new HashMap<>();

    Connection conn = null;
    PreparedStatement stmtLabs = null;
    PreparedStatement stmtSlots = null;
    PreparedStatement stmtBookings = null;
    ResultSet rsLabs = null;
    ResultSet rsSlots = null;
    ResultSet rsBookings = null;

    try {
        conn = DBConnection.getConnection();

        String sqlLabs = "SELECT DISTINCT labId FROM booking ORDER BY labId ASC";
        stmtLabs = conn.prepareStatement(sqlLabs);
        rsLabs = stmtLabs.executeQuery();
        while (rsLabs.next()) {
            dynamicLabs.add(rsLabs.getString("labId"));
        }

        String sqlSlots = "SELECT DISTINCT REPLACE(timeSlot, '.', ':') AS cleanSlot FROM booking ORDER BY cleanSlot ASC";
        stmtSlots = conn.prepareStatement(sqlSlots);
        rsSlots = stmtSlots.executeQuery();
        while (rsSlots.next()) {
            dynamicSlots.add(rsSlots.getString("cleanSlot"));
        }

        String sqlBookings = "SELECT b.labId, REPLACE(b.timeSlot, '.', ':') AS cleanSlot, u.name FROM booking b " +
                             "JOIN user u ON b.lecturerId = u.userId " +
                             "WHERE b.bookingDate >= CURRENT_DATE() AND LOWER(b.status) = 'approved'";
        
        stmtBookings = conn.prepareStatement(sqlBookings);
        rsBookings = stmtBookings.executeQuery();

        while (rsBookings.next()) {
            String compositeKey = rsBookings.getString("labId") + "_" + rsBookings.getString("cleanSlot");
            activeBookings.put(compositeKey, rsBookings.getString("name"));
        }

    } catch (SQLException e) {
        e.printStackTrace();
    } finally {
        try { if (rsBookings != null) rsBookings.close(); } catch (SQLException e) {}
        try { if (rsSlots != null) rsSlots.close(); } catch (SQLException e) {}
        try { if (rsLabs != null) rsLabs.close(); } catch (SQLException e) {}
        try { if (stmtBookings != null) stmtBookings.close(); } catch (SQLException e) {}
        try { if (stmtSlots != null) stmtSlots.close(); } catch (SQLException e) {}
        try { if (stmtLabs != null) stmtLabs.close(); } catch (SQLException e) {}
        try { if (conn != null) conn.close(); } catch (SQLException e) {}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Master Lab Schedule | MLMS</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-color: #2c3e50;
            --accent-color: #3498db;
            --bg-color: #f8fafc;
            --card-bg: #ffffff;
            --border-color: #e2e8f0;
            --danger-color: #e74c3c;
            --success-color: #10b981;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Inter', sans-serif; 
            background-color: var(--bg-color);
            margin: 0; 
            padding: 30px 16px; 
            display: flex; 
            justify-content: center;
            min-height: 100vh;
        }

        .container { width: 100%; max-width: 950px; }

        .card {
            background-color: var(--card-bg); 
            border-radius: 14px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.03); 
            padding: 30px 25px;
            border: 1px solid var(--border-color);
        }

        h1 { font-size: 22px; font-weight: 800; color: var(--primary-color); margin: 0 0 6px 0; }
        .subtitle { color: #64748b; font-size: 13.5px; margin-bottom: 24px; }

        .table-responsive { 
            width: 100%; 
            overflow-x: auto; 
            margin-bottom: 25px; 
            -webkit-overflow-scrolling: touch; 
        }
        
        table { width: 100%; border-collapse: collapse; text-align: left; }
        th, td { padding: 13px 12px; border-bottom: 1px solid var(--border-color); font-size: 13.5px; }
        th { background-color: #f8fafc; color: var(--primary-color); font-weight: 700; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }

        .status-badge { display: inline-block; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
        .status-booked { background-color: #fef2f2; color: #ef4444; border: 1px solid #fecaca; }
        .status-available { background-color: #ecfdf5; color: #10b981; border: 1px solid #a7f3d0; }

        .btn-group {
            display: flex;
            gap: 12px;
            align-items: center;
        }

        .btn-nav {
            display: inline-block; 
            text-decoration: none; 
            background-color: var(--accent-color);
            color: white; 
            padding: 10px 18px; 
            border-radius: 8px; 
            font-size: 13.5px; 
            font-weight: 600; 
            transition: background 0.2s;
        }
        .btn-nav:hover { background-color: #2980b9; }

        .btn-secondary {
            display: inline-block;
            text-decoration: none;
            background-color: transparent;
            color: var(--primary-color);
            border: 1px solid var(--border-color);
            padding: 10px 18px;
            border-radius: 8px;
            font-size: 13.5px;
            font-weight: 600;
            transition: background 0.2s;
        }
        .btn-secondary:hover { background-color: #f1f5f9; }

        /* Mobile View: Vertical Cards */
        @media (max-width: 650px) {
            body { padding: 16px 10px; }
            .card { padding: 20px 14px; }
            table, thead, tbody, th, td, tr { display: block; }
            thead tr { position: absolute; top: -9999px; left: -9999px; }
            tbody tr {
                background: #ffffff; 
                border: 1px solid var(--border-color);
                border-radius: 12px; 
                margin-bottom: 12px; 
                padding: 12px 14px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.01);
            }
            td {
                border: none; 
                padding: 6px 0; 
                display: flex; 
                justify-content: space-between; 
                align-items: center;
            }
            td::before {
                content: attr(data-label); 
                font-weight: 700; 
                color: #64748b; 
                font-size: 11px; 
                text-transform: uppercase;
            }
            .btn-group { flex-direction: column; width: 100%; }
            .btn-nav, .btn-secondary { width: 100%; text-align: center; }
        }
    </style>
</head>
<body>

    <div class="container">
        <div class="card">
            <h1>Master Lab Schedule</h1>
            <p class="subtitle">Live look-up of active schedule slot definitions across environment tracks.</p>

            <div class="table-responsive">
                <table>
                    <thead>
                        <tr>
                            <th>Laboratory</th>
                            <th>Time Slot</th>
                            <th>Status</th>
                            <th>Current Reservation</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        if (dynamicLabs.isEmpty() || dynamicSlots.isEmpty()) {
                    %>
                        <tr>
                            <td colspan="4" style="text-align: center; color: #94a3b8; padding: 20px;">
                                No active lab bookings found in system records.
                            </td>
                        </tr>
                    <%
                        } else {
                            for (String labId : dynamicLabs) {
                                for (String rawSlot : dynamicSlots) {
                                    String targetKey = labId + "_" + rawSlot;
                                    boolean isBooked = activeBookings.containsKey(targetKey);
                                    String assignedLecturer = isBooked ? activeBookings.get(targetKey) : "—";

                                    String displaySlot = rawSlot.startsWith("10") ? "10:00 AM - 12:00 PM" : 
                                                         (rawSlot.startsWith("14") ? "02:00 PM - 04:00 PM" : rawSlot);
                    %>
                        <tr>
                            <td data-label="Laboratory" style="font-weight: 600;"><%= labNames.containsKey(labId) ? labNames.get(labId) : labId %></td>
                            <td data-label="Time Slot" style="font-family: 'JetBrains Mono', monospace;"><%= displaySlot %></td>
                            <td data-label="Status">
                                <span class="status-badge <%= isBooked ? "status-booked" : "status-available" %>">
                                    <%= isBooked ? "Reserved" : "Available" %>
                                </span>
                            </td>
                            <td data-label="Faculty" style="color: <%= isBooked ? "var(--primary-color)" : "#94a3b8" %>; font-weight: <%= isBooked ? "700" : "400" %>;">
                                <%= assignedLecturer %>
                            </td>
                        </tr>
                    <%
                                }
                            }
                        }
                    %>
                    </tbody>
                </table>
            </div>

            <div class="btn-group">
                <a href="<%= request.getContextPath() %>/lecturer/book-lab" class="btn-nav">← Go to Booking Form</a>
                <a href="<%= request.getContextPath() %>/lecturer/dashboard" class="btn-secondary">Dashboard Overview</a>
            </div>
        </div>
    </div>

</body>
</html>