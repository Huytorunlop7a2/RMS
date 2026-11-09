package com.fpt.rms.dao;

import com.fpt.rms.model.RestaurantTable;
import com.fpt.rms.util.DBContext;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.time.LocalDate;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

public class TableDAO {
    public List<RestaurantTable> findAll() throws SQLException {
        String sql = "SELECT " + "table_id," + "table_number," + "capacity," + "status," + "qr_token," + "active "
                + "FROM restaurant_tables " + "ORDER BY table_number";
        List<RestaurantTable> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(map(rs));
            }
        }
        return list;
    }

    public List<RestaurantTable> findActive() throws SQLException {
        String sql = "SELECT " + "table_id," + "table_number," + "capacity," + "status," + "qr_token," + "active "
                + "FROM restaurant_tables " + "WHERE active=1 " + "ORDER BY table_number";
        List<RestaurantTable> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(map(rs));
            }
        }
        return list;
    }

    public RestaurantTable findByToken(String token) throws SQLException {
        if (token == null || token.isBlank()) {
            return null;
        }
        String sql = "SELECT " + "table_id," + "table_number," + "capacity," + "status," + "qr_token," + "active "
                + "FROM restaurant_tables " + "WHERE qr_token=? " + "AND active=1";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, token.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    public RestaurantTable findById(long id) throws SQLException {
        String sql = "SELECT " + "table_id," + "table_number," + "capacity," + "status," + "qr_token," + "active "
                + "FROM restaurant_tables " + "WHERE table_id=?";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    public List<RestaurantTable> findByIds(Connection c, List<Long> ids, boolean lock) throws SQLException {
        if (ids == null || ids.isEmpty()) {
            return new ArrayList<>();
        }
        String placeholders = String.join(",", Collections.nCopies(ids.size(), "?"));
        String hint = lock ? " WITH (UPDLOCK,HOLDLOCK) " : " ";
        String sql = "SELECT " + "table_id," + "table_number," + "capacity," + "status," + "qr_token," + "active "
                + "FROM restaurant_tables" + hint + "WHERE table_id IN (" + placeholders + ") " + "ORDER BY table_id";
        List<RestaurantTable> list = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < ids.size(); i++) {
                ps.setLong(i + 1, ids.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(map(rs));
                }
            }
        }
        return list;
    }

    public void create(String tableNumber, int capacity) throws SQLException {
        if (tableNumber == null || tableNumber.isBlank()) {
            throw new IllegalArgumentException("Số bàn không được để trống");
        }
        if (capacity < 1) {
            throw new IllegalArgumentException("Sức chứa phải lớn hơn 0");
        }
        String normalizedNumber = tableNumber.trim().toUpperCase();
        try (Connection c = DBContext.getConnection()) {
            try (PreparedStatement ps = c
                    .prepareStatement("SELECT 1 " + "FROM restaurant_tables " + "WHERE table_number=?")) {
                ps.setString(1, normalizedNumber);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        throw new IllegalArgumentException("Số bàn đã tồn tại");
                    }
                }
            }
            String sql = "INSERT INTO restaurant_tables(" + "table_number," + "capacity," + "status," + "qr_token,"
                    + "active" + ") " + "VALUES(" + "?,?," + "'AVAILABLE'," + "?,1" + ")";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, normalizedNumber);
                ps.setInt(2, capacity);
                ps.setString(3, newQrToken());
                ps.executeUpdate();
            }
        }
    }

    public void update(long id, int capacity, boolean active) throws SQLException {
        if (capacity < 1) {
            throw new IllegalArgumentException("Sức chứa phải lớn hơn 0");
        }
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                int currentCapacity;
                boolean currentActive;
                String currentStatus;
                String lockSql = "SELECT " + "capacity," + "active," + "status " + "FROM restaurant_tables "
                        + "WITH (UPDLOCK,HOLDLOCK) " + "WHERE table_id=?";
                try (PreparedStatement ps = c.prepareStatement(lockSql)) {
                    ps.setLong(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Bàn không tồn tại");
                        }
                        currentCapacity = rs.getInt("capacity");
                        currentActive = rs.getBoolean("active");
                        currentStatus = rs.getString("status");
                    }
                }
                if (capacity < currentCapacity) {
                    validateCapacityReduction(c, id, capacity);
                }
                if (currentActive && !active) {
                    if ("OCCUPIED".equals(currentStatus)) {
                        throw new IllegalStateException("Không thể ngừng dùng bàn đang có khách");
                    }
                    validateNoActiveReservations(c, id);
                    validateNoOpenOrder(c, id);
                }
                try (PreparedStatement ps = c.prepareStatement(
                        "UPDATE restaurant_tables " + "SET " + "capacity=?," + "active=? " + "WHERE table_id=?")) {
                    ps.setInt(1, capacity);
                    ps.setBoolean(2, active);
                    ps.setLong(3, id);
                    if (ps.executeUpdate() != 1) {
                        throw new IllegalStateException("Không thể cập nhật bàn");
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

    private void validateCapacityReduction(Connection c, long tableId, int newCapacity) throws SQLException {
        String sql = "SELECT " + "r.reservation_id," + "r.customer_name," + "r.reservation_date," + "r.start_time,"
                + "r.party_size," + "SUM(" + "CASE " + "WHEN rt.table_id=? " + "THEN ? " + "ELSE t.capacity " + "END"
                + ") AS new_total_capacity " + "FROM reservations r " + "JOIN reservation_tables selected_rt "
                + "ON selected_rt.reservation_id=" + "r.reservation_id " + "JOIN reservation_tables rt "
                + "ON rt.reservation_id=" + "r.reservation_id " + "JOIN restaurant_tables t "
                + "ON t.table_id=rt.table_id " + "WHERE " + "selected_rt.table_id=? " + "AND r.status IN ("
                + "'CONFIRMED'," + "'CHECKED_IN'" + ") " + "AND r.reservation_date>=? " + "GROUP BY "
                + "r.reservation_id," + "r.customer_name," + "r.reservation_date," + "r.start_time," + "r.party_size";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, tableId);
            ps.setInt(2, newCapacity);
            ps.setLong(3, tableId);
            ps.setDate(4, java.sql.Date.valueOf(LocalDate.now()));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int partySize = rs.getInt("party_size");
                    int newTotalCapacity = rs.getInt("new_total_capacity");
                    if (newTotalCapacity < partySize) {
                        throw new IllegalStateException(
                                "Không thể giảm sức chứa. " + "Reservation #" + rs.getLong("reservation_id") + " của "
                                        + rs.getString("customer_name") + " ngày " + rs.getDate("reservation_date")
                                        + " lúc " + rs.getTime("start_time") + " có " + partySize
                                        + " khách nhưng nhóm bàn sau thay đổi chỉ còn " + newTotalCapacity + " chỗ.");
                    }
                }
            }
        }
    }

    private void validateNoActiveReservations(Connection c, long tableId) throws SQLException {
        String sql = "SELECT TOP 1 " + "r.reservation_id," + "r.reservation_date," + "r.start_time "
                + "FROM reservation_tables rt " + "JOIN reservations r " + "ON r.reservation_id=" + "rt.reservation_id "
                + "WHERE rt.table_id=? " + "AND r.status IN (" + "'CONFIRMED'," + "'CHECKED_IN'" + ") " + "ORDER BY "
                + "r.reservation_date," + "r.start_time";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, tableId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    throw new IllegalStateException("Không thể ngừng sử dụng bàn. " + "Bàn đang thuộc reservation #"
                            + rs.getLong("reservation_id") + " ngày " + rs.getDate("reservation_date") + " lúc "
                            + rs.getTime("start_time") + ".");
                }
            }
        }
    }

    private void validateNoOpenOrder(Connection c, long tableId) throws SQLException {
        String sql = "SELECT TOP 1 " + "o.order_id " + "FROM orders o " + "WHERE o.order_status='OPEN' " + "AND (" + "("
                + "o.reservation_id IS NULL " + "AND o.table_id=?" + ") " + "OR " + "("
                + "o.reservation_id IS NOT NULL " + "AND EXISTS(" + "SELECT 1 " + "FROM reservation_tables rt "
                + "WHERE " + "rt.reservation_id=o.reservation_id " + "AND rt.table_id=?" + ")" + ")" + ")";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, tableId);
            ps.setLong(2, tableId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    throw new IllegalStateException(
                            "Không thể ngừng sử dụng bàn vì đang có đơn hàng mở #" + rs.getLong("order_id"));
                }
            }
        }
    }

    public void regenerateToken(long id) throws SQLException {
        String sql = "UPDATE restaurant_tables " + "SET qr_token=? " + "WHERE table_id=?";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, newQrToken());
            ps.setLong(2, id);
            if (ps.executeUpdate() != 1) {
                throw new IllegalArgumentException("Bàn không tồn tại");
            }
        }
    }

    public boolean releaseSingleReservationTableIfMember(long tableId) throws SQLException {
        if (tableId <= 0) {
            throw new IllegalArgumentException("Bàn không hợp lệ");
        }

        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                lockOccupiedTable(c, tableId);

                ReservationAssignment reservation = findCheckedInReservationByTable(c, tableId);
                if (reservation == null) {
                    c.commit();
                    return false;
                }

                List<ReservationTableMember> members = findReservationTableMembers(
                        c,
                        reservation.reservationId());

                if (members.isEmpty()) {
                    throw new IllegalStateException("Reservation không còn bàn được gán");
                }

                ReservationTableMember selected = members.stream()
                        .filter(member -> member.tableId() == tableId)
                        .findFirst()
                        .orElseThrow(() -> new IllegalStateException(
                                "Bàn không còn thuộc Reservation đang sử dụng"));

                if (members.size() == 1) {
                    completeCheckedInReservation(c, reservation.reservationId(), members);
                    c.commit();
                    return true;
                }

                int remainingCapacity = members.stream()
                        .filter(member -> member.tableId() != tableId)
                        .mapToInt(ReservationTableMember::capacity)
                        .sum();

                if (remainingCapacity < reservation.partySize()) {
                    throw new IllegalStateException(
                            "Không thể trả riêng bàn " + selected.tableNumber()
                                    + " vì nhóm còn lại chỉ có " + remainingCapacity
                                    + " chỗ, không đủ cho " + reservation.partySize()
                                    + " khách. Vui lòng trả cả nhóm hoặc giữ lại bàn này.");
                }

                if (reservation.primaryTableId() == tableId) {
                    long newPrimaryTableId = members.stream()
                            .filter(member -> member.tableId() != tableId)
                            .mapToLong(ReservationTableMember::tableId)
                            .findFirst()
                            .orElseThrow(() -> new IllegalStateException(
                                    "Không tìm được bàn chính thay thế"));

                    try (PreparedStatement ps = c.prepareStatement(
                            "UPDATE reservations SET table_id=? "
                                    + "WHERE reservation_id=? AND status='CHECKED_IN'")) {
                        ps.setLong(1, newPrimaryTableId);
                        ps.setLong(2, reservation.reservationId());
                        if (ps.executeUpdate() != 1) {
                            throw new IllegalStateException("Reservation đã thay đổi trạng thái");
                        }
                    }

                    try (PreparedStatement ps = c.prepareStatement(
                            "UPDATE orders SET table_id=? "
                                    + "WHERE reservation_id=? AND order_status='OPEN'")) {
                        ps.setLong(1, newPrimaryTableId);
                        ps.setLong(2, reservation.reservationId());
                        ps.executeUpdate();
                    }
                }

                try (PreparedStatement ps = c.prepareStatement(
                        "DELETE FROM reservation_tables WHERE reservation_id=? AND table_id=?")) {
                    ps.setLong(1, reservation.reservationId());
                    ps.setLong(2, tableId);
                    if (ps.executeUpdate() != 1) {
                        throw new IllegalStateException("Không thể tách bàn khỏi Reservation");
                    }
                }

                releasePhysicalTable(c, tableId);
                c.commit();
                return true;

            } catch (Exception e) {
                c.rollback();
                throw wrap(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    public boolean releaseWholeReservationGroupIfMember(long tableId) throws SQLException {
        if (tableId <= 0) {
            throw new IllegalArgumentException("Bàn không hợp lệ");
        }

        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                lockOccupiedTable(c, tableId);

                ReservationAssignment reservation = findCheckedInReservationByTable(c, tableId);
                if (reservation == null) {
                    c.commit();
                    return false;
                }

                List<ReservationTableMember> members = findReservationTableMembers(
                        c,
                        reservation.reservationId());

                if (members.isEmpty()) {
                    throw new IllegalStateException("Reservation không còn bàn được gán");
                }

                completeCheckedInReservation(c, reservation.reservationId(), members);
                c.commit();
                return true;

            } catch (Exception e) {
                c.rollback();
                throw wrap(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    private void lockOccupiedTable(Connection c, long tableId) throws SQLException {
        String sql = "SELECT table_id, status FROM restaurant_tables WITH (UPDLOCK,HOLDLOCK) WHERE table_id=?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, tableId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Bàn không tồn tại");
                }
                if (!"OCCUPIED".equals(rs.getString("status"))) {
                    throw new IllegalStateException("Bàn không ở trạng thái đang sử dụng");
                }
            }
        }
    }

    private ReservationAssignment findCheckedInReservationByTable(
            Connection c,
            long tableId) throws SQLException {

        String sql = "SELECT TOP 1 r.reservation_id, r.table_id, r.party_size "
                + "FROM reservations r WITH (UPDLOCK,HOLDLOCK) "
                + "JOIN reservation_tables rt ON rt.reservation_id=r.reservation_id "
                + "WHERE rt.table_id=? AND r.status='CHECKED_IN' "
                + "ORDER BY r.reservation_id DESC";

        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, tableId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return new ReservationAssignment(
                        rs.getLong("reservation_id"),
                        rs.getLong("table_id"),
                        rs.getInt("party_size"));
            }
        }
    }

    private List<ReservationTableMember> findReservationTableMembers(
            Connection c,
            long reservationId) throws SQLException {

        List<ReservationTableMember> members = new ArrayList<>();
        String sql = "SELECT t.table_id, t.table_number, t.capacity "
                + "FROM restaurant_tables t WITH (UPDLOCK,HOLDLOCK) "
                + "JOIN reservation_tables rt ON rt.table_id=t.table_id "
                + "WHERE rt.reservation_id=? ORDER BY t.table_id";

        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, reservationId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    members.add(new ReservationTableMember(
                            rs.getLong("table_id"),
                            rs.getString("table_number"),
                            rs.getInt("capacity")));
                }
            }
        }

        return members;
    }

    private void completeCheckedInReservation(
            Connection c,
            long reservationId,
            List<ReservationTableMember> members) throws SQLException {

        validateReservationNoOpenOrder(c, reservationId);

        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE reservations SET status='COMPLETED' "
                        + "WHERE reservation_id=? AND status='CHECKED_IN'")) {
            ps.setLong(1, reservationId);
            if (ps.executeUpdate() != 1) {
                throw new IllegalStateException("Reservation đã thay đổi trạng thái");
            }
        }

        String placeholders = String.join(",", Collections.nCopies(members.size(), "?"));
        String sql = "UPDATE restaurant_tables SET status='AVAILABLE' "
                + "WHERE table_id IN (" + placeholders + ") AND status='OCCUPIED'";

        try (PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < members.size(); i++) {
                ps.setLong(i + 1, members.get(i).tableId());
            }
            int updated = ps.executeUpdate();
            if (updated != members.size()) {
                throw new IllegalStateException("Không thể trả toàn bộ bàn của Reservation");
            }
        }
    }

    private void releasePhysicalTable(Connection c, long tableId) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE restaurant_tables SET status='AVAILABLE' "
                        + "WHERE table_id=? AND status='OCCUPIED'")) {
            ps.setLong(1, tableId);
            if (ps.executeUpdate() != 1) {
                throw new IllegalStateException("Không thể cập nhật trạng thái bàn vừa chọn");
            }
        }
    }

    public void releaseTable(long tableId) throws SQLException {
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                try (PreparedStatement ps = c.prepareStatement("SELECT table_id " + "FROM restaurant_tables "
                        + "WITH (UPDLOCK,HOLDLOCK) " + "WHERE table_id=?")) {
                    ps.setLong(1, tableId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Bàn không tồn tại");
                        }
                    }
                }
                Long reservationId = null;
                String findReservation = "SELECT TOP 1 " + "r.reservation_id " + "FROM reservations r "
                        + "WITH (UPDLOCK,HOLDLOCK) " + "JOIN reservation_tables rt " + "ON rt.reservation_id="
                        + "r.reservation_id " + "WHERE rt.table_id=? " + "AND r.status='CHECKED_IN' "
                        + "ORDER BY r.reservation_id DESC";
                try (PreparedStatement ps = c.prepareStatement(findReservation)) {
                    ps.setLong(1, tableId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            reservationId = rs.getLong("reservation_id");
                        }
                    }
                }
                if (reservationId != null) {
                    validateReservationNoOpenOrder(c, reservationId);
                    lockReservationTables(c, reservationId);
                    try (PreparedStatement ps = c.prepareStatement("UPDATE reservations " + "SET status='COMPLETED' "
                            + "WHERE " + "reservation_id=? " + "AND status='CHECKED_IN'")) {
                        ps.setLong(1, reservationId);
                        if (ps.executeUpdate() != 1) {
                            throw new IllegalStateException("Reservation đã thay đổi trạng thái");
                        }
                    }
                    try (PreparedStatement ps = c.prepareStatement("UPDATE t " + "SET t.status='AVAILABLE' "
                            + "FROM restaurant_tables t " + "JOIN reservation_tables rt " + "ON rt.table_id=t.table_id "
                            + "WHERE rt.reservation_id=?")) {
                        ps.setLong(1, reservationId);
                        ps.executeUpdate();
                    }
                } else {
                    validateNoOpenOrder(c, tableId);
                    try (PreparedStatement ps = c.prepareStatement(
                            "UPDATE restaurant_tables " + "SET status='AVAILABLE' " + "WHERE table_id=?")) {
                        ps.setLong(1, tableId);
                        if (ps.executeUpdate() != 1) {
                            throw new IllegalStateException("Không thể trả bàn");
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

    private void validateReservationNoOpenOrder(Connection c, long reservationId) throws SQLException {
        String sql = "SELECT TOP 1 order_id " + "FROM orders WITH (UPDLOCK,HOLDLOCK) " + "WHERE " + "reservation_id=? "
                + "AND order_status='OPEN'";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, reservationId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    throw new IllegalStateException(
                            "Nhóm bàn vẫn còn đơn hàng chưa thanh toán #" + rs.getLong("order_id"));
                }
            }
        }
    }

    private void lockReservationTables(Connection c, long reservationId) throws SQLException {
        String sql = "SELECT t.table_id " + "FROM restaurant_tables t " + "WITH (UPDLOCK,HOLDLOCK) "
                + "JOIN reservation_tables rt " + "ON rt.table_id=t.table_id " + "WHERE rt.reservation_id=? "
                + "ORDER BY t.table_id";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, reservationId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                }
            }
        }
    }

    private RestaurantTable map(ResultSet rs) throws SQLException {
        RestaurantTable table = new RestaurantTable();
        table.setTableId(rs.getLong("table_id"));
        table.setTableNumber(rs.getString("table_number"));
        table.setCapacity(rs.getInt("capacity"));
        table.setStatus(rs.getString("status"));
        table.setQrToken(rs.getString("qr_token"));
        table.setActive(rs.getBoolean("active"));
        return table;
    }

    private String newQrToken() {
        return UUID.randomUUID().toString().replace("-", "");
    }

    private SQLException wrap(Exception e) {
        if (e instanceof SQLException se) {
            return se;
        }
        return new SQLException(e.getMessage(), e);
    }

    private record ReservationAssignment(long reservationId, long primaryTableId, int partySize) {
    }

    private record ReservationTableMember(long tableId, String tableNumber, int capacity) {
    }
}