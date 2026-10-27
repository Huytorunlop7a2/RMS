package com.fpt.rms.filter;

import com.fpt.rms.model.Staff;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebFilter("/*")
public class AuthFilter implements Filter {
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;
        req.setCharacterEncoding("UTF-8");
        resp.setCharacterEncoding("UTF-8");
        String path = req.getRequestURI().substring(req.getContextPath().length());
        if (path.equals("/") || path.equals("/index.jsp") || path.equals("/login") || path.equals("/logout")
                || path.startsWith("/assets/") || path.startsWith("/customer/")) {
            chain.doFilter(request, response);
            return;
        }
        HttpSession session = req.getSession(false);
        Staff staff = session == null ? null : (Staff) session.getAttribute("staff");
        if (staff == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        String required = null;
        if (path.startsWith("/manager/"))
            required = "MANAGER";
        else if (path.equals("/waiter") || path.startsWith("/waiter/"))
            required = "WAITER";
        else if (path.equals("/kitchen") || path.startsWith("/kitchen/"))
            required = "KITCHEN";
        else if (path.equals("/receptionist") || path.startsWith("/receptionist/"))
            required = "RECEPTIONIST";
        if (required != null && !required.equals(staff.getRole())) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền truy cập khu vực này");
            return;
        }
        chain.doFilter(request, response);
    }
}
