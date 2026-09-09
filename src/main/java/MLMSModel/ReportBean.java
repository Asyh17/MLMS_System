package MLMSModel;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Carries the fully aggregated result of an Administrator "View Report" request
 * (SRD_REQ-01, Use Case 5) from the ReportServlet controller back to viewReport.jsp.
 *
 * Mirrors the Data Design section of the SDD:
 *  - Data Input:  reportType, dateFrom/dateTo, optional labType filter
 *  - Data Output: summary statistics, a data table, and a chart-ready dataset
 */
public class ReportBean implements Serializable {

    private String reportType;     // Attendance | Utilization | ContactHours
    private String dateFrom;
    private String dateTo;
    private String labTypeFilter;  // All | CS | Physics | Chemistry | Biology
    private String generatedOn;

    private List<String> columnHeaders = new ArrayList<>();
    private List<ReportRowBean> dataRows = new ArrayList<>();
    private Map<String, String> summaryMetrics = new LinkedHashMap<>();

    private String chartTitle;
    private List<String> chartLabels = new ArrayList<>();
    private List<Double> chartValues = new ArrayList<>();

    public ReportBean() {
    }

    public String getReportType() { return reportType; }
    public void setReportType(String reportType) { this.reportType = reportType; }

    public String getDateFrom() { return dateFrom; }
    public void setDateFrom(String dateFrom) { this.dateFrom = dateFrom; }

    public String getDateTo() { return dateTo; }
    public void setDateTo(String dateTo) { this.dateTo = dateTo; }

    public String getLabTypeFilter() { return labTypeFilter; }
    public void setLabTypeFilter(String labTypeFilter) { this.labTypeFilter = labTypeFilter; }

    public String getGeneratedOn() { return generatedOn; }
    public void setGeneratedOn(String generatedOn) { this.generatedOn = generatedOn; }

    public List<String> getColumnHeaders() { return columnHeaders; }
    public void setColumnHeaders(List<String> columnHeaders) { this.columnHeaders = columnHeaders; }

    public List<ReportRowBean> getDataRows() { return dataRows; }
    public void setDataRows(List<ReportRowBean> dataRows) { this.dataRows = dataRows; }

    public Map<String, String> getSummaryMetrics() { return summaryMetrics; }
    public void setSummaryMetrics(Map<String, String> summaryMetrics) { this.summaryMetrics = summaryMetrics; }

    public String getChartTitle() { return chartTitle; }
    public void setChartTitle(String chartTitle) { this.chartTitle = chartTitle; }

    public List<String> getChartLabels() { return chartLabels; }
    public void setChartLabels(List<String> chartLabels) { this.chartLabels = chartLabels; }

    public List<Double> getChartValues() { return chartValues; }
    public void setChartValues(List<Double> chartValues) { this.chartValues = chartValues; }
}
