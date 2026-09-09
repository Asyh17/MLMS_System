package com.mycompany.mlms_system.controller;

import com.mycompany.mlms_system.database.DBConnection;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.time.LocalTime;
import java.time.ZonedDateTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet(name = "AttendanceServlet", urlPatterns = {"/AttendanceServlet"})
public class AttendanceServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");

        if ("LIVE_FEED".equalsIgnoreCase(action)) {
            String bookingId = request.getParameter("bookingId");
            
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            
            StringBuilder json = new StringBuilder();
            json.append("[");

            if (bookingId != null && !bookingId.trim().isEmpty()) {
                String sql = "SELECT a.studentId, u.name, "
                           + "DATE_FORMAT(a.entryTime, '%h:%i:%s %p') AS scan_time, a.status "
                           + "FROM attendancelog a "
                           + "JOIN user u ON a.studentId = u.userId "
                           + "WHERE a.bookingId = ? "
                           + "AND UPPER(a.status) IN ('PRESENT', 'LATE', 'COMPLETED', 'VERIFIED', 'AUTO_CLOSED') "
                           + "ORDER BY a.entryTime DESC";

                try (Connection conn = DBConnection.getConnection();
                     PreparedStatement ps = conn.prepareStatement(sql)) {
                    
                    ps.setString(1, bookingId.trim());
                    
                    try (ResultSet rs = ps.executeQuery()) {
                        boolean first = true;
                        while (rs.next()) {
                            if (!first) {
                                json.append(",");
                            }
                            first = false;

                            int sId = rs.getInt("studentId");
                            String sName = rs.getString("name");
                            if (sName == null) sName = "Student " + sId;
                            String sTime = rs.getString("scan_time");
                            if (sTime == null) sTime = "Verified";
                            String sStatus = rs.getString("status");
                            if (sStatus == null) sStatus = "PRESENT";

                            sName = sName.replace("\"", "\\\"");

                            json.append("{")
                                .append("\"studentId\":").append(sId).append(",")
                                .append("\"name\":\"").append(sName).append("\",")
                                .append("\"scanTime\":\"").append(sTime).append("\",")
                                .append("\"status\":\"").append(sStatus).append("\"")
                                .append("}");
                        }
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }

            json.append("]");

            PrintWriter out = response.getWriter();
            out.print(json.toString());
            out.flush();
            return;
        }

        response.sendRedirect(request.getContextPath() + "/student/dashboard");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        
        if (session.getAttribute("userId") == null) {
            handleScanFailure(request, response, "Session expired. Please log in again.");
            return;
        }

        int studentId = (Integer) session.getAttribute("userId");
        String scannedBookingId = request.getParameter("bookingId");
        String action = request.getParameter("action");
        
        Connection conn = null;
        PreparedStatement autoCloseStmt = null;
        PreparedStatement checkStmt = null;
        PreparedStatement streamStmt = null; 
        PreparedStatement insertStmt = null;
        PreparedStatement logStmt = null;
        ResultSet rs = null;
        ResultSet rsStream = null;

        try {
            conn = DBConnection.getConnection();

            String autoCloseSQL = "UPDATE attendancelog al "
                                + "JOIN booking b ON al.bookingId = b.bookingId "
                                + "SET al.exitTime = ADDTIME(b.timeSlot, '02:00:00'), al.status = CASE WHEN al.status = 'PRESENT' THEN 'COMPLETED' ELSE al.status END "
                                + "WHERE al.exitTime IS NULL "
                                + "AND b.bookingDate <= CURRENT_DATE() "
                                + "AND ADDTIME(b.timeSlot, '02:00:00') < CURRENT_TIME()";
            
            autoCloseStmt = conn.prepareStatement(autoCloseSQL);
            int closedRows = autoCloseStmt.executeUpdate();
            if (closedRows > 0) {
                System.out.println("LOG [AutoCheckOut]: Lazily swept and closed " + closedRows + " attendance records.");

                String logSQL = "INSERT INTO system_activity_log (eventDescription, actorType) VALUES (?, ?)";
                logStmt = conn.prepareStatement(logSQL);
                logStmt.setString(1, "Batch check-out executed (" + closedRows + " records updated)");
                logStmt.setString(2, "System");
                logStmt.executeUpdate();
                logStmt.close();
            }

            String checkSQL = "SELECT COUNT(*) FROM attendancelog WHERE studentId = ? AND bookingId = ?";
            checkStmt = conn.prepareStatement(checkSQL);
            checkStmt.setInt(1, studentId);
            checkStmt.setString(2, scannedBookingId);
            
            rs = checkStmt.executeQuery();
            if (rs.next() && rs.getInt(1) > 0) {
                handleScanFailure(request, response, "You have already checked into this lab reservation slot!");
                return;
            }
            rs.close(); 

            if ("SCAN_QR".equals(action)) {
                
                String fetchLabSQL = "SELECT labId, timeSlot, "
                                   + "(bookingDate = CURRENT_DATE() AND CURRENT_TIME() BETWEEN timeSlot AND ADDTIME(timeSlot, '02:00:00')) AS is_valid_window, "
                                   + "(bookingDate < CURRENT_DATE() OR (bookingDate = CURRENT_DATE() AND ADDTIME(timeSlot, '02:00:00') < CURRENT_TIME())) AS is_expired "
                                   + "FROM booking WHERE bookingId = ? AND LOWER(status) = 'approved'";
                
                streamStmt = conn.prepareStatement(fetchLabSQL);
                streamStmt.setString(1, scannedBookingId);
                rsStream = streamStmt.executeQuery();
                
                String targetLabId = "";
                Time rawTimeSlot = null;
                boolean isValidWindow = false;
                boolean isExpired = false;

                if (rsStream.next()) {
                    targetLabId = rsStream.getString("labId");
                    rawTimeSlot = rsStream.getTime("timeSlot");
                    isValidWindow = rsStream.getBoolean("is_valid_window");
                    isExpired = rsStream.getBoolean("is_expired");
                } else {
                    handleScanFailure(request, response, "Invalid Lab Booking: Reservation not found or not approved.");
                    return;
                }
                rsStream.close();
                streamStmt.close();

                if (isExpired) {
                    handleScanFailure(request, response, "Session Expired: This lab session window has already ended.");
                    return;
                }
                if (!isValidWindow) {
                    handleScanFailure(request, response, "Invalid Schedule Window: You can only check in during scheduled lab session hours.");
                    return;
                }

                String fetchStreamSQL = "SELECT studentStream FROM student WHERE userId = ?";
                streamStmt = conn.prepareStatement(fetchStreamSQL);
                streamStmt.setInt(1, studentId);
                rsStream = streamStmt.executeQuery();
                
                boolean isScienceStream = false;
                if (rsStream.next()) {
                    String actualStream = rsStream.getString("studentStream");
                    if ("Science Stream".equalsIgnoreCase(actualStream)) {
                        isScienceStream = true; 
                    }
                }
                rsStream.close();

                if (isScienceStream && "LAB_CS_04".equalsIgnoreCase(targetLabId)) {
                    handleScanFailure(request, response, "Stream Violation: You are registered under Science Stream and cannot check into Computer Science facilities.");
                    return;
                }
                if (!isScienceStream && "LAB_BIO_01".equalsIgnoreCase(targetLabId)) {
                    handleScanFailure(request, response, "Stream Violation: You are registered under Engineering Stream and cannot check into Biology facilities.");
                    return;
                }

                ZonedDateTime malaysiaNow = ZonedDateTime.now(ZoneId.of("Asia/Kuala_Lumpur"));
                LocalTime scanTime = malaysiaNow.toLocalTime();
                LocalTime sessionStartTime = rawTimeSlot != null ? rawTimeSlot.toLocalTime() : scanTime;

                long minutesDifference = ChronoUnit.MINUTES.between(sessionStartTime, scanTime);

                String attendanceStatus = "PRESENT";
                if (minutesDifference > 30) {
                    attendanceStatus = "LATE";
                }

                String insertSQL = "INSERT INTO attendancelog (studentId, bookingId, entryTime, exitTime, contactHours, status) " +
                                   "VALUES (?, ?, CURRENT_TIMESTAMP, NULL, 0.00, ?)";
                
                insertStmt = conn.prepareStatement(insertSQL);
                insertStmt.setInt(1, studentId);
                insertStmt.setString(2, scannedBookingId);
                insertStmt.setString(3, attendanceStatus);

                int rowsAffected = insertStmt.executeUpdate();

                if (rowsAffected > 0) {
                    java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("hh:mm:ss a");
                    String scanClockTime = malaysiaNow.format(formatter);
        
                    session.setAttribute("lastScanTime", scanClockTime);

                    if (isAjaxRequest(request)) {
                        response.setContentType("application/json");
                        response.setCharacterEncoding("UTF-8");
                        response.getWriter().write("{\"success\":true,\"redirect\":\"" + request.getContextPath() + "/student/my-attendance\"}");
                    } else {
                        response.sendRedirect(request.getContextPath() + "/student/my-attendance");
                    }
                } else {
                    handleScanFailure(request, response, "Database Insertion Failure: Unable to log verification records.");
                }
            } else {
                handleScanFailure(request, response, "Invalid Action Request Handler Validation Process.");
            }
                
        } catch (SQLException e) {
            e.printStackTrace();
            handleScanFailure(request, response, "Database Error: " + e.getMessage());
        } finally {
            try { if (rsStream != null) rsStream.close(); } catch (SQLException e) {}
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (autoCloseStmt != null) autoCloseStmt.close(); } catch (SQLException e) {}
            try { if (checkStmt != null) checkStmt.close(); } catch (SQLException e) {}
            try { if (streamStmt != null) streamStmt.close(); } catch (SQLException e) {}
            try { if (insertStmt != null) insertStmt.close(); } catch (SQLException e) {}
            try { if (logStmt != null) logStmt.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }

    private void handleScanFailure(HttpServletRequest request, HttpServletResponse response, String errorMessage) 
            throws ServletException, IOException {
        
        if (isAjaxRequest(request)) {
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            
            String safeMsg = errorMessage.replace("\"", "\\\"");
            response.getWriter().write("{\"success\":false,\"message\":\"" + safeMsg + "\"}");
        } else {
            request.setAttribute("exceptionMessage", errorMessage);
            request.getRequestDispatcher("/WEB-INF/errorPage.jsp").forward(request, response);
        }
    }

    private boolean isAjaxRequest(HttpServletRequest request) {
        String acceptHeader = request.getHeader("Accept");
        String requestedWith = request.getHeader("X-Requested-With");
        return (acceptHeader != null && acceptHeader.contains("application/json")) ||
               "XMLHttpRequest".equalsIgnoreCase(requestedWith);
    }
}