package com.fpt.rms.controller;

import com.fpt.rms.dao.StaffDAO;
import com.fpt.rms.model.Staff;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import org.mindrot.jbcrypt.BCrypt;
import java.io.IOException;

@WebServlet(urlPatterns = { "/login", "/logout" })
public class AuthServlet extends HttpServlet {
    private final StaffDAO staffDAO = new StaffDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (req.getServletPath().equals("/logout")) {
            HttpSession s = req.getSession(false);
            if (s != null)
                s.invalidate();
            resp.sendRedirect(req.getContextPath() + "/login?logout=1");
            return;
        }
        Staff staff = (Staff) req.getSession().getAttribute("staff");
        if (staff != null) {
            redirectByRole(req, resp, staff);
            return;
        }
        req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            Staff staff = staffDAO.findByUsername(req.getParameter("username"));
            String password = req.getParameter("password");
            if (staff == null || !"ACTIVE".equals(staff.getAccountStatus()) || password == null
                    || !BCrypt.checkpw(password, staff.getPassword())) {
                resp.sendRedirect(req.getContextPath() + "/login?error=1");
                return;
            }
            staff.setPassword(null);
            req.getSession(true).setAttribute("staff", staff);
            redirectByRole(req, resp, staff);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    private void redirectByRole(HttpServletRequest req, HttpServletResponse resp, Staff staff) throws IOException {
        String path = switch (staff.getRole()) {
        case "MANAGER" -> "/manager/tables";
        case "WAITER" -> "/waiter";
        case "KITCHEN" -> "/kitchen";
        case "RECEPTIONIST" -> "/receptionist";
        default -> "/login";
        };
        resp.sendRedirect(req.getContextPath() + path);
    }
}
