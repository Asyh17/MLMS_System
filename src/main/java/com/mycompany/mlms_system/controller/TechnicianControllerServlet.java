package com.mycompany.mlms_system.controller;

import com.mycompany.mlms_system.database.DBConnection;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet(name = "TechnicianControllerServlet", urlPatterns = {"/TechnicianControllerServlet"})
public class TechnicianControllerServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        String userRole = (String) session.getAttribute("userRole");
        if (session.getAttribute("userToken") == null || 
            (!"TECHNICIAN".equalsIgnoreCase(userRole) && !"LAB TECHNICIAN".equalsIgnoreCase(userRole))) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String view = request.getParameter("view");
        if (view == null) view = "dashboard";

        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();

            if ("dashboard".equals(view)) {
                String sql = "SELECT COUNT(*) AS total_count, " +
                             "SUM(CASE WHEN LOWER(status) = 'pending' THEN 1 ELSE 0 END) AS pending_count, " +
                             "SUM(CASE WHEN LOWER(status) = 'approved' THEN 1 ELSE 0 END) AS approved_count " +
                             "FROM Booking";

                stmt = conn.prepareStatement(sql);
                rs = stmt.executeQuery();

                int totalActiveQueue = 0;
                int awaitingVerification = 0;
                int verifiedCommits = 0;

                if (rs.next()) {
                    totalActiveQueue = rs.getInt("total_count");
                    awaitingVerification = rs.getInt("pending_count");
                    verifiedCommits = rs.getInt("approved_count");
                }

                request.setAttribute("totalActiveQueue", totalActiveQueue);
                request.setAttribute("awaitingVerification", awaitingVerification);
                request.setAttribute("verifiedCommits", verifiedCommits);

                request.getRequestDispatcher("/WEB-INF/technician/techDashboard.jsp").forward(request, response);
                return;
                
            } else if ("schedule".equals(view)) {
                request.getRequestDispatcher("/WEB-INF/technician/ManageScheduleEntry.jsp").forward(request, response);
                return;
                
            } else if ("verify".equals(view)) {
                request.getRequestDispatcher("/WEB-INF/technician/verifyLabStatus.jsp").forward(request, response);
                return;
                
            } else if ("profiles".equals(view)) {
                request.getRequestDispatcher("/WEB-INF/technician/LabProfile.jsp").forward(request, response);
                return;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (stmt != null) stmt.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
        
        response.sendRedirect(request.getContextPath() + "/technician/dashboard");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        String userRole = (String) session.getAttribute("userRole");
        if (session.getAttribute("userToken") == null || 
            (!"TECHNICIAN".equalsIgnoreCase(userRole) && !"LAB TECHNICIAN".equalsIgnoreCase(userRole))) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String action = request.getParameter("action");
        String targetBookingId = request.getParameter("bookingId");

        if (action != null && targetBookingId != null) {
            Connection conn = null;
            PreparedStatement stmt = null;
            try {
                conn = DBConnection.getConnection();
                
                if ("APPROVE".equals(action)) {
                    String sql = "UPDATE Booking SET status = 'APPROVED' WHERE bookingId = ?";
                    stmt = conn.prepareStatement(sql);
                    stmt.setString(1, targetBookingId);
                    stmt.executeUpdate();
                    session.setAttribute("successMsg", "Lab session allocation " + targetBookingId + " verified and approved successfully!");

                } else if ("REJECT".equals(action)) {
                    String sql = "UPDATE Booking SET status = 'REJECTED' WHERE bookingId = ?";
                    stmt = conn.prepareStatement(sql);
                    stmt.setString(1, targetBookingId);
                    stmt.executeUpdate();
                    session.setAttribute("successMsg", "Lab session request " + targetBookingId + " has been rejected cleanly.");
                }
            } catch (SQLException e) {
                e.printStackTrace();
                session.setAttribute("successMsg", "Error: Database update failed.");
            } finally {
                try { if (stmt != null) stmt.close(); } catch (SQLException e) {}
                try { if (conn != null) conn.close(); } catch (SQLException e) {}
            }
        }
        
        response.sendRedirect(request.getContextPath() + "/technician/verify-labs");
    }
}