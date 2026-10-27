package com.fpt.rms.model;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

public class OpeningHour {

    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm");

    private int dayOfWeek;

    private LocalTime openTime;

    private LocalTime closeTime;

    private boolean closed;

    private boolean special;

    private LocalDate effectiveDate;

    private String reason;

    public OpeningHour() {
    }

    public OpeningHour(
            int dayOfWeek,
            LocalTime openTime,
            LocalTime closeTime,
            boolean closed) {

        this.dayOfWeek = dayOfWeek;

        this.openTime = openTime;

        this.closeTime = closeTime;

        this.closed = closed;
    }

    public int getDayOfWeek() {
        return dayOfWeek;
    }

    public void setDayOfWeek(
            int dayOfWeek) {

        this.dayOfWeek = dayOfWeek;
    }

    public LocalTime getOpenTime() {
        return openTime;
    }

    public void setOpenTime(
            LocalTime openTime) {

        this.openTime = openTime;
    }

    public LocalTime getCloseTime() {
        return closeTime;
    }

    public void setCloseTime(
            LocalTime closeTime) {

        this.closeTime = closeTime;
    }

    public boolean isClosed() {
        return closed;
    }

    public void setClosed(
            boolean closed) {

        this.closed = closed;
    }

    public boolean isSpecial() {
        return special;
    }

    public void setSpecial(
            boolean special) {

        this.special = special;
    }

    public LocalDate getEffectiveDate() {
        return effectiveDate;
    }

    public void setEffectiveDate(
            LocalDate effectiveDate) {

        this.effectiveDate = effectiveDate;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(
            String reason) {

        this.reason = reason;
    }

    public String getOpenTimeValue() {

        if (openTime == null) {

            return "";
        }

        return openTime.format(
                TIME_FORMAT);
    }

    public String getCloseTimeValue() {

        if (closeTime == null) {

            return "";
        }

        return closeTime.format(
                TIME_FORMAT);
    }

    public String getDayName() {

        return switch (dayOfWeek) {

            case 1 ->
                "Thứ 2";

            case 2 ->
                "Thứ 3";

            case 3 ->
                "Thứ 4";

            case 4 ->
                "Thứ 5";

            case 5 ->
                "Thứ 6";

            case 6 ->
                "Thứ 7";

            case 7 ->
                "Chủ nhật";

            default ->
                "Không xác định";
        };
    }

    public String getScheduleText() {

        if (closed) {

            return "Đóng cửa";
        }

        if (openTime == null
                ||
                closeTime == null) {

            return "Chưa cấu hình";
        }

        return openTime.format(
                TIME_FORMAT)
                + " - "
                + closeTime.format(
                        TIME_FORMAT);
    }
}