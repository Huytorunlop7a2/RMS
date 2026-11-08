package com.fpt.rms.dao;

import com.fpt.rms.model.Reservation;
import com.fpt.rms.util.DBContext;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class ReservationDAO {

    private static final int CHECKIN_EARLY_MINUTES = 30;
    private static final int NO_SHOW_AFTER_MINUTES = 30;

    private static final String SELECT_RESERVATION =
            "SELECT "
            + "r.reservation_id, "
            + "r.table_id, "
            + "COALESCE(x.table_numbers, t.table_number) AS table_number, "
            + "r.customer_name, "
            + "r.phone_number, "
            + "r.reservation_date, "
            + "r.start_time, "
            + "r.end_time, "
            + "r.party_size, "
            + "r.status "
            + "FROM reservations r "
            + "JOIN restaurant_tables t ON t.table_id = r.table_id "
            + "LEFT JOIN ("
            + "SELECT rt.reservation_id, "
            + "STRING_AGG(tb.table_number, ' + ') "
            + "WITHIN GROUP (ORDER BY tb.table_number) AS table_numbers "
            + "FROM reservation_tables rt "
            + "JOIN restaurant_tables tb ON tb.table_id = rt.table_id "
            + "GROUP BY rt.reservation_id"
            + ") x ON x.reservation_id = r.reservation_id ";

    public List<Reservation> findAll() throws SQLException {

        List<Reservation> list = new ArrayList<>();

        String sql = SELECT_RESERVATION
                + "ORDER BY "
                + "CASE WHEN r.status IN ('CONFIRMED', 'CHECKED_IN') THEN 0 ELSE 1 END, "
                + "CASE WHEN r.reservation_date >= CAST(GETDATE() AS DATE) THEN 0 ELSE 1 END, "
                + "r.reservation_date, r.start_time, r.reservation_id";

        try (
                Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()
        ) {
            while (rs.next()) {
                list.add(mapReservation(rs));
            }
        }

        return list;
    }

    public Reservation findById(long reservationId) throws SQLException {

        String sql = SELECT_RESERVATION
                + "WHERE r.reservation_id = ?";

        try (
                Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql)
        ) {
            ps.setLong(1, reservationId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapReservation(rs) : null;
            }
        }
    }

    public List<Long> findTableIds(long reservationId) throws SQLException {

        try (Connection c = DBContext.getConnection()) {

            long primaryTableId;

            try (
                    PreparedStatement ps = c.prepareStatement(
                            "SELECT table_id FROM reservations WHERE reservation_id = ?"
                    )
            ) {
                ps.setLong(1, reservationId);

                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Đặt bàn không tồn tại");
                    }

                    primaryTableId = rs.getLong("table_id");
                }
            }

            return getTableIds(c, reservationId, primaryTableId);
        }
    }

    public Set<Long> findBusyTableIds(
            LocalDate date,
            LocalTime start,
            LocalTime end
    ) throws SQLException {

        return findBusyTableIds(date, start, end, null);
    }

    public Set<Long> findBusyTableIds(
            LocalDate date,
            LocalTime start,
            LocalTime end,
            Long excludedReservationId
    ) throws SQLException {

        Set<Long> ids = new HashSet<>();

        String sql = "SELECT DISTINCT rt.table_id "
                + "FROM reservation_tables rt "
                + "JOIN reservations r ON r.reservation_id = rt.reservation_id "
                + "WHERE r.reservation_date = ? "
                + "AND r.status IN ('CONFIRMED', 'CHECKED_IN') "
                + "AND r.start_time < ? "
                + "AND r.end_time > ? "
                + (excludedReservationId == null
                        ? ""
                        : "AND r.reservation_id <> ?");

        try (
                Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql)
        ) {

            ps.setDate(1, Date.valueOf(date));
            ps.setTime(2, Time.valueOf(end));
            ps.setTime(3, Time.valueOf(start));

            if (excludedReservationId != null) {
                ps.setLong(4, excludedReservationId);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ids.add(rs.getLong("table_id"));
                }
            }
        }

        return ids;
    }

    public boolean hasOverlap(
            Connection c,
            List<Long> tableIds,
            LocalDate date,
            LocalTime start,
            LocalTime end
    ) throws SQLException {

        return hasOverlap(c, tableIds, date, start, end, null);
    }

    public boolean hasOverlap(
            Connection c,
            List<Long> tableIds,
            LocalDate date,
            LocalTime start,
            LocalTime end,
            Long excludedReservationId
    ) throws SQLException {

        if (tableIds == null || tableIds.isEmpty()) {
            return false;
        }

        String placeholders = String.join(
                ",",
                Collections.nCopies(tableIds.size(), "?")
        );

        String sql = "SELECT COUNT(*) "
                + "FROM reservation_tables rt WITH (UPDLOCK, HOLDLOCK) "
                + "JOIN reservations r WITH (UPDLOCK, HOLDLOCK) "
                + "ON r.reservation_id = rt.reservation_id "
                + "WHERE rt.table_id IN (" + placeholders + ") "
                + "AND r.reservation_date = ? "
                + "AND r.status IN ('CONFIRMED', 'CHECKED_IN') "
                + "AND r.start_time < ? "
                + "AND r.end_time > ? "
                + (excludedReservationId == null
                        ? ""
                        : "AND r.reservation_id <> ?");

        try (PreparedStatement ps = c.prepareStatement(sql)) {

            int index = 1;

            for (Long tableId : tableIds) {
                ps.setLong(index++, tableId);
            }

            ps.setDate(index++, Date.valueOf(date));
            ps.setTime(index++, Time.valueOf(end));
            ps.setTime(index++, Time.valueOf(start));

            if (excludedReservationId != null) {
                ps.setLong(index, excludedReservationId);
            }

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    public long insertReservation(
            Connection c,
            long primaryTableId,
            long staffId,
            String customerName,
            String phoneNumber,
            LocalDate date,
            LocalTime start,
            LocalTime end,
            int partySize
    ) throws SQLException {

        String sql = "INSERT INTO reservations("
                + "table_id, created_by_staff_id, customer_name, phone_number, "
                + "reservation_date, start_time, end_time, party_size, status"
                + ") OUTPUT INSERTED.reservation_id "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'CONFIRMED')";

        try (PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setLong(1, primaryTableId);
            ps.setLong(2, staffId);
            ps.setString(3, customerName.trim());
            ps.setString(4, phoneNumber.trim());
            ps.setDate(5, Date.valueOf(date));
            ps.setTime(6, Time.valueOf(start));
            ps.setTime(7, Time.valueOf(end));
            ps.setInt(8, partySize);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("Không thể tạo đặt bàn");
                }

                return rs.getLong(1);
            }
        }
    }

    public void insertReservationTables(
            Connection c,
            long reservationId,
            List<Long> tableIds
    ) throws SQLException {

        if (tableIds == null || tableIds.isEmpty()) {
            throw new IllegalArgumentException(
                    "Đặt bàn phải có ít nhất một bàn"
            );
        }

        String sql = "INSERT INTO reservation_tables("
                + "reservation_id, table_id"
                + ") VALUES (?, ?)";

        try (PreparedStatement ps = c.prepareStatement(sql)) {

            for (Long tableId : tableIds) {
                ps.setLong(1, reservationId);
                ps.setLong(2, tableId);
                ps.addBatch();
            }

            ps.executeBatch();
        }
    }

    public Reservation lockReservation(
            Connection c,
            long reservationId
    ) throws SQLException {

        String sql = "SELECT "
                + "reservation_id, table_id, customer_name, phone_number, "
                + "reservation_date, start_time, end_time, party_size, status "
                + "FROM reservations WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE reservation_id = ?";

        try (PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setLong(1, reservationId);

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    throw new IllegalArgumentException(
                            "Đặt bàn không tồn tại"
                    );
                }

                Reservation reservation = new Reservation();

                reservation.setReservationId(
                        rs.getLong("reservation_id")
                );

                reservation.setTableId(
                        rs.getLong("table_id")
                );

                reservation.setCustomerName(
                        rs.getString("customer_name")
                );

                reservation.setPhoneNumber(
                        rs.getString("phone_number")
                );

                reservation.setReservationDate(
                        rs.getDate("reservation_date").toLocalDate()
                );

                reservation.setStartTime(
                        rs.getTime("start_time").toLocalTime()
                );

                reservation.setEndTime(
                        rs.getTime("end_time").toLocalTime()
                );

                reservation.setPartySize(
                        rs.getInt("party_size")
                );

                reservation.setStatus(
                        rs.getString("status")
                );

                return reservation;
            }
        }
    }

    public List<Long> findTableIds(
            Connection c,
            long reservationId,
            long primaryTableId
    ) throws SQLException {

        return getTableIds(
                c,
                reservationId,
                primaryTableId
        );
    }

    public boolean hasOpenOrder(
            Connection c,
            long reservationId
    ) throws SQLException {

        String sql = "SELECT COUNT(*) "
                + "FROM orders WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE reservation_id = ? "
                + "AND order_status = 'OPEN'";

        try (PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setLong(1, reservationId);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    public void updateReservationRecord(
            Connection c,
            long reservationId,
            long primaryTableId,
            String customerName,
            String phoneNumber,
            LocalDate date,
            LocalTime start,
            LocalTime end,
            int partySize
    ) throws SQLException {

        String sql = "UPDATE reservations SET "
                + "table_id = ?, "
                + "customer_name = ?, "
                + "phone_number = ?, "
                + "reservation_date = ?, "
                + "start_time = ?, "
                + "end_time = ?, "
                + "party_size = ? "
                + "WHERE reservation_id = ? "
                + "AND status = 'CONFIRMED'";

        try (PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setLong(1, primaryTableId);
            ps.setString(2, customerName.trim());
            ps.setString(3, phoneNumber.trim());
            ps.setDate(4, Date.valueOf(date));
            ps.setTime(5, Time.valueOf(start));
            ps.setTime(6, Time.valueOf(end));
            ps.setInt(7, partySize);
            ps.setLong(8, reservationId);

            if (ps.executeUpdate() != 1) {
                throw new IllegalStateException(
                        "Reservation đã thay đổi trạng thái. Vui lòng tải lại."
                );
            }
        }
    }

    public void replaceReservationTables(
            Connection c,
            long reservationId,
            List<Long> tableIds
    ) throws SQLException {

        try (PreparedStatement ps = c.prepareStatement(
                "DELETE FROM reservation_tables WHERE reservation_id = ?"
        )) {

            ps.setLong(1, reservationId);
            ps.executeUpdate();
        }

        insertReservationTables(
                c,
                reservationId,
                tableIds
        );
    }

    public void insertChangeHistory(
            Connection c,
            long reservationId,
            long staffId,
            String reason,
            String oldValues,
            String newValues
    ) throws SQLException {

        String sql = "INSERT INTO reservation_change_history("
                + "reservation_id, changed_by_staff_id, reason, old_values, new_values"
                + ") VALUES (?, ?, ?, ?, ?)";

        try (PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setLong(1, reservationId);
            ps.setLong(2, staffId);

            if (reason == null || reason.isBlank()) {
                ps.setNull(3, Types.NVARCHAR);
            } else {
                ps.setString(3, reason.trim());
            }

            ps.setString(4, oldValues);
            ps.setString(5, newValues);

            ps.executeUpdate();
        }
    }

    public void changeStatus(
            long reservationId,
            String action
    ) throws SQLException {

        try (Connection c = DBContext.getConnection()) {

            c.setAutoCommit(false);

            try {
                Reservation reservation = lockReservation(c, reservationId);

                List<Long> tableIds = getTableIds(
                        c,
                        reservationId,
                        reservation.getTableId()
                );

                if (tableIds.isEmpty()) {
                    throw new IllegalStateException(
                            "Đặt bàn chưa được gán bàn"
                    );
                }

                String newStatus;

                if ("checkin".equals(action)) {

                    validateCheckInTime(reservation);
                    newStatus = "CHECKED_IN";
                    lockTablesForCheckin(c, tableIds, reservationId);

                } else if ("cancel".equals(action)) {

                    if (!"CONFIRMED".equals(reservation.getStatus())) {
                        throw new IllegalStateException(
                                "Chỉ đặt bàn đã xác nhận mới có thể hủy"
                        );
                    }

                    newStatus = "CANCELLED";

                } else if ("noshow".equals(action)) {

                    validateNoShowTime(reservation);
                    newStatus = "NO_SHOW";

                } else {

                    throw new IllegalArgumentException(
                            "Thao tác không hợp lệ"
                    );
                }

                try (
                        PreparedStatement ps = c.prepareStatement(
                                "UPDATE reservations SET status = ? "
                                + "WHERE reservation_id = ? "
                                + "AND status = 'CONFIRMED'"
                        )
                ) {

                    ps.setString(1, newStatus);
                    ps.setLong(2, reservationId);

                    if (ps.executeUpdate() != 1) {
                        throw new IllegalStateException(
                                "Trạng thái đặt bàn đã thay đổi. Vui lòng tải lại."
                        );
                    }
                }

                if ("CHECKED_IN".equals(newStatus)) {

                    String placeholders = String.join(
                            ",",
                            Collections.nCopies(tableIds.size(), "?")
                    );

                    String sql = "UPDATE restaurant_tables "
                            + "SET status = 'OCCUPIED' "
                            + "WHERE table_id IN (" + placeholders + ")";

                    try (PreparedStatement ps = c.prepareStatement(sql)) {

                        for (int i = 0; i < tableIds.size(); i++) {
                            ps.setLong(i + 1, tableIds.get(i));
                        }

                        int updated = ps.executeUpdate();

                        if (updated != tableIds.size()) {
                            throw new IllegalStateException(
                                    "Không thể cập nhật trạng thái toàn bộ nhóm bàn"
                            );
                        }
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

    private void validateCheckInTime(Reservation reservation) {

        if (!"CONFIRMED".equals(reservation.getStatus())) {
            throw new IllegalStateException(
                    "Chỉ đặt bàn đã xác nhận mới có thể check-in"
            );
        }

        LocalDateTime reservationStart = LocalDateTime.of(
                reservation.getReservationDate(),
                reservation.getStartTime()
        );

        LocalDateTime earliest =
                reservationStart.minusMinutes(CHECKIN_EARLY_MINUTES);

        LocalDateTime latestExclusive =
                reservationStart.plusMinutes(NO_SHOW_AFTER_MINUTES);

        LocalDateTime now = LocalDateTime.now();

        if (now.isBefore(earliest)) {
            throw new IllegalStateException(
                    "Chỉ được check-in từ 30 phút trước giờ đặt"
            );
        }

        if (!now.isBefore(latestExclusive)) {
            throw new IllegalStateException(
                    "Đã quá thời gian check-in. Có thể đánh dấu No-show."
            );
        }
    }

    private void validateNoShowTime(Reservation reservation) {

        if (!"CONFIRMED".equals(reservation.getStatus())) {
            throw new IllegalStateException(
                    "Chỉ đặt bàn đã xác nhận mới có thể đánh dấu No-show"
            );
        }

        LocalDateTime reservationStart = LocalDateTime.of(
                reservation.getReservationDate(),
                reservation.getStartTime()
        );

        LocalDateTime noShowAt =
                reservationStart.plusMinutes(NO_SHOW_AFTER_MINUTES);

        if (LocalDateTime.now().isBefore(noShowAt)) {
            throw new IllegalStateException(
                    "Chỉ có thể đánh dấu No-show sau 30 phút kể từ giờ đặt"
            );
        }
    }

    private List<Long> getTableIds(
            Connection c,
            long reservationId,
            long primaryTableId
    ) throws SQLException {

        List<Long> ids = new ArrayList<>();

        String sql = "SELECT table_id "
                + "FROM reservation_tables "
                + "WHERE reservation_id = ? "
                + "ORDER BY table_id";

        try (PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setLong(1, reservationId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ids.add(rs.getLong("table_id"));
                }
            }
        }

        if (ids.isEmpty() && primaryTableId > 0) {
            ids.add(primaryTableId);
        }

        return ids;
    }

    private void lockTablesForCheckin(
            Connection c,
            List<Long> tableIds,
            long reservationId
    ) throws SQLException {

        String placeholders = String.join(
                ",",
                Collections.nCopies(tableIds.size(), "?")
        );

        String tableSql = "SELECT table_id, status, active "
                + "FROM restaurant_tables WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE table_id IN (" + placeholders + ") "
                + "ORDER BY table_id";

        int count = 0;

        try (PreparedStatement ps = c.prepareStatement(tableSql)) {

            for (int i = 0; i < tableIds.size(); i++) {
                ps.setLong(i + 1, tableIds.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    count++;

                    if (!rs.getBoolean("active")) {
                        throw new IllegalStateException(
                                "Có bàn trong nhóm đã ngừng sử dụng"
                        );
                    }

                    if ("OCCUPIED".equals(rs.getString("status"))) {
                        throw new IllegalStateException(
                                "Có bàn trong nhóm đang được sử dụng"
                        );
                    }
                }
            }
        }

        if (count != tableIds.size()) {
            throw new IllegalStateException(
                    "Có bàn trong đặt bàn không còn tồn tại"
            );
        }

        String orderSql = "SELECT COUNT(*) "
                + "FROM orders o WITH (UPDLOCK, HOLDLOCK) "
                + "WHERE o.order_status = 'OPEN' "
                + "AND ("
                + "(o.reservation_id IS NULL AND o.table_id IN (" + placeholders + ")) "
                + "OR "
                + "(o.reservation_id IS NOT NULL AND o.reservation_id <> ? "
                + "AND EXISTS ("
                + "SELECT 1 FROM reservation_tables ort "
                + "WHERE ort.reservation_id = o.reservation_id "
                + "AND ort.table_id IN (" + placeholders + ")"
                + "))"
                + ")";

        try (PreparedStatement ps = c.prepareStatement(orderSql)) {

            int index = 1;

            for (Long tableId : tableIds) {
                ps.setLong(index++, tableId);
            }

            ps.setLong(index++, reservationId);

            for (Long tableId : tableIds) {
                ps.setLong(index++, tableId);
            }

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();

                if (rs.getInt(1) > 0) {
                    throw new IllegalStateException(
                            "Có bàn trong nhóm đang có đơn hàng mở"
                    );
                }
            }
        }
    }

    private Reservation mapReservation(ResultSet rs) throws SQLException {

        Reservation r = new Reservation();

        r.setReservationId(rs.getLong("reservation_id"));
        r.setTableId(rs.getLong("table_id"));
        r.setTableNumber(rs.getString("table_number"));
        r.setCustomerName(rs.getString("customer_name"));
        r.setPhoneNumber(rs.getString("phone_number"));
        r.setReservationDate(rs.getDate("reservation_date").toLocalDate());
        r.setStartTime(rs.getTime("start_time").toLocalTime());
        r.setEndTime(rs.getTime("end_time").toLocalTime());
        r.setPartySize(rs.getInt("party_size"));
        r.setStatus(rs.getString("status"));

        return r;
    }

    private SQLException wrap(Exception e) {
        if (e instanceof SQLException se) {
            return se;
        }

        return new SQLException(e.getMessage(), e);
    }
}