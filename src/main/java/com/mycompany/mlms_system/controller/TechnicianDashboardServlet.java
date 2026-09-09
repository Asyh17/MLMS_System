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

@WebServlet(name = "TechnicianDashboardServlet", urlPatterns = {"/technician/dashboard"})
public class TechnicianDashboardServlet extends HttpServlet {

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

        int totalCount = 0;
        int pending = 0;
        int approved = 0;

        try (Connection conn = DBConnection.getConnection()) {
            // 1. Total Active Queue (e.g., total bookings or attendance logs)
            try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM booking")) {
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) totalCount = rs.getInt(1);
                }
            }

            // 2. Awaiting Verification (e.g., pending bookings)
            try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM booking WHERE LOWER(status) = 'pending'")) {
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) pending = rs.getInt(1);
                }
            }

            // 3. Verified Content Commits (e.g., approved bookings)
            try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM booking WHERE LOWER(status) = 'approved'")) {
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) approved = rs.getInt(1);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        // Set attributes for the JSP view
        request.setAttribute("totalActiveQueue", totalCount);
        request.setAttribute("awaitingVerification", pending);
        request.setAttribute("verifiedCommits", approved);

        // Forward securely to the protected JSP view
        request.getRequestDispatcher("/WEB-INF/technician/techDashboard.jsp").forward(request, response);
    }
}