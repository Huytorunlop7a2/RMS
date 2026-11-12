package com.fpt.rms.controller;

import com.fpt.rms.dao.InventoryDAO;
import com.fpt.rms.dao.OrderDAO;

import com.fpt.rms.model.DishGroup;
import com.fpt.rms.model.Staff;
import com.fpt.rms.model.OrderDetail;
import com.fpt.rms.model.RestaurantOrder;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet("/kitchen")
public class KitchenServlet extends HttpServlet {
    private final OrderDAO orderDAO = new OrderDAO();
    private final InventoryDAO inventoryDAO = new InventoryDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            HttpSession session = req.getSession();

            String mode = req.getParameter("mode");

            if ("table".equals(mode) || "group".equals(mode)) {
                session.setAttribute("kitchenMode", mode);
            } else {
                Object saved = session.getAttribute("kitchenMode");
                mode = "group".equals(saved) ? "group" : "table";
            }

            List<RestaurantOrder> orders = orderDAO.findPendingKitchenOrders();
            req.setAttribute("kitchenMode", mode);
            req.setAttribute("orders", orders);
            req.setAttribute("dishGroups", buildDishGroups(orders));
            consumeFlash(req);
            req.getRequestDispatcher("/WEB-INF/views/kitchen/dashboard.jsp").forward(req, resp);
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

            if ("readyDetail".equals(action)) {

                String detailIdValue = req.getParameter("detailId");

                if (detailIdValue == null || detailIdValue.isBlank()) {
                    throw new IllegalArgumentException("Thiếu mã món");
                }

                long detailId = Long.parseLong(detailIdValue);

                inventoryDAO.markDetailReady(detailId, staff.getStaffId());

                req.getSession().setAttribute(
                        "flashSuccess",
                        "Món #" + detailId + " đã hoàn thành.");

            } else if ("readyOrder".equals(action)) {

                String orderIdValue = req.getParameter("orderId");

                if (orderIdValue == null || orderIdValue.isBlank()) {
                    throw new IllegalArgumentException("Thiếu mã đơn hàng");
                }

                long orderId = Long.parseLong(orderIdValue);

                inventoryDAO.markOrderReady(orderId, staff.getStaffId());

                req.getSession().setAttribute(
                        "flashSuccess",
                        "Đơn #" + orderId + " đã hoàn thành tất cả món!");

            } else {
                throw new IllegalArgumentException("Thao tác của bếp không hợp lệ");
            }
        } catch (Exception e) {
            req.getSession().setAttribute("flashError", message(e));
        }
        resp.sendRedirect(req.getContextPath() + "/kitchen");
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
        return value == null || value.isBlank() ? "Không thể xử lý món ăn" : value;
    }

    private List<DishGroup> buildDishGroups(
            List<RestaurantOrder> orders) {

        Map<Long, DishGroup> groups = new LinkedHashMap<>();

        for (RestaurantOrder order : orders) {

            for (OrderDetail detail : order.getDetails()) {

                if (!"PENDING".equals(detail.getStatus())) {
                    continue;
                }

                long menuItemId = detail.getMenuItemId();

                DishGroup group = groups.get(menuItemId);

                if (group == null) {
                    group = new DishGroup(detail);
                    groups.put(menuItemId, group);
                }

                group.addDetail(detail);
            }
        }

        return new ArrayList<>(groups.values());
    }
}
