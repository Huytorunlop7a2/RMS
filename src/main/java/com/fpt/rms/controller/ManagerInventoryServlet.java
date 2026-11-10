package com.fpt.rms.controller;

import com.fpt.rms.dao.InventoryDAO;
import com.fpt.rms.model.Staff;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Set;

@WebServlet("/manager/inventory")
public class ManagerInventoryServlet extends HttpServlet {
    private final InventoryDAO dao = new InventoryDAO();

    // @Override
    // protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws
    // ServletException, IOException {
    // try {
    // req.setAttribute("inventory", dao.findAll());
    // consumeFlash(req);
    // req.getRequestDispatcher("/WEB-INF/views/manager/inventory.jsp").forward(req,
    // resp);
    // } catch (Exception e) {
    // throw new ServletException(e);
    // }
    // }

    @Override
    protected void doGet(
            HttpServletRequest req,
            HttpServletResponse resp)
            throws ServletException, IOException {

        try {
            String tab = req.getParameter("tab");
            String fromText = req.getParameter("fromDate");
            String toText = req.getParameter("toDate");
            String type = req.getParameter("type");
            String keyword = req.getParameter("keyword");

            LocalDate fromDate = parseDate(fromText);
            LocalDate toDate = parseDate(toText);

            if (fromDate != null && toDate != null
                    && fromDate.isAfter(toDate)) {
                throw new IllegalArgumentException(
                        "Ngày bắt đầu không được sau ngày kết thúc");
            }

            Set<String> validTypes = Set.of(
                    "RESTOCK",
                    "WASTE_LOSS",
                    "ADJUSTMENT",
                    "USAGE");

            if (type == null || type.isBlank()) {
                type = "";
            } else if (!validTypes.contains(type)) {
                throw new IllegalArgumentException(
                        "Loại giao dịch không hợp lệ");
            }

            if (keyword == null) {
                keyword = "";
            }
            keyword = keyword.trim();

            if (keyword.length() > 100) {
                throw new IllegalArgumentException(
                        "Từ khóa tìm kiếm tối đa 100 ký tự");
            }

            int pageSize = parseInt(req.getParameter("pageSize"), 20);
            if (pageSize != 20 && pageSize != 50 && pageSize != 80) {
                pageSize = 20;
            }

            int page = parseInt(req.getParameter("page"), 1);
            if (page < 1) {
                page = 1;
            }

            long totalTransactions = dao.countTransactions(
                    fromDate, toDate, type, keyword);

            long totalPages = Math.max(
                    1L,
                    (totalTransactions + pageSize - 1) / pageSize);

            if (page > totalPages) {
                page = (int) Math.min(totalPages, Integer.MAX_VALUE);
            }

            req.setAttribute("inventory", dao.findAll());

            req.setAttribute("transactions", dao.findTransactions(
                    fromDate, toDate, type, keyword, page, pageSize));

            req.setAttribute("totalTransactions", totalTransactions);
            req.setAttribute("totalPages", totalPages);
            req.setAttribute("currentPage", page);
            req.setAttribute("pageSize", pageSize);

            req.setAttribute("fromDate", fromText);
            req.setAttribute("toDate", toText);
            req.setAttribute("selectedType", type);
            req.setAttribute("keyword", keyword);

            req.setAttribute(
                    "activeTab",
                    "history".equals(tab) ? "history" : "inventory");

            String detailId = req.getParameter("detailId");

            if (detailId != null && !detailId.isBlank()) {
                long id = Long.parseLong(detailId);

                if (id <= 0) {
                    throw new IllegalArgumentException(
                            "Mã giao dịch không hợp lệ");
                }

                req.setAttribute(
                        "transactionDetail",
                        dao.findTransactionById(id));
            }

            consumeFlash(req);

            req.getRequestDispatcher(
                    "/WEB-INF/views/manager/inventory.jsp").forward(req, resp);

        } catch (IllegalArgumentException e) {
            resp.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    e.getMessage());
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    private LocalDate parseDate(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        try {
            return LocalDate.parse(value);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException(
                    "Ngày lọc không hợp lệ", e);
        }
    }

    private int parseInt(String value, int fallback) {
        if (value == null || value.isBlank()) {
            return fallback;
        }

        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            Staff staff = (Staff) req.getSession().getAttribute("staff");
            if (staff == null) {
                throw new IllegalStateException("Phiên đăng nhập đã hết hạn");
            }
            String action = req.getParameter("action");
            if ("create".equals(action)) {
                String unit = req.getParameter("unit");

                java.util.Set<String> validUnits = java.util.Set.of(
                        "kg", "gram", "lít", "ml",
                        "lon", "chai", "hop", "goi", "piece", "qua");

                if (!validUnits.contains(unit)) {
                    throw new IllegalArgumentException("Đơn vị không hợp lệ");
                }

                BigDecimal quantity = new BigDecimal(req.getParameter("initialQuantity"));

                BigDecimal threshold = new BigDecimal(req.getParameter("lowStockThreshold"));

                if (quantity.signum() < 0 || threshold.signum() < 0) {
                    throw new IllegalArgumentException("Số lượng không được âm");
                }

                java.util.Set<String> countUnits = java.util.Set.of(
                        "lon", "chai", "hop", "goi", "piece", "qua");

                if (countUnits.contains(unit)) {
                    if (quantity.stripTrailingZeros().scale() > 0 ||
                            threshold.stripTrailingZeros().scale() > 0) {
                        throw new IllegalArgumentException(
                                "Đơn vị đếm phải có số lượng nguyên");
                    }
                }

                dao.create(
                        req.getParameter("name"),
                        unit,
                        quantity,
                        threshold,
                        staff.getStaffId());
            } else if ("stockin".equals(action)) {
                dao.stockIn(Long.parseLong(req.getParameter("id")), new BigDecimal(req.getParameter("quantity")),
                        blankDecimal(req.getParameter("unitCost")), normalizeNote(req.getParameter("note")),
                        staff.getStaffId());
            } else if ("adjust".equals(action)) {
                dao.adjust(Long.parseLong(req.getParameter("id")), new BigDecimal(req.getParameter("actualQuantity")),
                        requiredReason(req.getParameter("note")), staff.getStaffId());
            } else if ("waste".equals(action)) {
                dao.waste(Long.parseLong(req.getParameter("id")), new BigDecimal(req.getParameter("quantity")),
                        requiredReason(req.getParameter("note")), staff.getStaffId());
            } else if ("threshold".equals(action)) {
                dao.setThreshold(Long.parseLong(req.getParameter("id")), new BigDecimal(req.getParameter("threshold")));
            } else {
                throw new IllegalArgumentException("Thao tác quản lý kho không hợp lệ");
            }
            req.getSession().setAttribute("flashSuccess", "Đã cập nhật kho thành công");
        } catch (Exception e) {
            req.getSession().setAttribute("flashError", message(e));
        }
        resp.sendRedirect(req.getContextPath() + "/manager/inventory");
    }

    private BigDecimal blankDecimal(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return new BigDecimal(value);
    }

    private String normalizeNote(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String result = value.trim();
        if (result.length() > 500) {
            throw new IllegalArgumentException("Ghi chú tối đa 500 ký tự");
        }
        return result;
    }

    private void consumeFlash(HttpServletRequest req) {
        HttpSession session = req.getSession();
        req.setAttribute("success", session.getAttribute("flashSuccess"));
        req.setAttribute("error", session.getAttribute("flashError"));
        session.removeAttribute("flashSuccess");
        session.removeAttribute("flashError");
    }

    private String message(Exception e) {
        Throwable current = e;
        while (current.getCause() != null && current.getCause() != current) {
            current = current.getCause();
        }
        String value = current.getMessage();
        if (value == null || value.isBlank()) {
            value = e.getMessage();
        }
        return value == null || value.isBlank() ? "Không thể cập nhật kho" : value;
    }

    private String requiredReason(String value) {
        String reason = normalizeNote(value);

        if (reason == null) {
            throw new IllegalArgumentException(
                    "Vui lòng nhập lý do điều chỉnh hoặc hao hụt");
        }

        return reason;
    }
}
