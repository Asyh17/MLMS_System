package MLMSModel;

import java.io.Serializable;

/**
 * Generic row container used to render the data table inside the Administrator
 * "View Report" screen (SRD_REQ-01 - Use Case 5). The same bean shape is reused
 * across all three report types (Attendance / Lab Utilization / Contact Hours)
 * so the JSP table-rendering logic does not need to branch on report type.
 */
public class ReportRowBean implements Serializable {

    private String column1;
    private String column2;
    private String column3;
    private String column4;
    private String statusLabel;   // Human readable status text, e.g. "High", "Compliant"
    private String statusVariant; // CSS variant used for badge colouring: good | warn | bad

    public ReportRowBean() {
    }

    public ReportRowBean(String column1, String column2, String column3, String column4,
                          String statusLabel, String statusVariant) {
        this.column1 = column1;
        this.column2 = column2;
        this.column3 = column3;
        this.column4 = column4;
        this.statusLabel = statusLabel;
        this.statusVariant = statusVariant;
    }

    public String getColumn1() { return column1; }
    public void setColumn1(String column1) { this.column1 = column1; }

    public String getColumn2() { return column2; }
    public void setColumn2(String column2) { this.column2 = column2; }

    public String getColumn3() { return column3; }
    public void setColumn3(String column3) { this.column3 = column3; }

    public String getColumn4() { return column4; }
    public void setColumn4(String column4) { this.column4 = column4; }

    public String getStatusLabel() { return statusLabel; }
    public void setStatusLabel(String statusLabel) { this.statusLabel = statusLabel; }

    public String getStatusVariant() { return statusVariant; }
    public void setStatusVariant(String statusVariant) { this.statusVariant = statusVariant; }
}
