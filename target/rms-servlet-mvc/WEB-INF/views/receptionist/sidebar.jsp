<%@ page contentType="text/html;charset=UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>

        <aside class="sidebar">

            <a class="brand" href="${ctx}/receptionist/reservations">
                RMS · Lễ tân
            </a>

            <div class="sidebar-section-title">
                QUẢN LÝ TIẾP NHẬN
            </div>

            <nav class="nav">

                <a href="${ctx}/receptionist/create-reservation"
                    class="${activePage eq 'create-reservation' ? 'active' : ''}">

                    <span class="nav-icon">＋</span>
                    <span>Tạo đặt bàn</span>

                </a>

                <a href="${ctx}/receptionist/reservations" class="${activePage eq 'reservations' ? 'active' : ''}">

                    <span class="nav-icon">▦</span>
                    <span>Danh sách đặt bàn</span>

                </a>

                <a href="${ctx}/receptionist/walk-ins" class="${activePage eq 'walk-ins' ? 'active' : ''}">

                    <span class="nav-icon">♟</span>
                    <span>Khách trực tiếp (Walk-in)</span>

                </a>

                <a href="${ctx}/receptionist/table-status" class="${activePage eq 'table-status' ? 'active' : ''}">

                    <span class="nav-icon">▤</span>
                    <span>Trạng thái bàn</span>

                </a>

                <a href="${ctx}/logout">

                    <span class="nav-icon">↪</span>
                    <span>Đăng xuất</span>

                </a>

            </nav>

        </aside>