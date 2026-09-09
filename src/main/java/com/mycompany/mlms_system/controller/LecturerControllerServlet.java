package com.mycompany.mlms_system.controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet(name = "LecturerControllerServlet", urlPatterns = {"/lecturer/*"})
public class LecturerControllerServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        String userRole = (String) session.getAttribute("userRole");
        
        if (session.getAttribute("userToken") == null || !"LECTURER".equalsIgnoreCase(userRole)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String pathInfo = request.getPathInfo(); // Matches e.g., "/dashboard", "/book-lab", "/my-bookings"
        if (pathInfo == null) pathInfo = "/dashboard";

        switch (pathInfo) {
            case "/dashboard":
                request.getRequestDispatcher("/WEB-INF/lecturer/lecturerDashboard.jsp").forward(request, response);
                break;
            case "/book-lab":
                request.getRequestDispatcher("/WEB-INF/lecturer/bookingForm.jsp").forward(request, response);
                break;
            case "/my-bookings":
                request.getRequestDispatcher("/WEB-INF/lecturer/viewMyBookings.jsp").forward(request, response);
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