package com.fpt.rms.controller;

import com.fpt.rms.dao.MenuDAO;
import com.fpt.rms.dao.OrderDAO;
import com.fpt.rms.dao.PaymentDAO;
import com.fpt.rms.dao.TableDAO;
import com.fpt.rms.dao.WalkInGroupDAO;

import com.fpt.rms.model.Payment;
import com.fpt.rms.model.RestaurantOrder;
import com.fpt.rms.model.RestaurantTable;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet("/customer/*")
public class CustomerServlet
                extends HttpServlet {

        private final TableDAO tableDAO = new TableDAO();

        private final MenuDAO menuDAO = new MenuDAO();

        private final OrderDAO orderDAO = new OrderDAO();

        private final PaymentDAO paymentDAO = new PaymentDAO();

        private final WalkInGroupDAO walkInGroupDAO = new WalkInGroupDAO();

        @Override
        protected void doGet(
                        HttpServletRequest req,
                        HttpServletResponse resp)
                        throws ServletException, IOException {

                try {

                        String path = req.getPathInfo() == null
                                        ? "/menu"
                                        : req.getPathInfo();

                        /*
                         * token:
                         * QR thật mà khách vừa scan.
                         *
                         * Ví dụ khách đang ngồi T05
                         * thì token vẫn là QR của T05.
                         */
                        String token = normalizeToken(
                                        req.getParameter(
                                                        "token"));

                        RestaurantTable table = tableDAO.findByToken(
                                        token);

                        if (table == null) {

                                resp.sendError(
                                                HttpServletResponse.SC_NOT_FOUND,
                                                "Mã QR bàn không hợp lệ hoặc bàn đã ngừng dùng");

                                return;
                        }

                        /*
                         * serviceToken:
                         *
                         * Nếu bàn đứng riêng:
                         * T05 → QR T05
                         *
                         * Nếu T05 thuộc walk-in group
                         * có anchor T01:
                         *
                         * T05 → QR T01
                         *
                         * Từ đây OrderDAO vẫn chạy
                         * đúng logic cũ.
                         */
                        String serviceToken = walkInGroupDAO.resolveServiceToken(
                                        token);

                        /*
                         * Giao diện vẫn hiện đúng bàn
                         * khách vừa scan.
                         */
                        req.setAttribute(
                                        "table",
                                        table);

                        req.setAttribute(
                                        "token",
                                        token);

                        consumeFlash(
                                        req);

                        /*
                         * =================================================
                         * MENU
                         * =================================================
                         */
                        if ("/menu".equals(
                                        path)) {

                                req.setAttribute(
                                                "items",
                                                menuDAO.findAvailableItems());

                                RestaurantOrder openOrder = orderDAO.findOpenOrderByToken(
                                                serviceToken);

                                req.setAttribute(
                                                "openOrder",
                                                openOrder);

                                if (openOrder != null) {

                                        req.setAttribute(
                                                        "paymentPending",

                                                        paymentDAO.findPendingByOrder(
                                                                        openOrder.getOrderId()) != null);
                                }

                                req.getRequestDispatcher(
                                                "/WEB-INF/views/customer/menu.jsp")
                                                .forward(
                                                                req,
                                                                resp);

                                return;
                        }

                        /*
                         * =================================================
                         * CURRENT ORDER
                         * =================================================
                         */
                        if ("/order".equals(
                                        path)) {

                                RestaurantOrder order = orderDAO.findOpenOrderByToken(
                                                serviceToken);

                                req.setAttribute(
                                                "order",
                                                order);

                                if (order != null) {

                                        req.setAttribute(
                                                        "total",

                                                        orderDAO.total(
                                                                        order.getOrderId()));

                                        req.setAttribute(
                                                        "canPay",

                                                        orderDAO.canPay(
                                                                        order.getOrderId()));

                                        req.setAttribute(
                                                        "paymentPending",

                                                        paymentDAO.findPendingByOrder(
                                                                        order.getOrderId()) != null);
                                }

                                req.getRequestDispatcher(
                                                "/WEB-INF/views/customer/order.jsp")
                                                .forward(
                                                                req,
                                                                resp);

                                return;
                        }

                        /*
                         * =================================================
                         * PAYMENT PAGE
                         * =================================================
                         */
                        if ("/payment".equals(
                                        path)) {

                                showPayment(
                                                req,
                                                resp,
                                                serviceToken);

                                return;
                        }

                        resp.sendError(
                                        HttpServletResponse.SC_NOT_FOUND);

                } catch (Exception e) {

                        throw new ServletException(
                                        e);
                }
        }

        private void showPayment(
                        HttpServletRequest req,
                        HttpServletResponse resp,
                        String serviceToken)
                        throws Exception {

                String paymentIdValue = req.getParameter(
                                "paymentId");

                Payment selectedPayment = null;

                /*
                 * Nếu URL có paymentId
                 * thì kiểm tra payment đó
                 * có thuộc Order chung hay không.
                 */
                if (paymentIdValue != null
                                &&
                                !paymentIdValue.isBlank()) {

                        long paymentId;

                        try {

                                paymentId = Long.parseLong(
                                                paymentIdValue);

                        } catch (NumberFormatException e) {

                                throw new IllegalArgumentException(
                                                "Mã thanh toán không hợp lệ");
                        }

                        selectedPayment = paymentDAO.findById(
                                        paymentId);

                        /*
                         * Dùng serviceToken của anchor
                         * thay vì token bàn thành viên.
                         */
                        if (selectedPayment != null
                                        &&
                                        !paymentDAO.belongsToToken(
                                                        paymentId,
                                                        serviceToken)) {

                                selectedPayment = null;
                        }
                }

                /*
                 * Payment đã PAID.
                 */
                if (selectedPayment != null
                                &&
                                "PAID".equals(
                                                selectedPayment.getPaymentStatus())) {

                        req.setAttribute(
                                        "paidSuccess",
                                        true);

                        req.setAttribute(
                                        "paidPayment",
                                        selectedPayment);

                        req.getRequestDispatcher(
                                        "/WEB-INF/views/customer/payment.jsp")
                                        .forward(
                                                        req,
                                                        resp);

                        return;
                }

                /*
                 * Tìm OPEN Order chung.
                 */
                RestaurantOrder order = orderDAO.findOpenOrderByToken(
                                serviceToken);

                if (order == null) {

                        req.setAttribute(
                                        "noOpenOrder",
                                        true);

                        req.getRequestDispatcher(
                                        "/WEB-INF/views/customer/payment.jsp")
                                        .forward(
                                                        req,
                                                        resp);

                        return;
                }

                req.setAttribute(
                                "order",
                                order);

                req.setAttribute(
                                "total",

                                orderDAO.total(
                                                order.getOrderId()));

                req.setAttribute(
                                "canPay",

                                orderDAO.canPay(
                                                order.getOrderId()));

                /*
                 * Nếu paymentId trên URL
                 * không còn hợp lệ,
                 * lấy PENDING payment hiện tại.
                 */
                if (selectedPayment == null
                                ||
                                selectedPayment.getOrderId() != order.getOrderId()
                                ||
                                !"PENDING".equals(
                                                selectedPayment.getPaymentStatus())) {

                        selectedPayment = paymentDAO.findPendingByOrder(
                                        order.getOrderId());
                }

                req.setAttribute(
                                "pendingPayment",
                                selectedPayment);

                req.getRequestDispatcher(
                                "/WEB-INF/views/customer/payment.jsp")
                                .forward(
                                                req,
                                                resp);
        }

        @Override
        protected void doPost(
                        HttpServletRequest req,
                        HttpServletResponse resp)
                        throws IOException {

                /*
                 * Giữ original token để redirect.
                 *
                 * Khách scan QR T05 thì URL
                 * vẫn giữ QR của T05.
                 */
                String token = normalizeToken(
                                req.getParameter(
                                                "token"));

                String path = req.getPathInfo() == null
                                ? ""
                                : req.getPathInfo();

                try {

                        RestaurantTable table = tableDAO.findByToken(
                                        token);

                        if (table == null) {

                                throw new IllegalArgumentException(
                                                "Mã QR bàn không hợp lệ");
                        }

                        /*
                         * Tìm token dùng cho nghiệp vụ Order.
                         */
                        String serviceToken = walkInGroupDAO.resolveServiceToken(
                                        token);

                        /*
                         * =================================================
                         * SUBMIT ORDER
                         * =================================================
                         */
                        if ("/order".equals(
                                        path)) {

                                orderDAO.submitOrder(

                                                serviceToken,

                                                req.getParameterValues(
                                                                "itemId"),

                                                req.getParameterValues(
                                                                "quantity"),

                                                req.getParameterValues(
                                                                "note"));

                                req.getSession()
                                                .setAttribute(
                                                                "flashSuccess",
                                                                "Đã gửi món xuống bếp");

                                /*
                                 * Redirect vẫn giữ QR thật
                                 * của bàn khách đang ngồi.
                                 */
                                resp.sendRedirect(
                                                req.getContextPath()
                                                                + "/customer/order?token="
                                                                + token);

                                return;
                        }

                        /*
                         * =================================================
                         * CANCEL ORDER DETAIL
                         * =================================================
                         */
                        if ("/cancel".equals(
                                        path)) {

                                long detailId = Long.parseLong(
                                                req.getParameter(
                                                                "detailId"));

                                boolean orderClosed = orderDAO.cancelDetail(

                                                serviceToken,
                                                detailId);

                                if (orderClosed) {

                                        req.getSession()
                                                        .setAttribute(
                                                                        "flashSuccess",

                                                                        "Đã hủy món cuối cùng. "
                                                                                        + "Đơn hàng đã được đóng. "
                                                                                        + "Bàn vẫn được giữ cho đến khi nhân viên trả bàn.");

                                } else {

                                        req.getSession()
                                                        .setAttribute(
                                                                        "flashSuccess",
                                                                        "Đã hủy món đang chờ");
                                }

                                resp.sendRedirect(
                                                req.getContextPath()
                                                                + "/customer/order?token="
                                                                + token);

                                return;
                        }

                        /*
                         * =================================================
                         * PAYMENT ACTIONS
                         * =================================================
                         */
                        RestaurantOrder order = orderDAO.findOpenOrderByToken(
                                        serviceToken);

                        if (order == null) {

                                throw new IllegalStateException(
                                                "Không có đơn hàng đang mở");
                        }

                        /*
                         * CASH
                         */
                        if ("/payment/cash".equals(
                                        path)) {

                                long paymentId = paymentDAO.createPending(

                                                order.getOrderId(),
                                                "CASH");

                                resp.sendRedirect(
                                                req.getContextPath()
                                                                + "/customer/payment?token="
                                                                + token
                                                                + "&paymentId="
                                                                + paymentId);

                                return;
                        }

                        /*
                         * ONLINE
                         */
                        if ("/payment/online".equals(
                                        path)) {

                                long paymentId = paymentDAO.createPending(

                                                order.getOrderId(),
                                                "ONLINE");

                                resp.sendRedirect(
                                                req.getContextPath()
                                                                + "/customer/payment?token="
                                                                + token
                                                                + "&paymentId="
                                                                + paymentId);

                                return;
                        }

                        /*
                         * ONLINE SUCCESS
                         */
                        if ("/payment/online-success".equals(
                                        path)) {

                                long paymentId = Long.parseLong(
                                                req.getParameter(
                                                                "paymentId"));

                                validatePaymentOwnership(

                                                paymentId,
                                                order.getOrderId(),
                                                serviceToken);

                                paymentDAO.confirmOnline(
                                                paymentId);

                                resp.sendRedirect(
                                                req.getContextPath()
                                                                + "/customer/payment?token="
                                                                + token
                                                                + "&paymentId="
                                                                + paymentId);

                                return;
                        }

                        /*
                         * ONLINE FAIL
                         */
                        if ("/payment/online-fail".equals(
                                        path)) {

                                long paymentId = Long.parseLong(
                                                req.getParameter(
                                                                "paymentId"));

                                validatePaymentOwnership(

                                                paymentId,
                                                order.getOrderId(),
                                                serviceToken);

                                paymentDAO.failOnline(
                                                paymentId);

                                req.getSession()
                                                .setAttribute(
                                                                "flashError",

                                                                "Thanh toán thất bại. "
                                                                                + "Bạn có thể thử lại hoặc chọn phương thức khác.");

                                resp.sendRedirect(
                                                req.getContextPath()
                                                                + "/customer/payment?token="
                                                                + token);

                                return;
                        }

                        resp.sendError(
                                        HttpServletResponse.SC_NOT_FOUND);

                } catch (Exception e) {

                        req.getSession()
                                        .setAttribute(
                                                        "flashError",
                                                        message(
                                                                        e));

                        String target;

                        if ("/order".equals(
                                        path)) {

                                target = "/customer/menu?token=";

                        } else if (path.startsWith(
                                        "/payment")) {

                                target = "/customer/payment?token=";

                        } else {

                                target = "/customer/order?token=";
                        }

                        resp.sendRedirect(
                                        req.getContextPath()
                                                        + target
                                                        + token);
                }
        }

        private void validatePaymentOwnership(
                        long paymentId,
                        long orderId,
                        String serviceToken)
                        throws Exception {

                Payment payment = paymentDAO.findById(
                                paymentId);

                if (payment == null
                                ||
                                payment.getOrderId() != orderId
                                ||
                                !paymentDAO.belongsToToken(
                                                paymentId,
                                                serviceToken)) {

                        throw new IllegalStateException(
                                        "Thanh toán không thuộc đơn hàng của bàn này");
                }
        }

        private String normalizeToken(
                        String token) {

                return token == null
                                ? null
                                : token.trim();
        }

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

        private String message(
                        Exception e) {

                String message = e.getCause() != null
                                &&
                                e.getCause()
                                                .getMessage() != null

                                                                ? e.getCause()
                                                                                .getMessage()

                                                                : e.getMessage();

                return message == null
                                ||
                                message.isBlank()

                                                ? "Không thể thực hiện thao tác. Vui lòng thử lại."

                                                : message;
        }
}