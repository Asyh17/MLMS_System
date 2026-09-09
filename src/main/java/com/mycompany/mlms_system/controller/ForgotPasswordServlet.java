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

@WebServlet(name = "ForgotPasswordServlet", urlPatterns = {"/ForgotPasswordServlet", "/forgot-password"})
public class ForgotPasswordServlet extends HttpServlet {

    // 🌟 Handle GET Requests: Safely forward to the protected view inside WEB-INF
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/forgotPassword.jsp").forward(request, response);
    }

    // 🌟 Handle POST Requests: Execute password update logic
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String username = request.getParameter("username");
        String securityAnswer = request.getParameter("securityAnswer");
        String newPassword = request.getParameter("newPassword");

        Connection conn = null;
        PreparedStatement checkStmt = null;
        PreparedStatement updateStmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();

            // 1. Check if username and security key match
            String checkSQL = "SELECT userId FROM user WHERE LOWER(TRIM(username)) = LOWER(TRIM(?)) AND security_answer = ?";
            checkStmt = conn.prepareStatement(checkSQL);
            checkStmt.setString(1, username != null ? username.trim() : "");
            checkStmt.setString(2, securityAnswer != null ? securityAnswer.trim() : "");
            rs = checkStmt.executeQuery();

            if (rs.next()) {
                int userId = rs.getInt("userId");
                rs.close();
                checkStmt.close();

                // 2. Update the password
                String updateSQL = "UPDATE user SET password = ? WHERE userId = ?";
                updateStmt = conn.prepareStatement(updateSQL);
                updateStmt.setString(1, newPassword);
                updateStmt.setInt(2, userId);

                int rowsUpdated = updateStmt.executeUpdate();
                updateStmt.close();

                if (rowsUpdated > 0) {
                    // Redirect to login page with success flag
                    response.sendRedirect(request.getContextPath() + "/login.jsp?reset=success");
                    return;
                }
            }

            // If verification fails, forward back to the protected JSP
            request.setAttribute("errorMessage", "Invalid Username or Security Key verification provided.");
            request.getRequestDispatcher("/WEB-INF/forgotPassword.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database Error: " + e.getMessage());
            request.getRequestDispatcher("/WEB-INF/forgotPassword.jsp").forward(request, response);
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (checkStmt != null) checkStmt.close(); } catch (SQLException e) {}
            try { if (updateStmt != null) updateStmt.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }
}