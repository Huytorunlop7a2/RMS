package com.fpt.rms.dao;

import com.fpt.rms.model.InventoryItem;
import com.fpt.rms.util.DBContext;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class InventoryDAO {
    public List<InventoryItem> findAll() throws SQLException {
        List<InventoryItem> list = new ArrayList<>();
        String sql = "SELECT " + "inventory_item_id, " + "name, " + "unit, " + "quantity, " + "reserved_quantity, "
                + "low_stock_threshold, " + "active " + "FROM inventory_items " + "ORDER BY name";
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                InventoryItem item = new InventoryItem();
                item.setInventoryItemId(rs.getLong("inventory_item_id"));
                item.setName(rs.getString("name"));
                item.setUnit(rs.getString("unit"));
                item.setQuantity(rs.getBigDecimal("quantity"));
                item.setReservedQuantity(rs.getBigDecimal("reserved_quantity"));
                item.setLowStockThreshold(rs.getBigDecimal("low_stock_threshold"));
                item.setActive(rs.getBoolean("active"));
                list.add(item);
            }
        }
        return list;
    }

    public void create(String name, String unit, BigDecimal initial, BigDecimal low, long staffId) throws SQLException {
        if (name == null || name.isBlank() || unit == null || unit.isBlank()) {
            throw new IllegalArgumentException("Tên và đơn vị nguyên liệu không được để trống");
        }
        if (initial == null || low == null || initial.signum() < 0 || low.signum() < 0) {
            throw new IllegalArgumentException("Số lượng không được âm");
        }
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                long id;
                String sql = "INSERT INTO inventory_items(" + "name," + "unit," + "quantity," + "reserved_quantity,"
                        + "low_stock_threshold," + "active" + ") " + "VALUES(?,?,?,0,?,1)";
                try (PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, name.trim());
                    ps.setString(2, unit.trim());
                    ps.setBigDecimal(3, initial);
                    ps.setBigDecimal(4, low);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new SQLException("Không thể tạo nguyên liệu");
                        }
                        id = rs.getLong(1);
                    }
                }
                if (initial.signum() > 0) {
                    insertTx(c, id, staffId, initial, null, "RESTOCK", "Tồn kho ban đầu", null);
                }
                refreshMenuAvailability(c);
                c.commit();
            } catch (Exception e) {
                c.rollback();
                throw wrap(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    public void stockIn(long id, BigDecimal quantity, BigDecimal unitCost, String note, long staffId)
            throws SQLException {
        if (quantity == null || quantity.signum() <= 0) {
            throw new IllegalArgumentException("Số lượng phải lớn hơn 0");
        }
        if (unitCost != null && unitCost.signum() < 0) {
            throw new IllegalArgumentException("Đơn giá không được âm");
        }
        change(id, quantity, "RESTOCK", unitCost, note, staffId);
    }

    public void waste(long id, BigDecimal quantity, String note, long staffId) throws SQLException {
        if (quantity == null || quantity.signum() <= 0) {
            throw new IllegalArgumentException("Số lượng phải lớn hơn 0");
        }
        change(id, quantity.negate(), "WASTE_LOSS", null, note, staffId);
    }

    public void adjust(long id, BigDecimal actual, String note, long staffId) throws SQLException {
        if (actual == null || actual.signum() < 0) {
            throw new IllegalArgumentException("Tồn thực tế không được âm");
        }
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                BigDecimal current;
                BigDecimal reserved;
                String select = "SELECT " + "quantity, " + "reserved_quantity " + "FROM inventory_items "
                        + "WITH (UPDLOCK,HOLDLOCK) " + "WHERE inventory_item_id=?";
                try (PreparedStatement ps = c.prepareStatement(select)) {
                    ps.setLong(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Nguyên liệu không tồn tại");
                        }
                        current = rs.getBigDecimal("quantity");
                        reserved = rs.getBigDecimal("reserved_quantity");
                    }
                }
                if (actual.compareTo(reserved) < 0) {
                    throw new IllegalStateException("Không thể điều chỉnh tồn thực tế xuống thấp hơn lượng đã giữ chỗ ("
                            + reserved.stripTrailingZeros().toPlainString() + ")");
                }
                BigDecimal delta = actual.subtract(current);
                String update = "UPDATE inventory_items " + "SET quantity=? " + "WHERE inventory_item_id=? "
                        + "AND ?>=reserved_quantity";
                try (PreparedStatement ps = c.prepareStatement(update)) {
                    ps.setBigDecimal(1, actual);
                    ps.setLong(2, id);
                    ps.setBigDecimal(3, actual);
                    if (ps.executeUpdate() != 1) {
                        throw new IllegalStateException("Không thể cập nhật nguyên liệu vì tồn kho đã thay đổi");
                    }
                }
                if (delta.signum() != 0) {
                    insertTx(c, id, staffId, delta, null, "ADJUSTMENT", note, null);
                }
                refreshMenuAvailability(c);
                c.commit();
            } catch (Exception e) {
                c.rollback();
                throw wrap(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    public void setThreshold(long id, BigDecimal threshold) throws SQLException {
        if (threshold == null || threshold.signum() < 0) {
            throw new IllegalArgumentException("Ngưỡng không được âm");
        }
        String sql = "UPDATE inventory_items " + "SET low_stock_threshold=? " + "WHERE inventory_item_id=?";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setBigDecimal(1, threshold);
            ps.setLong(2, id);
            if (ps.executeUpdate() != 1) {
                throw new IllegalArgumentException("Nguyên liệu không tồn tại");
            }
        }
    }

    public void markDetailReady(long orderDetailId, long staffId) throws SQLException {
        if (orderDetailId <= 0) {
            throw new IllegalArgumentException("Mã món không hợp lệ");
        }
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                long orderId;
                String orderDetailSql = "SELECT order_id " + "FROM order_details " + "WHERE order_detail_id=?";
                try (PreparedStatement ps = c.prepareStatement(orderDetailSql)) {
                    ps.setLong(1, orderDetailId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Món không tồn tại");
                        }
                        orderId = rs.getLong("order_id");
                    }
                }
                lockOpenOrder(c, orderId);
                String menuItemName;
                String detailSql = "SELECT " + "d.status, " + "m.name " + "FROM order_details d "
                        + "WITH (UPDLOCK,HOLDLOCK) " + "JOIN menu_items m " + "ON m.menu_item_id=d.menu_item_id "
                        + "WHERE d.order_detail_id=? " + "AND d.order_id=?";
                try (PreparedStatement ps = c.prepareStatement(detailSql)) {
                    ps.setLong(1, orderDetailId);
                    ps.setLong(2, orderId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Món không tồn tại trong đơn hàng");
                        }
                        if (!"PENDING".equals(rs.getString("status"))) {
                            throw new IllegalStateException("Món không còn ở trạng thái PENDING");
                        }
                        menuItemName = rs.getString("name");
                    }
                }
                Map<Long, BigDecimal> required = new LinkedHashMap<>();
                String snapshotSql = "SELECT " + "inventory_item_id, " + "required_quantity "
                        + "FROM order_detail_ingredients " + "WHERE order_detail_id=? " + "ORDER BY inventory_item_id";
                try (PreparedStatement ps = c.prepareStatement(snapshotSql)) {
                    ps.setLong(1, orderDetailId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            required.put(rs.getLong("inventory_item_id"), rs.getBigDecimal("required_quantity"));
                        }
                    }
                }
                if (required.isEmpty()) {
                    throw new IllegalStateException("Món " + menuItemName + " chưa có dữ liệu nguyên liệu đã giữ chỗ. "
                            + "Hãy hủy món và đặt lại.");
                }
                for (Map.Entry<Long, BigDecimal> entry : required.entrySet()) {
                    String inventorySql = "SELECT " + "name, " + "quantity, " + "reserved_quantity, " + "active "
                            + "FROM inventory_items " + "WITH (UPDLOCK,HOLDLOCK) " + "WHERE inventory_item_id=?";
                    try (PreparedStatement ps = c.prepareStatement(inventorySql)) {
                        ps.setLong(1, entry.getKey());
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) {
                                throw new IllegalStateException("Thiếu cấu hình nguyên liệu");
                            }
                            String name = rs.getString("name");
                            if (!rs.getBoolean("active")) {
                                throw new IllegalStateException("Nguyên liệu đã ngừng sử dụng: " + name);
                            }
                            BigDecimal onHand = rs.getBigDecimal("quantity");
                            BigDecimal reserved = rs.getBigDecimal("reserved_quantity");
                            if (reserved.compareTo(entry.getValue()) < 0) {
                                throw new IllegalStateException("Dữ liệu giữ chỗ nguyên liệu không đồng bộ: " + name);
                            }
                            if (onHand.compareTo(entry.getValue()) < 0) {
                                throw new IllegalStateException(
                                        "Tồn thực tế không còn đủ cho lượng đã giữ chỗ: " + name);
                            }
                        }
                    }
                }
                for (Map.Entry<Long, BigDecimal> entry : required.entrySet()) {
                    String consumeSql = "UPDATE inventory_items " + "SET " + "quantity=quantity-?, "
                            + "reserved_quantity=" + "reserved_quantity-? " + "WHERE inventory_item_id=? "
                            + "AND quantity>=? " + "AND reserved_quantity>=?";
                    try (PreparedStatement ps = c.prepareStatement(consumeSql)) {
                        ps.setBigDecimal(1, entry.getValue());
                        ps.setBigDecimal(2, entry.getValue());
                        ps.setLong(3, entry.getKey());
                        ps.setBigDecimal(4, entry.getValue());
                        ps.setBigDecimal(5, entry.getValue());
                        if (ps.executeUpdate() != 1) {
                            throw new IllegalStateException("Tồn kho vừa thay đổi, vui lòng thử lại");
                        }
                    }
                    insertTx(c, entry.getKey(), staffId, entry.getValue().negate(), null, "USAGE",
                            "Tiêu hao cho món #" + orderDetailId + " - đơn #" + orderId, orderId);
                }
                String updateDetail = "UPDATE order_details " + "SET " + "status='READY'," + "ready_at=SYSDATETIME() "
                        + "WHERE order_detail_id=? " + "AND order_id=? " + "AND status='PENDING'";
                try (PreparedStatement ps = c.prepareStatement(updateDetail)) {
                    ps.setLong(1, orderDetailId);
                    ps.setLong(2, orderId);
                    if (ps.executeUpdate() != 1) {
                        throw new IllegalStateException("Món vừa thay đổi trạng thái, vui lòng thử lại");
                    }
                }
                refreshMenuAvailability(c);
                c.commit();
            } catch (Exception e) {
                c.rollback();
                throw wrap(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    private void lockOpenOrder(Connection c, long orderId) throws SQLException {
        String sql = "SELECT order_status " + "FROM orders " + "WITH (UPDLOCK,HOLDLOCK) " + "WHERE order_id=?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
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
    }

    private void change(long id, BigDecimal delta, String type, BigDecimal unitCost, String note, long staffId)
            throws SQLException {
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                BigDecimal current;
                BigDecimal reserved;
                String select = "SELECT " + "quantity, " + "reserved_quantity " + "FROM inventory_items "
                        + "WITH (UPDLOCK,HOLDLOCK) " + "WHERE inventory_item_id=?";
                try (PreparedStatement ps = c.prepareStatement(select)) {
                    ps.setLong(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Nguyên liệu không tồn tại");
                        }
                        current = rs.getBigDecimal("quantity");
                        reserved = rs.getBigDecimal("reserved_quantity");
                    }
                }
                BigDecimal next = current.add(delta);
                if (next.signum() < 0) {
                    throw new IllegalStateException("Tồn kho không được âm");
                }
                if (next.compareTo(reserved) < 0) {
                    throw new IllegalStateException("Không thể giảm tồn kho xuống thấp hơn lượng đã giữ chỗ ("
                            + reserved.stripTrailingZeros().toPlainString() + ")");
                }
                String update = "UPDATE inventory_items " + "SET quantity=? " + "WHERE inventory_item_id=? "
                        + "AND ?>=reserved_quantity";
                try (PreparedStatement ps = c.prepareStatement(update)) {
                    ps.setBigDecimal(1, next);
                    ps.setLong(2, id);
                    ps.setBigDecimal(3, next);
                    if (ps.executeUpdate() != 1) {
                        throw new IllegalStateException("Không thể cập nhật nguyên liệu vì tồn kho đã thay đổi");
                    }
                }
                insertTx(c, id, staffId, delta, unitCost, type, note, null);
                refreshMenuAvailability(c);
                c.commit();
            } catch (Exception e) {
                c.rollback();
                throw wrap(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    private void insertTx(Connection c, long inventoryId, long staffId, BigDecimal delta, BigDecimal unitCost,
            String type, String note, Long orderId) throws SQLException {
        String sql = "INSERT INTO inventory_transactions(" + "inventory_item_id," + "reference_order_id,"
                + "created_by_staff_id," + "quantity_change," + "unit_cost," + "transaction_type," + "description"
                + ") VALUES(?,?,?,?,?,?,?)";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, inventoryId);
            if (orderId == null) {
                ps.setNull(2, Types.BIGINT);
            } else {
                ps.setLong(2, orderId);
            }
            ps.setLong(3, staffId);
            ps.setBigDecimal(4, delta);
            if (unitCost == null) {
                ps.setNull(5, Types.DECIMAL);
            } else {
                ps.setBigDecimal(5, unitCost);
            }
            ps.setString(6, type);
            ps.setString(7, note == null || note.isBlank() ? null : note.trim());
            ps.executeUpdate();
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

    private SQLException wrap(Exception e) {
        if (e instanceof SQLException se) {
            return se;
        }
        return new SQLException(e.getMessage(), e);
    }
}
