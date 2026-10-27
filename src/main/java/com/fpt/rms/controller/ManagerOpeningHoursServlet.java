package com.fpt.rms.controller;

import com.fpt.rms.dao.OpeningHourDAO;

import com.fpt.rms.model.OpeningException;
import com.fpt.rms.model.OpeningHour;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

import java.time.LocalDate;
import java.time.LocalTime;

import java.util.ArrayList;
import java.util.List;

@WebServlet("/manager/opening-hours")
public class ManagerOpeningHoursServlet extends HttpServlet {
    private final OpeningHourDAO openingHourDAO = new OpeningHourDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("openingHours", openingHourDAO.findAll());
            req.setAttribute("exceptions", openingHourDAO.findAllExceptions());
            consumeFlash(req);
            req.getRequestDispatcher("/WEB-INF/views/manager/opening-hours.jsp").forward(req, resp);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            String action = req.getParameter("action");
            if ("saveWeekly".equals(action)) {
                saveWeekly(req);
                req.getSession().setAttribute("flashSuccess", "Đã cập nhật lịch hoạt động trong tuần");
            } else if ("saveException".equals(action)) {
                saveException(req);
                req.getSession().setAttribute("flashSuccess", "Đã lưu ngày hoạt động đặc biệt");
            } else if ("deleteException".equals(action)) {
                LocalDate date = LocalDate.parse(req.getParameter("exceptionDate"));
                openingHourDAO.deleteException(date);
                req.getSession().setAttribute("flashSuccess", "Đã xóa ngày hoạt động đặc biệt");
            } else {
                throw new IllegalArgumentException("Thao tác không hợp lệ");
            }
        } catch (Exception e) {
            req.getSession().setAttribute("flashError", message(e));
        }
        resp.sendRedirect(req.getContextPath() + "/manager/opening-hours");
    }

    private void saveWeekly(HttpServletRequest req) throws Exception {
        List<OpeningHour> hours = new ArrayList<>();
        for (int day = 1; day <= 7; day++) {
            boolean closed = req.getParameter("closed_" + day) != null;
            LocalTime openTime = null;
            LocalTime closeTime = null;
            if (!closed) {
                String openValue = req.getParameter("openTime_" + day);
                String closeValue = req.getParameter("closeTime_" + day);
                if (openValue == null || openValue.isBlank() || closeValue == null || closeValue.isBlank()) {
                    throw new IllegalArgumentException("Vui lòng nhập đầy đủ giờ mở và đóng cửa");
                }
                openTime = LocalTime.parse(openValue);
                closeTime = LocalTime.parse(closeValue);
            }
            hours.add(new OpeningHour(day, openTime, closeTime, closed));
        }
        openingHourDAO.saveAll(hours);
    }

    private void saveException(HttpServletRequest req) throws Exception {
        String dateValue = req.getParameter("exceptionDate");
        if (dateValue == null || dateValue.isBlank()) {
            throw new IllegalArgumentException("Vui lòng chọn ngày đặc biệt");
        }
        LocalDate date = LocalDate.parse(dateValue);
        boolean closed = req.getParameter("exceptionClosed") != null;
        LocalTime openTime = null;
        LocalTime closeTime = null;
        if (!closed) {
            String openValue = req.getParameter("exceptionOpenTime");
            String closeValue = req.getParameter("exceptionCloseTime");
            if (openValue == null || openValue.isBlank() || closeValue == null || closeValue.isBlank()) {
                throw new IllegalArgumentException("Vui lòng nhập giờ mở và đóng cửa cho ngày đặc biệt");
            }
            openTime = LocalTime.parse(openValue);
            closeTime = LocalTime.parse(closeValue);
        }
        OpeningException exception = new OpeningException(date, openTime, closeTime, closed,
                req.getParameter("reason"));
        openingHourDAO.saveException(exception);
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
        return value == null || value.isBlank() ? "Không thể cập nhật giờ hoạt động" : value;
    }
}
