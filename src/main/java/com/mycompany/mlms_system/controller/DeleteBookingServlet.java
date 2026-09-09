package com.mycompany.mlms_system.controller;

import com.mycompany.mlms_system.database.DBConnection;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet(name = "DeleteBookingServlet", urlPatterns = {"/DeleteBookingServlet"})
public class DeleteBookingServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String bookingId = request.getParameter("bookingId");
        
        if (bookingId != null && !bookingId.trim().isEmpty()) {
            Connection conn = null;
            PreparedStatement stmtCheck = null;
            PreparedStatement stmtLogs = null;
            PreparedStatement stmtBooking = null;
            ResultSet rsCheck = null;
            
            try {
                conn = DBConnection.getConnection();
                String checkSQL = "SELECT bookingDate FROM Booking WHERE bookingId = ?";
                stmtCheck = conn.prepareStatement(checkSQL);
                stmtCheck.setString(1, bookingId);
                rsCheck = stmtCheck.executeQuery();
                
                if (rsCheck.next()) {
                    java.sql.Date dbBookingDate = rsCheck.getDate("bookingDate");
                    java.util.Calendar cal = java.util.Calendar.getInstance();
                    cal.set(java.util.Calendar.HOUR_OF_DAY, 0);
                    cal.set(java.util.Calendar.MINUTE, 0);
                    cal.set(java.util.Calendar.SECOND, 0);
                    cal.set(java.util.Calendar.MILLISECOND, 0);
                    Date todayAtMidnight = cal.getTime();
                    
                    if (dbBookingDate.before(todayAtMidnight)) {
                        request.getSession().setAttribute("errorMsg", "⚠️ Restriction Violation: You cannot cancel a past laboratory session. Historical attendance logs must be preserved.");
                        response.sendRedirect(request.getContextPath() + "/lecturer/my-bookings");
                        return;
                    }
                }
                
                conn.setAutoCommit(false);
                
                String deleteLogsSQL = "DELETE FROM AttendanceLog WHERE bookingId = ?";
                stmtLogs = conn.prepareStatement(deleteLogsSQL);
                stmtLogs.setString(1, bookingId);
                stmtLogs.executeUpdate();

                String deleteBookingSQL = "DELETE FROM Booking WHERE bookingId = ?";
                stmtBooking = conn.prepareStatement(deleteBookingSQL);
                stmtBooking.setString(1, bookingId);
                stmtBooking.executeUpdate();
                
                conn.commit();
                request.getSession().setAttribute("successMsg", "✅ Lab session booking successfully canceled.");
                
            } catch (SQLException e) {
                if (conn != null) {
                    try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
                }
                e.printStackTrace();
            } finally {
                try { if (rsCheck != null) rsCheck.close(); } catch (SQLException e) {}
                try { if (stmtCheck != null) stmtCheck.close(); } catch (SQLException e) {}
                try { if (stmtLogs != null) stmtLogs.close(); } catch (SQLException e) {}
                try { if (stmtBooking != null) stmtBooking.close(); } catch (SQLException e) {}
                try { if (conn != null) conn.close(); } catch (SQLException e) {}
            }
        }
        
        response.sendRedirect(request.getContextPath() + "/lecturer/my-bookings");
    }
}