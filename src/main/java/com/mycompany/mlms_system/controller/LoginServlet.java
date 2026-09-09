package com.mycompany.mlms_system.controller;

import com.mycompany.mlms_system.database.DBConnection;
import com.mycompany.mlms_system.database.PasswordUtil;

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

@WebServlet(name = "LoginServlet", urlPatterns = {"/LoginServlet"})
public class LoginServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("login.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String usernameInput = request.getParameter("username");
        String passwordInput = request.getParameter("password");
        
        HttpSession session = request.getSession();

        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();

            String sql = "SELECT userId, name, password, role FROM User WHERE username = ?";
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, usernameInput);

            rs = stmt.executeQuery();

            if (rs.next()) {
                String dbStoredPassword = rs.getString("password");

                if (PasswordUtil.checkPassword(passwordInput, dbStoredPassword)) {
                    int userId = rs.getInt("userId");
                    String name = rs.getString("name");
                    String role = rs.getString("role"); 

                    session.setAttribute("userId", userId);
                    session.setAttribute("userToken", usernameInput);
                    session.setAttribute("userName", name);
                    session.setAttribute("userRole", role);

                    if ("STUDENT".equalsIgnoreCase(role)) {
                        String stream = "Computer Science Student"; 
                        PreparedStatement studentStmt = null;
                        ResultSet studentRs = null;
                        try {
                            String studentSQL = "SELECT studentStream FROM Student WHERE userId = ?";
                            studentStmt = conn.prepareStatement(studentSQL);
                            studentStmt.setInt(1, userId);
                            studentRs = studentStmt.executeQuery();
                            if (studentRs.next()) {
                                stream = studentRs.getString("studentStream");
                            }
                        } catch (SQLException e) {
                            e.printStackTrace();
                        } finally {
                            if (studentRs != null) studentRs.close();
                            if (studentStmt != null) studentStmt.close();
                        }
                        
                        session.setAttribute("userDisplayRole", stream);
                        response.sendRedirect(request.getContextPath() + "/student/dashboard");
                        return;
                        
                    } else {
                        session.setAttribute("userDisplayRole", role);
                        
                        if ("LECTURER".equalsIgnoreCase(role)) {
                            response.sendRedirect(request.getContextPath() + "/lecturer/dashboard");
                            return;
                            
                        } else if ("TECHNICIAN".equalsIgnoreCase(role) || "LAB TECHNICIAN".equalsIgnoreCase(role)) {
                            response.sendRedirect(request.getContextPath() + "/technician/dashboard");
                            return;

                        } else if ("ADMIN".equalsIgnoreCase(role)) {
                            response.sendRedirect(request.getContextPath() + "/admin/dashboard");
                            return;
                        }
                    }
                } else {
                    // Password mismatch
                    request.setAttribute("loginError", "Invalid Username or Password configuration.");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                    return;
                }
            } else {
                request.setAttribute("loginError", "Invalid Username or Password configuration.");
                request.getRequestDispatcher("login.jsp").forward(request, response);
                return;
            }

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("loginError", "Database Exception Failure: " + e.getMessage());
            request.getRequestDispatcher("login.jsp").forward(request, response);
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (stmt != null) stmt.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }
}