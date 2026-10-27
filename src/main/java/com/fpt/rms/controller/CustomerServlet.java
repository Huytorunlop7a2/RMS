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
public class CustomerServlet extends HttpServlet {
    private final TableDAO tableDAO = new TableDAO();
    private final MenuDAO menuDAO = new MenuDAO();
    private final OrderDAO orderDAO = new OrderDAO();
    private final PaymentDAO paymentDAO = new PaymentDAO();
    private final WalkInGroupDAO walkInGroupDAO = new WalkInGroupDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            String path = req.getPathInfo() == null ? "/menu" : req.getPathInfo();
            String token = normalizeToken(req.getParameter("token"));
            RestaurantTable table = tableDAO.findByToken(token);
            if (table == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Mã QR bàn không hợp lệ hoặc bàn đã ngừng dùng");
                return;
            }
            String serviceToken = walkInGroupDAO.resolveServiceToken(token);
            req.setAttribute("table", table);
            req.setAttribute("token", token);
            consumeFlash(req);
            if ("/menu".equals(path)) {
                req.setAttribute("items", menuDAO.findAvailableItems());
                RestaurantOrder openOrder = orderDAO.findOpenOrderByToken(serviceToken);
                req.setAttribute("openOrder", openOrder);
                if (openOrder != null) {
                    req.setAttribute("paymentPending", paymentDAO.findPendingByOrder(openOrder.getOrderId()) != null);
                }
                req.getRequestDispatcher("/WEB-INF/views/customer/menu.jsp").forward(req, resp);
                return;
            }
            if ("/order".equals(path)) {
                RestaurantOrder order = orderDAO.findOpenOrderByToken(serviceToken);
                req.setAttribute("order", order);
                if (order != null) {
                    req.setAttribute("total", orderDAO.total(order.getOrderId()));
                    req.setAttribute("canPay", orderDAO.canPay(order.getOrderId()));
                    req.setAttribute("paymentPending", paymentDAO.findPendingByOrder(order.getOrderId()) != null);
                }
                req.getRequestDispatcher("/WEB-INF/views/customer/order.jsp").forward(req, resp);
                return;
            }
            if ("/payment".equals(path)) {
                showPayment(req, resp, serviceToken);
                return;
            }
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    private void showPayment(HttpServletRequest req, HttpServletResponse resp, String serviceToken) throws Exception {
        String paymentIdValue = req.getParameter("paymentId");
        Payment selectedPayment = null;
        if (paymentIdValue != null && !paymentIdValue.isBlank()) {
            long paymentId;
            try {
                paymentId = Long.parseLong(paymentIdValue);
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException("Mã thanh toán không hợp lệ");
            }
            selectedPayment = paymentDAO.findById(paymentId);
            if (selectedPayment != null && !paymentDAO.belongsToToken(paymentId, serviceToken)) {
                selectedPayment = null;
            }
        }
        if (selectedPayment != null && "PAID".equals(selectedPayment.getPaymentStatus())) {
            req.setAttribute("paidSuccess", true);
            req.setAttribute("paidPayment", selectedPayment);
            req.getRequestDispatcher("/WEB-INF/views/customer/payment.jsp").forward(req, resp);
            return;
        }
        RestaurantOrder order = orderDAO.findOpenOrderByToken(serviceToken);
        if (order == null) {
            req.setAttribute("noOpenOrder", true);
            req.getRequestDispatcher("/WEB-INF/views/customer/payment.jsp").forward(req, resp);
            return;
        }
        req.setAttribute("order", order);
        req.setAttribute("total", orderDAO.total(order.getOrderId()));
        req.setAttribute("canPay", orderDAO.canPay(order.getOrderId()));
        if (selectedPayment == null || selectedPayment.getOrderId() != order.getOrderId()
                || !"PENDING".equals(selectedPayment.getPaymentStatus())) {
            selectedPayment = paymentDAO.findPendingByOrder(order.getOrderId());
        }
        req.setAttribute("pendingPayment", selectedPayment);
        req.getRequestDispatcher("/WEB-INF/views/customer/payment.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String token = normalizeToken(req.getParameter("token"));
        String path = req.getPathInfo() == null ? "" : req.getPathInfo();
        try {
            RestaurantTable table = tableDAO.findByToken(token);
            if (table == null) {
                throw new IllegalArgumentException("Mã QR bàn không hợp lệ");
            }
            String serviceToken = walkInGroupDAO.resolveServiceToken(token);
            if ("/order".equals(path)) {
                orderDAO.submitOrder(serviceToken, req.getParameterValues("itemId"), req.getParameterValues("quantity"),
                        req.getParameterValues("note"));
                req.getSession().setAttribute("flashSuccess", "Đã gửi món xuống bếp");
                resp.sendRedirect(req.getContextPath() + "/customer/order?token=" + token);
                return;
            }
            if ("/cancel".equals(path)) {
                long detailId = Long.parseLong(req.getParameter("detailId"));
                boolean orderClosed = orderDAO.cancelDetail(serviceToken, detailId);
                if (orderClosed) {
                    req.getSession().setAttribute("flashSuccess", "Đã hủy món cuối cùng. " + "Đơn hàng đã được đóng. "
                            + "Bàn vẫn được giữ cho đến khi nhân viên trả bàn.");
                } else {
                    req.getSession().setAttribute("flashSuccess", "Đã hủy món đang chờ");
                }
                resp.sendRedirect(req.getContextPath() + "/customer/order?token=" + token);
                return;
            }
            RestaurantOrder order = orderDAO.findOpenOrderByToken(serviceToken);
            if (order == null) {
                throw new IllegalStateException("Không có đơn hàng đang mở");
            }
            if ("/payment/cash".equals(path)) {
                long paymentId = paymentDAO.createPending(order.getOrderId(), "CASH");
                resp.sendRedirect(
                        req.getContextPath() + "/customer/payment?token=" + token + "&paymentId=" + paymentId);
                return;
            }
            if ("/payment/online".equals(path)) {
                long paymentId = paymentDAO.createPending(order.getOrderId(), "ONLINE");
                resp.sendRedirect(
                        req.getContextPath() + "/customer/payment?token=" + token + "&paymentId=" + paymentId);
                return;
            }
            if ("/payment/online-success".equals(path)) {
                long paymentId = Long.parseLong(req.getParameter("paymentId"));
                validatePaymentOwnership(paymentId, order.getOrderId(), serviceToken);
                paymentDAO.confirmOnline(paymentId);
                resp.sendRedirect(
                        req.getContextPath() + "/customer/payment?token=" + token + "&paymentId=" + paymentId);
                return;
            }
            if ("/payment/online-fail".equals(path)) {
                long paymentId = Long.parseLong(req.getParameter("paymentId"));
                validatePaymentOwnership(paymentId, order.getOrderId(), serviceToken);
                paymentDAO.failOnline(paymentId);
                req.getSession().setAttribute("flashError",
                        "Thanh toán thất bại. " + "Bạn có thể thử lại hoặc chọn phương thức khác.");
                resp.sendRedirect(req.getContextPath() + "/customer/payment?token=" + token);
                return;
            }
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        } catch (Exception e) {
            req.getSession().setAttribute("flashError", message(e));
            String target;
            if ("/order".equals(path)) {
                target = "/customer/menu?token=";
            } else if (path.startsWith("/payment")) {
                target = "/customer/payment?token=";
            } else {
                target = "/customer/order?token=";
            }
            resp.sendRedirect(req.getContextPath() + target + token);
        }
    }

    private void validatePaymentOwnership(long paymentId, long orderId, String serviceToken) throws Exception {
        Payment payment = paymentDAO.findById(paymentId);
        if (payment == null || payment.getOrderId() != orderId || !paymentDAO.belongsToToken(paymentId, serviceToken)) {
            throw new IllegalStateException("Thanh toán không thuộc đơn hàng của bàn này");
        }
    }

    private String normalizeToken(String token) {
        return token == null ? null : token.trim();
    }

    private void consumeFlash(HttpServletRequest req) {
        HttpSession session = req.getSession();
        req.setAttribute("success", session.getAttribute("flashSuccess"));
        req.setAttribute("error", session.getAttribute("flashError"));
        session.removeAttribute("flashSuccess");
        session.removeAttribute("flashError");
    }

    private String message(Exception e) {
        String message = e.getCause() != null && e.getCause().getMessage() != null ? e.getCause().getMessage()
                : e.getMessage();
        return message == null || message.isBlank() ? "Không thể thực hiện thao tác. Vui lòng thử lại." : message;
    }
}
