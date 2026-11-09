package com.fpt.rms.dao;

import com.fpt.rms.model.OrderDetail;
import com.fpt.rms.model.RestaurantOrder;
import com.fpt.rms.util.DBContext;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

public class OrderDAO {
    private static final String TABLE_LABEL_APPLY = " OUTER APPLY (" + " SELECT STRING_AGG(tb.table_number,' + ') "
            + " WITHIN GROUP (ORDER BY tb.table_number) AS table_numbers " + " FROM reservation_tables rt "
            + " JOIN restaurant_tables tb " + "   ON tb.table_id=rt.table_id "
            + " WHERE rt.reservation_id=o.reservation_id " + " ) lbl ";

    public RestaurantOrder findOpenOrderByToken(String token) throws SQLException {
        try (Connection c = DBContext.getConnection()) {
            ServiceContext ctx = resolveContext(c, token, false);
            if (ctx == null) {
                return null;
            }
            String sql;
            if (ctx.reservationId() != null) {
                sql = "SELECT " + "o.order_id, " + "o.table_id, "
                        + "COALESCE(lbl.table_numbers,t.table_number) AS table_number, " + "o.order_status, "
                        + "o.created_at " + "FROM orders o " + "JOIN restaurant_tables t " + "ON t.table_id=o.table_id "
                        + TABLE_LABEL_APPLY + "WHERE o.reservation_id=? " + "AND o.order_status='OPEN'";
            } else {
                sql = "SELECT " + "o.order_id, " + "o.table_id, " + "t.table_number, " + "o.order_status, "
                        + "o.created_at " + "FROM orders o " + "JOIN restaurant_tables t " + "ON t.table_id=o.table_id "
                        + "WHERE o.table_id=? " + "AND o.reservation_id IS NULL " + "AND o.order_status='OPEN'";
            }
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setLong(1, ctx.reservationId() != null ? ctx.reservationId() : ctx.tableId());
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        return null;
                    }
                    RestaurantOrder order = mapOrder(rs);
                    order.setDetails(findDetails(c, order.getOrderId()));
                    return order;
                }
            }
        }
    }

    public RestaurantOrder findOpenOrderById(long orderId) throws SQLException {
        String sql = "SELECT " + "o.order_id, " + "o.table_id, "
                + "COALESCE(lbl.table_numbers,t.table_number) AS table_number, " + "o.order_status, " + "o.created_at "
                + "FROM orders o " + "JOIN restaurant_tables t " + "ON t.table_id=o.table_id " + TABLE_LABEL_APPLY
                + "WHERE o.order_id=? " + "AND o.order_status='OPEN'";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                RestaurantOrder order = mapOrder(rs);
                order.setDetails(findDetails(c, orderId));
                return order;
            }
        }
    }

    public List<RestaurantOrder> findPendingKitchenOrders() throws SQLException {
        String sql = "SELECT " + "o.order_id, " + "o.table_id, " + "COALESCE(" + "lbl.table_numbers," + "t.table_number"
                + ") AS table_number, " + "o.order_status, " + "o.created_at, " + "d.order_detail_id, "
                + "d.menu_item_id, " + "m.name AS menu_item_name, " + "cat.name AS category_name, " + "d.quantity, "
                + "d.unit_price, " + "d.note, "
                + "d.status, " + "d.created_at AS detail_created_at " + "FROM orders o " + "JOIN restaurant_tables t "
                + "ON t.table_id=o.table_id " + TABLE_LABEL_APPLY + "JOIN order_details d "
                + "ON d.order_id=o.order_id " + "JOIN menu_items m " + "ON m.menu_item_id=d.menu_item_id "
                + "JOIN menu_categories cat "
                + "ON cat.category_id=m.category_id " + "WHERE "
                + "o.order_status='OPEN' " + "AND d.status IN ('PENDING','READY') "
                + "AND EXISTS ("
                + "SELECT 1 FROM order_details pending "
                + "WHERE pending.order_id=o.order_id "
                + "AND pending.status='PENDING' "
                + ") " + "ORDER BY " + "o.created_at, "
                + "d.created_at";
        Map<Long, RestaurantOrder> map = new LinkedHashMap<>();
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                long orderId = rs.getLong("order_id");
                RestaurantOrder order = map.get(orderId);
                if (order == null) {
                    order = new RestaurantOrder();
                    order.setOrderId(orderId);
                    order.setTableId(rs.getLong("table_id"));
                    order.setTableNumber(rs.getString("table_number"));
                    order.setOrderStatus(rs.getString("order_status"));
                    order.setCreatedAt(toLocalDateTime(rs.getTimestamp("created_at")));
                    map.put(orderId, order);
                }
                OrderDetail detail = new OrderDetail();
                detail.setOrderDetailId(rs.getLong("order_detail_id"));
                detail.setOrderId(orderId);
                detail.setTableNumber(order.getTableNumber());
                detail.setMenuItemId(rs.getLong("menu_item_id"));
                detail.setMenuItemName(rs.getString("menu_item_name"));
                detail.setCategoryName(rs.getString("category_name"));
                detail.setQuantity(rs.getInt("quantity"));
                detail.setUnitPrice(rs.getBigDecimal("unit_price"));
                detail.setNote(rs.getString("note"));
                detail.setStatus(rs.getString("status"));
                detail.setCreatedAt(toLocalDateTime(rs.getTimestamp("detail_created_at")));
                order.getDetails().add(detail);
            }
        }
        return new ArrayList<>(map.values());
    }

    public List<OrderDetail> findReadyDetails() throws SQLException {
        String sql = "SELECT " + "d.order_detail_id, " + "d.order_id, " + "COALESCE(" + "lbl.table_numbers,"
                + "t.table_number" + ") AS table_number, " + "d.menu_item_id, " + "m.name AS menu_item_name, "
                + "d.quantity, " + "d.unit_price, " + "d.note, " + "d.status, " + "d.created_at "
                + "FROM order_details d " + "JOIN orders o " + "ON o.order_id=d.order_id " + "JOIN restaurant_tables t "
                + "ON t.table_id=o.table_id " + TABLE_LABEL_APPLY + "JOIN menu_items m "
                + "ON m.menu_item_id=d.menu_item_id " + "WHERE " + "o.order_status='OPEN' " + "AND d.status='READY' "
                + "ORDER BY d.created_at";
        List<OrderDetail> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapDetail(rs));
            }
        }
        return list;
    }

    public long submitOrder(String token, String[] itemIds, String[] quantities, String[] notes) throws SQLException {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Thiếu mã QR của bàn");
        }
        if (itemIds == null || quantities == null || itemIds.length == 0 || itemIds.length != quantities.length) {
            throw new IllegalArgumentException("Vui lòng chọn ít nhất một món");
        }
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                ServiceContext ctx = resolveContext(c, token, true);
                if (ctx == null) {
                    throw new IllegalArgumentException("Mã QR bàn không hợp lệ hoặc bàn đã ngừng sử dụng");
                }
                List<RequestedItem> requestedItems = validateRequestedItems(c, itemIds, quantities, notes);
                Long orderId = findOpenOrderId(c, ctx);
                if (orderId == null) {
                    String sql = "INSERT INTO orders(" + "table_id," + "reservation_id," + "order_status" + ") "
                            + "OUTPUT INSERTED.order_id " + "VALUES(?,?,'OPEN')";
                    try (PreparedStatement ps = c.prepareStatement(sql)) {
                        ps.setLong(1, ctx.anchorTableId());
                        if (ctx.reservationId() == null) {
                            ps.setNull(2, Types.BIGINT);
                        } else {
                            ps.setLong(2, ctx.reservationId());
                        }
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) {
                                throw new SQLException("Không thể tạo đơn hàng mới");
                            }
                            orderId = rs.getLong(1);
                        }
                    }
                } else {
                    assertOrderModifiable(c, orderId);
                }
                List<PreparedRequestedItem> preparedItems = prepareAndReserveIngredients(c, requestedItems);
                markServiceTablesOccupied(c, ctx);
                for (PreparedRequestedItem prepared : preparedItems) {
                    RequestedItem item = prepared.item();
                    Long pendingDetailId = findSamePendingDetail(c, orderId, item);
                    long detailId;
                    if (pendingDetailId != null) {
                        String update = "UPDATE order_details " + "SET quantity=quantity+? "
                                + "WHERE order_detail_id=? " + "AND status='PENDING'";
                        try (PreparedStatement ps = c.prepareStatement(update)) {
                            ps.setInt(1, item.quantity());
                            ps.setLong(2, pendingDetailId);
                            if (ps.executeUpdate() != 1) {
                                throw new IllegalStateException("Món đang chờ đã thay đổi, vui lòng thử lại");
                            }
                        }
                        detailId = pendingDetailId;
                    } else {
                        String insert = "INSERT INTO order_details(" + "order_id," + "menu_item_id," + "quantity,"
                                + "unit_price," + "note," + "status" + ") " + "OUTPUT INSERTED.order_detail_id "
                                + "VALUES(" + "?,?,?,?,?,'PENDING'" + ")";
                        try (PreparedStatement ps = c.prepareStatement(insert)) {
                            ps.setLong(1, orderId);
                            ps.setLong(2, item.menuItemId());
                            ps.setInt(3, item.quantity());
                            ps.setBigDecimal(4, item.price());
                            if (item.note() == null) {
                                ps.setNull(5, Types.NVARCHAR);
                            } else {
                                ps.setString(5, item.note());
                            }
                            try (ResultSet rs = ps.executeQuery()) {
                                if (!rs.next()) {
                                    throw new SQLException("Không thể tạo chi tiết đơn hàng");
                                }
                                detailId = rs.getLong(1);
                            }
                        }
                    }
                    addDetailIngredientSnapshot(c, detailId, prepared.requirements());
                }
                refreshMenuAvailability(c);
                c.commit();
                return orderId;
            } catch (Exception e) {
                c.rollback();
                if (e instanceof SQLException se) {
                    throw se;
                }
                if (e instanceof RuntimeException re) {
                    throw re;
                }
                throw new SQLException(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    public boolean cancelDetail(String token, long detailId) throws SQLException {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Thiếu mã QR của bàn");
        }
        if (detailId <= 0) {
            throw new IllegalArgumentException("Món cần hủy không hợp lệ");
        }
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                ServiceContext ctx = resolveContext(c, token, true);
                if (ctx == null) {
                    throw new IllegalArgumentException("Mã QR bàn không hợp lệ hoặc bàn đã ngừng sử dụng");
                }
                Long orderId = findOpenOrderId(c, ctx);
                if (orderId == null) {
                    throw new IllegalStateException("Không có đơn hàng đang mở");
                }
                String paymentSql = "SELECT TOP 1 payment_id " + "FROM payments " + "WITH (UPDLOCK,HOLDLOCK) "
                        + "WHERE order_id=? " + "AND payment_status='PENDING'";
                try (PreparedStatement ps = c.prepareStatement(paymentSql)) {
                    ps.setLong(1, orderId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            throw new IllegalStateException("Đơn hàng đang chờ thanh toán nên không thể hủy món.");
                        }
                    }
                }
                String detailSql = "SELECT status " + "FROM order_details " + "WITH (UPDLOCK,HOLDLOCK) "
                        + "WHERE order_detail_id=? " + "AND order_id=?";
                try (PreparedStatement ps = c.prepareStatement(detailSql)) {
                    ps.setLong(1, detailId);
                    ps.setLong(2, orderId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalStateException("Món không tồn tại trong đơn này.");
                        }
                        if (!"PENDING".equals(rs.getString("status"))) {
                            throw new IllegalStateException("Món đã được nhà bếp xử lý nên không thể hủy.");
                        }
                    }
                }
                releaseReservedIngredients(c, detailId);
                String cancelSql = "UPDATE order_details " + "SET status='CANCELLED' " + "WHERE order_detail_id=? "
                        + "AND order_id=? " + "AND status='PENDING'";
                try (PreparedStatement ps = c.prepareStatement(cancelSql)) {
                    ps.setLong(1, detailId);
                    ps.setLong(2, orderId);
                    if (ps.executeUpdate() != 1) {
                        throw new IllegalStateException("Món vừa thay đổi trạng thái, vui lòng thử lại.");
                    }
                }
                refreshMenuAvailability(c);
                String countSql = "SELECT COUNT(*) " + "FROM order_details " + "WITH (UPDLOCK,HOLDLOCK) "
                        + "WHERE order_id=? " + "AND status<>'CANCELLED'";
                int activeDetailCount;
                try (PreparedStatement ps = c.prepareStatement(countSql)) {
                    ps.setLong(1, orderId);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        activeDetailCount = rs.getInt(1);
                    }
                }
                boolean orderClosed = false;
                if (activeDetailCount == 0) {
                    String closeSql = "UPDATE orders " + "SET " + "order_status='CLOSED'," + "closed_at=SYSDATETIME() "
                            + "WHERE order_id=? " + "AND order_status='OPEN'";
                    try (PreparedStatement ps = c.prepareStatement(closeSql)) {
                        ps.setLong(1, orderId);
                        if (ps.executeUpdate() != 1) {
                            throw new IllegalStateException("Không thể đóng đơn hàng.");
                        }
                    }
                    orderClosed = true;
                }
                c.commit();
                return orderClosed;
            } catch (Exception e) {
                c.rollback();
                if (e instanceof SQLException se) {
                    throw se;
                }
                if (e instanceof RuntimeException re) {
                    throw re;
                }
                throw new SQLException(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    private void assertOrderModifiable(Connection c, long orderId) throws SQLException {
        String orderSql = "SELECT order_status " + "FROM orders " + "WITH (UPDLOCK,HOLDLOCK) " + "WHERE order_id=?";
        try (PreparedStatement ps = c.prepareStatement(orderSql)) {
            ps.setLong(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Đơn hàng không tồn tại");
                }
                if (!"OPEN".equals(rs.getString("order_status"))) {
                    throw new IllegalStateException("Đơn hàng đã đóng");
                }
            }
        }
        String paymentSql = "SELECT TOP 1 payment_id " + "FROM payments " + "WITH (UPDLOCK,HOLDLOCK) "
                + "WHERE order_id=? " + "AND payment_status='PENDING'";
        try (PreparedStatement ps = c.prepareStatement(paymentSql)) {
            ps.setLong(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    throw new IllegalStateException("Đơn hàng đang chờ thanh toán, không thể gọi thêm hoặc hủy món");
                }
            }
        }
    }

    public void markServed(long detailId) throws SQLException {
        String sql = "UPDATE order_details " + "SET " + "status='SERVED'," + "served_at=SYSDATETIME() "
                + "WHERE order_detail_id=? " + "AND status='READY'";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, detailId);
            if (ps.executeUpdate() != 1) {
                throw new IllegalStateException("Món chưa ở trạng thái sẵn sàng");
            }
        }
    }

    public BigDecimal total(long orderId) throws SQLException {
        String sql = "SELECT COALESCE(" + "SUM(quantity*unit_price),0" + ") " + "FROM order_details "
                + "WHERE order_id=? " + "AND status<>'CANCELLED'";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getBigDecimal(1);
            }
        }
    }

    public boolean canPay(long orderId) throws SQLException {
        String sql = "SELECT " + "SUM(" + "CASE " + "WHEN status<>'CANCELLED' " + "THEN 1 ELSE 0 END"
                + ") AS active_count, " + "SUM(" + "CASE " + "WHEN status NOT IN(" + "'SERVED'," + "'CANCELLED'" + ") "
                + "THEN 1 ELSE 0 END" + ") AS waiting_count " + "FROM order_details " + "WHERE order_id=?";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt("active_count") > 0 && rs.getInt("waiting_count") == 0;
            }
        }
    }

    private ServiceContext resolveContext(Connection c, String token, boolean lock) throws SQLException {
        if (token == null || token.isBlank()) {
            return null;
        }
        String hint = lock ? " WITH (UPDLOCK,HOLDLOCK) " : " ";
        long tableId;
        String tableSql = "SELECT table_id " + "FROM restaurant_tables" + hint + "WHERE qr_token=? " + "AND active=1";
        try (PreparedStatement ps = c.prepareStatement(tableSql)) {
            ps.setString(1, token.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                tableId = rs.getLong("table_id");
            }
        }
        String reservationSql = "SELECT TOP 1 " + "r.reservation_id," + "r.table_id " + "FROM reservations r "
                + "JOIN reservation_tables rt " + "ON rt.reservation_id=r.reservation_id " + "WHERE " + "rt.table_id=? "
                + "AND r.status='CHECKED_IN' " + "ORDER BY r.reservation_id DESC";
        try (PreparedStatement ps = c.prepareStatement(reservationSql)) {
            ps.setLong(1, tableId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new ServiceContext(tableId, rs.getLong("reservation_id"), rs.getLong("table_id"));
                }
            }
        }
        return new ServiceContext(tableId, null, tableId);
    }

    private Long findOpenOrderId(Connection c, ServiceContext ctx) throws SQLException {
        String sql;
        if (ctx.reservationId() != null) {
            sql = "SELECT TOP 1 order_id " + "FROM orders " + "WITH (UPDLOCK,HOLDLOCK) " + "WHERE reservation_id=? "
                    + "AND order_status='OPEN'";
        } else {
            sql = "SELECT TOP 1 order_id " + "FROM orders " + "WITH (UPDLOCK,HOLDLOCK) " + "WHERE table_id=? "
                    + "AND reservation_id IS NULL " + "AND order_status='OPEN'";
        }
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, ctx.reservationId() != null ? ctx.reservationId() : ctx.tableId());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong(1) : null;
            }
        }
    }

    private void markServiceTablesOccupied(Connection c, ServiceContext ctx) throws SQLException {
        if (ctx.reservationId() == null) {
            String sql = "UPDATE restaurant_tables " + "SET status='OCCUPIED' " + "WHERE table_id=?";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setLong(1, ctx.tableId());
                ps.executeUpdate();
            }
            return;
        }
        String sql = "UPDATE t " + "SET t.status='OCCUPIED' " + "FROM restaurant_tables t "
                + "JOIN reservation_tables rt " + "ON rt.table_id=t.table_id " + "WHERE rt.reservation_id=?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, ctx.reservationId());
            ps.executeUpdate();
        }
    }

    private List<RequestedItem> validateRequestedItems(Connection c, String[] itemIds, String[] quantities,
            String[] notes) throws SQLException {
        List<RequestedItem> list = new ArrayList<>();
        String sql = "SELECT " + "m.name, " + "m.price, " + "m.active, " + "m.inventory_available, "
                + "c.active AS category_active, " + "CASE WHEN EXISTS(" + "SELECT 1 " + "FROM menu_item_ingredients r "
                + "WHERE r.menu_item_id=m.menu_item_id" + ") " + "THEN 1 ELSE 0 END AS has_recipe "
                + "FROM menu_items m " + "JOIN menu_categories c " + "ON c.category_id=m.category_id "
                + "WHERE m.menu_item_id=?";
        for (int i = 0; i < itemIds.length; i++) {
            long itemId;
            int quantity;
            try {
                itemId = Long.parseLong(itemIds[i]);
                quantity = Integer.parseInt(quantities[i]);
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException("Dữ liệu món ăn hoặc số lượng không hợp lệ");
            }
            if (quantity <= 0) {
                throw new IllegalArgumentException("Số lượng món phải lớn hơn 0");
            }
            String note = normalizeNote(notes != null && i < notes.length ? notes[i] : null);
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setLong(1, itemId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Món ăn không tồn tại");
                    }
                    String name = rs.getString("name");
                    if (!rs.getBoolean("active") || !rs.getBoolean("category_active")) {
                        throw new IllegalStateException("Món đã ngừng phục vụ: " + name);
                    }
                    if (!rs.getBoolean("has_recipe")) {
                        throw new IllegalStateException("Món chưa được cấu hình công thức: " + name);
                    }
                    if (!rs.getBoolean("inventory_available")) {
                        throw new IllegalStateException("Món hiện đã hết nguyên liệu: " + name);
                    }
                    list.add(new RequestedItem(itemId, name, quantity, rs.getBigDecimal("price"), note));
                }
            }
        }
        return list;
    }

    private List<PreparedRequestedItem> prepareAndReserveIngredients(Connection c, List<RequestedItem> requestedItems)
            throws SQLException {
        List<PreparedRequestedItem> prepared = new ArrayList<>();
        Map<Long, BigDecimal> totalRequired = new TreeMap<>();
        for (RequestedItem item : requestedItems) {
            Map<Long, BigDecimal> requirements = new TreeMap<>();
            String recipeSql = "SELECT " + "r.inventory_item_id, " + "r.required_quantity "
                    + "FROM menu_item_ingredients r " + "WITH (HOLDLOCK) " + "WHERE r.menu_item_id=? "
                    + "ORDER BY r.inventory_item_id";
            try (PreparedStatement ps = c.prepareStatement(recipeSql)) {
                ps.setLong(1, item.menuItemId());
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        long inventoryId = rs.getLong("inventory_item_id");
                        BigDecimal needed = rs.getBigDecimal("required_quantity")
                                .multiply(BigDecimal.valueOf(item.quantity()));
                        requirements.merge(inventoryId, needed, BigDecimal::add);
                        totalRequired.merge(inventoryId, needed, BigDecimal::add);
                    }
                }
            }
            if (requirements.isEmpty()) {
                throw new IllegalStateException("Món chưa được cấu hình công thức: " + item.name());
            }
            prepared.add(new PreparedRequestedItem(item, requirements));
        }
        for (Map.Entry<Long, BigDecimal> entry : totalRequired.entrySet()) {
            String sql = "SELECT " + "name, " + "unit, " + "quantity, " + "reserved_quantity, " + "active "
                    + "FROM inventory_items " + "WITH (UPDLOCK,HOLDLOCK) " + "WHERE inventory_item_id=?";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setLong(1, entry.getKey());
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalStateException("Thiếu cấu hình nguyên liệu cho món đã chọn");
                    }
                    String name = rs.getString("name");
                    String unit = rs.getString("unit");
                    if (!rs.getBoolean("active")) {
                        throw new IllegalStateException("Nguyên liệu đã ngừng sử dụng: " + name);
                    }
                    BigDecimal onHand = rs.getBigDecimal("quantity");
                    BigDecimal reserved = rs.getBigDecimal("reserved_quantity");
                    BigDecimal available = onHand.subtract(reserved);
                    if (available.compareTo(entry.getValue()) < 0) {
                        throw new IllegalStateException("Không đủ nguyên liệu " + name + ". Còn khả dụng "
                                + available.stripTrailingZeros().toPlainString() + " " + unit + ", cần "
                                + entry.getValue().stripTrailingZeros().toPlainString() + " " + unit);
                    }
                }
            }
        }
        for (Map.Entry<Long, BigDecimal> entry : totalRequired.entrySet()) {
            String reserveSql = "UPDATE inventory_items " + "SET " + "reserved_quantity=" + "reserved_quantity+? "
                    + "WHERE inventory_item_id=? " + "AND active=1 " + "AND (" + "quantity-reserved_quantity" + ")>=?";
            try (PreparedStatement ps = c.prepareStatement(reserveSql)) {
                ps.setBigDecimal(1, entry.getValue());
                ps.setLong(2, entry.getKey());
                ps.setBigDecimal(3, entry.getValue());
                if (ps.executeUpdate() != 1) {
                    throw new IllegalStateException("Tồn kho vừa thay đổi, vui lòng đặt món lại");
                }
            }
        }
        return prepared;
    }

    private void addDetailIngredientSnapshot(Connection c, long detailId, Map<Long, BigDecimal> requirements)
            throws SQLException {
        for (Map.Entry<Long, BigDecimal> entry : requirements.entrySet()) {
            String update = "UPDATE order_detail_ingredients " + "SET " + "required_quantity=" + "required_quantity+? "
                    + "WHERE order_detail_id=? " + "AND inventory_item_id=?";
            int affected;
            try (PreparedStatement ps = c.prepareStatement(update)) {
                ps.setBigDecimal(1, entry.getValue());
                ps.setLong(2, detailId);
                ps.setLong(3, entry.getKey());
                affected = ps.executeUpdate();
            }
            if (affected == 0) {
                String insert = "INSERT INTO order_detail_ingredients(" + "order_detail_id," + "inventory_item_id,"
                        + "required_quantity" + ") VALUES(?,?,?)";
                try (PreparedStatement ps = c.prepareStatement(insert)) {
                    ps.setLong(1, detailId);
                    ps.setLong(2, entry.getKey());
                    ps.setBigDecimal(3, entry.getValue());
                    ps.executeUpdate();
                }
            }
        }
    }

    private void releaseReservedIngredients(Connection c, long detailId) throws SQLException {
        Map<Long, BigDecimal> reserved = new TreeMap<>();
        String sql = "SELECT " + "inventory_item_id, " + "required_quantity " + "FROM order_detail_ingredients "
                + "WHERE order_detail_id=? " + "ORDER BY inventory_item_id";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, detailId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    reserved.put(rs.getLong("inventory_item_id"), rs.getBigDecimal("required_quantity"));
                }
            }
        }
        if (reserved.isEmpty()) {
            return;
        }
        for (Map.Entry<Long, BigDecimal> entry : reserved.entrySet()) {
            String lockSql = "SELECT reserved_quantity " + "FROM inventory_items " + "WITH (UPDLOCK,HOLDLOCK) "
                    + "WHERE inventory_item_id=?";
            try (PreparedStatement ps = c.prepareStatement(lockSql)) {
                ps.setLong(1, entry.getKey());
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalStateException("Nguyên liệu của món không còn tồn tại");
                    }
                    BigDecimal currentReserved = rs.getBigDecimal("reserved_quantity");
                    if (currentReserved.compareTo(entry.getValue()) < 0) {
                        throw new IllegalStateException("Dữ liệu giữ chỗ nguyên liệu không đồng bộ");
                    }
                }
            }
            String release = "UPDATE inventory_items " + "SET " + "reserved_quantity=" + "reserved_quantity-? "
                    + "WHERE inventory_item_id=? " + "AND reserved_quantity>=?";
            try (PreparedStatement ps = c.prepareStatement(release)) {
                ps.setBigDecimal(1, entry.getValue());
                ps.setLong(2, entry.getKey());
                ps.setBigDecimal(3, entry.getValue());
                if (ps.executeUpdate() != 1) {
                    throw new IllegalStateException("Không thể giải phóng nguyên liệu đã giữ chỗ");
                }
            }
        }
    }

    private void refreshMenuAvailability(Connection c) throws SQLException {
        String sql = "UPDATE m " + "SET inventory_available=CASE " + "WHEN EXISTS(" + "SELECT 1 "
                + "FROM menu_item_ingredients r " + "WHERE r.menu_item_id=m.menu_item_id" + ") " + "AND NOT EXISTS("
                + "SELECT 1 " + "FROM menu_item_ingredients r " + "JOIN inventory_items i "
                + "ON i.inventory_item_id=r.inventory_item_id " + "WHERE r.menu_item_id=m.menu_item_id " + "AND ("
                + "i.active=0 " + "OR " + "(" + "i.quantity-i.reserved_quantity" + ")<r.required_quantity" + ")" + ") "
                + "THEN 1 " + "ELSE 0 " + "END " + "FROM menu_items m";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.executeUpdate();
        }
    }

    private Long findSamePendingDetail(Connection c, long orderId, RequestedItem item) throws SQLException {
        String sql = "SELECT TOP 1 order_detail_id " + "FROM order_details " + "WITH (UPDLOCK,ROWLOCK) "
                + "WHERE order_id=? " + "AND menu_item_id=? " + "AND unit_price=? " + "AND status='PENDING' " + "AND ("
                + "(note IS NULL AND ? IS NULL) " + "OR note=?" + ") " + "ORDER BY order_detail_id";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, orderId);
            ps.setLong(2, item.menuItemId());
            ps.setBigDecimal(3, item.price());
            if (item.note() == null) {
                ps.setNull(4, Types.NVARCHAR);
                ps.setNull(5, Types.NVARCHAR);
            } else {
                ps.setString(4, item.note());
                ps.setString(5, item.note());
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong("order_detail_id") : null;
            }
        }
    }

    private List<OrderDetail> findDetails(Connection c, long orderId) throws SQLException {
        String sql = "SELECT " + "d.order_detail_id, " + "d.order_id, " + "COALESCE(" + "lbl.table_numbers,"
                + "t.table_number" + ") AS table_number, " + "d.menu_item_id, " + "m.name AS menu_item_name, "
                + "d.quantity, " + "d.unit_price, " + "d.note, " + "d.status, " + "d.created_at "
                + "FROM order_details d " + "JOIN orders o " + "ON o.order_id=d.order_id " + "JOIN restaurant_tables t "
                + "ON t.table_id=o.table_id " + TABLE_LABEL_APPLY + "JOIN menu_items m "
                + "ON m.menu_item_id=d.menu_item_id " + "WHERE d.order_id=? " + "ORDER BY d.created_at";
        List<OrderDetail> list = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapDetail(rs));
                }
            }
        }
        return list;
    }

    private String normalizeNote(String note) {
        if (note == null) {
            return null;
        }
        String value = note.trim();
        if (value.isEmpty()) {
            return null;
        }
        if (value.length() > 500) {
            throw new IllegalArgumentException("Ghi chú tối đa 500 ký tự");
        }
        return value;
    }

    private RestaurantOrder mapOrder(ResultSet rs) throws SQLException {
        RestaurantOrder order = new RestaurantOrder();
        order.setOrderId(rs.getLong("order_id"));
        order.setTableId(rs.getLong("table_id"));
        order.setTableNumber(rs.getString("table_number"));
        order.setOrderStatus(rs.getString("order_status"));
        order.setCreatedAt(toLocalDateTime(rs.getTimestamp("created_at")));
        return order;
    }

    private OrderDetail mapDetail(ResultSet rs) throws SQLException {
        OrderDetail detail = new OrderDetail();
        detail.setOrderDetailId(rs.getLong("order_detail_id"));
        detail.setOrderId(rs.getLong("order_id"));
        detail.setTableNumber(rs.getString("table_number"));
        detail.setMenuItemId(rs.getLong("menu_item_id"));
        detail.setMenuItemName(rs.getString("menu_item_name"));
        detail.setQuantity(rs.getInt("quantity"));
        detail.setUnitPrice(rs.getBigDecimal("unit_price"));
        detail.setNote(rs.getString("note"));
        detail.setStatus(rs.getString("status"));
        detail.setCreatedAt(toLocalDateTime(rs.getTimestamp("created_at")));
        return detail;
    }

    private LocalDateTime toLocalDateTime(Timestamp timestamp) {
        return timestamp == null ? null : timestamp.toLocalDateTime();
    }

    private record RequestedItem(long menuItemId, String name, int quantity, BigDecimal price, String note) {
    }

    private record PreparedRequestedItem(RequestedItem item, Map<Long, BigDecimal> requirements) {
    }

    private record ServiceContext(long tableId, Long reservationId, long anchorTableId) {
    }
}
