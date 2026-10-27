package com.fpt.rms.dao;

import com.fpt.rms.model.RestaurantTable;
import com.fpt.rms.util.DBContext;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class WalkInGroupDAO {

        private static final int MAX_GROUP_TABLES = 8;

        private final TableDAO tableDAO = new TableDAO();

        private final TableLayoutDAO tableLayoutDAO = new TableLayoutDAO();

        /*
         * =====================================================
         * CREATE WALK-IN GROUP
         * =====================================================
         */

        public long createGroup(
                        String[] rawTableIds,
                        long staffId) throws SQLException {

                List<Long> tableIds = parseTableIds(rawTableIds);

                if (tableIds.size() < 2) {
                        throw new IllegalArgumentException(
                                        "Vui lòng chọn ít nhất 2 bàn");
                }

                if (tableIds.size() > MAX_GROUP_TABLES) {
                        throw new IllegalArgumentException(
                                        "Chỉ được gộp tối đa "
                                                        + MAX_GROUP_TABLES
                                                        + " bàn");
                }

                Collections.sort(tableIds);

                try (Connection c = DBContext.getConnection()) {

                        c.setAutoCommit(false);

                        try {

                                List<RestaurantTable> tables = tableDAO.findByIds(
                                                c,
                                                tableIds,
                                                true);

                                if (tables.size() != tableIds.size()) {
                                        throw new IllegalArgumentException(
                                                        "Có bàn không tồn tại");
                                }

                                for (RestaurantTable table : tables) {

                                        if (!table.isActive()) {
                                                throw new IllegalStateException(
                                                                "Bàn "
                                                                                + table.getTableNumber()
                                                                                + " đã ngừng sử dụng");
                                        }

                                        if (!"AVAILABLE".equals(
                                                        table.getStatus())) {
                                                throw new IllegalStateException(
                                                                "Bàn "
                                                                                + table.getTableNumber()
                                                                                + " hiện không trống");
                                        }
                                }

                                validateNoActiveGroup(
                                                c,
                                                tableIds);

                                validateNoOpenWalkInOrder(
                                                c,
                                                tableIds);

                                if (!tableLayoutDAO.isValidMergeGroup(
                                                c,
                                                tableIds)) {

                                        throw new IllegalStateException(
                                                        "Các bàn được chọn không tạo thành "
                                                                        + "một nhóm ghép hợp lệ");
                                }

                                long anchorTableId = tableIds.get(0);

                                String insertGroupSql = "INSERT INTO walk_in_groups(" +
                                                "anchor_table_id," +
                                                "created_by_staff_id," +
                                                "status" +
                                                ") " +
                                                "OUTPUT INSERTED.walk_in_group_id " +
                                                "VALUES(?,?,'ACTIVE')";

                                long groupId;

                                try (PreparedStatement ps = c.prepareStatement(
                                                insertGroupSql)) {

                                        ps.setLong(
                                                        1,
                                                        anchorTableId);

                                        ps.setLong(
                                                        2,
                                                        staffId);

                                        try (ResultSet rs = ps.executeQuery()) {

                                                if (!rs.next()) {
                                                        throw new SQLException(
                                                                        "Không thể tạo nhóm bàn walk-in");
                                                }

                                                groupId = rs.getLong(1);
                                        }
                                }

                                String insertMemberSql = "INSERT INTO walk_in_group_tables(" +
                                                "walk_in_group_id," +
                                                "table_id," +
                                                "active" +
                                                ") " +
                                                "VALUES(?,?,1)";

                                try (PreparedStatement ps = c.prepareStatement(
                                                insertMemberSql)) {

                                        for (Long tableId : tableIds) {

                                                ps.setLong(
                                                                1,
                                                                groupId);

                                                ps.setLong(
                                                                2,
                                                                tableId);

                                                ps.addBatch();
                                        }

                                        ps.executeBatch();
                                }

                                String placeholders = String.join(
                                                ",",
                                                Collections.nCopies(
                                                                tableIds.size(),
                                                                "?"));

                                String occupySql = "UPDATE restaurant_tables " +
                                                "SET status='OCCUPIED' " +
                                                "WHERE table_id IN (" +
                                                placeholders +
                                                ") " +
                                                "AND active=1 " +
                                                "AND status='AVAILABLE'";

                                try (PreparedStatement ps = c.prepareStatement(
                                                occupySql)) {

                                        bindIds(
                                                        ps,
                                                        tableIds);

                                        int updated = ps.executeUpdate();

                                        if (updated != tableIds.size()) {
                                                throw new IllegalStateException(
                                                                "Trạng thái bàn vừa thay đổi, "
                                                                                + "vui lòng thử lại");
                                        }
                                }

                                c.commit();

                                return groupId;

                        } catch (Exception e) {

                                c.rollback();

                                throw wrap(e);

                        } finally {

                                c.setAutoCommit(true);
                        }
                }
        }

        /*
         * =====================================================
         * RESOLVE SERVICE TOKEN
         * =====================================================
         */

        public String resolveServiceToken(
                        String originalToken) throws SQLException {

                if (originalToken == null
                                || originalToken.isBlank()) {

                        return originalToken;
                }

                String token = originalToken.trim();

                String sql = "SELECT TOP 1 " +
                                "anchor_table.qr_token " +

                                "FROM restaurant_tables member_table " +

                                "JOIN walk_in_group_tables wgt " +
                                "ON wgt.table_id=member_table.table_id " +

                                "JOIN walk_in_groups wg " +
                                "ON wg.walk_in_group_id=" +
                                "wgt.walk_in_group_id " +

                                "JOIN restaurant_tables anchor_table " +
                                "ON anchor_table.table_id=" +
                                "wg.anchor_table_id " +

                                "WHERE member_table.qr_token=? " +
                                "AND member_table.active=1 " +
                                "AND wgt.active=1 " +
                                "AND wg.status='ACTIVE' " +

                                "ORDER BY wg.walk_in_group_id DESC";

                try (
                                Connection c = DBContext.getConnection();

                                PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setString(
                                        1,
                                        token);

                        try (ResultSet rs = ps.executeQuery()) {

                                return rs.next()
                                                ? rs.getString(1)
                                                : token;
                        }
                }
        }

        /*
         * =====================================================
         * ACTIVE GROUP TABLE IDS
         * =====================================================
         */

        public Set<Long> findActiveGroupTableIds()
                        throws SQLException {

                Set<Long> ids = new HashSet<>();

                String sql = "SELECT wgt.table_id " +

                                "FROM walk_in_group_tables wgt " +

                                "JOIN walk_in_groups wg " +
                                "ON wg.walk_in_group_id=" +
                                "wgt.walk_in_group_id " +

                                "WHERE wgt.active=1 " +
                                "AND wg.status='ACTIVE'";

                try (
                                Connection c = DBContext.getConnection();

                                PreparedStatement ps = c.prepareStatement(sql);

                                ResultSet rs = ps.executeQuery()) {

                        while (rs.next()) {

                                ids.add(
                                                rs.getLong(
                                                                "table_id"));
                        }
                }

                return ids;
        }

        /*
         * =====================================================
         * ACTIVE GROUP LABELS
         * 
         * KEY = TABLE NUMBER
         * 
         * Ví dụ:
         * 
         * T01 -> Nhóm #5 · T01, T02, T03
         * T02 -> Nhóm #5 · T01, T02, T03
         * T03 -> Nhóm #5 · T01, T02, T03
         * =====================================================
         */

        public Map<String, String> findActiveGroupLabels()
                        throws SQLException {

                Map<Long, List<String>> groups = new LinkedHashMap<>();

                String sql = "SELECT " +
                                "wg.walk_in_group_id, " +
                                "t.table_number " +

                                "FROM walk_in_groups wg " +

                                "JOIN walk_in_group_tables wgt " +
                                "ON wgt.walk_in_group_id=" +
                                "wg.walk_in_group_id " +

                                "JOIN restaurant_tables t " +
                                "ON t.table_id=wgt.table_id " +

                                "WHERE wg.status='ACTIVE' " +
                                "AND wgt.active=1 " +

                                "ORDER BY " +
                                "wg.walk_in_group_id, " +
                                "t.table_number";

                try (
                                Connection c = DBContext.getConnection();

                                PreparedStatement ps = c.prepareStatement(sql);

                                ResultSet rs = ps.executeQuery()) {

                        while (rs.next()) {

                                long groupId = rs.getLong(
                                                "walk_in_group_id");

                                String tableNumber = rs.getString(
                                                "table_number");

                                groups
                                                .computeIfAbsent(
                                                                groupId,
                                                                key -> new ArrayList<>())
                                                .add(
                                                                tableNumber);
                        }
                }

                Map<String, String> result = new LinkedHashMap<>();

                for (Map.Entry<Long, List<String>> entry : groups.entrySet()) {

                        Long groupId = entry.getKey();

                        List<String> tableNumbers = entry.getValue();

                        String label = "Nhóm #"
                                        + groupId
                                        + " · "
                                        + String.join(
                                                        ", ",
                                                        tableNumbers);

                        for (String tableNumber : tableNumbers) {

                                result.put(
                                                tableNumber,
                                                label);
                        }
                }

                return result;
        }

        /*
         * =====================================================
         * RELEASE SINGLE TABLE
         * =====================================================
         */

        public boolean releaseSingleTableIfMember(
                        long tableId) throws SQLException {

                if (tableId <= 0) {
                        throw new IllegalArgumentException(
                                        "Bàn không hợp lệ");
                }

                try (Connection c = DBContext.getConnection()) {

                        c.setAutoCommit(false);

                        try {

                                GroupInfo group = findActiveGroupByTable(
                                                c,
                                                tableId);

                                if (group == null) {

                                        c.commit();

                                        return false;
                                }

                                List<Long> memberIds = findActiveMemberIds(
                                                c,
                                                group.groupId());

                                if (!memberIds.contains(
                                                tableId)) {
                                        throw new IllegalStateException(
                                                        "Bàn không còn thuộc nhóm walk-in");
                                }

                                tableDAO.findByIds(
                                                c,
                                                memberIds,
                                                true);

                                /*
                                 * Bàn cuối cùng trong group.
                                 */
                                if (memberIds.size() == 1) {

                                        validateAnchorHasNoOpenOrder(
                                                        c,
                                                        group.anchorTableId());

                                        deactivateSingleMember(
                                                        c,
                                                        group.groupId(),
                                                        tableId);

                                        releasePhysicalTable(
                                                        c,
                                                        tableId);

                                        closeGroup(
                                                        c,
                                                        group.groupId());

                                        c.commit();

                                        return true;
                                }

                                /*
                                 * Nếu bàn được trả là anchor,
                                 * chuyển anchor sang bàn còn lại.
                                 */
                                if (tableId == group.anchorTableId()) {

                                        long newAnchorId = chooseNewAnchor(
                                                        memberIds,
                                                        tableId);

                                        validateNoOpenWalkInOrderOnTable(
                                                        c,
                                                        newAnchorId);

                                        moveOpenOrderToNewAnchor(
                                                        c,
                                                        group.anchorTableId(),
                                                        newAnchorId);

                                        updateGroupAnchor(
                                                        c,
                                                        group.groupId(),
                                                        newAnchorId);
                                }

                                deactivateSingleMember(
                                                c,
                                                group.groupId(),
                                                tableId);

                                releasePhysicalTable(
                                                c,
                                                tableId);

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

        /*
         * =====================================================
         * RELEASE WHOLE GROUP
         * =====================================================
         */

        public boolean releaseWholeGroupIfMember(
                        long tableId) throws SQLException {

                if (tableId <= 0) {
                        throw new IllegalArgumentException(
                                        "Bàn không hợp lệ");
                }

                try (Connection c = DBContext.getConnection()) {

                        c.setAutoCommit(false);

                        try {

                                GroupInfo group = findActiveGroupByTable(
                                                c,
                                                tableId);

                                if (group == null) {

                                        c.commit();

                                        return false;
                                }

                                List<Long> memberIds = findActiveMemberIds(
                                                c,
                                                group.groupId());

                                if (memberIds.isEmpty()) {
                                        throw new IllegalStateException(
                                                        "Nhóm bàn không còn bàn hoạt động");
                                }

                                tableDAO.findByIds(
                                                c,
                                                memberIds,
                                                true);

                                validateAnchorHasNoOpenOrder(
                                                c,
                                                group.anchorTableId());

                                try (PreparedStatement ps = c.prepareStatement(

                                                "UPDATE walk_in_group_tables " +
                                                                "SET active=0 " +
                                                                "WHERE walk_in_group_id=? " +
                                                                "AND active=1")) {

                                        ps.setLong(
                                                        1,
                                                        group.groupId());

                                        ps.executeUpdate();
                                }

                                String placeholders = String.join(
                                                ",",
                                                Collections.nCopies(
                                                                memberIds.size(),
                                                                "?"));

                                try (PreparedStatement ps = c.prepareStatement(

                                                "UPDATE restaurant_tables " +
                                                                "SET status='AVAILABLE' " +
                                                                "WHERE table_id IN (" +
                                                                placeholders +
                                                                ")")) {

                                        bindIds(
                                                        ps,
                                                        memberIds);

                                        ps.executeUpdate();
                                }

                                closeGroup(
                                                c,
                                                group.groupId());

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

        /*
         * =====================================================
         * FIND ACTIVE GROUP
         * =====================================================
         */

        private GroupInfo findActiveGroupByTable(
                        Connection c,
                        long tableId) throws SQLException {

                String sql = "SELECT TOP 1 " +
                                "wg.walk_in_group_id, " +
                                "wg.anchor_table_id " +

                                "FROM walk_in_groups wg " +

                                "JOIN walk_in_group_tables wgt " +
                                "ON wgt.walk_in_group_id=" +
                                "wg.walk_in_group_id " +

                                "WHERE wgt.table_id=? " +
                                "AND wgt.active=1 " +
                                "AND wg.status='ACTIVE' " +

                                "ORDER BY wg.walk_in_group_id DESC";

                try (PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        tableId);

                        try (ResultSet rs = ps.executeQuery()) {

                                if (!rs.next()) {
                                        return null;
                                }

                                return new GroupInfo(
                                                rs.getLong(
                                                                "walk_in_group_id"),
                                                rs.getLong(
                                                                "anchor_table_id"));
                        }
                }
        }

        /*
         * =====================================================
         * ACTIVE MEMBER IDS
         * =====================================================
         */

        private List<Long> findActiveMemberIds(
                        Connection c,
                        long groupId) throws SQLException {

                List<Long> ids = new ArrayList<>();

                String sql = "SELECT table_id " +

                                "FROM walk_in_group_tables " +

                                "WHERE walk_in_group_id=? " +
                                "AND active=1 " +

                                "ORDER BY table_id";

                try (PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        groupId);

                        try (ResultSet rs = ps.executeQuery()) {

                                while (rs.next()) {

                                        ids.add(
                                                        rs.getLong(
                                                                        "table_id"));
                                }
                        }
                }

                return ids;
        }

        /*
         * =====================================================
         * CHOOSE NEW ANCHOR
         * =====================================================
         */

        private long chooseNewAnchor(
                        List<Long> memberIds,
                        long leavingTableId) {

                for (Long id : memberIds) {

                        if (id != leavingTableId) {
                                return id;
                        }
                }

                throw new IllegalStateException(
                                "Không tìm được bàn anchor mới");
        }

        /*
         * =====================================================
         * MOVE OPEN ORDER
         * =====================================================
         */

        private void moveOpenOrderToNewAnchor(
                        Connection c,
                        long oldAnchorId,
                        long newAnchorId) throws SQLException {

                String sql = "UPDATE orders " +
                                "SET table_id=? " +
                                "WHERE table_id=? " +
                                "AND reservation_id IS NULL " +
                                "AND order_status='OPEN'";

                try (PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        newAnchorId);

                        ps.setLong(
                                        2,
                                        oldAnchorId);

                        ps.executeUpdate();
                }
        }

        /*
         * =====================================================
         * UPDATE GROUP ANCHOR
         * =====================================================
         */

        private void updateGroupAnchor(
                        Connection c,
                        long groupId,
                        long newAnchorId) throws SQLException {

                String sql = "UPDATE walk_in_groups " +
                                "SET anchor_table_id=? " +
                                "WHERE walk_in_group_id=? " +
                                "AND status='ACTIVE'";

                try (PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        newAnchorId);

                        ps.setLong(
                                        2,
                                        groupId);

                        if (ps.executeUpdate() != 1) {
                                throw new IllegalStateException(
                                                "Không thể chuyển bàn chính của nhóm");
                        }
                }
        }

        /*
         * =====================================================
         * DEACTIVATE MEMBER
         * =====================================================
         */

        private void deactivateSingleMember(
                        Connection c,
                        long groupId,
                        long tableId) throws SQLException {

                String sql = "UPDATE walk_in_group_tables " +
                                "SET active=0 " +
                                "WHERE walk_in_group_id=? " +
                                "AND table_id=? " +
                                "AND active=1";

                try (PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        groupId);

                        ps.setLong(
                                        2,
                                        tableId);

                        if (ps.executeUpdate() != 1) {
                                throw new IllegalStateException(
                                                "Bàn đã được trả trước đó");
                        }
                }
        }

        /*
         * =====================================================
         * RELEASE PHYSICAL TABLE
         * =====================================================
         */

        private void releasePhysicalTable(
                        Connection c,
                        long tableId) throws SQLException {

                String sql = "UPDATE restaurant_tables " +
                                "SET status='AVAILABLE' " +
                                "WHERE table_id=?";

                try (PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        tableId);

                        ps.executeUpdate();
                }
        }

        /*
         * =====================================================
         * CLOSE GROUP
         * =====================================================
         */

        private void closeGroup(
                        Connection c,
                        long groupId) throws SQLException {

                String sql = "UPDATE walk_in_groups " +
                                "SET " +
                                "status='CLOSED'," +
                                "closed_at=SYSDATETIME() " +
                                "WHERE walk_in_group_id=? " +
                                "AND status='ACTIVE'";

                try (PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        groupId);

                        if (ps.executeUpdate() != 1) {
                                throw new IllegalStateException(
                                                "Không thể đóng nhóm bàn");
                        }
                }
        }

        /*
         * =====================================================
         * VALIDATE OPEN ORDER OF ANCHOR
         * =====================================================
         */

        private void validateAnchorHasNoOpenOrder(
                        Connection c,
                        long anchorTableId) throws SQLException {

                String sql = "SELECT TOP 1 order_id " +

                                "FROM orders " +

                                "WHERE table_id=? " +
                                "AND reservation_id IS NULL " +
                                "AND order_status='OPEN'";

                try (PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        anchorTableId);

                        try (ResultSet rs = ps.executeQuery()) {

                                if (rs.next()) {

                                        throw new IllegalStateException(
                                                        "Nhóm bàn vẫn còn đơn hàng mở #"
                                                                        + rs.getLong(
                                                                                        "order_id")
                                                                        + ". Vui lòng thanh toán "
                                                                        + "hoặc đóng đơn trước.");
                                }
                        }
                }
        }

        /*
         * =====================================================
         * VALIDATE NEW ANCHOR
         * =====================================================
         */

        private void validateNoOpenWalkInOrderOnTable(
                        Connection c,
                        long tableId) throws SQLException {

                String sql = "SELECT TOP 1 order_id " +

                                "FROM orders " +

                                "WHERE table_id=? " +
                                "AND reservation_id IS NULL " +
                                "AND order_status='OPEN'";

                try (PreparedStatement ps = c.prepareStatement(sql)) {

                        ps.setLong(
                                        1,
                                        tableId);

                        try (ResultSet rs = ps.executeQuery()) {

                                if (rs.next()) {

                                        throw new IllegalStateException(
                                                        "Bàn anchor mới đang có OPEN Order #"
                                                                        + rs.getLong(
                                                                                        "order_id"));
                                }
                        }
                }
        }

        /*
         * =====================================================
         * VALIDATE ACTIVE GROUP
         * =====================================================
         */

        private void validateNoActiveGroup(
                        Connection c,
                        List<Long> tableIds) throws SQLException {

                String placeholders = String.join(
                                ",",
                                Collections.nCopies(
                                                tableIds.size(),
                                                "?"));

                String sql = "SELECT TOP 1 t.table_number " +

                                "FROM walk_in_group_tables wgt " +

                                "JOIN walk_in_groups wg " +
                                "ON wg.walk_in_group_id=" +
                                "wgt.walk_in_group_id " +

                                "JOIN restaurant_tables t " +
                                "ON t.table_id=wgt.table_id " +

                                "WHERE wgt.table_id IN (" +
                                placeholders +
                                ") " +

                                "AND wgt.active=1 " +
                                "AND wg.status='ACTIVE'";

                try (PreparedStatement ps = c.prepareStatement(sql)) {

                        bindIds(
                                        ps,
                                        tableIds);

                        try (ResultSet rs = ps.executeQuery()) {

                                if (rs.next()) {

                                        throw new IllegalStateException(
                                                        "Bàn "
                                                                        + rs.getString(
                                                                                        "table_number")
                                                                        + " đã thuộc một nhóm walk-in khác");
                                }
                        }
                }
        }

        /*
         * =====================================================
         * VALIDATE OPEN ORDER BEFORE GROUPING
         * =====================================================
         */

        private void validateNoOpenWalkInOrder(
                        Connection c,
                        List<Long> tableIds) throws SQLException {

                String placeholders = String.join(
                                ",",
                                Collections.nCopies(
                                                tableIds.size(),
                                                "?"));

                String sql = "SELECT TOP 1 t.table_number " +

                                "FROM orders o " +

                                "JOIN restaurant_tables t " +
                                "ON t.table_id=o.table_id " +

                                "WHERE o.table_id IN (" +
                                placeholders +
                                ") " +

                                "AND o.reservation_id IS NULL " +
                                "AND o.order_status='OPEN'";

                try (PreparedStatement ps = c.prepareStatement(sql)) {

                        bindIds(
                                        ps,
                                        tableIds);

                        try (ResultSet rs = ps.executeQuery()) {

                                if (rs.next()) {

                                        throw new IllegalStateException(
                                                        "Bàn "
                                                                        + rs.getString(
                                                                                        "table_number")
                                                                        + " đang có đơn hàng mở, "
                                                                        + "không thể gộp bàn");
                                }
                        }
                }
        }

        /*
         * =====================================================
         * PARSE IDS
         * =====================================================
         */

        private List<Long> parseTableIds(
                        String[] rawTableIds) {

                if (rawTableIds == null) {
                        return new ArrayList<>();
                }

                Set<Long> uniqueIds = new LinkedHashSet<>();

                for (String raw : rawTableIds) {

                        if (raw == null
                                        || raw.isBlank()) {
                                continue;
                        }

                        try {

                                long id = Long.parseLong(
                                                raw.trim());

                                if (id <= 0) {
                                        throw new NumberFormatException();
                                }

                                uniqueIds.add(id);

                        } catch (NumberFormatException e) {

                                throw new IllegalArgumentException(
                                                "Danh sách bàn không hợp lệ");
                        }
                }

                return new ArrayList<>(
                                uniqueIds);
        }

        /*
         * =====================================================
         * BIND IDS
         * =====================================================
         */

        private void bindIds(
                        PreparedStatement ps,
                        List<Long> ids) throws SQLException {

                for (int i = 0; i < ids.size(); i++) {

                        ps.setLong(
                                        i + 1,
                                        ids.get(i));
                }
        }

        /*
         * =====================================================
         * WRAP
         * =====================================================
         */

        private SQLException wrap(
                        Exception e) {

                if (e instanceof SQLException se) {
                        return se;
                }

                return new SQLException(
                                e.getMessage(),
                                e);
        }

        private record GroupInfo(
                        long groupId,
                        long anchorTableId) {
        }
}