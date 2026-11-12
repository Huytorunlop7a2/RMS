package com.fpt.rms.controller;

import com.fpt.rms.dao.OrderDAO;
import com.fpt.rms.dao.ReservationDAO;
import com.fpt.rms.dao.TableDAO;
import com.fpt.rms.dao.WalkInGroupDAO;

import com.fpt.rms.model.Staff;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet("/waiter")
public class WaiterServlet extends HttpServlet {
    private final OrderDAO orderDAO = new OrderDAO();
    private final ReservationDAO reservationDAO = new ReservationDAO();
    private final TableDAO tableDAO = new TableDAO();
    private final WalkInGroupDAO walkInGroupDAO = new WalkInGroupDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("readyDetails", orderDAO.findReadyDetails());
            req.setAttribute("tables", tableDAO.findAll());
            req.setAttribute("activeWalkInTableIds", walkInGroupDAO.findActiveGroupTableIds());
            req.setAttribute("activeWalkInGroupLabels", walkInGroupDAO.findActiveGroupLabels());
            req.setAttribute("activeReservationTables", reservationDAO.findCheckedInTableAssignments());
            consumeFlash(req);
            req.getRequestDispatcher("/WEB-INF/views/waiter/dashboard.jsp").forward(req, resp);
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
            String successMessage;
            if ("served".equals(action)) {
                long detailId = Long.parseLong(req.getParameter("id"));
                orderDAO.markServed(detailId);
                successMessage = "Đã xác nhận món được phục vụ";
            } else if ("createWalkInGroup".equals(action)) {
                long groupId = walkInGroupDAO.createGroup(req.getParameterValues("tableIds"), staff.getStaffId());
                successMessage = "Đã gộp bàn walk-in thành công. " + "Nhóm #" + groupId;
            } else if ("releaseOne".equals(action) || "release".equals(action)) {
                long tableId = Long.parseLong(req.getParameter("id"));
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
                long tableId = Long.parseLong(req.getParameter("id"));
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
                throw new IllegalArgumentException("Thao tác của phục vụ không hợp lệ");
            }
            req.getSession().setAttribute("flashSuccess", successMessage);
        } catch (Exception e) {
            req.getSession().setAttribute("flashError", message(e));
        }
        resp.sendRedirect(req.getContextPath() + "/waiter");
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