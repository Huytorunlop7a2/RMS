package com.fpt.rms.controller;

import com.fpt.rms.dao.InventoryDAO;
import com.fpt.rms.dao.MenuDAO;

import jakarta.servlet.ServletException;

import jakarta.servlet.annotation.WebServlet;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

import java.math.BigDecimal;

@WebServlet("/manager/menu")
public class ManagerMenuServlet extends HttpServlet {
    private final MenuDAO menuDAO = new MenuDAO();
    private final InventoryDAO inventoryDAO = new InventoryDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("items", menuDAO.findAllItems());
            req.setAttribute("categories", menuDAO.findAllCategories());
            req.setAttribute("inventory", inventoryDAO.findAll());
            consumeFlash(req);
            req.getRequestDispatcher("/WEB-INF/views/manager/menu.jsp").forward(req, resp);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            String action = req.getParameter("action");
            if ("create".equals(action)) {
                menuDAO.create(Long.parseLong(req.getParameter("categoryId")), req.getParameter("name"),
                        req.getParameter("description"), new BigDecimal(req.getParameter("price")));
                flashSuccess(req, "Đã tạo món. Hãy cấu hình công thức nguyên liệu trước khi bán.");
            } else if ("update".equals(action)) {
                menuDAO.update(Long.parseLong(req.getParameter("id")), Long.parseLong(req.getParameter("categoryId")),
                        req.getParameter("name"), req.getParameter("description"),
                        new BigDecimal(req.getParameter("price")));
                flashSuccess(req, "Đã cập nhật món");
            } else if ("toggle".equals(action)) {
                menuDAO.setActive(Long.parseLong(req.getParameter("id")),
                        Boolean.parseBoolean(req.getParameter("active")));
                flashSuccess(req, "Đã cập nhật trạng thái món");
            } else if ("saveIngredient".equals(action)) {
                menuDAO.saveIngredient(Long.parseLong(req.getParameter("menuItemId")),
                        Long.parseLong(req.getParameter("inventoryItemId")),
                        new BigDecimal(req.getParameter("requiredQuantity")));
                flashSuccess(req, "Đã lưu công thức nguyên liệu");
            } else if ("removeIngredient".equals(action)) {
                menuDAO.removeIngredient(Long.parseLong(req.getParameter("menuItemId")),
                        Long.parseLong(req.getParameter("inventoryItemId")));
                flashSuccess(req, "Đã xóa nguyên liệu khỏi công thức");
            } else {
                throw new IllegalArgumentException("Thao tác quản lý menu không hợp lệ");
            }
        } catch (Exception e) {
            req.getSession().setAttribute("flashError", message(e));
        }
        resp.sendRedirect(req.getContextPath() + "/manager/menu");
    }

    private void flashSuccess(HttpServletRequest req, String message) {
        req.getSession().setAttribute("flashSuccess", message);
    }

    private void consumeFlash(HttpServletRequest req) {
        HttpSession session = req.getSession();
        req.setAttribute("success", session.getAttribute("flashSuccess"));
        req.setAttribute("error", session.getAttribute("flashError"));
        session.removeAttribute("flashSuccess");
        session.removeAttribute("flashError");
    }

    private String message(Exception e) {
        String value = e.getCause() != null && e.getCause().getMessage() != null ? e.getCause().getMessage()
                : e.getMessage();
        return value == null || value.isBlank() ? "Không thể cập nhật menu" : value;
    }
}
