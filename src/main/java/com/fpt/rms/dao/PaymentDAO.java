package com.fpt.rms.dao;

import com.fpt.rms.model.Payment;
import com.fpt.rms.util.DBContext;

import java.math.BigDecimal;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

import java.util.ArrayList;
import java.util.List;

public class PaymentDAO {

        private static final String TABLE_LABEL_APPLY = " OUTER APPLY (" +
                        "SELECT STRING_AGG(tb.table_number,' + ') " +
                        "WITHIN GROUP (ORDER BY tb.table_number) AS table_numbers " +
                        "FROM reservation_tables rt " +
                        "JOIN restaurant_tables tb " +
                        "ON tb.table_id=rt.table_id " +
                        "WHERE rt.reservation_id=o.reservation_id" +
                        ") lbl ";

        public List<Payment> findPendingCash()
                        throws SQLException {

                String sql = "SELECT " +
                                "p.payment_id," +
                                "p.order_id," +

                                "COALESCE(" +
                                "lbl.table_numbers," +
                                "t.table_number" +
                                ") AS table_number," +

                                "p.amount," +
                                "p.payment_method," +
                                "p.payment_status," +
                                "p.created_at," +
                                "p.paid_at " +

                                "FROM payments p " +

                                "JOIN orders o " +
                                "ON o.order_id=p.order_id " +

                                "JOIN restaurant_tables t " +
                                "ON t.table_id=o.table_id " +

                                TABLE_LABEL_APPLY +

                                "WHERE " +
                                "p.payment_method='CASH' " +
                                "AND p.payment_status='PENDING' " +
                                "AND o.order_status='OPEN' " +

                                "ORDER BY p.created_at";

                List<Payment> list = new ArrayList<>();

                try (
                                Connection c = DBContext.getConnection();

                                PreparedStatement ps = c.prepareStatement(sql);

                                ResultSet rs = ps.executeQuery()) {

                        while (rs.next()) {

                                list.add(
                                                map(
                                                                rs));
                        }
                }

                return list;
        }

        public Payment findById(
                        long paymentId) throws SQLException {

                String sql = "SELECT " +
                                "p.payment_id," +
                                "p.order_id," +

                                "COALESCE(" +
                                "lbl.table_numbers," +
                                "t.table_number" +
                                ") AS table_number," +

                                "p.amount," +
                                "p.payment_method," +
                                "p.payment_status," +
                                "p.created_at," +
                                "p.paid_at " +

                                "FROM payments p " +

                                "JOIN orders o " +
                                "ON o.order_id=p.order_id " +

                                "JOIN restaurant_tables t " +
                                "ON t.table_id=o.table_id " +

                                TABLE_LABEL_APPLY +

                                "WHERE p.payment_id=?";

                try (
                                Connection c = DBContext.getConnection();

                                PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        paymentId);

                        try (
                                        ResultSet rs = ps.executeQuery()) {

                                return rs.next()
                                                ? map(rs)
                                                : null;
                        }
                }
        }

        public Payment findPendingByOrder(
                        long orderId) throws SQLException {

                String sql = "SELECT TOP 1 " +
                                "p.payment_id," +
                                "p.order_id," +

                                "COALESCE(" +
                                "lbl.table_numbers," +
                                "t.table_number" +
                                ") AS table_number," +

                                "p.amount," +
                                "p.payment_method," +
                                "p.payment_status," +
                                "p.created_at," +
                                "p.paid_at " +

                                "FROM payments p " +

                                "JOIN orders o " +
                                "ON o.order_id=p.order_id " +

                                "JOIN restaurant_tables t " +
                                "ON t.table_id=o.table_id " +

                                TABLE_LABEL_APPLY +

                                "WHERE " +
                                "p.order_id=? " +
                                "AND p.payment_status='PENDING' " +

                                "ORDER BY p.payment_id DESC";

                try (
                                Connection c = DBContext.getConnection();

                                PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        orderId);

                        try (
                                        ResultSet rs = ps.executeQuery()) {

                                return rs.next()
                                                ? map(rs)
                                                : null;
                        }
                }
        }

        public boolean belongsToToken(
                        long paymentId,
                        String token) throws SQLException {

                if (token == null
                                ||
                                token.isBlank()) {

                        return false;
                }

                String sql = "SELECT COUNT(*) " +

                                "FROM payments p " +

                                "JOIN orders o " +
                                "ON o.order_id=p.order_id " +

                                "WHERE p.payment_id=? " +

                                "AND (" +

                                "(" +

                                "o.reservation_id IS NULL " +

                                "AND EXISTS(" +

                                "SELECT 1 " +

                                "FROM restaurant_tables t " +

                                "WHERE " +
                                "t.table_id=o.table_id " +
                                "AND t.qr_token=? " +

                                ")" +

                                ") " +

                                "OR " +

                                "(" +

                                "o.reservation_id IS NOT NULL " +

                                "AND EXISTS(" +

                                "SELECT 1 " +

                                "FROM reservation_tables rt " +

                                "JOIN restaurant_tables t " +
                                "ON t.table_id=rt.table_id " +

                                "WHERE " +
                                "rt.reservation_id=o.reservation_id " +
                                "AND t.qr_token=? " +

                                ")" +

                                ")" +

                                ")";

                try (
                                Connection c = DBContext.getConnection();

                                PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        paymentId);

                        ps.setString(
                                        2,
                                        token.trim());

                        ps.setString(
                                        3,
                                        token.trim());

                        try (
                                        ResultSet rs = ps.executeQuery()) {

                                rs.next();

                                return rs.getInt(1) > 0;
                        }
                }
        }

        public long createPending(
                        long orderId,
                        String method) throws SQLException {

                if (!"CASH".equals(method)
                                &&
                                !"ONLINE".equals(method)) {

                        throw new IllegalArgumentException(
                                        "Phương thức thanh toán không hợp lệ");
                }

                try (
                                Connection c = DBContext.getConnection()) {

                        c.setAutoCommit(
                                        false);

                        try {

                                ensurePayable(
                                                c,
                                                orderId);

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                "SELECT TOP 1 " +
                                                                                "payment_id," +
                                                                                "payment_method " +

                                                                                "FROM payments " +
                                                                                "WITH (UPDLOCK,HOLDLOCK) " +

                                                                                "WHERE " +
                                                                                "order_id=? " +
                                                                                "AND payment_status='PENDING' " +

                                                                                "ORDER BY payment_id DESC")) {

                                        ps.setLong(
                                                        1,
                                                        orderId);

                                        try (
                                                        ResultSet rs = ps.executeQuery()) {

                                                if (rs.next()) {

                                                        long paymentId = rs.getLong(
                                                                        "payment_id");

                                                        String existingMethod = rs.getString(
                                                                        "payment_method");

                                                        if (!method.equals(
                                                                        existingMethod)) {

                                                                throw new IllegalStateException(
                                                                                "Đơn hàng đã có yêu cầu thanh toán "
                                                                                                + existingMethod
                                                                                                + " đang chờ xử lý");
                                                        }

                                                        c.commit();

                                                        return paymentId;
                                                }
                                        }
                                }

                                BigDecimal total = orderTotal(
                                                c,
                                                orderId);

                                if (total == null
                                                ||
                                                total.signum() <= 0) {

                                        throw new IllegalStateException(
                                                        "Tổng tiền thanh toán không hợp lệ");
                                }

                                String insertSql = "INSERT INTO payments(" +
                                                "order_id," +
                                                "amount," +
                                                "payment_method," +
                                                "payment_status" +
                                                ") " +

                                                "OUTPUT INSERTED.payment_id " +

                                                "VALUES(?,?,?,'PENDING')";

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                insertSql)) {

                                        ps.setLong(
                                                        1,
                                                        orderId);

                                        ps.setBigDecimal(
                                                        2,
                                                        total);

                                        ps.setString(
                                                        3,
                                                        method);

                                        try (
                                                        ResultSet rs = ps.executeQuery()) {

                                                if (!rs.next()) {

                                                        throw new SQLException(
                                                                        "Không thể tạo thanh toán");
                                                }

                                                long paymentId = rs.getLong(1);

                                                c.commit();

                                                return paymentId;
                                        }
                                }

                        } catch (Exception e) {

                                c.rollback();

                                throw wrap(
                                                e);

                        } finally {

                                c.setAutoCommit(
                                                true);
                        }
                }
        }

        public void confirmCash(
                        long paymentId) throws SQLException {

                complete(
                                paymentId,
                                "CASH");
        }

        public void confirmOnline(
                        long paymentId) throws SQLException {

                complete(
                                paymentId,
                                "ONLINE");
        }

        public void failOnline(
                        long paymentId) throws SQLException {

                try (
                                Connection c = DBContext.getConnection()) {

                        c.setAutoCommit(
                                        false);

                        try {

                                long orderId;

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                "SELECT order_id " +
                                                                                "FROM payments " +
                                                                                "WHERE payment_id=?")) {

                                        ps.setLong(
                                                        1,
                                                        paymentId);

                                        try (
                                                        ResultSet rs = ps.executeQuery()) {

                                                if (!rs.next()) {

                                                        throw new IllegalArgumentException(
                                                                        "Thanh toán không tồn tại");
                                                }

                                                orderId = rs.getLong(
                                                                "order_id");
                                        }
                                }

                                lockOpenOrder(
                                                c,
                                                orderId);

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                "UPDATE payments " +
                                                                                "SET payment_status='FAILED' " +
                                                                                "WHERE " +
                                                                                "payment_id=? " +
                                                                                "AND order_id=? " +
                                                                                "AND payment_method='ONLINE' " +
                                                                                "AND payment_status='PENDING'")) {

                                        ps.setLong(
                                                        1,
                                                        paymentId);

                                        ps.setLong(
                                                        2,
                                                        orderId);

                                        if (ps.executeUpdate() != 1) {

                                                throw new IllegalStateException(
                                                                "Giao dịch không còn ở trạng thái chờ");
                                        }
                                }

                                c.commit();

                        } catch (Exception e) {

                                c.rollback();

                                throw wrap(
                                                e);

                        } finally {

                                c.setAutoCommit(
                                                true);
                        }
                }
        }

        private void complete(
                        long paymentId,
                        String method) throws SQLException {

                try (
                                Connection c = DBContext.getConnection()) {

                        c.setAutoCommit(
                                        false);

                        try {

                                long orderId;

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                "SELECT order_id " +
                                                                                "FROM payments " +
                                                                                "WHERE payment_id=?")) {

                                        ps.setLong(
                                                        1,
                                                        paymentId);

                                        try (
                                                        ResultSet rs = ps.executeQuery()) {

                                                if (!rs.next()) {

                                                        throw new IllegalArgumentException(
                                                                        "Thanh toán không tồn tại");
                                                }

                                                orderId = rs.getLong(
                                                                "order_id");
                                        }
                                }

                                ensurePayable(
                                                c,
                                                orderId);

                                String paymentStatus;
                                String paymentMethod;
                                BigDecimal paymentAmount;

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                "SELECT " +
                                                                                "payment_status," +
                                                                                "payment_method," +
                                                                                "amount " +

                                                                                "FROM payments " +
                                                                                "WITH (UPDLOCK,HOLDLOCK) " +

                                                                                "WHERE " +
                                                                                "payment_id=? " +
                                                                                "AND order_id=?")) {

                                        ps.setLong(
                                                        1,
                                                        paymentId);

                                        ps.setLong(
                                                        2,
                                                        orderId);

                                        try (
                                                        ResultSet rs = ps.executeQuery()) {

                                                if (!rs.next()) {

                                                        throw new IllegalArgumentException(
                                                                        "Thanh toán không tồn tại");
                                                }

                                                paymentStatus = rs.getString(
                                                                "payment_status");

                                                paymentMethod = rs.getString(
                                                                "payment_method");

                                                paymentAmount = rs.getBigDecimal(
                                                                "amount");
                                        }
                                }

                                if (!method.equals(
                                                paymentMethod)) {

                                        throw new IllegalStateException(
                                                        "Sai phương thức thanh toán");
                                }

                                if (!"PENDING".equals(
                                                paymentStatus)) {

                                        throw new IllegalStateException(
                                                        "Thanh toán đã được xử lý");
                                }

                                BigDecimal currentTotal = orderTotal(
                                                c,
                                                orderId);

                                if (paymentAmount == null
                                                ||
                                                currentTotal.compareTo(
                                                                paymentAmount) != 0) {

                                        throw new IllegalStateException(
                                                        "Tổng tiền đơn hàng đã thay đổi. " +
                                                                        "Vui lòng tạo lại yêu cầu thanh toán");
                                }

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                "UPDATE payments " +
                                                                                "SET " +
                                                                                "payment_status='PAID'," +
                                                                                "paid_at=SYSDATETIME() " +
                                                                                "WHERE " +
                                                                                "payment_id=? " +
                                                                                "AND payment_status='PENDING'")) {

                                        ps.setLong(
                                                        1,
                                                        paymentId);

                                        if (ps.executeUpdate() != 1) {

                                                throw new IllegalStateException(
                                                                "Thanh toán đã được xử lý");
                                        }
                                }

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                "UPDATE orders " +
                                                                                "SET " +
                                                                                "order_status='CLOSED'," +
                                                                                "closed_at=SYSDATETIME() " +
                                                                                "WHERE " +
                                                                                "order_id=? " +
                                                                                "AND order_status='OPEN'")) {

                                        ps.setLong(
                                                        1,
                                                        orderId);

                                        if (ps.executeUpdate() != 1) {

                                                throw new IllegalStateException(
                                                                "Đơn hàng đã đóng");
                                        }
                                }

                                c.commit();

                        } catch (Exception e) {

                                c.rollback();

                                throw wrap(
                                                e);

                        } finally {

                                c.setAutoCommit(
                                                true);
                        }
                }
        }

        private void ensurePayable(
                        Connection c,
                        long orderId) throws SQLException {

                lockOpenOrder(
                                c,
                                orderId);

                String sql = "SELECT " +

                                "SUM(" +
                                "CASE " +
                                "WHEN status<>'CANCELLED' " +
                                "THEN 1 ELSE 0 END" +
                                ") AS active_count," +

                                "SUM(" +
                                "CASE " +
                                "WHEN status NOT IN (" +
                                "'SERVED'," +
                                "'CANCELLED'" +
                                ") " +
                                "THEN 1 ELSE 0 END" +
                                ") AS waiting_count " +

                                "FROM order_details " +

                                "WHERE order_id=?";

                try (
                                PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        orderId);

                        try (
                                        ResultSet rs = ps.executeQuery()) {

                                rs.next();

                                if (rs.getInt(
                                                "active_count") <= 0) {

                                        throw new IllegalStateException(
                                                        "Đơn hàng chưa có món để thanh toán");
                                }

                                if (rs.getInt(
                                                "waiting_count") > 0) {

                                        throw new IllegalStateException(
                                                        "Vẫn còn món chưa được phục vụ");
                                }
                        }
                }
        }

        private void lockOpenOrder(
                        Connection c,
                        long orderId) throws SQLException {

                try (
                                PreparedStatement ps = c.prepareStatement(
                                                "SELECT order_status " +
                                                                "FROM orders " +
                                                                "WITH (UPDLOCK,HOLDLOCK) " +
                                                                "WHERE order_id=?")) {

                        ps.setLong(
                                        1,
                                        orderId);

                        try (
                                        ResultSet rs = ps.executeQuery()) {

                                if (!rs.next()) {

                                        throw new IllegalArgumentException(
                                                        "Đơn hàng không tồn tại");
                                }

                                if (!"OPEN".equals(
                                                rs.getString(
                                                                "order_status"))) {

                                        throw new IllegalStateException(
                                                        "Đơn hàng đã đóng");
                                }
                        }
                }
        }

        private BigDecimal orderTotal(
                        Connection c,
                        long orderId) throws SQLException {

                String sql = "SELECT COALESCE(" +
                                "SUM(quantity*unit_price),0" +
                                ") " +

                                "FROM order_details " +

                                "WHERE " +
                                "order_id=? " +
                                "AND status<>'CANCELLED'";

                try (
                                PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        orderId);

                        try (
                                        ResultSet rs = ps.executeQuery()) {

                                rs.next();

                                return rs.getBigDecimal(
                                                1);
                        }
                }
        }

        private Payment map(
                        ResultSet rs) throws SQLException {

                Payment p = new Payment();

                p.setPaymentId(
                                rs.getLong(
                                                "payment_id"));

                p.setOrderId(
                                rs.getLong(
                                                "order_id"));

                p.setTableNumber(
                                rs.getString(
                                                "table_number"));

                p.setAmount(
                                rs.getBigDecimal(
                                                "amount"));

                p.setPaymentMethod(
                                rs.getString(
                                                "payment_method"));

                p.setPaymentStatus(
                                rs.getString(
                                                "payment_status"));

                Timestamp created = rs.getTimestamp(
                                "created_at");

                Timestamp paid = rs.getTimestamp(
                                "paid_at");

                p.setCreatedAt(
                                created == null
                                                ? null
                                                : created.toLocalDateTime());

                p.setPaidAt(
                                paid == null
                                                ? null
                                                : paid.toLocalDateTime());

                return p;
        }

        private SQLException wrap(
                        Exception e) {

                if (e instanceof SQLException se) {

                        return se;
                }

                return new SQLException(
                                e.getMessage(),
                                e);
        }
}