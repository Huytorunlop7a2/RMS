package com.fpt.rms.service;

import com.fpt.rms.dao.OpeningHourDAO;
import com.fpt.rms.dao.ReservationDAO;
import com.fpt.rms.dao.TableDAO;
import com.fpt.rms.dao.TableLayoutDAO;
import com.fpt.rms.model.OpeningHour;
import com.fpt.rms.model.RestaurantTable;
import com.fpt.rms.model.TableCandidate;
import com.fpt.rms.model.TableLayout;
import com.fpt.rms.util.DBContext;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

import java.util.stream.Collectors;

public class ReservationService {
    private static final int RESERVATION_HOURS = 2;
    private static final int MAX_MERGED_TABLES = 8;
    private static final int MAX_SUGGESTIONS = 8;
    private static final int MAX_SEARCH_STATES_PER_AREA = 25000;
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm");
    private static final Comparator<TableCandidate> CANDIDATE_COMPARATOR = Comparator
            .comparingInt(TableCandidate::getWaste).thenComparingInt(TableCandidate::getTableCount)
            .thenComparing(TableCandidate::getTableDisplay);
    private final ReservationDAO reservationDAO = new ReservationDAO();
    private final TableDAO tableDAO = new TableDAO();
    private final TableLayoutDAO layoutDAO = new TableLayoutDAO();
    private final OpeningHourDAO openingHourDAO = new OpeningHourDAO();

    public List<TableCandidate> suggestTables(LocalDate date, LocalTime start, int partySize) throws SQLException {
        LocalTime end = validateBasicSearch(date, start, partySize);
        OpeningHour openingHour = openingHourDAO.findByDate(date);
        validateOpeningHours(openingHour, start, end);
        Set<Long> busyTableIds = reservationDAO.findBusyTableIds(date, start, end);
        List<RestaurantTable> activeTables = tableDAO.findActive();
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime requestedStart = LocalDateTime.of(date, start);
        LocalDateTime requestedEnd = requestedStart.plusHours(RESERVATION_HOURS);
        boolean intervalContainsNow = !now.isBefore(requestedStart) && now.isBefore(requestedEnd);
        if (intervalContainsNow) {
            for (RestaurantTable table : activeTables) {
                if ("OCCUPIED".equals(table.getStatus())) {
                    busyTableIds.add(table.getTableId());
                }
            }
        }
        Map<Long, RestaurantTable> availableTables = new HashMap<>();
        List<TableCandidate> candidates = new ArrayList<>();
        for (RestaurantTable table : activeTables) {
            if (busyTableIds.contains(table.getTableId())) {
                continue;
            }
            availableTables.put(table.getTableId(), table);
            if (table.getCapacity() >= partySize) {
                TableCandidate candidate = createCandidate(List.of(table), partySize);
                addTopCandidate(candidates, candidate);
            }
        }
        List<TableLayout> availableLayouts = new ArrayList<>();
        for (TableLayout layout : layoutDAO.findAll()) {
            if (layout.isMergeEnabled() && availableTables.containsKey(layout.getTableId())) {
                availableLayouts.add(layout);
            }
        }
        generateConnectedCandidates(availableLayouts, availableTables, partySize, candidates);
        candidates.sort(CANDIDATE_COMPARATOR);
        return candidates;
    }

    private LocalTime validateBasicSearch(LocalDate date, LocalTime start, int partySize) {
        if (date == null || start == null) {
            throw new IllegalArgumentException("Ngày và giờ đặt bàn không được để trống");
        }
        if (partySize < 1) {
            throw new IllegalArgumentException("Số khách phải lớn hơn 0");
        }
        LocalDateTime startDateTime = LocalDateTime.of(date, start);
        if (startDateTime.isBefore(LocalDateTime.now().minusMinutes(1))) {
            throw new IllegalArgumentException("Không thể đặt bàn ở thời điểm đã qua");
        }
        LocalDateTime endDateTime = startDateTime.plusHours(RESERVATION_HOURS);
        if (!endDateTime.toLocalDate().equals(date)) {
            throw new IllegalArgumentException("Hiện hệ thống chưa hỗ trợ " + "đặt bàn kéo dài qua ngày hôm sau");
        }
        return endDateTime.toLocalTime();
    }

    private void validateOpeningHours(OpeningHour openingHour, LocalTime start, LocalTime end) {
        if (openingHour == null) {
            throw new IllegalStateException("Ngày này chưa được cấu hình " + "giờ hoạt động");
        }
        if (openingHour.isClosed()) {
            String reason = openingHour.getReason() == null || openingHour.getReason().isBlank() ? ""
                    : " - " + openingHour.getReason();
            throw new IllegalStateException(openingHour.getDayName() + " nhà hàng đóng cửa cả ngày" + reason);
        }
        LocalTime openTime = openingHour.getOpenTime();
        LocalTime closeTime = openingHour.getCloseTime();
        if (openTime == null || closeTime == null) {
            throw new IllegalStateException("Giờ hoạt động của " + openingHour.getDayName() + " chưa hợp lệ");
        }
        if (start.isBefore(openTime) || end.isAfter(closeTime)) {
            throw new IllegalArgumentException("Nhà hàng hoạt động từ " + openTime.format(TIME_FORMAT) + " đến "
                    + closeTime.format(TIME_FORMAT) + ". Lượt đặt bàn " + RESERVATION_HOURS + " giờ phải nằm hoàn toàn "
                    + "trong giờ hoạt động.");
        }
    }

    private void generateConnectedCandidates(List<TableLayout> layouts, Map<Long, RestaurantTable> availableTables,
            int partySize, List<TableCandidate> candidates) throws SQLException {
        Map<String, List<TableLayout>> areas = new LinkedHashMap<>();
        for (TableLayout layout : layouts) {
            areas.computeIfAbsent(layout.getAreaCode(), key -> new ArrayList<>()).add(layout);
        }
        for (List<TableLayout> areaLayouts : areas.values()) {
            Map<Long, Set<Long>> graph = layoutDAO.buildMergeGraph(areaLayouts);
            List<Long> startIds = new ArrayList<>(graph.keySet());
            startIds.sort(Comparator.comparingLong(Long::longValue));
            Set<String> exploredGroups = new HashSet<>();
            int[] exploredCount = { 0 };
            for (Long startId : startIds) {
                if (exploredCount[0] >= MAX_SEARCH_STATES_PER_AREA) {
                    break;
                }
                if (!availableTables.containsKey(startId)) {
                    continue;
                }
                LinkedHashSet<Long> group = new LinkedHashSet<>();
                group.add(startId);
                exploreConnectedGroup(group, graph, availableTables, partySize, candidates, exploredGroups,
                        exploredCount);
            }
        }
    }

    private void exploreConnectedGroup(LinkedHashSet<Long> group, Map<Long, Set<Long>> graph,
            Map<Long, RestaurantTable> availableTables, int partySize, List<TableCandidate> candidates,
            Set<String> exploredGroups, int[] exploredCount) {
        if (exploredCount[0] >= MAX_SEARCH_STATES_PER_AREA) {
            return;
        }
        String groupKey = createIdGroupKey(group);
        if (!exploredGroups.add(groupKey)) {
            return;
        }
        exploredCount[0]++;
        int totalCapacity = calculateCapacity(group, availableTables);
        if (group.size() >= 2 && totalCapacity >= partySize) {
            List<RestaurantTable> tables = toRestaurantTables(group, availableTables);
            TableCandidate candidate = createCandidate(tables, partySize);
            addTopCandidate(candidates, candidate);
            return;
        }
        if (group.size() >= MAX_MERGED_TABLES) {
            return;
        }
        TreeSet<Long> frontier = new TreeSet<>();
        for (Long tableId : group) {
            frontier.addAll(graph.getOrDefault(tableId, Set.of()));
        }
        frontier.removeAll(group);
        for (Long neighborId : frontier) {
            if (exploredCount[0] >= MAX_SEARCH_STATES_PER_AREA) {
                return;
            }
            if (!availableTables.containsKey(neighborId)) {
                continue;
            }
            LinkedHashSet<Long> expandedGroup = new LinkedHashSet<>(group);
            expandedGroup.add(neighborId);
            exploreConnectedGroup(expandedGroup, graph, availableTables, partySize, candidates, exploredGroups,
                    exploredCount);
        }
    }

    private int calculateCapacity(Set<Long> group, Map<Long, RestaurantTable> availableTables) {
        int total = 0;
        for (Long id : group) {
            RestaurantTable table = availableTables.get(id);
            if (table != null) {
                total += table.getCapacity();
            }
        }
        return total;
    }

    private List<RestaurantTable> toRestaurantTables(Set<Long> group, Map<Long, RestaurantTable> availableTables) {
        List<RestaurantTable> tables = new ArrayList<>();
        for (Long id : group) {
            RestaurantTable table = availableTables.get(id);
            if (table != null) {
                tables.add(table);
            }
        }
        tables.sort(Comparator.comparing(RestaurantTable::getTableNumber));
        return tables;
    }

    private String createIdGroupKey(Set<Long> group) {
        return group.stream().sorted().map(String::valueOf).collect(Collectors.joining(","));
    }

    private TableCandidate createCandidate(List<RestaurantTable> inputTables, int partySize) {
        List<RestaurantTable> tables = new ArrayList<>(inputTables);
        tables.sort(Comparator.comparing(RestaurantTable::getTableNumber));
        int capacity = tables.stream().mapToInt(RestaurantTable::getCapacity).sum();
        TableCandidate candidate = new TableCandidate();
        candidate.setTables(tables);
        String candidateKey = tables.stream().map(RestaurantTable::getTableId).sorted().map(String::valueOf)
                .collect(Collectors.joining(","));
        candidate.setCandidateKey(candidateKey);
        if (tables.size() == 1) {
            candidate.setName("Bàn " + tables.get(0).getTableNumber());
        } else {
            String tableNames = tables.stream().map(RestaurantTable::getTableNumber).collect(Collectors.joining(" + "));
            candidate.setName("Ghép " + tableNames);
        }
        candidate.setTotalCapacity(capacity);
        candidate.setWaste(capacity - partySize);
        candidate.setPriority(0);
        return candidate;
    }

    private void addTopCandidate(List<TableCandidate> candidates, TableCandidate candidate) {
        candidates.add(candidate);
        candidates.sort(CANDIDATE_COMPARATOR);
        if (candidates.size() > MAX_SUGGESTIONS) {
            candidates.subList(MAX_SUGGESTIONS, candidates.size()).clear();
        }
    }

    public long confirmReservation(String customerName, String phoneNumber, LocalDate date, LocalTime start,
            int partySize, String selectedTableIdsCsv, long staffId) throws SQLException {
        LocalTime end = validateBasicSearch(date, start, partySize);
        validateCustomer(customerName, phoneNumber);
        List<Long> selectedIds = parseCsv(selectedTableIdsCsv);
        if (selectedIds.isEmpty()) {
            throw new IllegalArgumentException("Vui lòng chọn một phương án bàn");
        }
        if (selectedIds.size() > MAX_MERGED_TABLES) {
            throw new IllegalStateException("Không được ghép quá " + MAX_MERGED_TABLES + " bàn");
        }
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                OpeningHour openingHour = openingHourDAO.findByDate(c, date, true);
                validateOpeningHours(openingHour, start, end);
                List<RestaurantTable> tables = tableDAO.findByIds(c, selectedIds, true);
                if (tables.size() != selectedIds.size()) {
                    throw new IllegalStateException("Có bàn không tồn tại");
                }
                for (RestaurantTable table : tables) {
                    if (!table.isActive()) {
                        throw new IllegalStateException("Bàn " + table.getTableNumber() + " đã ngừng sử dụng");
                    }
                }
                if (selectedIds.size() > 1 && !layoutDAO.isValidMergeGroup(c, selectedIds)) {
                    throw new IllegalStateException("Các bàn đã chọn phải tạo thành " + "một cụm liền kề duy nhất "
                            + "theo sơ đồ và quy tắc ghép bàn");
                }
                int totalCapacity = tables.stream().mapToInt(RestaurantTable::getCapacity).sum();
                if (totalCapacity < partySize) {
                    throw new IllegalStateException("Phương án bàn không đủ sức chứa");
                }
                LocalDateTime now = LocalDateTime.now();
                LocalDateTime requestedStart = LocalDateTime.of(date, start);
                LocalDateTime requestedEnd = requestedStart.plusHours(RESERVATION_HOURS);
                boolean intervalContainsNow = !now.isBefore(requestedStart) && now.isBefore(requestedEnd);
                if (intervalContainsNow) {
                    boolean occupied = tables.stream().anyMatch(table -> "OCCUPIED".equals(table.getStatus()));
                    if (occupied) {
                        throw new IllegalStateException("Một hoặc nhiều bàn đang được sử dụng");
                    }
                }
                if (reservationDAO.hasOverlap(c, selectedIds, date, start, end)) {
                    throw new IllegalStateException(
                            "Một hoặc nhiều bàn vừa được " + "đặt bởi reservation khác. " + "Vui lòng chọn lại bàn.");
                }
                long reservationId = reservationDAO.insertReservation(c, selectedIds.get(0), staffId,
                        customerName.trim(), phoneNumber.trim(), date, start, end, partySize);
                reservationDAO.insertReservationTables(c, reservationId, selectedIds);
                c.commit();
                return reservationId;
            } catch (Exception e) {
                c.rollback();
                throw wrap(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    private void validateCustomer(String customerName, String phoneNumber) {
        if (customerName == null || customerName.isBlank()) {
            throw new IllegalArgumentException("Tên khách không được để trống");
        }
        if (!customerName.trim().matches("[\\p{L} ]+")) {
        throw new IllegalArgumentException("Tên khách hàng chỉ được chứa chữ cái và khoảng trắng");
        }
        if (phoneNumber == null || phoneNumber.isBlank()) {
            throw new IllegalArgumentException("Số điện thoại không được để trống");
        }
        if (!phoneNumber.trim().matches("[0-9+ .()-]{8,20}")) {
            throw new IllegalArgumentException("Số điện thoại không hợp lệ");
        }
    }

    private List<Long> parseCsv(String csv) {
        if (csv == null || csv.isBlank()) {
            return new ArrayList<>();
        }
        TreeSet<Long> ids = new TreeSet<>();
        for (String part : csv.split(",")) {
            try {
                String value = part.trim();
                if (value.isBlank()) {
                    continue;
                }
                long id = Long.parseLong(value);
                if (id <= 0) {
                    throw new NumberFormatException();
                }
                ids.add(id);
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException("Phương án bàn không hợp lệ");
            }
        }
        return new ArrayList<>(ids);
    }

    private SQLException wrap(Exception e) {
        if (e instanceof SQLException se) {
            return se;
        }
        return new SQLException(e.getMessage(), e);
    }
}
