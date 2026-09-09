package com.mycompany.mlms_system.controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet(name = "StudentControllerServlet", urlPatterns = {"/student/*"})
public class StudentControllerServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        String userRole = (String) session.getAttribute("userRole");
        
        if (session.getAttribute("userToken") == null || !"STUDENT".equalsIgnoreCase(userRole)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String pathInfo = request.getPathInfo(); // Matches e.g., "/dashboard", "/scan", "/my-attendance"
        if (pathInfo == null) pathInfo = "/dashboard";

        switch (pathInfo) {
            case "/dashboard":
                request.getRequestDispatcher("/WEB-INF/student/studentDashboard.jsp").forward(request, response);
                break;
            case "/scan":
                request.getRequestDispatcher("/WEB-INF/student/scanAttendance.jsp").forward(request, response);
                break;
            case "/my-attendance":
                request.getRequestDispatcher("/WEB-INF/student/viewAttendance.jsp").forward(request, response);
                break;
            default:
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}