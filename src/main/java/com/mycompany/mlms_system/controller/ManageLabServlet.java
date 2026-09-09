package com.mycompany.mlms_system.controller;

import com.mycompany.mlms_system.database.DBConnection;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet(name = "ManageLabServlet", urlPatterns = {"/ManageLabServlet"})
public class ManageLabServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/technician/lab-profile");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        Connection conn = null;
        PreparedStatement stmt = null;
        PreparedStatement logStmt = null;
        
        try {
            conn = DBConnection.getConnection();
            
            if ("ADD".equals(action)) {
                String labId = request.getParameter("labId");
                String labName = request.getParameter("labName");
                int capacity = Integer.parseInt(request.getParameter("capacity"));
                String location = request.getParameter("location");
                String status = request.getParameter("status");
                
                String sql = "INSERT INTO laboratory (labId, labName, capacity, location, status) VALUES (?, ?, ?, ?, ?)";
                stmt = conn.prepareStatement(sql);
                stmt.setString(1, labId != null ? labId.trim().toUpperCase() : "");
                stmt.setString(2, labName != null ? labName.trim() : "");
                stmt.setInt(3, capacity);
                stmt.setString(4, location != null ? location.trim() : "");
                stmt.setString(5, status);
                stmt.executeUpdate();
                stmt.close();

                String logSQL = "INSERT INTO system_activity_log (eventDescription, actorType) VALUES (?, ?)";
                logStmt = conn.prepareStatement(logSQL);
                logStmt.setString(1, "New lab profile created: " + labId);
                logStmt.setString(2, "Technician");
                logStmt.executeUpdate();
                
            } else if ("UPDATE_STATUS".equals(action)) {
                String labId = request.getParameter("labId");
                String status = request.getParameter("status");
                
                String sql = "UPDATE laboratory SET status = ? WHERE labId = ?";
                stmt = conn.prepareStatement(sql);
                stmt.setString(1, status);
                stmt.setString(2, labId);
                stmt.executeUpdate();
                stmt.close();
      
                String logSQL = "INSERT INTO system_activity_log (eventDescription, actorType) VALUES (?, ?)";
                logStmt = conn.prepareStatement(logSQL);
                logStmt.setString(1, "Lab profile " + labId + " status changed to \"" + status + "\"");
                logStmt.setString(2, "Technician");
                logStmt.executeUpdate();
                
            } else if ("DELETE".equals(action)) {
                String labId = request.getParameter("labId");
                String sql = "DELETE FROM laboratory WHERE labId = ?";
                stmt = conn.prepareStatement(sql);
                stmt.setString(1, labId);
                stmt.executeUpdate();
                stmt.close();

                String logSQL = "INSERT INTO system_activity_log (eventDescription, actorType) VALUES (?, ?)";
                logStmt = conn.prepareStatement(logSQL);
                logStmt.setString(1, "Lab profile " + labId + " removed from system");
                logStmt.setString(2, "Technician");
                logStmt.executeUpdate();
            }
            
            response.sendRedirect(request.getContextPath() + "/technician/lab-profile?msg=success");
            
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/technician/lab-profile?msg=error");
        } finally {
            try { if (logStmt != null) logStmt.close(); } catch (SQLException e) {}
            try { if (stmt != null) stmt.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }
}