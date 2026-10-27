package com.fpt.rms.controller;

import com.fpt.rms.dao.TableDAO;
import com.fpt.rms.dao.TableLayoutDAO;

import com.fpt.rms.model.RestaurantTable;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.MultiFormatWriter;

import com.google.zxing.client.j2se.MatrixToImageWriter;

import com.google.zxing.common.BitMatrix;

import jakarta.servlet.ServletException;

import jakarta.servlet.annotation.WebServlet;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet("/manager/tables")
public class ManagerTableServlet extends HttpServlet {
    private final TableDAO tableDAO = new TableDAO();
    private final TableLayoutDAO layoutDAO = new TableLayoutDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            if ("qr".equals(req.getParameter("action"))) {
                writeQr(req, resp);
                return;
            }
            req.setAttribute("tables", tableDAO.findAll());
            req.setAttribute("layouts", layoutDAO.findAll());
            req.setAttribute("adjacencyOverrides", layoutDAO.findAllOverrides());
            consumeFlash(req);
            req.getRequestDispatcher("/WEB-INF/views/manager/tables.jsp").forward(req, resp);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");
        try {
            String action = req.getParameter("action");
            if ("create".equals(action)) {
                tableDAO.create(req.getParameter("tableNumber"), Integer.parseInt(req.getParameter("capacity")));
                flashSuccess(req, "Đã tạo bàn mới");
            } else if ("update".equals(action)) {
                tableDAO.update(Long.parseLong(req.getParameter("id")), Integer.parseInt(req.getParameter("capacity")),
                        Boolean.parseBoolean(req.getParameter("active")));
                flashSuccess(req, "Đã cập nhật bàn");
            } else if ("regenerate".equals(action)) {
                tableDAO.regenerateToken(Long.parseLong(req.getParameter("id")));
                flashSuccess(req, "Đã tạo lại mã QR");
            } else if ("saveRowLayout".equals(action)) {
                layoutDAO.saveRow(req.getParameter("areaCode"), Integer.parseInt(req.getParameter("rowNo")),
                        req.getParameter("tableNumbers"));
                flashSuccess(req, "Đã lưu sơ đồ hàng bàn");
            } else if ("removeRowLayout".equals(action)) {
                layoutDAO.removeRow(req.getParameter("areaCode"), Integer.parseInt(req.getParameter("rowNo")));
                flashSuccess(req, "Đã xóa sơ đồ hàng bàn");
            } else if ("saveAdjacencyOverride".equals(action)) {
                String tableNumber1 = req.getParameter("tableNumber1");
                String tableNumber2 = req.getParameter("tableNumber2");
                boolean allowed = Boolean.parseBoolean(req.getParameter("allowed"));
                layoutDAO.saveAdjacencyOverride(tableNumber1, tableNumber2, allowed);
                flashSuccess(req, allowed ? "Đã thêm rule cho phép ghép hai bàn" : "Đã thêm rule chặn ghép hai bàn");
            } else if ("removeAdjacencyOverride".equals(action)) {
                layoutDAO.removeAdjacencyOverride(Long.parseLong(req.getParameter("tableId1")),
                        Long.parseLong(req.getParameter("tableId2")));
                flashSuccess(req, "Đã xóa rule đặc biệt. Hai bàn sẽ quay về quy tắc tự động của sơ đồ.");
            } else {
                throw new IllegalArgumentException("Thao tác không hợp lệ");
            }
        } catch (Exception e) {
            req.getSession().setAttribute("flashError", message(e));
        }
        resp.sendRedirect(req.getContextPath() + "/manager/tables");
    }

    private void flashSuccess(HttpServletRequest req, String message) {
        req.getSession().setAttribute("flashSuccess", message);
    }

    private void writeQr(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        String idValue = req.getParameter("id");
        if (idValue == null || idValue.isBlank()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        long id;
        try {
            id = Long.parseLong(idValue);
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        RestaurantTable table = tableDAO.findById(id);
        if (table == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        String base = req.getScheme() + "://" + req.getServerName();
        boolean defaultPort = ("http".equalsIgnoreCase(req.getScheme()) && req.getServerPort() == 80)
                || ("https".equalsIgnoreCase(req.getScheme()) && req.getServerPort() == 443);
        if (!defaultPort) {
            base += ":" + req.getServerPort();
        }
        String url = base + req.getContextPath() + "/customer/menu?token=" + table.getQrToken();
        BitMatrix matrix = new MultiFormatWriter().encode(url, BarcodeFormat.QR_CODE, 260, 260);
        resp.setContentType("image/png");
        resp.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        MatrixToImageWriter.writeToStream(matrix, "PNG", resp.getOutputStream());
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
        return value == null || value.isBlank() ? "Không thể thực hiện thao tác" : value;
    }
}
