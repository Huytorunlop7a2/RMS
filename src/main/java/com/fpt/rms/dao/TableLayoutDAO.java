package com.fpt.rms.dao;

import com.fpt.rms.model.TableAdjacencyOverride;
import com.fpt.rms.model.TableLayout;
import com.fpt.rms.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Queue;
import java.util.Set;

public class TableLayoutDAO {

        public List<TableLayout> findAll() throws SQLException {
                String sql = "SELECT " +
                                "l.table_id," +
                                "t.table_number," +
                                "l.area_code," +
                                "l.row_no," +
                                "l.position_no," +
                                "l.merge_enabled " +
                                "FROM table_layouts l " +
                                "JOIN restaurant_tables t " +
                                "ON t.table_id=l.table_id " +
                                "ORDER BY " +
                                "l.area_code," +
                                "l.row_no," +
                                "l.position_no";
                List<TableLayout> list = new ArrayList<>();
                try (
                                Connection c = DBContext.getConnection();
                                PreparedStatement ps = c.prepareStatement(sql);
                                ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                                list.add(map(rs));
                        }
                }
                return list;
        }

        public Map<Long, Set<Long>> buildMergeGraph(List<TableLayout> layouts) throws SQLException {
                try (
                                Connection c = DBContext.getConnection()) {
                        return buildMergeGraph(c, layouts);
                }
        }

        private Map<Long, Set<Long>> buildMergeGraph(Connection c, List<TableLayout> layouts) throws SQLException {
                Map<Long, Set<Long>> graph = new HashMap<>();
                Map<Long, TableLayout> layoutById = new HashMap<>();
                Map<String, TableLayout> coordinateMap = new HashMap<>();
                for (TableLayout layout : layouts) {
                        graph.put(layout.getTableId(), new HashSet<>());
                        layoutById.put(layout.getTableId(), layout);
                        coordinateMap.put(
                                        coordinateKey(layout.getAreaCode(), layout.getRowNo(), layout.getPositionNo()),
                                        layout);
                }
                int[][] directions = {
                                { 0, 1 },
                                { 0, -1 },
                                { 1, 0 },
                                { -1, 0 }
                };
                for (TableLayout layout : layouts) {
                        if (!layout.isMergeEnabled()) {
                                continue;
                        }
                        for (int[] direction : directions) {
                                TableLayout neighbor = coordinateMap.get(
                                                coordinateKey(layout.getAreaCode(), layout.getRowNo() + direction[0],
                                                                layout.getPositionNo() + direction[1]));
                                if (neighbor == null || !neighbor.isMergeEnabled()) {
                                        continue;
                                }
                                addEdge(graph, layout.getTableId(), neighbor.getTableId());
                        }
                }
                String overrideSql = "SELECT " +
                                "table_id_1," +
                                "table_id_2," +
                                "allowed " +
                                "FROM table_adjacency_overrides";
                try (
                                PreparedStatement ps = c.prepareStatement(overrideSql);
                                ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                                long id1 = rs.getLong("table_id_1");
                                long id2 = rs.getLong("table_id_2");
                                boolean allowed = rs.getBoolean("allowed");
                                if (!graph.containsKey(id1) || !graph.containsKey(id2)) {
                                        continue;
                                }
                                TableLayout layout1 = layoutById.get(id1);
                                TableLayout layout2 = layoutById.get(id2);
                                if (layout1 == null || layout2 == null) {
                                        continue;
                                }
                                if (!Objects.equals(layout1.getAreaCode(), layout2.getAreaCode())) {
                                        continue;
                                }
                                if (allowed) {
                                        if (layout1.isMergeEnabled() && layout2.isMergeEnabled()) {
                                                addEdge(graph, id1, id2);
                                        }
                                } else {
                                        removeEdge(graph, id1, id2);
                                }
                        }
                }
                return graph;
        }

        public Map<Long, TableLayout> findAllAsMap()
                        throws SQLException {

                Map<Long, TableLayout> result = new HashMap<>();

                for (TableLayout layout : findAll()) {

                        result.put(
                                        layout.getTableId(),
                                        layout);
                }

                return result;
        }

        public List<TableLayout> findByTableIds(
                        Connection c,
                        List<Long> tableIds) throws SQLException {

                if (tableIds == null
                                ||
                                tableIds.isEmpty()) {

                        return new ArrayList<>();
                }

                String placeholders = String.join(
                                ",",
                                Collections.nCopies(
                                                tableIds.size(),
                                                "?"));

                String sql = "SELECT " +
                                "l.table_id," +
                                "t.table_number," +
                                "l.area_code," +
                                "l.row_no," +
                                "l.position_no," +
                                "l.merge_enabled " +

                                "FROM table_layouts l " +

                                "JOIN restaurant_tables t " +
                                "ON t.table_id=l.table_id " +

                                "WHERE l.table_id IN (" +
                                placeholders +
                                ")";

                List<TableLayout> list = new ArrayList<>();

                try (
                                PreparedStatement ps = c.prepareStatement(sql)) {

                        for (int i = 0; i < tableIds.size(); i++) {

                                ps.setLong(
                                                i + 1,
                                                tableIds.get(i));
                        }

                        try (
                                        ResultSet rs = ps.executeQuery()) {

                                while (rs.next()) {

                                        list.add(
                                                        map(
                                                                        rs));
                                }
                        }
                }

                return list;
        }

        public List<TableAdjacencyOverride> findAllOverrides()
                        throws SQLException {

                String sql = "SELECT " +
                                "a.table_id_1," +
                                "t1.table_number AS table_number_1," +
                                "a.table_id_2," +
                                "t2.table_number AS table_number_2," +
                                "a.allowed " +

                                "FROM table_adjacency_overrides a " +

                                "JOIN restaurant_tables t1 " +
                                "ON t1.table_id=a.table_id_1 " +

                                "JOIN restaurant_tables t2 " +
                                "ON t2.table_id=a.table_id_2 " +

                                "ORDER BY " +
                                "t1.table_number," +
                                "t2.table_number";

                List<TableAdjacencyOverride> list = new ArrayList<>();

                try (
                                Connection c = DBContext.getConnection();

                                PreparedStatement ps = c.prepareStatement(
                                                sql);

                                ResultSet rs = ps.executeQuery()) {

                        while (rs.next()) {

                                TableAdjacencyOverride rule = new TableAdjacencyOverride();

                                rule.setTableId1(
                                                rs.getLong(
                                                                "table_id_1"));

                                rule.setTableNumber1(
                                                rs.getString(
                                                                "table_number_1"));

                                rule.setTableId2(
                                                rs.getLong(
                                                                "table_id_2"));

                                rule.setTableNumber2(
                                                rs.getString(
                                                                "table_number_2"));

                                rule.setAllowed(
                                                rs.getBoolean(
                                                                "allowed"));

                                list.add(
                                                rule);
                        }
                }

                return list;
        }

        public void saveRow(
                        String areaCode,
                        int rowNo,
                        String tableNumbers) throws SQLException {

                if (areaCode == null
                                ||
                                areaCode.isBlank()) {

                        throw new IllegalArgumentException(
                                        "Khu vực không được để trống");
                }

                if (rowNo < 1) {

                        throw new IllegalArgumentException(
                                        "Số hàng phải lớn hơn 0");
                }

                List<String> numbers = parseTableNumbers(
                                tableNumbers);

                if (numbers.size() < 2) {

                        throw new IllegalArgumentException(
                                        "Một hàng phải có ít nhất 2 bàn");
                }

                try (
                                Connection c = DBContext.getConnection()) {

                        c.setAutoCommit(
                                        false);

                        try {

                                List<Long> tableIds = findTableIds(
                                                c,
                                                numbers);

                                if (tableIds.size() != numbers.size()) {

                                        throw new IllegalArgumentException(
                                                        "Có số bàn không tồn tại");
                                }

                                String normalizedArea = areaCode
                                                .trim()
                                                .toUpperCase();

                                List<Long> oldRowIds = findRowTableIds(
                                                c,
                                                normalizedArea,
                                                rowNo);

                                Set<Long> affectedIds = new HashSet<>();

                                affectedIds.addAll(
                                                oldRowIds);

                                affectedIds.addAll(
                                                tableIds);

                                /*
                                 * Layout thay đổi thì các override liên quan
                                 * đến những bàn này có thể không còn đúng.
                                 *
                                 * Vì vậy xóa rule cũ để Manager cấu hình lại.
                                 */
                                deleteOverridesForTables(
                                                c,
                                                new ArrayList<>(
                                                                affectedIds));

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                "DELETE FROM table_layouts " +
                                                                                "WHERE area_code=? " +
                                                                                "AND row_no=?")) {

                                        ps.setString(
                                                        1,
                                                        normalizedArea);

                                        ps.setInt(
                                                        2,
                                                        rowNo);

                                        ps.executeUpdate();
                                }

                                String placeholders = String.join(
                                                ",",
                                                Collections.nCopies(
                                                                tableIds.size(),
                                                                "?"));

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                "DELETE FROM table_layouts " +
                                                                                "WHERE table_id IN (" +
                                                                                placeholders +
                                                                                ")")) {

                                        for (int i = 0; i < tableIds.size(); i++) {

                                                ps.setLong(
                                                                i + 1,
                                                                tableIds.get(i));
                                        }

                                        ps.executeUpdate();
                                }

                                String insertSql = "INSERT INTO table_layouts(" +
                                                "table_id," +
                                                "area_code," +
                                                "row_no," +
                                                "position_no," +
                                                "merge_enabled" +
                                                ") " +

                                                "VALUES(?,?,?,?,1)";

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                insertSql)) {

                                        for (int i = 0; i < tableIds.size(); i++) {

                                                ps.setLong(
                                                                1,
                                                                tableIds.get(i));

                                                ps.setString(
                                                                2,
                                                                normalizedArea);

                                                ps.setInt(
                                                                3,
                                                                rowNo);

                                                ps.setInt(
                                                                4,
                                                                i + 1);

                                                ps.addBatch();
                                        }

                                        ps.executeBatch();
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

        public void removeRow(
                        String areaCode,
                        int rowNo) throws SQLException {

                if (areaCode == null
                                ||
                                areaCode.isBlank()) {

                        throw new IllegalArgumentException(
                                        "Khu vực không hợp lệ");
                }

                if (rowNo < 1) {

                        throw new IllegalArgumentException(
                                        "Hàng không hợp lệ");
                }

                try (
                                Connection c = DBContext.getConnection()) {

                        c.setAutoCommit(
                                        false);

                        try {

                                String normalizedArea = areaCode
                                                .trim()
                                                .toUpperCase();

                                List<Long> tableIds = findRowTableIds(
                                                c,
                                                normalizedArea,
                                                rowNo);

                                deleteOverridesForTables(
                                                c,
                                                tableIds);

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                "DELETE FROM table_layouts " +
                                                                                "WHERE area_code=? " +
                                                                                "AND row_no=?")) {

                                        ps.setString(
                                                        1,
                                                        normalizedArea);

                                        ps.setInt(
                                                        2,
                                                        rowNo);

                                        ps.executeUpdate();
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

        public void saveAdjacencyOverride(
                        String tableNumber1,
                        String tableNumber2,
                        boolean allowed) throws SQLException {

                String number1 = normalizeTableNumber(
                                tableNumber1);

                String number2 = normalizeTableNumber(
                                tableNumber2);

                if (number1.equals(
                                number2)) {

                        throw new IllegalArgumentException(
                                        "Phải chọn hai bàn khác nhau");
                }

                try (
                                Connection c = DBContext.getConnection()) {

                        c.setAutoCommit(
                                        false);

                        try {

                                TableLayout layout1 = findLayoutByTableNumber(
                                                c,
                                                number1);

                                TableLayout layout2 = findLayoutByTableNumber(
                                                c,
                                                number2);

                                if (layout1 == null
                                                ||
                                                layout2 == null) {

                                        throw new IllegalArgumentException(
                                                        "Cả hai bàn phải được cấu hình trong sơ đồ bàn");
                                }

                                if (!Objects.equals(
                                                layout1.getAreaCode(),
                                                layout2.getAreaCode())) {

                                        throw new IllegalArgumentException(
                                                        "Chỉ có thể cấu hình liên kết giữa các bàn cùng khu vực");
                                }

                                if (!layout1.isMergeEnabled()
                                                ||
                                                !layout2.isMergeEnabled()) {

                                        throw new IllegalStateException(
                                                        "Có bàn đang bị tắt chức năng ghép");
                                }

                                long id1 = Math.min(
                                                layout1.getTableId(),
                                                layout2.getTableId());

                                long id2 = Math.max(
                                                layout1.getTableId(),
                                                layout2.getTableId());

                                String updateSql = "UPDATE table_adjacency_overrides " +

                                                "SET allowed=? " +

                                                "WHERE " +
                                                "table_id_1=? " +
                                                "AND table_id_2=?";

                                int affected;

                                try (
                                                PreparedStatement ps = c.prepareStatement(
                                                                updateSql)) {

                                        ps.setBoolean(
                                                        1,
                                                        allowed);

                                        ps.setLong(
                                                        2,
                                                        id1);

                                        ps.setLong(
                                                        3,
                                                        id2);

                                        affected = ps.executeUpdate();
                                }

                                if (affected == 0) {

                                        String insertSql = "INSERT INTO table_adjacency_overrides(" +
                                                        "table_id_1," +
                                                        "table_id_2," +
                                                        "allowed" +
                                                        ") " +

                                                        "VALUES(?,?,?)";

                                        try (
                                                        PreparedStatement ps = c.prepareStatement(
                                                                        insertSql)) {

                                                ps.setLong(
                                                                1,
                                                                id1);

                                                ps.setLong(
                                                                2,
                                                                id2);

                                                ps.setBoolean(
                                                                3,
                                                                allowed);

                                                ps.executeUpdate();
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

        public void removeAdjacencyOverride(
                        long tableId1,
                        long tableId2) throws SQLException {

                long id1 = Math.min(
                                tableId1,
                                tableId2);

                long id2 = Math.max(
                                tableId1,
                                tableId2);

                if (id1 <= 0
                                ||
                                id2 <= 0
                                ||
                                id1 == id2) {

                        throw new IllegalArgumentException(
                                        "Cặp bàn không hợp lệ");
                }

                try (
                                Connection c = DBContext.getConnection();

                                PreparedStatement ps = c.prepareStatement(
                                                "DELETE FROM table_adjacency_overrides " +
                                                                "WHERE table_id_1=? " +
                                                                "AND table_id_2=?")) {

                        ps.setLong(
                                        1,
                                        id1);

                        ps.setLong(
                                        2,
                                        id2);

                        if (ps.executeUpdate() == 0) {

                                throw new IllegalArgumentException(
                                                "Rule ghép bàn không tồn tại");
                        }
                }
        }

        public boolean isValidMergeGroup(
                        Connection c,
                        List<Long> tableIds) throws SQLException {

                if (tableIds == null
                                ||
                                tableIds.size() < 2) {

                        return false;
                }

                List<TableLayout> layouts = findByTableIds(
                                c,
                                tableIds);

                if (layouts.size() != tableIds.size()) {

                        return false;
                }

                String area = layouts
                                .get(0)
                                .getAreaCode();

                for (TableLayout layout : layouts) {

                        if (!layout.isMergeEnabled()) {

                                return false;
                        }

                        if (!Objects.equals(
                                        area,
                                        layout.getAreaCode())) {

                                return false;
                        }
                }

                Map<Long, Set<Long>> graph = buildMergeGraph(
                                c,
                                layouts);

                long startId = layouts
                                .get(0)
                                .getTableId();

                Set<Long> visited = new HashSet<>();

                Queue<Long> queue = new ArrayDeque<>();

                queue.add(
                                startId);

                visited.add(
                                startId);

                while (!queue.isEmpty()) {

                        long current = queue.poll();

                        for (Long neighbor : graph.getOrDefault(
                                        current,
                                        Collections.emptySet())) {

                                if (visited.add(
                                                neighbor)) {

                                        queue.add(
                                                        neighbor);
                                }
                        }
                }

                return visited.size() == layouts.size();
        }

        private void addEdge(
                        Map<Long, Set<Long>> graph,
                        long id1,
                        long id2) {

                graph.computeIfAbsent(
                                id1,
                                key -> new HashSet<>()).add(
                                                id2);

                graph.computeIfAbsent(
                                id2,
                                key -> new HashSet<>()).add(
                                                id1);
        }

        private void removeEdge(
                        Map<Long, Set<Long>> graph,
                        long id1,
                        long id2) {

                Set<Long> set1 = graph.get(
                                id1);

                if (set1 != null) {

                        set1.remove(
                                        id2);
                }

                Set<Long> set2 = graph.get(
                                id2);

                if (set2 != null) {

                        set2.remove(
                                        id1);
                }
        }

        private TableLayout findLayoutByTableNumber(
                        Connection c,
                        String tableNumber) throws SQLException {

                String sql = "SELECT " +
                                "l.table_id," +
                                "t.table_number," +
                                "l.area_code," +
                                "l.row_no," +
                                "l.position_no," +
                                "l.merge_enabled " +

                                "FROM restaurant_tables t " +

                                "JOIN table_layouts l " +
                                "ON l.table_id=t.table_id " +

                                "WHERE " +
                                "t.table_number=? " +
                                "AND t.active=1";

                try (
                                PreparedStatement ps = c.prepareStatement(
                                                sql)) {

                        ps.setString(
                                        1,
                                        tableNumber);

                        try (
                                        ResultSet rs = ps.executeQuery()) {

                                return rs.next()
                                                ? map(
                                                                rs)
                                                : null;
                        }
                }
        }

        private List<Long> findRowTableIds(
                        Connection c,
                        String areaCode,
                        int rowNo) throws SQLException {

                List<Long> ids = new ArrayList<>();

                try (
                                PreparedStatement ps = c.prepareStatement(
                                                "SELECT table_id " +
                                                                "FROM table_layouts " +
                                                                "WHERE area_code=? " +
                                                                "AND row_no=?")) {

                        ps.setString(
                                        1,
                                        areaCode);

                        ps.setInt(
                                        2,
                                        rowNo);

                        try (
                                        ResultSet rs = ps.executeQuery()) {

                                while (rs.next()) {

                                        ids.add(
                                                        rs.getLong(
                                                                        "table_id"));
                                }
                        }
                }

                return ids;
        }

        private void deleteOverridesForTables(
                        Connection c,
                        List<Long> tableIds) throws SQLException {

                if (tableIds == null
                                ||
                                tableIds.isEmpty()) {

                        return;
                }

                String placeholders = String.join(
                                ",",
                                Collections.nCopies(
                                                tableIds.size(),
                                                "?"));

                String sql = "DELETE FROM table_adjacency_overrides " +

                                "WHERE table_id_1 IN (" +
                                placeholders +
                                ") " +

                                "OR table_id_2 IN (" +
                                placeholders +
                                ")";

                try (
                                PreparedStatement ps = c.prepareStatement(
                                                sql)) {

                        int index = 1;

                        for (Long id : tableIds) {

                                ps.setLong(
                                                index++,
                                                id);
                        }

                        for (Long id : tableIds) {

                                ps.setLong(
                                                index++,
                                                id);
                        }

                        ps.executeUpdate();
                }
        }

        private String coordinateKey(
                        String areaCode,
                        int row,
                        int position) {

                return areaCode
                                + "::"
                                + row
                                + ":"
                                + position;
        }

        private List<Long> findTableIds(
                        Connection c,
                        List<String> tableNumbers) throws SQLException {

                String placeholders = String.join(
                                ",",
                                Collections.nCopies(
                                                tableNumbers.size(),
                                                "?"));

                String sql = "SELECT " +
                                "table_id," +
                                "table_number " +

                                "FROM restaurant_tables " +

                                "WHERE table_number IN (" +
                                placeholders +
                                ")";

                Map<String, Long> idByNumber = new HashMap<>();

                try (
                                PreparedStatement ps = c.prepareStatement(
                                                sql)) {

                        for (int i = 0; i < tableNumbers.size(); i++) {

                                ps.setString(
                                                i + 1,
                                                tableNumbers.get(i));
                        }

                        try (
                                        ResultSet rs = ps.executeQuery()) {

                                while (rs.next()) {

                                        idByNumber.put(
                                                        rs.getString(
                                                                        "table_number").toUpperCase(),

                                                        rs.getLong(
                                                                        "table_id"));
                                }
                        }
                }

                List<Long> result = new ArrayList<>();

                for (String number : tableNumbers) {

                        Long id = idByNumber.get(
                                        number);

                        if (id != null) {

                                result.add(
                                                id);
                        }
                }

                return result;
        }

        private List<String> parseTableNumbers(
                        String value) {

                if (value == null
                                ||
                                value.isBlank()) {

                        return new ArrayList<>();
                }

                LinkedHashSet<String> set = new LinkedHashSet<>();

                for (String part : value.split(",")) {

                        String number = normalizeTableNumber(
                                        part);

                        if (!number.isBlank()) {

                                set.add(
                                                number);
                        }
                }

                return new ArrayList<>(
                                set);
        }

        private String normalizeTableNumber(
                        String value) {

                if (value == null
                                ||
                                value.isBlank()) {

                        throw new IllegalArgumentException(
                                        "Số bàn không được để trống");
                }

                return value
                                .trim()
                                .toUpperCase();
        }

        private TableLayout map(
                        ResultSet rs) throws SQLException {

                TableLayout layout = new TableLayout();

                layout.setTableId(
                                rs.getLong(
                                                "table_id"));

                layout.setTableNumber(
                                rs.getString(
                                                "table_number"));

                layout.setAreaCode(
                                rs.getString(
                                                "area_code"));

                layout.setRowNo(
                                rs.getInt(
                                                "row_no"));

                layout.setPositionNo(
                                rs.getInt(
                                                "position_no"));

                layout.setMergeEnabled(
                                rs.getBoolean(
                                                "merge_enabled"));

                return layout;
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