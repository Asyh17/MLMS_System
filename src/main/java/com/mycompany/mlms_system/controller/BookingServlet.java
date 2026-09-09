package com.mycompany.mlms_system.controller;

import com.mycompany.mlms_system.database.DBConnection;
import MLMSModel.BookingBean;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet(name = "BookingServlet", urlPatterns = {"/BookingServlet"})
public class BookingServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/lecturer/book-lab"); 
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        String action = request.getParameter("action");

        if ("LECTURER_BATCH_CHECKOUT".equals(action)) {
            String bookingId = request.getParameter("bookingId");
            
            Connection conn = null;
            PreparedStatement updateAttendanceStmt = null;
            PreparedStatement logStmt = null;

            try {
                conn = DBConnection.getConnection();
                String updateAttendanceSQL = "UPDATE AttendanceLog SET exitTime = CURRENT_TIMESTAMP, status = 'COMPLETED' "
                                           + "WHERE bookingId = ? AND exitTime IS NULL";
                updateAttendanceStmt = conn.prepareStatement(updateAttendanceSQL);
                updateAttendanceStmt.setString(1, bookingId);
                updateAttendanceStmt.executeUpdate();
                updateAttendanceStmt.close();
                
                // 🌟 Log early lecturer checkout
                String logSQL = "INSERT INTO system_activity_log (eventDescription, actorType) VALUES (?, ?)";
                logStmt = conn.prepareStatement(logSQL);
                logStmt.setString(1, "Batch check-out executed for booking ID: " + bookingId);
                logStmt.setString(2, "Lecturer");
                logStmt.executeUpdate();
                
                System.out.println("LOG: Lecturer executed early batch check-out for booking ID: " + bookingId);
                session.setAttribute("successMsg", "Lab session closed early successfully. All remaining students checked out.");
                
            } catch (SQLException e) {
                e.printStackTrace();
                session.setAttribute("errorMsg", "Database operational failure: " + e.getMessage());
            } finally {
                try { if (logStmt != null) logStmt.close(); } catch (SQLException e) {}
                try { if (updateAttendanceStmt != null) updateAttendanceStmt.close(); } catch (SQLException e) {}
                try { if (conn != null) conn.close(); } catch (SQLException e) {}
            }
            
            response.sendRedirect(request.getContextPath() + "/lecturer/my-bookings");
            return;
        }
        
        String lecturerIdStr = request.getParameter("lecturerId");
        String labId = request.getParameter("laboratoryId");
        String date = request.getParameter("bookingDate"); // Expects YYYY-MM-DD
        String timeSlot = request.getParameter("timeSlot");    // Expects HH:MM:SS
        String stream = request.getParameter("academicStream");

        // Validate date parameter
        try {
            LocalDate selectedBookingDate = LocalDate.parse(date);
            LocalDate currentSystemDate = LocalDate.now();

            if (selectedBookingDate.isBefore(currentSystemDate)) {
                request.setAttribute("exceptionMessage", "Scheduling Failure: You cannot issue a laboratory reservation request for a past chronological date block.");
                request.getRequestDispatcher("/WEB-INF/errorPage.jsp").forward(request, response);
                return;
            }
        } catch (Exception ex) {
            request.setAttribute("exceptionMessage", "Date Parameter Parsing Failure: The input timestamp formatting string was structurally invalid.");
            request.getRequestDispatcher("/WEB-INF/errorPage.jsp").forward(request, response);
            return;
        }

        // Validate academic stream constraints
        boolean streamMatches = true;
        if ("Engineering Stream".equals(stream) && "LAB_BIO_01".equalsIgnoreCase(labId)) {
            streamMatches = false;
        } else if ("Science Stream".equals(stream) && "LAB_CS_04".equalsIgnoreCase(labId)) {
            streamMatches = false;
        }

        if (!streamMatches) {
            request.setAttribute("exceptionMessage", "Invalid combination: The selected laboratory does not match your chosen Academic Stream profile.");
            request.getRequestDispatcher("/WEB-INF/errorPage.jsp").forward(request, response);
            return;
        }

        Connection conn = null;
        PreparedStatement deptStmt = null;
        PreparedStatement insertStmt = null;
        PreparedStatement logStmt = null;
        ResultSet rsDept = null;

        try {
            conn = DBConnection.getConnection();
            int parsedLecturerId = Integer.parseInt(lecturerIdStr);

            // Look up lecturer's assigned department
            String lecturerDept = "";
            String deptSQL = "SELECT department FROM lecturer WHERE userId = ?";
            deptStmt = conn.prepareStatement(deptSQL);
            deptStmt.setInt(1, parsedLecturerId);
            rsDept = deptStmt.executeQuery();
            if (rsDept.next()) {
                lecturerDept = rsDept.getString("department");
            }
            rsDept.close();
            deptStmt.close();

            // Enforce strict departmental lab access
            boolean isDepartmentAuthorized = false;
            if (lecturerDept != null) {
                if (lecturerDept.contains("Computer Science") && "LAB_CS_04".equalsIgnoreCase(labId)) {
                    isDepartmentAuthorized = true;
                } else if (lecturerDept.contains("Physics") && "LAB_PHYS_01".equalsIgnoreCase(labId)) {
                    isDepartmentAuthorized = true;
                } else if (lecturerDept.contains("Chemistry") && "LAB_CHEM_01".equalsIgnoreCase(labId)) {
                    isDepartmentAuthorized = true;
                } else if (lecturerDept.contains("Biology") && "LAB_BIO_01".equalsIgnoreCase(labId)) {
                    isDepartmentAuthorized = true;
                }
            }

            if (!isDepartmentAuthorized) {
                request.setAttribute("exceptionMessage", "Department Restriction Violation: You are registered under " 
                    + (!lecturerDept.isEmpty() ? ("'" + lecturerDept + "'") : "an unassigned department") 
                    + " and are not authorized to book this laboratory facility (" + labId + ").");
                request.getRequestDispatcher("/WEB-INF/errorPage.jsp").forward(request, response);
                return;
            }

            // Verify room availability against schedule collisions
            if (!isSlotAvailable(conn, labId, date, timeSlot)) {
                request.setAttribute("exceptionMessage", "Scheduling clash: This specific laboratory is already reserved by another faculty member during this time window.");
                request.getRequestDispatcher("/WEB-INF/errorPage.jsp").forward(request, response);
                return;
            }

            // Commit booking
            String programmaticBookingId = "BK" + (int)(Math.random() * 9000 + 1000);

            String insertSQL = "INSERT INTO Booking (bookingId, labId, lecturerId, bookingDate, timeSlot, status) VALUES (?, ?, ?, ?, ?, ?)";
            insertStmt = conn.prepareStatement(insertSQL);
            insertStmt.setString(1, programmaticBookingId);
            insertStmt.setString(2, labId);
            insertStmt.setInt(3, parsedLecturerId);
            insertStmt.setString(4, date);
            insertStmt.setString(5, timeSlot);
            insertStmt.setString(6, "PENDING");

            int rowsInserted = insertStmt.executeUpdate();
            insertStmt.close();

            if (rowsInserted > 0) {
                String logSQL = "INSERT INTO system_activity_log (eventDescription, actorType) VALUES (?, ?)";
                logStmt = conn.prepareStatement(logSQL);
                logStmt.setString(1, "Booking confirmed: " + labId + ", " + timeSlot);
                logStmt.setString(2, "Lecturer");
                logStmt.executeUpdate();

                java.time.ZonedDateTime malaysiaTime = java.time.ZonedDateTime.now(java.time.ZoneId.of("Asia/Kuala_Lumpur"));
                String scanClockTime = malaysiaTime.format(java.time.format.DateTimeFormatter.ofPattern("hh:mm:ss a"));
                
                session.setAttribute("lastScanTime", scanClockTime);
                response.sendRedirect(request.getContextPath() + "/success");
            } else {
                request.setAttribute("exceptionMessage", "Database failure: The system was unable to commit your reservation log record.");
                request.getRequestDispatcher("/WEB-INF/errorPage.jsp").forward(request, response);
            }

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("exceptionMessage", "SQL Exception Diagnostic Error: " + e.getMessage());
            request.getRequestDispatcher("/WEB-INF/errorPage.jsp").forward(request, response);
        } finally {
            try { if (logStmt != null) logStmt.close(); } catch (SQLException e) {}
            try { if (rsDept != null) rsDept.close(); } catch (SQLException e) {}
            try { if (deptStmt != null) deptStmt.close(); } catch (SQLException e) {}
            try { if (insertStmt != null) insertStmt.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }

    public boolean isSlotAvailable(Connection conn, String labId, String date, String timeSlot) throws SQLException {
        String sql = "SELECT COUNT(*) FROM Booking "
                   + "WHERE labId = ? AND bookingDate = ? AND timeSlot = ? AND status <> 'CANCELLED'";
                   
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, labId);
            ps.setString(2, date);
            ps.setString(3, timeSlot);
            
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) == 0; 
                }
            }
        }
        return false;
    }

    @Override
    public String getServletInfo() {
        return "Lab Booking Controller Servlet with Core Database Bindings";
    }
}