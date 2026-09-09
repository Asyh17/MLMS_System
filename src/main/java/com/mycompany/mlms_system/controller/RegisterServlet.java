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

@WebServlet(name = "RegisterServlet", urlPatterns = {"/RegisterServlet"})
public class RegisterServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String name = request.getParameter("name");
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String stream = request.getParameter("studentStream");
        
        System.out.println("DEBUG REGISTER: Received Form Parameters -> Name: " + name + ", Username: " + username + ", Stream: " + stream);
        
        Connection conn = null;
        PreparedStatement checkStmt = null;
        PreparedStatement insertUserStmt = null;
        PreparedStatement insertStudentStmt = null;
        ResultSet rs = null;
        
        try {
            conn = DBConnection.getConnection();
            
            
            String checkSQL = "SELECT COUNT(*) FROM user WHERE LOWER(TRIM(username)) = LOWER(TRIM(?))";
            checkStmt = conn.prepareStatement(checkSQL);
            checkStmt.setString(1, username != null ? username.trim() : "");
            rs = checkStmt.executeQuery();
            
            if (rs.next()) {
                int count = rs.getInt(1);
                System.out.println("DEBUG REGISTER: Username duplication count = " + count);
                if (count > 0) {
                    System.out.println("DEBUG REGISTER: Blocking registration. Username already exists.");
                    rs.close();
                    checkStmt.close();
                    
                    request.setAttribute("regError", "Username '" + username.trim() + "' already exists! Please use a different username.");
                    request.getRequestDispatcher("/register.jsp").forward(request, response);
                    return;
                }
            }
            rs.close();
            checkStmt.close();

            conn.setAutoCommit(false);
            System.out.println("DEBUG REGISTER: Transaction started. Auto-commit set to false.");
            String rawPassword = null;
            
            String hashedPassword = PasswordUtil.hashPassword(rawPassword);
           
            String insertUserSQL = "INSERT INTO user (name, username, password, role) VALUES (?, ?, ?, 'STUDENT')";
            insertUserStmt = conn.prepareStatement(insertUserSQL, java.sql.Statement.RETURN_GENERATED_KEYS);
            insertUserStmt.setString(1, name);
            insertUserStmt.setString(2, username != null ? username.trim() : "");
            insertUserStmt.setString(3, password);
            
            int userRows = insertUserStmt.executeUpdate();
            System.out.println("DEBUG REGISTER: Parent table rows affected = " + userRows);
            
            int newUserId = -1;
            if (userRows > 0) {
                try (ResultSet generatedKeys = insertUserStmt.getGeneratedKeys()) {
                    if (generatedKeys.next()) {
                        newUserId = generatedKeys.getInt(1);
                        System.out.println("DEBUG REGISTER: Retrieved Generated Key userId = " + newUserId);
                    }
                }
            }
           
            if (newUserId != -1) {
                String insertStudentSQL = "INSERT INTO student (userId, studentStream) VALUES (?, ?)";
                insertStudentStmt = conn.prepareStatement(insertStudentSQL);
                insertStudentStmt.setInt(1, newUserId);
                insertStudentStmt.setString(2, stream);
                
                int studentRows = insertStudentStmt.executeUpdate();
                System.out.println("DEBUG REGISTER: Child table rows affected = " + studentRows);
                
                if (studentRows > 0) {
                    // Success! Commit changes to database permanently
                    conn.commit();
                    System.out.println("DEBUG REGISTER: Transaction successfully committed to database!");
                    response.sendRedirect(request.getContextPath() + "/login.jsp?registration=success");
                    return;
                }
            }
            
            System.out.println("DEBUG REGISTER: Execution failed down the pipeline. Rolling back changes.");
            conn.rollback();
            
            request.setAttribute("regError", "Database Transaction Failure: System was unable to map data entities across user streams.");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
            
        } catch (SQLException e) {
            System.out.println("DEBUG REGISTER: SQLException Caught! Message: " + e.getMessage());
            e.printStackTrace();
            if (conn != null) {
                try { 
                    System.out.println("DEBUG REGISTER: Exception rollback executed.");
                    conn.rollback(); 
                } catch (SQLException ex) { ex.printStackTrace(); }
            }
            
            
            request.setAttribute("regError", "Database Error Diagnostics: " + e.getMessage());
            request.getRequestDispatcher("/register.jsp").forward(request, response);
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (checkStmt != null) checkStmt.close(); } catch (SQLException e) {}
            try { if (insertUserStmt != null) insertUserStmt.close(); } catch (SQLException e) {}
            try { if (insertStudentStmt != null) insertStudentStmt.close(); } catch (SQLException e) {}
            try { 
                if (conn != null) {
                    conn.setAutoCommit(true);
                    conn.close();
                    System.out.println("DEBUG REGISTER: Database connection securely closed.");
                }
            } catch (SQLException e) {}
        }
    }
}