package com.fpt.rms.dao;

import com.fpt.rms.model.MenuCategory;
import com.fpt.rms.model.MenuItem;
import com.fpt.rms.model.RecipeIngredient;
import com.fpt.rms.util.DBContext;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MenuDAO {
    public List<MenuItem> findAvailableItems() throws SQLException {
        String sql = "SELECT " + "m.menu_item_id, " + "m.category_id, " + "c.name AS category_name, " + "m.name, "
                + "m.description, " + "m.price, " + "m.active, " + "m.inventory_available " + "FROM menu_items m "
                + "JOIN menu_categories c " + "ON c.category_id=m.category_id " + "WHERE " + "m.active=1 "
                + "AND m.inventory_available=1 " + "AND c.active=1 " + "AND EXISTS(" + "SELECT 1 "
                + "FROM menu_item_ingredients r " + "WHERE r.menu_item_id=m.menu_item_id" + ") "
                + "ORDER BY c.name,m.name";
        List<MenuItem> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapItem(rs));
            }
        }
        return list;
    }

    public List<MenuItem> findAllItems() throws SQLException {
        String sql = "SELECT " + "m.menu_item_id, " + "m.category_id, " + "c.name AS category_name, " + "m.name, "
                + "m.description, " + "m.price, " + "m.active, " + "m.inventory_available " + "FROM menu_items m "
                + "JOIN menu_categories c " + "ON c.category_id=m.category_id " + "ORDER BY c.name,m.name";
        try (Connection c = DBContext.getConnection()) {
            List<MenuItem> list = new ArrayList<>();
            Map<Long, MenuItem> byId = new HashMap<>();
            try (PreparedStatement ps = c.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    MenuItem item = mapItem(rs);
                    list.add(item);
                    byId.put(item.getMenuItemId(), item);
                }
            }
            String recipeSql = "SELECT " + "r.menu_item_id, " + "r.inventory_item_id, " + "i.name AS inventory_name, "
                    + "i.unit, " + "r.required_quantity " + "FROM menu_item_ingredients r " + "JOIN inventory_items i "
                    + "ON i.inventory_item_id=" + "r.inventory_item_id " + "ORDER BY " + "r.menu_item_id, " + "i.name";
            try (PreparedStatement ps = c.prepareStatement(recipeSql); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    MenuItem item = byId.get(rs.getLong("menu_item_id"));
                    if (item == null) {
                        continue;
                    }
                    RecipeIngredient ingredient = new RecipeIngredient();
                    ingredient.setInventoryItemId(rs.getLong("inventory_item_id"));
                    ingredient.setInventoryItemName(rs.getString("inventory_name"));
                    ingredient.setUnit(rs.getString("unit"));
                    ingredient.setRequiredQuantity(rs.getBigDecimal("required_quantity"));
                    item.getIngredients().add(ingredient);
                }
            }
            return list;
        }
    }

    public List<MenuCategory> findAllCategories() throws SQLException {
        List<MenuCategory> list = new ArrayList<>();
        String sql = "SELECT " + "category_id, " + "name, " + "active " + "FROM menu_categories " + "ORDER BY name";
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                MenuCategory category = new MenuCategory();
                category.setCategoryId(rs.getLong("category_id"));
                category.setName(rs.getString("name"));
                category.setActive(rs.getBoolean("active"));
                list.add(category);
            }
        }
        return list;
    }

    public void create(long categoryId, String name, String description, BigDecimal price) throws SQLException {
        validate(name, price);
        try (Connection c = DBContext.getConnection()) {
            ensureCategoryExists(c, categoryId);
            ensureNameUnique(c, name, null);
            String sql = "INSERT INTO menu_items(" + "category_id," + "name," + "description," + "price," + "active,"
                    + "inventory_available" + ") VALUES(?,?,?,?,1,0)";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setLong(1, categoryId);
                ps.setString(2, name.trim());
                ps.setString(3, blankToNull(description));
                ps.setBigDecimal(4, price);
                ps.executeUpdate();
            }
        }
    }

    public void update(long menuItemId, long categoryId, String name, String description, BigDecimal price)
            throws SQLException {
        validate(name, price);
        try (Connection c = DBContext.getConnection()) {
            ensureCategoryExists(c, categoryId);
            ensureNameUnique(c, name, menuItemId);
            String sql = "UPDATE menu_items " + "SET " + "category_id=?, " + "name=?, " + "description=?, " + "price=? "
                    + "WHERE menu_item_id=?";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setLong(1, categoryId);
                ps.setString(2, name.trim());
                ps.setString(3, blankToNull(description));
                ps.setBigDecimal(4, price);
                ps.setLong(5, menuItemId);
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("Món ăn không tồn tại");
                }
            }
        }
    }

    public void setActive(long menuItemId, boolean active) throws SQLException {
        String sql = "UPDATE menu_items " + "SET active=? " + "WHERE menu_item_id=?";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setBoolean(1, active);
            ps.setLong(2, menuItemId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Món ăn không tồn tại");
            }
        }
    }

    public void saveIngredient(long menuItemId, long inventoryItemId, BigDecimal requiredQuantity) throws SQLException {
        if (requiredQuantity == null || requiredQuantity.signum() <= 0) {
            throw new IllegalArgumentException("Định lượng nguyên liệu phải lớn hơn 0");
        }
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                ensureMenuItemExists(c, menuItemId);
                ensureInventoryItemUsable(c, inventoryItemId);
                String update = "UPDATE menu_item_ingredients " + "SET required_quantity=? " + "WHERE "
                        + "menu_item_id=? " + "AND inventory_item_id=?";
                int affected;
                try (PreparedStatement ps = c.prepareStatement(update)) {
                    ps.setBigDecimal(1, requiredQuantity);
                    ps.setLong(2, menuItemId);
                    ps.setLong(3, inventoryItemId);
                    affected = ps.executeUpdate();
                }
                if (affected == 0) {
                    String insert = "INSERT INTO menu_item_ingredients(" + "menu_item_id," + "inventory_item_id,"
                            + "required_quantity" + ") VALUES(?,?,?)";
                    try (PreparedStatement ps = c.prepareStatement(insert)) {
                        ps.setLong(1, menuItemId);
                        ps.setLong(2, inventoryItemId);
                        ps.setBigDecimal(3, requiredQuantity);
                        ps.executeUpdate();
                    }
                }
                refreshMenuAvailability(c, menuItemId);
                c.commit();
            } catch (Exception e) {
                c.rollback();
                throw wrap(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    public void removeIngredient(long menuItemId, long inventoryItemId) throws SQLException {
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                String delete = "DELETE FROM menu_item_ingredients " + "WHERE menu_item_id=? "
                        + "AND inventory_item_id=?";
                try (PreparedStatement ps = c.prepareStatement(delete)) {
                    ps.setLong(1, menuItemId);
                    ps.setLong(2, inventoryItemId);
                    if (ps.executeUpdate() == 0) {
                        throw new IllegalArgumentException("Nguyên liệu không có trong công thức");
                    }
                }
                refreshMenuAvailability(c, menuItemId);
                c.commit();
            } catch (Exception e) {
                c.rollback();
                throw wrap(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    private void refreshMenuAvailability(Connection c, long menuItemId) throws SQLException {
        String sql = "UPDATE m " + "SET inventory_available=CASE " + "WHEN EXISTS(" + "SELECT 1 "
                + "FROM menu_item_ingredients r " + "WHERE r.menu_item_id=m.menu_item_id" + ") " + "AND NOT EXISTS("
                + "SELECT 1 " + "FROM menu_item_ingredients r " + "JOIN inventory_items i " + "ON i.inventory_item_id="
                + "r.inventory_item_id " + "WHERE " + "r.menu_item_id=m.menu_item_id " + "AND (" + "i.active=0 " + "OR "
                + "(" + "i.quantity-i.reserved_quantity" + ")<r.required_quantity" + ")" + ") " + "THEN 1 " + "ELSE 0 "
                + "END " + "FROM menu_items m " + "WHERE m.menu_item_id=?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, menuItemId);
            ps.executeUpdate();
        }
    }

    private void ensureCategoryExists(Connection c, long categoryId) throws SQLException {
        String sql = "SELECT 1 " + "FROM menu_categories " + "WHERE category_id=? " + "AND active=1";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, categoryId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Danh mục món không tồn tại hoặc đã tắt");
                }
            }
        }
    }

    private void ensureMenuItemExists(Connection c, long menuItemId) throws SQLException {
        String sql = "SELECT 1 " + "FROM menu_items " + "WHERE menu_item_id=?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, menuItemId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Món ăn không tồn tại");
                }
            }
        }
    }

    private void ensureInventoryItemUsable(Connection c, long inventoryItemId) throws SQLException {
        String sql = "SELECT 1 " + "FROM inventory_items " + "WHERE inventory_item_id=? " + "AND active=1";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, inventoryItemId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Nguyên liệu không tồn tại hoặc đã ngừng sử dụng");
                }
            }
        }
    }

    private void ensureNameUnique(Connection c, String name, Long exceptId) throws SQLException {
        String sql;
        if (exceptId == null) {
            sql = "SELECT 1 " + "FROM menu_items " + "WHERE name=?";
        } else {
            sql = "SELECT 1 " + "FROM menu_items " + "WHERE name=? " + "AND menu_item_id<>?";
        }
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, name.trim());
            if (exceptId != null) {
                ps.setLong(2, exceptId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    throw new IllegalArgumentException("Tên món đã tồn tại");
                }
            }
        }
    }

    private void validate(String name, BigDecimal price) {
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("Tên món không được để trống");
        }
        if (price == null || price.signum() < 0) {
            throw new IllegalArgumentException("Giá món không được âm");
        }
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private MenuItem mapItem(ResultSet rs) throws SQLException {
        MenuItem item = new MenuItem();
        item.setMenuItemId(rs.getLong("menu_item_id"));
        item.setCategoryId(rs.getLong("category_id"));
        item.setCategoryName(rs.getString("category_name"));
        item.setName(rs.getString("name"));
        item.setDescription(rs.getString("description"));
        item.setPrice(rs.getBigDecimal("price"));
        item.setActive(rs.getBoolean("active"));
        item.setInventoryAvailable(rs.getBoolean("inventory_available"));
        return item;
    }

    private SQLException wrap(Exception e) {
        if (e instanceof SQLException se) {
            return se;
        }
        return new SQLException(e.getMessage(), e);
    }
}
