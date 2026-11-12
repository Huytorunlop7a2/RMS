
package com.fpt.rms.controller;

import com.fpt.rms.dao.ReservationDAO;
import com.fpt.rms.dao.TableDAO;
import com.fpt.rms.dao.WalkInGroupDAO;
import com.fpt.rms.model.Reservation;
import com.fpt.rms.model.Staff;
import com.fpt.rms.model.TableCandidate;
import com.fpt.rms.service.ReservationService;
import com.fpt.rms.dao.OrderDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

import com.fpt.rms.dao.PaymentDAO;

import com.fpt.rms.model.Payment;
import com.fpt.rms.model.RestaurantOrder;
import com.fpt.rms.model.RestaurantTable;

@WebServlet(urlPatterns = { "/receptionist", "/receptionist/*" })
public class ReceptionistServlet extends HttpServlet {

        private final ReservationDAO reservationDAO = new ReservationDAO();
        private final TableDAO tableDAO = new TableDAO();
        private final ReservationService reservationService = new ReservationService();
        private final WalkInGroupDAO walkInGroupDAO = new WalkInGroupDAO();
        private final OrderDAO orderDAO = new OrderDAO();
        private final PaymentDAO paymentDAO = new PaymentDAO();

        @Override
        protected void doGet(
                        HttpServletRequest req,
                        HttpServletResponse resp) throws ServletException, IOException {

                req.setCharacterEncoding("UTF-8");

                consumeFlash(req);

                String path = req.getPathInfo();
                if ("/payment".equals(path)) {
                        try {
                                Staff staff = (Staff) req.getSession().getAttribute("staff");

                                if (staff == null) {
                                        resp.sendError(HttpServletResponse.SC_UNAUTHORIZED);
                                        return;
                                }

                                showReceptionPayment(req, resp);

                        } catch (Exception e) {
                                throw new ServletException(e);
                        }

                        return;
                }

                if ("/reservations/edit".equals(path)) {

                        try {
                                prepareEditPage(req);

                                req.getRequestDispatcher(
                                                "/WEB-INF/views/receptionist/reservation-edit.jsp").forward(req, resp);

                        } catch (Exception e) {

                                req.getSession().setAttribute(
                                                "flashError",
                                                message(e));

                                resp.sendRedirect(
                                                req.getContextPath() + "/receptionist/reservations");
                        }

                        return;
                }

                String page = resolvePage(req);

                if (page == null) {
                        resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                        return;
                }

                if ("reservations".equals(page)) {
                        loadReservationData(req);

                } else if ("create-reservation".equals(page)) {
                        handleReservationSearch(req);

                } else if ("walk-ins".equals(page)) {
                        loadWalkInData(req);

                } else {
                        loadTableStatusData(req);
                }

                String view = switch (page) {
                        case "reservations" ->
                                "/WEB-INF/views/receptionist/reservations.jsp";

                        case "create-reservation" ->
                                "/WEB-INF/views/receptionist/create-reservation.jsp";

                        case "walk-ins" ->
                                "/WEB-INF/views/receptionist/walk-ins.jsp";

                        case "table-status" ->
                                "/WEB-INF/views/receptionist/table-status.jsp";

                        default ->
                                throw new IllegalStateException("Trang không hợp lệ");
                };

                req.getRequestDispatcher(view).forward(req, resp);

        }

        @Override
        protected void doPost(
                        HttpServletRequest req,
                        HttpServletResponse resp) throws IOException {

                req.setCharacterEncoding("UTF-8");
                String path = req.getPathInfo();

                if (path != null && path.startsWith("/payment/")) {
                        handlePaymentPost(req, resp, path);
                        return;
                }

                String action = req.getParameter("action");

                String redirectPath = resolveRedirectPath(action);

                long updatingReservationId = -1;

                try {

                        Staff staff = (Staff) req.getSession()
                                        .getAttribute("staff");

                        if (staff == null) {
                                throw new IllegalStateException(
                                                "Phiên đăng nhập đã hết hạn");
                        }

                        String successMessage;

                        if ("create".equals(action)) {

                                long reservationId = reservationService.confirmReservation(
                                                req.getParameter("customerName"),
                                                req.getParameter("phoneNumber"),
                                                LocalDate.parse(
                                                                req.getParameter("reservationDate")),
                                                LocalTime.parse(
                                                                req.getParameter("startTime")),
                                                Integer.parseInt(
                                                                req.getParameter("partySize")),
                                                req.getParameter("candidateKey"),
                                                staff.getStaffId());

                                successMessage = "Đã tạo reservation #" + reservationId + " thành công";

                        } else if ("update".equals(action)) {

                                updatingReservationId = Long.parseLong(
                                                req.getParameter("id"));

                                reservationService.updateReservation(
                                                updatingReservationId,
                                                req.getParameter("customerName"),
                                                req.getParameter("phoneNumber"),
                                                LocalDate.parse(
                                                                req.getParameter("reservationDate")),
                                                LocalTime.parse(
                                                                req.getParameter("startTime")),
                                                Integer.parseInt(
                                                                req.getParameter("partySize")),
                                                req.getParameter("candidateKey"),
                                                staff.getStaffId(),
                                                req.getParameter("reason"));

                                successMessage = "Đã cập nhật Reservation #"
                                                + updatingReservationId
                                                + " thành công";

                        } else if ("checkin".equals(action)
                                        || "cancel".equals(action)
                                        || "noshow".equals(action)) {

                                long reservationId = Long.parseLong(
                                                req.getParameter("id"));

                                reservationDAO.changeStatus(
                                                reservationId,
                                                action);

                                successMessage = "Đã cập nhật trạng thái đặt bàn";

                        } else if ("createWalkInGroup".equals(action)) {

                                long groupId = walkInGroupDAO.createGroup(
                                                req.getParameterValues("tableIds"),
                                                staff.getStaffId());

                                successMessage = "Đã gộp bàn walk-in thành công. Nhóm #"
                                                + groupId;

                        } else if ("releaseOne".equals(action)
                                        || "release".equals(action)) {

                                long tableId = Long.parseLong(
                                                req.getParameter("id"));

                                boolean walkInMember = walkInGroupDAO.releaseSingleTableIfMember(tableId);

                                boolean reservationMember = false;

                                if (!walkInMember) {
                                        reservationMember = tableDAO.releaseSingleReservationTableIfMember(tableId);
                                }

                                if (!walkInMember && !reservationMember) {
                                        tableDAO.releaseTable(tableId);
                                }

                                successMessage = walkInMember
                                                ? "Đã trả riêng bàn khỏi nhóm walk-in"
                                                : reservationMember
                                                                ? "Đã trả riêng bàn khỏi nhóm Reservation"
                                                                : "Đã trả bàn thành công";

                        } else if ("releaseGroup".equals(action)) {

                                long tableId = Long.parseLong(
                                                req.getParameter("id"));

                                boolean released = walkInGroupDAO.releaseWholeGroupIfMember(tableId);

                                if (!released) {
                                        released = tableDAO.releaseWholeReservationGroupIfMember(tableId);
                                }

                                if (!released) {
                                        throw new IllegalStateException(
                                                        "Bàn này không thuộc nhóm Walk-in hoặc Reservation đang sử dụng");
                                }

                                successMessage = "Đã trả toàn bộ nhóm bàn thành công";

                        } else {

                                throw new IllegalArgumentException(
                                                "Thao tác không hợp lệ");
                        }

                        req.getSession().setAttribute(
                                        "flashSuccess",
                                        successMessage);

                } catch (Exception e) {

                        req.getSession().setAttribute(
                                        "flashError",
                                        message(e));

                        if ("update".equals(action)
                                        && updatingReservationId > 0) {

                                resp.sendRedirect(
                                                req.getContextPath()
                                                                + buildEditRedirect(
                                                                                req,
                                                                                updatingReservationId));

                                return;
                        }
                }

                resp.sendRedirect(
                                req.getContextPath() + redirectPath);
        }

        private void handlePaymentPost(
                        HttpServletRequest req,
                        HttpServletResponse resp,
                        String path) throws IOException {

                String token = req.getParameter("token");

                try {
                        Staff staff = (Staff) req.getSession().getAttribute("staff");

                        if (staff == null) {
                                throw new IllegalStateException("Phiên đăng nhập đã hết hạn");
                        }

                        if (token == null || token.isBlank()) {
                                throw new IllegalArgumentException("Thiếu mã QR bàn");
                        }

                        token = token.trim();

                        RestaurantTable table = tableDAO.findByToken(token);

                        if (table == null) {
                                throw new IllegalArgumentException("Mã QR bàn không hợp lệ");
                        }

                        String serviceToken = walkInGroupDAO.resolveServiceToken(token);

                        long paymentId;

                        if ("/payment/cash".equals(path)
                                        || "/payment/online".equals(path)) {

                                RestaurantOrder order = orderDAO.findOpenOrderByToken(serviceToken);

                                if (order == null) {
                                        throw new IllegalStateException("Không có đơn hàng đang mở");
                                }

                                if (!orderDAO.canPay(order.getOrderId())) {
                                        throw new IllegalStateException(
                                                        "Vẫn còn món chưa được phục vụ");
                                }

                                String method = "/payment/cash".equals(path)
                                                ? "CASH"
                                                : "ONLINE";

                                paymentId = paymentDAO.createPending(
                                                order.getOrderId(),
                                                method);

                                req.getSession().setAttribute(
                                                "flashSuccess",
                                                "Đã tạo yêu cầu thanh toán thành công");

                        } else {

                                paymentId = Long.parseLong(
                                                req.getParameter("paymentId"));

                                if (!paymentDAO.belongsToToken(paymentId, serviceToken)) {
                                        throw new IllegalArgumentException(
                                                        "Thanh toán không thuộc bàn này");
                                }

                                Payment payment = paymentDAO.findById(paymentId);

                                if (payment == null) {
                                        throw new IllegalArgumentException(
                                                        "Không tìm thấy giao dịch");
                                }

                                if ("/payment/cash-confirm".equals(path)) {

                                        if (!"CASH".equals(payment.getPaymentMethod())) {
                                                throw new IllegalStateException(
                                                                "Đây không phải thanh toán tiền mặt");
                                        }

                                        paymentDAO.confirmCash(paymentId);

                                        req.getSession().setAttribute(
                                                        "flashSuccess",
                                                        "Đã xác nhận nhận tiền thành công");

                                } else if ("/payment/online-success".equals(path)) {

                                        paymentDAO.confirmOnline(paymentId);

                                        req.getSession().setAttribute(
                                                        "flashSuccess",
                                                        "Thanh toán trực tuyến thành công");

                                } else if ("/payment/online-fail".equals(path)) {

                                        paymentDAO.failOnline(paymentId);

                                        req.getSession().setAttribute(
                                                        "flashError",
                                                        "Giao dịch thanh toán thất bại");

                                } else {
                                        throw new IllegalArgumentException(
                                                        "Đường dẫn thanh toán không hợp lệ");
                                }
                        }

                        String redirectUrl = req.getContextPath()
                                        + "/receptionist/payment?token="
                                        + URLEncoder.encode(token, StandardCharsets.UTF_8)
                                        + "&paymentId=" + paymentId;

                        resp.sendRedirect(redirectUrl);
                        return;

                } catch (Exception e) {

                        req.getSession().setAttribute(
                                        "flashError",
                                        message(e));

                        String redirectUrl = req.getContextPath()
                                        + "/receptionist/payment?token="
                                        + URLEncoder.encode(
                                                        token == null ? "" : token,
                                                        StandardCharsets.UTF_8);

                        resp.sendRedirect(redirectUrl);
                }
        }

        private void showReceptionPayment(
                        HttpServletRequest req,
                        HttpServletResponse resp) throws Exception {

                String token = req.getParameter("token");

                if (token == null || token.isBlank()) {
                        throw new IllegalArgumentException("Thiếu mã QR bàn");
                }

                token = token.trim();

                RestaurantTable table = tableDAO.findByToken(token);

                if (table == null) {
                        throw new IllegalArgumentException("Mã QR bàn không hợp lệ");
                }

                String serviceToken = walkInGroupDAO.resolveServiceToken(token);

                req.setAttribute("table", table);
                req.setAttribute("token", token);

                String paymentIdValue = req.getParameter("paymentId");
                Payment selectedPayment = null;

                if (paymentIdValue != null && !paymentIdValue.isBlank()) {
                        long paymentId = Long.parseLong(paymentIdValue);

                        selectedPayment = paymentDAO.findById(paymentId);

                        if (selectedPayment != null
                                        && !paymentDAO.belongsToToken(paymentId, serviceToken)) {
                                selectedPayment = null;
                        }
                }

                if (selectedPayment != null
                                && "PAID".equals(selectedPayment.getPaymentStatus())) {

                        req.setAttribute("paidSuccess", true);
                        req.setAttribute("paidPayment", selectedPayment);

                        req.getRequestDispatcher(
                                        "/WEB-INF/views/receptionist/payment.jsp")
                                        .forward(req, resp);

                        return;
                }

                RestaurantOrder order = orderDAO.findOpenOrderByToken(serviceToken);

                if (order == null) {
                        req.setAttribute("noOpenOrder", true);

                        req.getRequestDispatcher(
                                        "/WEB-INF/views/receptionist/payment.jsp")
                                        .forward(req, resp);

                        return;
                }

                req.setAttribute("order", order);
                req.setAttribute("total", orderDAO.total(order.getOrderId()));
                req.setAttribute("canPay", orderDAO.canPay(order.getOrderId()));

                if (selectedPayment == null
                                || selectedPayment.getOrderId() != order.getOrderId()
                                || !"PENDING".equals(selectedPayment.getPaymentStatus())) {

                        selectedPayment = paymentDAO.findPendingByOrder(order.getOrderId());
                }

                req.setAttribute("pendingPayment", selectedPayment);

                req.getRequestDispatcher(
                                "/WEB-INF/views/receptionist/payment.jsp")
                                .forward(req, resp);
        }

        private Reservation prepareReservation(
                        long reservationId) throws Exception {

                return reservationDAO.findById(reservationId);
        }

        private void prepareEditPage(
                        HttpServletRequest req) throws Exception {

                long reservationId = Long.parseLong(
                                req.getParameter("id"));

                Reservation reservation = prepareReservation(reservationId);

                reservationService.ensureEditable(reservation);

                boolean restrictedEdit = reservationService.isRestrictedEdit(reservation);

                LocalDate date = restrictedEdit
                                ? reservation.getReservationDate()
                                : hasText(req.getParameter("reservationDate"))
                                                ? LocalDate.parse(req.getParameter("reservationDate"))
                                                : reservation.getReservationDate();

                LocalTime start = restrictedEdit
                                ? reservation.getStartTime()
                                : hasText(req.getParameter("startTime"))
                                                ? LocalTime.parse(req.getParameter("startTime"))
                                                : reservation.getStartTime();

                int partySize = hasText(req.getParameter("partySize"))
                                ? Integer.parseInt(req.getParameter("partySize"))
                                : reservation.getPartySize();

                String customerName = hasText(req.getParameter("customerName"))
                                ? req.getParameter("customerName")
                                : reservation.getCustomerName();

                String phoneNumber = hasText(req.getParameter("phoneNumber"))
                                ? req.getParameter("phoneNumber")
                                : reservation.getPhoneNumber();

                String reason = req.getParameter("reason");

                List<TableCandidate> suggestions = Collections.emptyList();

                String editSearchError = null;

                try {

                        suggestions = reservationService.suggestTablesForEdit(
                                        date,
                                        start,
                                        partySize,
                                        reservationId);

                } catch (Exception e) {

                        editSearchError = message(e);
                }

                List<Long> currentTableIds = reservationDAO.findTableIds(reservationId);

                String currentCandidateKey = currentTableIds.stream()
                                .sorted()
                                .map(String::valueOf)
                                .collect(Collectors.joining(","));

                String selectedCandidateKey = req.getParameter("candidateKey");

                final String requestedCandidateKey = selectedCandidateKey;

                boolean selectedExists = hasText(requestedCandidateKey)
                                && suggestions.stream().anyMatch(
                                                candidate -> candidate.getCandidateKey()
                                                                .equals(requestedCandidateKey));

                if (!selectedExists) {

                        boolean currentExists = suggestions.stream().anyMatch(
                                        candidate -> candidate.getCandidateKey()
                                                        .equals(currentCandidateKey));

                        selectedCandidateKey = currentExists
                                        ? currentCandidateKey
                                        : suggestions.isEmpty()
                                                        ? ""
                                                        : suggestions.get(0).getCandidateKey();
                }

                req.setAttribute("editingReservation", reservation);
                req.setAttribute("today", LocalDate.now());

                req.setAttribute("editCustomerName", customerName);
                req.setAttribute("editPhoneNumber", phoneNumber);

                req.setAttribute("editDate", date);
                req.setAttribute("editStart", start);
                req.setAttribute("restrictedEdit", restrictedEdit);
                req.setAttribute("editEnd", start.plusHours(2));
                req.setAttribute("editPartySize", partySize);
                req.setAttribute("editReason", reason);

                req.setAttribute("currentTableIds", currentCandidateKey);
                req.setAttribute("suggestions", suggestions);
                req.setAttribute("editSearchError", editSearchError);
                req.setAttribute("selectedCandidateKey", selectedCandidateKey);
        }

        private String buildEditRedirect(
                        HttpServletRequest req,
                        long reservationId) {

                StringBuilder url = new StringBuilder(
                                "/receptionist/reservations/edit?id=" + reservationId);

                appendQuery(url, "customerName",
                                req.getParameter("customerName"));

                appendQuery(url, "phoneNumber",
                                req.getParameter("phoneNumber"));

                appendQuery(url, "reservationDate",
                                req.getParameter("reservationDate"));

                appendQuery(url, "startTime",
                                req.getParameter("startTime"));

                appendQuery(url, "partySize",
                                req.getParameter("partySize"));

                appendQuery(url, "candidateKey",
                                req.getParameter("candidateKey"));

                appendQuery(url, "reason",
                                req.getParameter("reason"));

                return url.toString();
        }

        private void appendQuery(
                        StringBuilder url,
                        String name,
                        String value) {

                if (value == null) {
                        return;
                }

                url.append(url.indexOf("?") >= 0 ? "&" : "?")
                                .append(URLEncoder.encode(
                                                name,
                                                StandardCharsets.UTF_8))
                                .append("=")
                                .append(URLEncoder.encode(
                                                value,
                                                StandardCharsets.UTF_8));
        }

        private boolean hasText(String value) {
                return value != null && !value.isBlank();
        }

        private String resolvePage(HttpServletRequest req) {

                String path = req.getPathInfo();

                if (path == null
                                || "/".equals(path)
                                || "/reservations".equals(path)) {
                        return "reservations";
                }

                if ("/create-reservation".equals(path)) {
                        return "create-reservation";
                }

                if ("/walk-ins".equals(path)) {
                        return "walk-ins";
                }

                if ("/table-status".equals(path)) {
                        return "table-status";
                }

                return null;
        }

        private String resolveRedirectPath(String action) {

                if ("create".equals(action)
                                || "update".equals(action)
                                || "checkin".equals(action)
                                || "cancel".equals(action)
                                || "noshow".equals(action)) {

                        return "/receptionist/reservations";
                }

                if ("createWalkInGroup".equals(action)) {
                        return "/receptionist/walk-ins";
                }

                return "/receptionist/table-status";
        }

        private void loadReservationData(HttpServletRequest req) {

                String keyword = req.getParameter("keyword");
                String dateValue = req.getParameter("date");
                String status = req.getParameter("status");

                keyword = keyword == null ? "" : keyword.trim();
                dateValue = dateValue == null ? "" : dateValue.trim();
                status = status == null ? "" : status.trim();

                LocalDate filterDate = null;

                if (!dateValue.isBlank()) {

                        try {
                                filterDate = LocalDate.parse(dateValue);

                        } catch (Exception e) {

                                dateValue = "";

                                req.setAttribute(
                                                "error",
                                                "Ngày lọc không hợp lệ. Vui lòng chọn lại ngày.");
                        }
                }

                Set<String> validStatuses = Set.of(
                                "CONFIRMED",
                                "CHECKED_IN",
                                "COMPLETED",
                                "CANCELLED",
                                "NO_SHOW");

                if (!status.isBlank()
                                && !validStatuses.contains(status)) {
                        status = "";
                }

                int page = 1;
                int pageSize = 10;

                try {
                        page = Integer.parseInt(req.getParameter("page"));
                } catch (Exception ignored) {
                        page = 1;
                }

                try {
                        pageSize = Integer.parseInt(req.getParameter("pageSize"));
                } catch (Exception ignored) {
                        pageSize = 10;
                }

                page = Math.max(1, page);

                if (pageSize != 10
                                && pageSize != 20
                                && pageSize != 50) {
                        pageSize = 10;
                }

                try {

                        List<Reservation> allReservations = reservationDAO.findAll();

                        final String searchTerm = keyword.toLowerCase(Locale.ROOT);

                        final LocalDate selectedDate = filterDate;

                        final String selectedStatus = status;

                        List<Reservation> filteredReservations = allReservations.stream()

                                        .filter(r -> selectedDate == null
                                                        || selectedDate.equals(
                                                                        r.getReservationDate()))

                                        .filter(r -> selectedStatus.isBlank()
                                                        || selectedStatus.equals(
                                                                        r.getStatus()))

                                        .filter(r -> {

                                                if (searchTerm.isBlank()) {
                                                        return true;
                                                }

                                                String searchableText = String.valueOf(r.getReservationId())
                                                                + " "
                                                                + safe(r.getCustomerName())
                                                                + " "
                                                                + safe(r.getPhoneNumber())
                                                                + " "
                                                                + safe(r.getTableNumber())
                                                                + " "
                                                                + String.valueOf(r.getTableId());

                                                return searchableText
                                                                .toLowerCase(Locale.ROOT)
                                                                .contains(searchTerm);
                                        })

                                        .collect(Collectors.toList());

                        int totalRecords = filteredReservations.size();

                        int totalPages = Math.max(
                                        1,
                                        (int) Math.ceil(
                                                        (double) totalRecords / pageSize));

                        if (page > totalPages) {
                                page = totalPages;
                        }

                        int fromIndex = (page - 1) * pageSize;

                        int toIndex = Math.min(
                                        fromIndex + pageSize,
                                        totalRecords);

                        List<Reservation> pageReservations = fromIndex < toIndex
                                        ? new ArrayList<>(
                                                        filteredReservations.subList(
                                                                        fromIndex,
                                                                        toIndex))
                                        : Collections.emptyList();

                        List<Integer> pageNumbers = new ArrayList<>();

                        int firstPage = Math.max(1, page - 2);
                        int lastPage = Math.min(totalPages, page + 2);

                        for (int i = firstPage; i <= lastPage; i++) {
                                pageNumbers.add(i);
                        }

                        req.setAttribute("reservations", pageReservations);

                        req.setAttribute("keyword", keyword);
                        req.setAttribute("filterDate", dateValue);
                        req.setAttribute("filterStatus", status);

                        req.setAttribute("currentPage", page);
                        req.setAttribute("pageSize", pageSize);
                        req.setAttribute("totalPages", totalPages);
                        req.setAttribute("totalRecords", totalRecords);
                        req.setAttribute("pageNumbers", pageNumbers);

                        req.setAttribute(
                                        "startRecord",
                                        totalRecords == 0 ? 0 : fromIndex + 1);

                        req.setAttribute("endRecord", toIndex);

                } catch (Exception e) {

                        req.setAttribute(
                                        "reservations",
                                        Collections.emptyList());

                        req.setAttribute("keyword", keyword);
                        req.setAttribute("filterDate", dateValue);
                        req.setAttribute("filterStatus", status);

                        req.setAttribute("currentPage", 1);
                        req.setAttribute("pageSize", pageSize);
                        req.setAttribute("totalPages", 1);
                        req.setAttribute("totalRecords", 0);
                        req.setAttribute("pageNumbers", List.of(1));
                        req.setAttribute("startRecord", 0);
                        req.setAttribute("endRecord", 0);

                        req.setAttribute("error", message(e));
                }
        }

        private String safe(String value) {
                return value == null ? "" : value;
        }

        private void handleReservationSearch(HttpServletRequest req) {

                if (!"1".equals(req.getParameter("search"))) {
                        return;
                }

                try {

                        LocalDate date = LocalDate.parse(
                                        req.getParameter("reservationDate"));

                        LocalTime start = LocalTime.parse(
                                        req.getParameter("startTime"));

                        int partySize = Integer.parseInt(
                                        req.getParameter("partySize"));

                        if (partySize < 1) {
                                throw new IllegalArgumentException(
                                                "Số khách phải lớn hơn 0.");
                        }

                        List<TableCandidate> suggestions = reservationService.suggestTables(
                                        date,
                                        start,
                                        partySize);

                        req.setAttribute("searched", true);
                        req.setAttribute("suggestions", suggestions);
                        req.setAttribute("searchDate", date);
                        req.setAttribute("searchStart", start);
                        req.setAttribute("searchEnd", start.plusHours(2));
                        req.setAttribute("searchPartySize", partySize);

                } catch (Exception e) {

                        req.setAttribute("error", message(e));
                }
        }

        private void loadWalkInData(HttpServletRequest req) {

                req.setAttribute("tables", Collections.emptyList());
                req.setAttribute("activeWalkInTableIds", Collections.emptySet());
                req.setAttribute("activeWalkInGroupLabels", Collections.emptyMap());

                try {

                        req.setAttribute("tables", tableDAO.findAll());

                        req.setAttribute(
                                        "activeWalkInTableIds",
                                        walkInGroupDAO.findActiveGroupTableIds());

                        req.setAttribute(
                                        "activeWalkInGroupLabels",
                                        walkInGroupDAO.findActiveGroupLabels());

                } catch (Exception e) {

                        req.setAttribute("error", message(e));
                }
        }

        private void loadTableStatusData(HttpServletRequest req) {

                req.setAttribute("tables", Collections.emptyList());
                req.setAttribute("activeWalkInTableIds", Collections.emptySet());
                req.setAttribute("activeWalkInGroupLabels", Collections.emptyMap());
                req.setAttribute("activeReservationTables", Collections.emptyMap());
                req.setAttribute("servedTableIds", Collections.emptySet());

                try {

                        req.setAttribute("tables", tableDAO.findAll());

                        req.setAttribute(
                                        "activeWalkInTableIds",
                                        walkInGroupDAO.findActiveGroupTableIds());

                        req.setAttribute(
                                        "activeWalkInGroupLabels",
                                        walkInGroupDAO.findActiveGroupLabels());

                        req.setAttribute(
                                        "activeReservationTables",
                                        reservationDAO.findCheckedInTableAssignments());
                        req.setAttribute(
                                        "servedTableIds",
                                        orderDAO.findPayableOpenOrderTableIds());
                } catch (Exception e) {

                        req.setAttribute("error", message(e));
                }
        }

        private void consumeFlash(HttpServletRequest req) {

                HttpSession session = req.getSession();

                req.setAttribute(
                                "success",
                                session.getAttribute("flashSuccess"));

                req.setAttribute(
                                "error",
                                session.getAttribute("flashError"));

                session.removeAttribute("flashSuccess");
                session.removeAttribute("flashError");
        }

        private String message(Exception e) {

                Throwable current = e;

                while (current.getCause() != null
                                && current.getCause() != current) {
                        current = current.getCause();
                }

                String value = current.getMessage();

                if (value == null || value.isBlank()) {
                        value = e.getMessage();
                }

                return value == null || value.isBlank()
                                ? "Không thể thực hiện thao tác"
                                : value;
        }
}
