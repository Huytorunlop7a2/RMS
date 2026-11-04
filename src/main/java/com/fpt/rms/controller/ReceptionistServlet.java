
package com.fpt.rms.controller;

import com.fpt.rms.dao.ReservationDAO;
import com.fpt.rms.dao.TableDAO;
import com.fpt.rms.dao.WalkInGroupDAO;
import com.fpt.rms.model.Staff;
import com.fpt.rms.model.TableCandidate;
import com.fpt.rms.service.ReservationService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Collections;
import java.util.List;

@WebServlet(urlPatterns = { "/receptionist", "/receptionist/*" })
public class ReceptionistServlet extends HttpServlet {

    private final ReservationDAO reservationDAO = new ReservationDAO();
    private final TableDAO tableDAO = new TableDAO();
    private final ReservationService reservationService = new ReservationService();
    private final WalkInGroupDAO walkInGroupDAO = new WalkInGroupDAO();

    @Override
    protected void doGet(
            HttpServletRequest req,
            HttpServletResponse resp) throws ServletException, IOException {

        String page = resolvePage(req);

        if (page == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        consumeFlash(req);

        if ("reservations".equals(page)) {
            loadReservationData(req);
            handleReservationSearch(req);
        } else {
            loadWalkInData(req);
        }

        String view = "reservations".equals(page)
                ? "/WEB-INF/views/receptionist/reservations.jsp"
                : "/WEB-INF/views/receptionist/walk-ins.jsp";

        req.getRequestDispatcher(view).forward(req, resp);
    }

    @Override
    protected void doPost(
            HttpServletRequest req,
            HttpServletResponse resp) throws IOException {

        String action = req.getParameter("action");
        String redirectPath = resolveRedirectPath(action);

        try {
            Staff staff = (Staff) req.getSession().getAttribute("staff");

            if (staff == null) {
                throw new IllegalStateException(
                        "Phiên đăng nhập đã hết hạn");
            }

            String successMessage;

            if ("create".equals(action)) {

                long reservationId = reservationService.confirmReservation(
                        req.getParameter("customerName"),
                        req.getParameter("phoneNumber"),
                        LocalDate.parse(req.getParameter("reservationDate")),
                        LocalTime.parse(req.getParameter("startTime")),
                        Integer.parseInt(req.getParameter("partySize")),
                        req.getParameter("candidateKey"),
                        staff.getStaffId());

                successMessage = "Đã tạo reservation #" + reservationId + " thành công";

            } else if ("checkin".equals(action)
                    || "cancel".equals(action)
                    || "noshow".equals(action)) {

                long reservationId = Long.parseLong(
                        req.getParameter("id"));

                reservationDAO.changeStatus(reservationId, action);

                successMessage = "Đã cập nhật trạng thái đặt bàn";

            } else if ("createWalkInGroup".equals(action)) {

                long groupId = walkInGroupDAO.createGroup(
                        req.getParameterValues("tableIds"),
                        staff.getStaffId());

                successMessage = "Đã gộp bàn walk-in thành công. Nhóm #" + groupId;

            } else if ("releaseOne".equals(action)
                    || "release".equals(action)) {

                long tableId = Long.parseLong(
                        req.getParameter("id"));

                boolean walkInMember = walkInGroupDAO.releaseSingleTableIfMember(tableId);

                if (!walkInMember) {
                    tableDAO.releaseTable(tableId);
                }

                successMessage = walkInMember
                        ? "Đã trả riêng bàn khỏi nhóm walk-in"
                        : "Đã trả bàn thành công";

            } else if ("releaseGroup".equals(action)) {

                long tableId = Long.parseLong(
                        req.getParameter("id"));

                boolean released = walkInGroupDAO.releaseWholeGroupIfMember(tableId);

                if (!released) {
                    throw new IllegalStateException(
                            "Bàn này không thuộc nhóm walk-in");
                }

                successMessage = "Đã trả toàn bộ nhóm bàn walk-in";

            } else {

                throw new IllegalArgumentException(
                        "Thao tác không hợp lệ");
            }

            req.getSession().setAttribute(
                    "flashSuccess",
                    successMessage);

        } catch (Exception e) {

            req.getSession().setAttribute(
                    "flashError",
                    message(e));
        }

        resp.sendRedirect(
                req.getContextPath() + redirectPath);
    }

    private String resolvePage(HttpServletRequest req) {

        String path = req.getPathInfo();

        if (path == null
                || "/".equals(path)
                || "/reservations".equals(path)) {
            return "reservations";
        }

        if ("/walk-ins".equals(path)) {
            return "walk-ins";
        }

        return null;
    }

    private String resolveRedirectPath(String action) {

        if ("create".equals(action)
                || "checkin".equals(action)
                || "cancel".equals(action)
                || "noshow".equals(action)) {
            return "/receptionist/reservations";
        }

        return "/receptionist/walk-ins";
    }

    private void loadReservationData(HttpServletRequest req) {

        req.setAttribute("reservations", Collections.emptyList());

        try {
            req.setAttribute(
                    "reservations",
                    reservationDAO.findAll());
        } catch (Exception e) {
            req.setAttribute("error", message(e));
        }
    }

    private void handleReservationSearch(HttpServletRequest req) {

        if (!"1".equals(req.getParameter("search"))) {
            return;
        }

        try {
            LocalDate date = LocalDate.parse(
                    req.getParameter("reservationDate"));

            LocalTime start = LocalTime.parse(
                    req.getParameter("startTime"));

            int partySize = Integer.parseInt(
                    req.getParameter("partySize"));

            List<TableCandidate> suggestions = reservationService.suggestTables(
                    date,
                    start,
                    partySize);

            req.setAttribute("searched", true);
            req.setAttribute("suggestions", suggestions);
            req.setAttribute("searchDate", date);
            req.setAttribute("searchStart", start);
            req.setAttribute("searchEnd", start.plusHours(2));
            req.setAttribute("searchPartySize", partySize);

        } catch (Exception e) {
            req.setAttribute("error", message(e));
        }
    }

    private void loadWalkInData(HttpServletRequest req) {

        req.setAttribute("tables", Collections.emptyList());
        req.setAttribute("activeWalkInTableIds", Collections.emptySet());
        req.setAttribute("activeWalkInGroupLabels", Collections.emptyMap());

        try {
            req.setAttribute("tables", tableDAO.findAll());

            req.setAttribute(
                    "activeWalkInTableIds",
                    walkInGroupDAO.findActiveGroupTableIds());

            req.setAttribute(
                    "activeWalkInGroupLabels",
                    walkInGroupDAO.findActiveGroupLabels());

        } catch (Exception e) {
            req.setAttribute("error", message(e));
        }
    }

    private void consumeFlash(HttpServletRequest req) {

        HttpSession session = req.getSession();

        req.setAttribute(
                "success",
                session.getAttribute("flashSuccess"));

        req.setAttribute(
                "error",
                session.getAttribute("flashError"));

        session.removeAttribute("flashSuccess");
        session.removeAttribute("flashError");
    }

    private String message(Exception e) {

        Throwable current = e;

        while (current.getCause() != null
                && current.getCause() != current) {
            current = current.getCause();
        }

        String value = current.getMessage();

        if (value == null || value.isBlank()) {
            value = e.getMessage();
        }

        return value == null || value.isBlank()
                ? "Không thể thực hiện thao tác"
                : value;
    }
}
