package com.fpt.rms.model;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

public class Reservation {
    private static final int CHECKIN_EARLY_MINUTES = 30;
    private static final int NO_SHOW_AFTER_MINUTES = 30;
    private static final DateTimeFormatter DATE_TIME_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
    private long reservationId;
    private long tableId;
    private String tableNumber;
    private String customerName;
    private String phoneNumber;
    private LocalDate reservationDate;
    private LocalTime startTime;
    private LocalTime endTime;
    private int partySize;
    private String status;

    public long getReservationId() {
        return reservationId;
    }

    public void setReservationId(long reservationId) {
        this.reservationId = reservationId;
    }

    public long getTableId() {
        return tableId;
    }

    public void setTableId(long tableId) {
        this.tableId = tableId;
    }

    public String getTableNumber() {
        return tableNumber;
    }

    public void setTableNumber(String tableNumber) {
        this.tableNumber = tableNumber;
    }

    public String getCustomerName() {
        return customerName;
    }

    public void setCustomerName(String customerName) {
        this.customerName = customerName;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public LocalDate getReservationDate() {
        return reservationDate;
    }

    public void setReservationDate(LocalDate reservationDate) {
        this.reservationDate = reservationDate;
    }

    public LocalTime getStartTime() {
        return startTime;
    }

    public void setStartTime(LocalTime startTime) {
        this.startTime = startTime;
    }

    public LocalTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalTime endTime) {
        this.endTime = endTime;
    }

    public int getPartySize() {
        return partySize;
    }

    public void setPartySize(int partySize) {
        this.partySize = partySize;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getStartDateTime() {
        if (reservationDate == null || startTime == null) {
            return null;
        }
        return LocalDateTime.of(reservationDate, startTime);
    }

    public LocalDateTime getEndDateTime() {
        if (reservationDate == null || endTime == null) {
            return null;
        }
        return LocalDateTime.of(reservationDate, endTime);
    }

    public boolean isCanCheckIn() {
        if (!"CONFIRMED".equals(status)) {
            return false;
        }
        LocalDateTime start = getStartDateTime();
        if (start == null) {
            return false;
        }
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime earliest = start.minusMinutes(CHECKIN_EARLY_MINUTES);
        LocalDateTime noShowAt = start.plusMinutes(NO_SHOW_AFTER_MINUTES);
        return !now.isBefore(earliest) && now.isBefore(noShowAt);
    }

    public boolean isCanNoShow() {
        if (!"CONFIRMED".equals(status)) {
            return false;
        }
        LocalDateTime start = getStartDateTime();
        if (start == null) {
            return false;
        }
        LocalDateTime noShowAt = start.plusMinutes(NO_SHOW_AFTER_MINUTES);
        return !LocalDateTime.now().isBefore(noShowAt);
    }

    public boolean isCanCancel() {
        return "CONFIRMED".equals(status);
    }

    public String getActionHint() {
        if (!"CONFIRMED".equals(status)) {
            return "";
        }
        LocalDateTime start = getStartDateTime();
        if (start == null) {
            return "";
        }
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime earliest = start.minusMinutes(CHECKIN_EARLY_MINUTES);
        LocalDateTime noShowAt = start.plusMinutes(NO_SHOW_AFTER_MINUTES);
        if (now.isBefore(earliest)) {
            return "Check-in từ " + earliest.format(DATE_TIME_FORMAT);
        }
        if (now.isBefore(noShowAt)) {
            return "Đang trong khung giờ check-in";
        }
        return "Đã quá 30 phút, có thể đánh dấu No-show";
    }

    public String getStatusLabel() {
        if (status == null) {
            return "";
        }
        return switch (status) {
        case "CONFIRMED" -> "Đã xác nhận";
        case "CHECKED_IN" -> "Đã check-in";
        case "COMPLETED" -> "Hoàn thành";
        case "CANCELLED" -> "Đã hủy";
        case "NO_SHOW" -> "Không đến";
        default -> status;
        };
    }
}
