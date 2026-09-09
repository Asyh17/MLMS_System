package com.mycompany.mlms_system.controller;

import com.mycompany.mlms_system.database.DBConnection;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet(name = "LecturerManagementServlet", urlPatterns = {"/LecturerManagementServlet"})
public class LecturerManagementServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (session.getAttribute("userToken") == null || 
            !"ADMIN".equals(session.getAttribute("userRole"))) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String action = request.getParameter("action");

        if ("ADD_LECTURER".equalsIgnoreCase(action)) {
            String name = request.getParameter("name");
            String username = request.getParameter("username");
            String password = request.getParameter("password");
            String department = request.getParameter("department");

            if (name == null || username == null || password == null || department == null ||
                name.trim().isEmpty() || username.trim().isEmpty() || password.trim().isEmpty()) {
                redirectWithError(request, response, "Please complete all required fields.");
                return;
            }

            Connection conn = null;
            PreparedStatement checkStmt = null;
            PreparedStatement userStmt = null;
            PreparedStatement lecturerStmt = null;
            ResultSet rs = null;

            try {
                conn = DBConnection.getConnection();
                conn.setAutoCommit(false); 

                String checkUsernameSQL = "SELECT COUNT(*) FROM user WHERE username = ?";
                checkStmt = conn.prepareStatement(checkUsernameSQL);
                checkStmt.setString(1, username.trim().toLowerCase());
                rs = checkStmt.executeQuery();
                if (rs.next() && rs.getInt(1) > 0) {
                    conn.rollback();
                    redirectWithError(request, response, "The username '" + username + "' is already registered in the system.");
                    return;
                }
                rs.close();

                String insertUserSQL = "INSERT INTO user (name, username, password, role, security_answer) VALUES (?, ?, ?, 'LECTURER', 'mlms123')";
                userStmt = conn.prepareStatement(insertUserSQL, Statement.RETURN_GENERATED_KEYS);
                userStmt.setString(1, name.trim());
                userStmt.setString(2, username.trim().toLowerCase());
                userStmt.setString(3, password.trim());
                userStmt.executeUpdate();

                int generatedUserId = -1;
                ResultSet generatedKeys = userStmt.getGeneratedKeys();
                if (generatedKeys.next()) {
                    generatedUserId = generatedKeys.getInt(1);
                }
                generatedKeys.close();

                if (generatedUserId == -1) {
                    conn.rollback();
                    redirectWithError(request, response, "Failed to generate User ID reference.");
                    return;
                }

                String insertLecturerSQL = "INSERT INTO lecturer (userId, department) VALUES (?, ?)";
                lecturerStmt = conn.prepareStatement(insertLecturerSQL);
                lecturerStmt.setInt(1, generatedUserId);
                lecturerStmt.setString(2, department);
                lecturerStmt.executeUpdate();

                conn.commit();
                response.sendRedirect(request.getContextPath() + "/admin/manageLecturers.jsp?status=created");

            } catch (SQLException e) {
                if (conn != null) {
                    try { conn.rollback(); } catch (SQLException rollbackEx) {}
                }
                e.printStackTrace();
                redirectWithError(request, response, "Database Error: " + e.getMessage());
            } finally {
                try { if (rs != null) rs.close(); } catch (SQLException e) {}
                try { if (checkStmt != null) checkStmt.close(); } catch (SQLException e) {}
                try { if (userStmt != null) userStmt.close(); } catch (SQLException e) {}
                try { if (lecturerStmt != null) lecturerStmt.close(); } catch (SQLException e) {}
                try { if (conn != null) conn.close(); } catch (SQLException e) {}
            }
        }
    }

    private void redirectWithError(HttpServletRequest request, HttpServletResponse response, String message) 
            throws IOException {
        String encodedMsg = URLEncoder.encode(message, StandardCharsets.UTF_8.toString());
        response.sendRedirect(request.getContextPath() + "/admin/manageLecturers.jsp?error=" + encodedMsg);
    }
}