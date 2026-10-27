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

@WebServlet("/manager/inventory")
public class ManagerInventoryServlet extends HttpServlet {
    private final InventoryDAO dao = new InventoryDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("inventory", dao.findAll());
            consumeFlash(req);
            req.getRequestDispatcher("/WEB-INF/views/manager/inventory.jsp").forward(req, resp);
        } catch (Exception e) {
            throw new ServletException(e);
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
                dao.create(req.getParameter("name"), req.getParameter("unit"),
                        new BigDecimal(req.getParameter("initialQuantity")),
                        new BigDecimal(req.getParameter("lowStockThreshold")), staff.getStaffId());
            } else if ("stockin".equals(action)) {
                dao.stockIn(Long.parseLong(req.getParameter("id")), new BigDecimal(req.getParameter("quantity")),
                        blankDecimal(req.getParameter("unitCost")), normalizeNote(req.getParameter("note")),
                        staff.getStaffId());
            } else if ("adjust".equals(action)) {
                dao.adjust(Long.parseLong(req.getParameter("id")), new BigDecimal(req.getParameter("actualQuantity")),
                        normalizeNote(req.getParameter("note")), staff.getStaffId());
            } else if ("waste".equals(action)) {
                dao.waste(Long.parseLong(req.getParameter("id")), new BigDecimal(req.getParameter("quantity")),
                        normalizeNote(req.getParameter("note")), staff.getStaffId());
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
}
