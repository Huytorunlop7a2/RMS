package com.fpt.rms.dao;

import com.fpt.rms.model.OpeningException;
import com.fpt.rms.model.OpeningHour;
import com.fpt.rms.util.DBContext;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class OpeningHourDAO {
    public List<OpeningHour> findAll() throws SQLException {
        String sql = "SELECT " + "day_of_week," + "open_time," + "close_time," + "is_closed "
                + "FROM restaurant_opening_hours " + "ORDER BY day_of_week";
        List<OpeningHour> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapWeekly(rs));
            }
        }
        return list;
    }

    public List<OpeningException> findAllExceptions() throws SQLException {
        String sql = "SELECT " + "exception_date," + "open_time," + "close_time," + "is_closed," + "reason,"
                + "created_at " + "FROM restaurant_schedule_exceptions " + "ORDER BY exception_date DESC";
        List<OpeningException> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapException(rs));
            }
        }
        return list;
    }

    public OpeningHour findByDate(LocalDate date) throws SQLException {
        if (date == null) {
            throw new IllegalArgumentException("Ngày không được để trống");
        }
        try (Connection c = DBContext.getConnection()) {
            return findByDate(c, date, false);
        }
    }

    public OpeningHour findByDate(Connection c, LocalDate date, boolean lock) throws SQLException {
        if (date == null) {
            throw new IllegalArgumentException("Ngày không được để trống");
        }
        OpeningException exception = findException(c, date, lock);
        if (exception != null) {
            OpeningHour result = new OpeningHour();
            result.setDayOfWeek(date.getDayOfWeek().getValue());
            result.setOpenTime(exception.getOpenTime());
            result.setCloseTime(exception.getCloseTime());
            result.setClosed(exception.isClosed());
            result.setSpecial(true);
            result.setEffectiveDate(date);
            result.setReason(exception.getReason());
            return result;
        }
        OpeningHour weekly = findWeeklyByDay(c, date.getDayOfWeek().getValue(), lock);
        if (weekly != null) {
            weekly.setSpecial(false);
            weekly.setEffectiveDate(date);
        }
        return weekly;
    }

    public void saveAll(List<OpeningHour> hours) throws SQLException {
        if (hours == null || hours.size() != 7) {
            throw new IllegalArgumentException("Phải cấu hình đủ 7 ngày trong tuần");
        }
        Map<Integer, OpeningHour> schedule = new HashMap<>();
        for (OpeningHour hour : hours) {
            validateWeekly(hour);
            if (schedule.put(hour.getDayOfWeek(), hour) != null) {
                throw new IllegalArgumentException("Ngày trong tuần bị trùng");
            }
        }
        if (schedule.size() != 7) {
            throw new IllegalArgumentException("Phải cấu hình đủ 7 ngày trong tuần");
        }
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                validateFutureReservationsAgainstWeekly(c, schedule);
                for (OpeningHour hour : hours) {
                    upsertWeekly(c, hour);
                }
                c.commit();
            } catch (Exception e) {
                c.rollback();
                throw wrap(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    public void saveException(OpeningException exception) throws SQLException {
        validateException(exception);
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                validateReservationsForDate(c, exception.getExceptionDate(), exception.isClosed(),
                        exception.getOpenTime(), exception.getCloseTime());
                String updateSql = "UPDATE restaurant_schedule_exceptions " + "SET " + "open_time=?," + "close_time=?,"
                        + "is_closed=?," + "reason=? " + "WHERE exception_date=?";
                int affected;
                try (PreparedStatement ps = c.prepareStatement(updateSql)) {
                    setNullableTime(ps, 1, exception.isClosed() ? null : exception.getOpenTime());
                    setNullableTime(ps, 2, exception.isClosed() ? null : exception.getCloseTime());
                    ps.setBoolean(3, exception.isClosed());
                    setNullableString(ps, 4, normalizeReason(exception.getReason()));
                    ps.setDate(5, Date.valueOf(exception.getExceptionDate()));
                    affected = ps.executeUpdate();
                }
                if (affected == 0) {
                    String insertSql = "INSERT INTO restaurant_schedule_exceptions(" + "exception_date," + "open_time,"
                            + "close_time," + "is_closed," + "reason" + ") " + "VALUES(?,?,?,?,?)";
                    try (PreparedStatement ps = c.prepareStatement(insertSql)) {
                        ps.setDate(1, Date.valueOf(exception.getExceptionDate()));
                        setNullableTime(ps, 2, exception.isClosed() ? null : exception.getOpenTime());
                        setNullableTime(ps, 3, exception.isClosed() ? null : exception.getCloseTime());
                        ps.setBoolean(4, exception.isClosed());
                        setNullableString(ps, 5, normalizeReason(exception.getReason()));
                        ps.executeUpdate();
                    }
                }
                c.commit();
            } catch (Exception e) {
                c.rollback();
                throw wrap(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    public void deleteException(LocalDate date) throws SQLException {
        if (date == null) {
            throw new IllegalArgumentException("Ngày ngoại lệ không hợp lệ");
        }
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                OpeningHour weekly = findWeeklyByDay(c, date.getDayOfWeek().getValue(), true);
                if (weekly == null) {
                    throw new IllegalStateException("Không thể xóa ngoại lệ vì lịch tuần chưa được cấu hình");
                }
                validateReservationsForDate(c, date, weekly.isClosed(), weekly.getOpenTime(), weekly.getCloseTime());
                try (PreparedStatement ps = c
                        .prepareStatement("DELETE FROM restaurant_schedule_exceptions " + "WHERE exception_date=?")) {
                    ps.setDate(1, Date.valueOf(date));
                    if (ps.executeUpdate() == 0) {
                        throw new IllegalArgumentException("Ngày đặc biệt không tồn tại");
                    }
                }
                c.commit();
            } catch (Exception e) {
                c.rollback();
                throw wrap(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    private OpeningException findException(Connection c, LocalDate date, boolean lock) throws SQLException {
        String hint = lock ? " WITH (UPDLOCK,HOLDLOCK) " : " ";
        String sql = "SELECT " + "exception_date," + "open_time," + "close_time," + "is_closed," + "reason,"
                + "created_at " + "FROM restaurant_schedule_exceptions" + hint + "WHERE exception_date=?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(date));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapException(rs);
                }
                return null;
            }
        }
    }

    private OpeningHour findWeeklyByDay(Connection c, int dayOfWeek, boolean lock) throws SQLException {
        String hint = lock ? " WITH (UPDLOCK,HOLDLOCK) " : " ";
        String sql = "SELECT " + "day_of_week," + "open_time," + "close_time," + "is_closed "
                + "FROM restaurant_opening_hours" + hint + "WHERE day_of_week=?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, dayOfWeek);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapWeekly(rs);
                }
                return null;
            }
        }
    }

    private void upsertWeekly(Connection c, OpeningHour hour) throws SQLException {
        String updateSql = "UPDATE restaurant_opening_hours " + "SET " + "open_time=?," + "close_time=?,"
                + "is_closed=? " + "WHERE day_of_week=?";
        int affected;
        try (PreparedStatement ps = c.prepareStatement(updateSql)) {
            setNullableTime(ps, 1, hour.isClosed() ? null : hour.getOpenTime());
            setNullableTime(ps, 2, hour.isClosed() ? null : hour.getCloseTime());
            ps.setBoolean(3, hour.isClosed());
            ps.setInt(4, hour.getDayOfWeek());
            affected = ps.executeUpdate();
        }
        if (affected == 0) {
            String insertSql = "INSERT INTO restaurant_opening_hours(" + "day_of_week," + "open_time," + "close_time,"
                    + "is_closed" + ") " + "VALUES(?,?,?,?)";
            try (PreparedStatement ps = c.prepareStatement(insertSql)) {
                ps.setInt(1, hour.getDayOfWeek());
                setNullableTime(ps, 2, hour.isClosed() ? null : hour.getOpenTime());
                setNullableTime(ps, 3, hour.isClosed() ? null : hour.getCloseTime());
                ps.setBoolean(4, hour.isClosed());
                ps.executeUpdate();
            }
        }
    }

    private void validateFutureReservationsAgainstWeekly(Connection c, Map<Integer, OpeningHour> schedule)
            throws SQLException {
        Set<LocalDate> exceptionDates = new HashSet<>();
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT exception_date " + "FROM restaurant_schedule_exceptions " + "WHERE exception_date>=?")) {
            ps.setDate(1, Date.valueOf(LocalDate.now()));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    exceptionDates.add(rs.getDate("exception_date").toLocalDate());
                }
            }
        }
        String sql = "SELECT " + "reservation_id," + "reservation_date," + "start_time," + "end_time,"
                + "customer_name " + "FROM reservations " + "WHERE reservation_date>=? " + "AND status IN ("
                + "'CONFIRMED'," + "'CHECKED_IN'" + ") " + "ORDER BY " + "reservation_date," + "start_time";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(LocalDate.now()));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LocalDate date = rs.getDate("reservation_date").toLocalDate();
                    if (exceptionDates.contains(date)) {
                        continue;
                    }
                    OpeningHour hour = schedule.get(date.getDayOfWeek().getValue());
                    LocalTime start = rs.getTime("start_time").toLocalTime();
                    LocalTime end = rs.getTime("end_time").toLocalTime();
                    if (!fitsSchedule(hour, start, end)) {
                        throw new IllegalStateException("Không thể lưu lịch tuần. " + "Reservation #"
                                + rs.getLong("reservation_id") + " của " + rs.getString("customer_name") + " ngày "
                                + date + " từ " + start + " đến " + end + " sẽ nằm ngoài giờ hoạt động mới.");
                    }
                }
            }
        }
    }

    private void validateReservationsForDate(Connection c, LocalDate date, boolean closed, LocalTime openTime,
            LocalTime closeTime) throws SQLException {
        String sql = "SELECT " + "reservation_id," + "customer_name," + "start_time," + "end_time "
                + "FROM reservations " + "WHERE reservation_date=? " + "AND status IN (" + "'CONFIRMED',"
                + "'CHECKED_IN'" + ") " + "ORDER BY start_time";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(date));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LocalTime start = rs.getTime("start_time").toLocalTime();
                    LocalTime end = rs.getTime("end_time").toLocalTime();
                    boolean invalid = closed || openTime == null || closeTime == null || start.isBefore(openTime)
                            || end.isAfter(closeTime);
                    if (invalid) {
                        throw new IllegalStateException("Không thể thay đổi lịch ngày " + date + ". Reservation #"
                                + rs.getLong("reservation_id") + " của " + rs.getString("customer_name") + " (" + start
                                + " - " + end + ") đang bị ảnh hưởng. " + "Hãy xử lý reservation này trước.");
                    }
                }
            }
        }
    }

    private boolean fitsSchedule(OpeningHour hour, LocalTime start, LocalTime end) {
        if (hour == null || hour.isClosed() || hour.getOpenTime() == null || hour.getCloseTime() == null) {
            return false;
        }
        return !start.isBefore(hour.getOpenTime()) && !end.isAfter(hour.getCloseTime());
    }

    private void validateWeekly(OpeningHour hour) {
        if (hour == null || hour.getDayOfWeek() < 1 || hour.getDayOfWeek() > 7) {
            throw new IllegalArgumentException("Ngày trong tuần không hợp lệ");
        }
        if (hour.isClosed()) {
            return;
        }
        if (hour.getOpenTime() == null || hour.getCloseTime() == null) {
            throw new IllegalArgumentException(hour.getDayName() + ": phải nhập giờ mở cửa và đóng cửa");
        }
        if (!hour.getOpenTime().isBefore(hour.getCloseTime())) {
            throw new IllegalArgumentException(hour.getDayName() + ": giờ đóng cửa phải sau giờ mở cửa");
        }
    }

    private void validateException(OpeningException exception) {
        if (exception == null || exception.getExceptionDate() == null) {
            throw new IllegalArgumentException("Ngày đặc biệt không hợp lệ");
        }
        if (exception.getExceptionDate().isBefore(LocalDate.now())) {
            throw new IllegalArgumentException("Không thể cấu hình ngày đặc biệt trong quá khứ");
        }
        String reason = normalizeReason(exception.getReason());
        if (reason != null && reason.length() > 500) {
            throw new IllegalArgumentException("Lý do tối đa 500 ký tự");
        }
        if (exception.isClosed()) {
            return;
        }
        if (exception.getOpenTime() == null || exception.getCloseTime() == null) {
            throw new IllegalArgumentException("Phải nhập giờ mở cửa và đóng cửa cho ngày đặc biệt");
        }
        if (!exception.getOpenTime().isBefore(exception.getCloseTime())) {
            throw new IllegalArgumentException("Giờ đóng cửa phải sau giờ mở cửa");
        }
    }

    private String normalizeReason(String reason) {
        if (reason == null || reason.isBlank()) {
            return null;
        }
        return reason.trim();
    }

    private void setNullableTime(PreparedStatement ps, int index, LocalTime value) throws SQLException {
        if (value == null) {
            ps.setNull(index, Types.TIME);
        } else {
            ps.setTime(index, Time.valueOf(value));
        }
    }

    private void setNullableString(PreparedStatement ps, int index, String value) throws SQLException {
        if (value == null) {
            ps.setNull(index, Types.NVARCHAR);
        } else {
            ps.setString(index, value);
        }
    }

    private OpeningHour mapWeekly(ResultSet rs) throws SQLException {
        Time open = rs.getTime("open_time");
        Time close = rs.getTime("close_time");
        OpeningHour hour = new OpeningHour();
        hour.setDayOfWeek(rs.getInt("day_of_week"));
        hour.setOpenTime(open == null ? null : open.toLocalTime());
        hour.setCloseTime(close == null ? null : close.toLocalTime());
        hour.setClosed(rs.getBoolean("is_closed"));
        return hour;
    }

    private OpeningException mapException(ResultSet rs) throws SQLException {
        OpeningException exception = new OpeningException();
        exception.setExceptionDate(rs.getDate("exception_date").toLocalDate());
        Time open = rs.getTime("open_time");
        Time close = rs.getTime("close_time");
        exception.setOpenTime(open == null ? null : open.toLocalTime());
        exception.setCloseTime(close == null ? null : close.toLocalTime());
        exception.setClosed(rs.getBoolean("is_closed"));
        exception.setReason(rs.getString("reason"));
        Timestamp created = rs.getTimestamp("created_at");
        exception.setCreatedAt(created == null ? null : created.toLocalDateTime());
        return exception;
    }

    private SQLException wrap(Exception e) {
        if (e instanceof SQLException se) {
            return se;
        }
        return new SQLException(e.getMessage(), e);
    }
}
