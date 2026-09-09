package com.mycompany.mlms_system.controller;

import MLMSModel.ReportBean;
import MLMSModel.ReportRowBean;
import com.mycompany.mlms_system.database.DBConnection;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * Controller for the Administrator "View Report" and "Live Monitor" use cases.
 */
@WebServlet(name = "ReportServlet", urlPatterns = {"/ReportServlet"})
public class ReportServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        if (session.getAttribute("userToken") == null || !"ADMIN".equalsIgnoreCase((String) session.getAttribute("userRole"))) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String reportType = request.getParameter("reportType");
        
        if ("Utilization".equals(reportType)) {
            LocalDate today = LocalDate.now();
            LocalDate weekAgo = today.minusDays(7);
            
            ReportBean liveReport = buildReport("Utilization", weekAgo, today, "All", weekAgo.toString(), today.toString());
            request.setAttribute("reportData", liveReport);
            request.getRequestDispatcher("/WEB-INF/admin/monitorUsage.jsp").forward(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/admin/dashboard");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        if (session.getAttribute("userToken") == null || !"ADMIN".equalsIgnoreCase((String) session.getAttribute("userRole"))) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String reportType = request.getParameter("reportType");
        String dateFromStr = request.getParameter("dateFrom");
        String dateToStr = request.getParameter("dateTo");
        String labType = request.getParameter("labType");
        if (labType == null || labType.isBlank()) {
            labType = "All";
        }

        // Echo selections back to user form context inputs
        request.setAttribute("submittedReportType", reportType);
        request.setAttribute("submittedDateFrom", dateFromStr);
        request.setAttribute("submittedDateTo", dateToStr);
        request.setAttribute("submittedLabType", labType);

        LocalDate dateFrom;
        LocalDate dateTo;
        try {
            dateFrom = LocalDate.parse(dateFromStr);
            dateTo = LocalDate.parse(dateToStr);
        } catch (DateTimeParseException | NullPointerException ex) {
            request.setAttribute("noRecordsMessage", "No records found for the selected period. Please adjust the date range.");
            request.getRequestDispatcher("/WEB-INF/admin/viewReport.jsp").forward(request, response);
            return;
        }

        if (dateFrom.isAfter(dateTo)) {
            request.setAttribute("noRecordsMessage", "Invalid Date Selection: 'From Date' cannot occur after 'To Date'.");
            request.getRequestDispatcher("/WEB-INF/admin/viewReport.jsp").forward(request, response);
            return;
        }

        ReportBean report = buildReport(reportType, dateFrom, dateTo, labType, dateFromStr, dateToStr);
        request.setAttribute("reportData", report);
        
        if ("Utilization".equals(reportType) && request.getParameter("isLiveMonitor") != null) {
            request.getRequestDispatcher("/WEB-INF/admin/monitorUsage.jsp").forward(request, response);
        } else {
            request.getRequestDispatcher("/WEB-INF/admin/viewReport.jsp").forward(request, response);
        }
    }

    private ReportBean buildReport(String reportType, LocalDate from, LocalDate to,
                                   String labType, String rawFrom, String rawTo) {

        ReportBean report = new ReportBean();
        report.setReportType(reportType != null ? reportType : "Attendance");
        report.setDateFrom(rawFrom);
        report.setDateTo(rawTo);
        report.setLabTypeFilter(labType);
        report.setGeneratedOn(LocalDate.now() + " " + LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm")));

        long spanDays = Math.max(1, ChronoUnit.DAYS.between(from, to) + 1);
        
        String[][] labs = {
            {"LAB_CS_04", "Computer Science Lab (Intelligence Systems)", "CS"},
            {"LAB_PHYS_01", "Physics Lab (Advanced Mechanics)", "Physics"},
            {"LAB_CHEM_01", "Chemistry Lab (Organic Molecular)", "Chemistry"},
            {"LAB_BIO_01", "Biology Lab (Genetics & Micro)", "Biology"}
        };

        List<ReportRowBean> rows = new ArrayList<>();
        List<String> chartLabels = new ArrayList<>();
        List<Double> chartValues = new ArrayList<>();

        if (null == report.getReportType()) {
            report.setReportType("Attendance");
            report.setColumnHeaders(List.of("Laboratory", "Academic Stream", "Students Present", "Attendance Rate"));
            report.setChartTitle("Average Attendance Rate by Room (%)");
        } else {
            switch (report.getReportType()) {
                case "Utilization" -> {
                    report.setColumnHeaders(List.of("Laboratory", "Academic Stream", "Bookings in Range", "Utilization Rate"));
                    report.setChartTitle("Lab Utilization Rate by Room (%)");
                }
                case "ContactHours" -> {
                    report.setColumnHeaders(List.of("Laboratory", "Academic Stream", "Total Contact Hours", "Compliance Status"));
                    report.setChartTitle("Total Logged Contact Hours by Room");
                }
                default -> {
                    report.setReportType("Attendance");
                    report.setColumnHeaders(List.of("Laboratory", "Academic Stream", "Students Present", "Attendance Rate"));
                    report.setChartTitle("Average Attendance Rate by Room (%)");
                }
            }
        }

        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;

        int totalGlobalBookings = 0;
        double overallUtilAccumulator = 0.0;
        int activeRoomsCounted = 0;

        try {
            conn = DBConnection.getConnection();

            for (String[] lab : labs) {
                if (!"All".equals(labType) && !lab[2].equalsIgnoreCase(labType)) {
                    continue;
                }

                String sql = "SELECT COUNT(*) FROM Booking WHERE labId = ? AND bookingDate BETWEEN ? AND ?";
                if ("Utilization".equals(report.getReportType())) {
                    sql += " AND LOWER(status) = 'approved'";
                }

                stmt = conn.prepareStatement(sql);
                stmt.setString(1, lab[0]);
                stmt.setString(2, from.toString());
                stmt.setString(3, to.toString());
                
                rs = stmt.executeQuery();
                int confirmedBookingsCount = 0;
                if (rs.next()) {
                    confirmedBookingsCount = rs.getInt(1);
                }
                rs.close();
                stmt.close();

                long totalPossibleOperationalCapacity = spanDays * 2;
                int computedRatePercent = (int) Math.min(100, Math.round((confirmedBookingsCount * 100.0) / totalPossibleOperationalCapacity));

                String labelMetric, variantStyle;
                if (computedRatePercent >= 75) {
                    labelMetric = "High / Compliant"; variantStyle = "good";
                } else if (computedRatePercent >= 40) {
                    labelMetric = "Moderate / At Risk"; variantStyle = "warn";
                } else {
                    labelMetric = "Low / Action Needed"; variantStyle = "bad";
                }

                String valueColumn, percentageColumn;
                if (null == report.getReportType()) {
                    valueColumn = confirmedBookingsCount + " sessions holds";
                    percentageColumn = computedRatePercent + "%";
                } else {
                    switch (report.getReportType()) {
                        case "ContactHours" -> {
                            int contactHours = confirmedBookingsCount * 2;
                            valueColumn = contactHours + " hrs";
                            percentageColumn = labelMetric;
                        }
                        case "Attendance" -> {
                            valueColumn = (int)(confirmedBookingsCount * 28) + " attendees";
                            percentageColumn = computedRatePercent + "%";
                        }
                        default -> {
                            valueColumn = confirmedBookingsCount + " sessions holds";
                            percentageColumn = computedRatePercent + "%";
                        }
                    }
                }

                rows.add(new ReportRowBean(lab[0] + " — " + lab[1], lab[2], valueColumn, percentageColumn, labelMetric, variantStyle));

                totalGlobalBookings += confirmedBookingsCount;
                overallUtilAccumulator += computedRatePercent;
                activeRoomsCounted++;

                chartLabels.add(lab[0]);
                chartValues.add((double) computedRatePercent);
            }

            if (activeRoomsCounted == 0) activeRoomsCounted = 1;
            int finalAverageAggregate = (int) Math.round(overallUtilAccumulator / activeRoomsCounted);

            if ("ContactHours".equals(report.getReportType())) {
                report.getSummaryMetrics().put("Total Contact Hours Logged", (totalGlobalBookings * 2) + " hrs");
                report.getSummaryMetrics().put("Average Hours per Laboratory", Math.round((totalGlobalBookings * 2.0) / activeRoomsCounted) + " hrs");
                report.getSummaryMetrics().put("Monitored Facility Nodes", String.valueOf(activeRoomsCounted));
            } else {
                report.getSummaryMetrics().put("Total Verified Bookings in Range", String.valueOf(totalGlobalBookings));
                report.getSummaryMetrics().put("Overall Performance Utilization", finalAverageAggregate + "%");
                report.getSummaryMetrics().put("Laboratories Included", String.valueOf(activeRoomsCounted));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (stmt != null) stmt.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }

        report.setDataRows(rows);
        report.setChartLabels(chartLabels);
        report.setChartValues(chartValues);
        return report;
    }

    @Override
    public String getServletInfo() {
        return "Administrator Report Generation Controller Servlet";
    }
}