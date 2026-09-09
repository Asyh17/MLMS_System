package MLMSModel;

import java.io.Serializable;

public class BookingBean implements Serializable {
    private String lecturerId;
    private String laboratoryId;
    private String bookingDate;
    private String timeSlot;
    private String academicStream;

    // No-argument constructor (Required for JavaBeans)
    public BookingBean() {}

    // Getters and Setters
    public String getLecturerId() { return lecturerId; }
    public void setLecturerId(String lecturerId) { this.lecturerId = lecturerId; }

    public String getLaboratoryId() { return laboratoryId; }
    public void setLaboratoryId(String laboratoryId) { this.laboratoryId = laboratoryId; }

    public String getBookingDate() { return bookingDate; }
    public void setBookingDate(String bookingDate) { this.bookingDate = bookingDate; }

    public String getTimeSlot() { return timeSlot; }
    public void setTimeSlot(String timeSlot) { this.timeSlot = timeSlot; }

    public String getAcademicStream() { return academicStream; }
    public void setAcademicStream(String academicStream) { this.academicStream = academicStream; }
}