<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>


<aside class="sidebar">

    <a class="brand"
       href="${ctx}/receptionist/reservations">
        RMS · Lễ tân
    </a>

    <div class="sidebar-section-title">
        QUẢN LÝ TIẾP NHẬN
    </div>

    <nav class="nav">

        <a href="${ctx}/receptionist/reservations"
           class="${activePage eq 'reservations' ? 'active' : ''}">

            <span class="nav-icon">▦</span>
            <span>Đặt bàn (Reservation)</span>

        </a>

        <a href="${ctx}/receptionist/walk-ins"
           class="${activePage eq 'walk-ins' ? 'active' : ''}">

            <span class="nav-icon">♟</span>
            <span>Khách trực tiếp (Walk-in)</span>

        </a>

        <a href="${ctx}/logout">
            <span class="nav-icon">↪</span>
            <span>Đăng xuất</span>
        </a>

    </nav>

</aside>