package com.fpt.rms.model;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

public class OpeningException {
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm");
    private LocalDate exceptionDate;
    private LocalTime openTime;
    private LocalTime closeTime;
    private boolean closed;
    private String reason;
    private LocalDateTime createdAt;

    public OpeningException() {
    }

    public OpeningException(LocalDate exceptionDate, LocalTime openTime, LocalTime closeTime, boolean closed,
            String reason) {
        this.exceptionDate = exceptionDate;
        this.openTime = openTime;
        this.closeTime = closeTime;
        this.closed = closed;
        this.reason = reason;
    }

    public LocalDate getExceptionDate() {
        return exceptionDate;
    }

    public void setExceptionDate(LocalDate exceptionDate) {
        this.exceptionDate = exceptionDate;
    }

    public LocalTime getOpenTime() {
        return openTime;
    }

    public void setOpenTime(LocalTime openTime) {
        this.openTime = openTime;
    }

    public LocalTime getCloseTime() {
        return closeTime;
    }

    public void setCloseTime(LocalTime closeTime) {
        this.closeTime = closeTime;
    }

    public boolean isClosed() {
        return closed;
    }

    public void setClosed(boolean closed) {
        this.closed = closed;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getOpenTimeValue() {
        if (openTime == null) {
            return "";
        }
        return openTime.format(TIME_FORMAT);
    }

    public String getCloseTimeValue() {
        if (closeTime == null) {
            return "";
        }
        return closeTime.format(TIME_FORMAT);
    }

    public String getScheduleText() {
        if (closed) {
            return "Đóng cửa cả ngày";
        }
        if (openTime == null || closeTime == null) {
            return "Chưa cấu hình";
        }
        return openTime.format(TIME_FORMAT) + " - " + closeTime.format(TIME_FORMAT);
    }
}
