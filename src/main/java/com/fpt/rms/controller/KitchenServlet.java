package com.fpt.rms.controller;

import com.fpt.rms.dao.InventoryDAO;
import com.fpt.rms.dao.OrderDAO;

import com.fpt.rms.model.Staff;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet("/kitchen")
public class KitchenServlet
                extends HttpServlet {

        private final OrderDAO orderDAO = new OrderDAO();

        private final InventoryDAO inventoryDAO = new InventoryDAO();

        /*
         * =====================================================
         * KITCHEN DASHBOARD
         * =====================================================
         */
        @Override
        protected void doGet(
                        HttpServletRequest req,
                        HttpServletResponse resp) throws ServletException, IOException {

                try {

                        /*
                         * Chỉ lấy OrderDetail:
                         *
                         * status = PENDING
                         *
                         * OrderDAO hiện group các detail
                         * theo Order để giao diện dễ xem.
                         */
                        req.setAttribute(
                                        "orders",
                                        orderDAO.findPendingKitchenOrders());

                        /*
                         * Tồn kho nhanh.
                         */
                        req.setAttribute(
                                        "inventory",
                                        inventoryDAO.findAll());

                        consumeFlash(
                                        req);

                        req.getRequestDispatcher(
                                        "/WEB-INF/views/kitchen/dashboard.jsp").forward(
                                                        req,
                                                        resp);

                } catch (Exception e) {

                        throw new ServletException(
                                        e);
                }
        }

        /*
         * =====================================================
         * MARK ONE DETAIL READY
         * =====================================================
         */
        @Override
        protected void doPost(
                        HttpServletRequest req,
                        HttpServletResponse resp) throws IOException {

                try {

                        /*
                         * Kiểm tra login.
                         */
                        Staff staff = (Staff) req.getSession()
                                        .getAttribute(
                                                        "staff");

                        if (staff == null) {

                                throw new IllegalStateException(
                                                "Phiên đăng nhập đã hết hạn");
                        }

                        String action = req.getParameter(
                                        "action");

                        /*
                         * Kitchen chỉ có action này.
                         */
                        if (!"readyDetail".equals(
                                        action)) {

                                throw new IllegalArgumentException(
                                                "Thao tác của bếp không hợp lệ");
                        }

                        String detailIdValue = req.getParameter(
                                        "detailId");

                        if (detailIdValue == null
                                        ||
                                        detailIdValue.isBlank()) {

                                throw new IllegalArgumentException(
                                                "Thiếu mã món");
                        }

                        long detailId = Long.parseLong(
                                        detailIdValue);

                        /*
                         * Chỉ READY đúng một OrderDetail.
                         */
                        inventoryDAO.markDetailReady(
                                        detailId,
                                        staff.getStaffId());

                        req.getSession()
                                        .setAttribute(
                                                        "flashSuccess",

                                                        "Món #"
                                                                        + detailId
                                                                        + " đã hoàn thành và chuyển sang READY.");

                } catch (Exception e) {

                        req.getSession()
                                        .setAttribute(
                                                        "flashError",
                                                        message(e));
                }

                /*
                 * PRG:
                 * POST → Redirect → GET
                 */
                resp.sendRedirect(
                                req.getContextPath()
                                                + "/kitchen");
        }

        /*
         * =====================================================
         * FLASH MESSAGE
         * =====================================================
         */
        private void consumeFlash(
                        HttpServletRequest req) {

                HttpSession session = req.getSession();

                req.setAttribute(
                                "success",
                                session.getAttribute(
                                                "flashSuccess"));

                req.setAttribute(
                                "error",
                                session.getAttribute(
                                                "flashError"));

                session.removeAttribute(
                                "flashSuccess");

                session.removeAttribute(
                                "flashError");
        }

        /*
         * =====================================================
         * ERROR MESSAGE
         * =====================================================
         */
        private String message(
                        Exception e) {

                Throwable current = e;

                /*
                 * InventoryDAO wrap business exception
                 * bằng SQLException.
                 *
                 * Đi xuống cause cuối để lấy message thật.
                 */
                while (current.getCause() != null
                                &&
                                current.getCause() != current) {

                        current = current.getCause();
                }

                String value = current.getMessage();

                if (value == null
                                ||
                                value.isBlank()) {

                        value = e.getMessage();
                }

                return value == null
                                ||
                                value.isBlank()

                                                ? "Không thể xử lý món ăn"

                                                : value;
        }
}