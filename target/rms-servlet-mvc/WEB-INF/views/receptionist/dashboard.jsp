<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!doctype html>
<html lang="vi">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Lễ tân</title>
        <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=receptionist-walkin-3">
    </head>

    <body>

        <%--=========================================================TOPBAR=========================================================--%>
        <div class="topbar">
            <span class="brand">RMS · Lễ tân</span>
            <a class="btn btn-outline" href="${ctx}/logout">Đăng xuất</a>
        </div>

        <main class="container">

            <%--=====================================================PAGE
            HEAD=====================================================--%>
            <div class="page-head">
                <div>
                    <h1>Đặt bàn & quản lý bàn</h1>
                    <p class="muted">Quản lý đặt bàn, khách walk-in và trạng thái bàn hiện tại.</p>
                </div>
            </div>

            <%--=====================================================SUCCESS=====================================================--%>
            <c:if test="${not empty success}">
                <div class="alert alert-success">
                    <c:out value="${success}" />
                </div>
            </c:if>

            <%--=====================================================ERROR=====================================================--%>
            <c:if test="${not empty error}">
                <div class="alert alert-danger">
                    <c:out value="${error}" />
                </div>
            </c:if>

            <%--=====================================================1. SEARCH
            TABLE=====================================================--%>

            <section class="card section">
                <h2>1. Tìm bàn phù hợp</h2>
                <p class="muted">Hệ thống tìm bàn đơn hoặc nhóm bàn phù hợp với số khách và thời gian đặt bàn.</p>
                <form method="get" action="${ctx}/receptionist">
                    <input type="hidden" name="search" value="1">
                    <div class="grid grid-3">
                        <div class="form-group">
                            <label>Ngày</label>
                            <input type="date" name="reservationDate" value="${searchDate}" required>
                        </div>
                        <div class="form-group">
                            <label>Giờ bắt đầu</label>
                            <input type="time" name="startTime" value="${searchStart}" required>
                        </div>
                        <div class="form-group">
                            <label>Số khách</label>
                            <input type="number" min="1" name="partySize" value="${searchPartySize}" required>
                        </div>
                    </div>
                    <button class="btn btn-primary" type="submit">Tìm bàn</button>
                </form>

            </section>

            <%--=====================================================2. SEARCH
            RESULT=====================================================--%>
            <c:if test="${searched}">

                <section class="card section">
                    <h2>2. Chọn phương án bàn</h2>
                    <p class="muted">
                        Khung giờ
                        <c:out value="${searchStart}" />
                        -
                        <c:out value="${searchEnd}" />
                        ·
                        <c:out value="${searchPartySize}" />
                        khách.
                    </p>
                    <c:choose>
                        <c:when test="${empty suggestions}">
                            <div class="alert alert-danger">Không có bàn hoặc nhóm bàn phù hợp.</div>
                        </c:when>
                        <c:otherwise>
                            <form method="post" action="${ctx}/receptionist">
                                <input type="hidden" name="action" value="create">
                                <input type="hidden" name="reservationDate" value="${searchDate}">
                                <input type="hidden" name="startTime" value="${searchStart}">
                                <input type="hidden" name="partySize" value="${searchPartySize}">
                                <div class="table-wrap">
                                    <table class="data-table">
                                        <thead>
                                            <tr>
                                                <th>Chọn</th>
                                                <th>Phương án</th>
                                                <th>Bàn</th>
                                                <th>Tổng chỗ</th>
                                                <th>Ghế dư</th>
                                                <th>Loại</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <c:forEach var="s" items="${suggestions}" varStatus="loop">
                                                <tr>
                                                    <td>
                                                        <input
                                                            type="radio"
                                                            name="candidateKey"
                                                            value="${s.candidateKey}"
                                                            ${loop.first ? 'checked' : '' }>
                                                    </td>
                                                    <td>
                                                        <b>
                                                            <c:out value="${s.name}" />
                                                        </b>
                                                        <c:if test="${loop.first}">
                                                            <br>
                                                            <span class="badge badge-success">Khuyến nghị</span>
                                                        </c:if>
                                                    </td>
                                                    <td>
                                                        <c:out value="${s.tableDisplay}" />
                                                    </td>
                                                    <td>
                                                        <c:out value="${s.totalCapacity}" />
                                                    </td>
                                                    <td>
                                                        <c:out value="${s.waste}" />
                                                    </td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${s.tableCount gt 1}">Ghép bàn</c:when>
                                                            <c:otherwise>Bàn đơn</c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                </tr>
                                            </c:forEach>
                                        </tbody>
                                    </table>
                                </div>
                                <h3 style="margin-top:22px">Thông tin khách</h3>
                                <div class="grid grid-2">
                                    <div class="form-group">
                                        <label>Tên khách</label>
                                        <input name="customerName" required>
                                    </div>
                                    <div class="form-group">
                                        <label>Số điện thoại</label>
                                        <input name="phoneNumber" maxlength="20" required>
                                    </div>
                                </div>
                                <button class="btn btn-primary" type="submit">Xác nhận đặt bàn</button>
                            </form>

                        </c:otherwise>
                    </c:choose>
                </section>

            </c:if>

            <%--=====================================================3. WALK-IN
            GROUP=====================================================--%>

            <section class="card section">
                <h2>3. Gộp bàn cho khách walk-in</h2>
                <form method="post" action="${ctx}/receptionist" onsubmit="return validateWalkInGroup();">
                    <input type="hidden" name="action" value="createWalkInGroup">
                    <div class="table-wrap">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Chọn</th>
                                    <th>Bàn</th>
                                    <th>Sức chứa</th>
                                    <th>Trạng thái</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:forEach var="t" items="${tables}">
                                    <c:if test="${ t.active and t.status eq 'AVAILABLE' }">
                                        <tr>
                                            <td>
                                                <input
                                                    class="walkin-table-checkbox"
                                                    type="checkbox"
                                                    name="tableIds"
                                                    value="${t.tableId}">
                                            </td>
                                            <td>
                                                <b>
                                                    <c:out value="${t.tableNumber}" />
                                                </b>
                                            </td>
                                            <td>
                                                <c:out value="${t.capacity}" />
                                                chỗ
                                            </td>
                                            <td>
                                                <span class="badge badge-success">Trống</span>
                                            </td>
                                        </tr>
                                    </c:if>
                                </c:forEach>
                            </tbody>
                        </table>
                    </div>
                    <div class="inline" style="margin-top:16px">
                        <button type="submit" class="btn btn-primary">Gộp các bàn đã chọn</button>
                        <span id="walkInSelectedCount" class="muted">Đã chọn: 0 bàn</span>
                    </div>
                </form>

            </section>

            <%--=====================================================4. TABLE
            STATUS=====================================================--%>

            <section class="card section">
                <h2>4. Trạng thái bàn</h2>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Bàn</th>
                                <th>Sức chứa</th>
                                <th>Trạng thái</th>
                                <th>Thao tác</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="t" items="${tables}">

                                <%-- Map theo TABLE NUMBER: T01 ->
                                Nhóm #4 · T01, T02, T03
                                --%>
                                <c:set var="walkInGroupLabel" value="${activeWalkInGroupLabels[t.tableNumber]}" />
                                <tr>

                                    <%-- TABLE --%>
                                    <td>
                                        <b>
                                            <c:out value="${t.tableNumber}" />
                                        </b>

                                        <%-- GROUP LABEL --%>
                                        <c:if test="${not empty walkInGroupLabel}">
                                            <br>
                                            <span class="badge badge-warning" style="margin-top:6px">
                                                <c:out value="${walkInGroupLabel}" />
                                            </span>
                                        </c:if>
                                    </td>

                                    <%-- CAPACITY --%>
                                    <td>
                                        <c:out value="${t.capacity}" />
                                        chỗ
                                    </td>

                                    <%-- STATUS --%>
                                    <td>
                                        <c:choose>
                                            <c:when test="${!t.active}">
                                                <span class="badge">Ngừng dùng</span>
                                            </c:when>
                                            <c:when test="${t.status eq 'AVAILABLE'}">
                                                <span class="badge badge-success">Trống</span>
                                            </c:when>
                                            <c:when test="${t.status eq 'OCCUPIED'}">
                                                <span class="badge badge-warning">Đang sử dụng</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge">
                                                    <c:out value="${t.status}" />
                                                </span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>

                                    <%-- ACTION --%>
                                    <td>
                                        <div class="inline">

                                            <%-- RELEASE ONE
                                            --%>
                                            <c:if test="${t.status eq 'OCCUPIED'}">
                                                <form method="post" action="${ctx}/receptionist">
                                                    <input type="hidden" name="action" value="releaseOne">
                                                    <input type="hidden" name="id" value="${t.tableId}">
                                                    <button
                                                        type="submit"
                                                        class="btn btn-sm btn-outline"
                                                        onclick="return confirm('Chỉ trả bàn này?');">
                                                        Trả bàn này
                                                    </button>
                                                </form>

                                            </c:if>

                                            <%-- RELEASE
                                            GROUP
                                            --%>
                                            <c:if test="${ t.status eq 'OCCUPIED' and activeWalkInTableIds.contains( t.tableId ) }">
                                                <form method="post" action="${ctx}/receptionist">
                                                    <input type="hidden" name="action" value="releaseGroup">
                                                    <input type="hidden" name="id" value="${t.tableId}">
                                                    <button
                                                        type="submit"
                                                        class="btn btn-sm btn-danger"
                                                        onclick="return confirm('Trả toàn bộ nhóm bàn walk-in?');">
                                                        Trả cả nhóm
                                                    </button>
                                                </form>

                                            </c:if>
                                        </div>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </section>

            <%--=====================================================5.
            RESERVATIONS=====================================================--%>

            <section class="card section">
                <h2>5. Danh sách đặt bàn</h2>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Khách</th>
                                <th>Bàn</th>
                                <th>Ngày giờ</th>
                                <th>Số khách</th>
                                <th>Trạng thái</th>
                                <th>Thao tác</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="r" items="${reservations}">
                                <tr>
                                    <td>
                                        <b>
                                            <c:out value="${r.customerName}" />
                                        </b>
                                        <br>
                                        <span class="muted">
                                            <c:out value="${r.phoneNumber}" />
                                        </span>
                                    </td>
                                    <td>
                                        <b>
                                            <c:out value="${r.tableNumber}" />
                                        </b>
                                    </td>
                                    <td>
                                        <c:out value="${r.reservationDate}" />
                                        <br>
                                        <c:out value="${r.startTime}" />
                                        -
                                        <c:out value="${r.endTime}" />
                                    </td>
                                    <td>
                                        <c:out value="${r.partySize}" />
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${ r.status eq 'CONFIRMED' }">
                                                <span class="badge badge-warning">Đã xác nhận</span>
                                            </c:when>
                                            <c:when test="${ r.status eq 'CHECKED_IN' }">
                                                <span class="badge badge-success">Đã check-in</span>
                                            </c:when>
                                            <c:when test="${ r.status eq 'COMPLETED' }">
                                                <span class="badge badge-info">Hoàn tất</span>
                                            </c:when>
                                            <c:when test="${ r.status eq 'CANCELLED' }">
                                                <span class="badge badge-danger">Đã hủy</span>
                                            </c:when>
                                            <c:when test="${ r.status eq 'NO_SHOW' }">
                                                <span class="badge">No-show</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge">
                                                    <c:out value="${r.status}" />
                                                </span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td>
                                        <c:if test="${ r.status eq 'CONFIRMED' }">
                                            <div class="inline">
                                                <form method="post" action="${ctx}/receptionist">
                                                    <input type="hidden" name="action" value="checkin">
                                                    <input type="hidden" name="id" value="${r.reservationId}">
                                                    <button class="btn btn-sm btn-success">Check-in</button>
                                                </form>

                                                <form method="post" action="${ctx}/receptionist">
                                                    <input type="hidden" name="action" value="cancel">
                                                    <input type="hidden" name="id" value="${r.reservationId}">
                                                    <button class="btn btn-sm btn-danger">Hủy</button>
                                                </form>

                                                <form method="post" action="${ctx}/receptionist">
                                                    <input type="hidden" name="action" value="noshow">
                                                    <input type="hidden" name="id" value="${r.reservationId}">
                                                    <button class="btn btn-sm">No-show</button>
                                                </form>

                                            </div>
                                        </c:if>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </section>

        </main>

        <script>
            /* =====================================================
               WALK-IN SELECTION COUNTER
               ===================================================== */
            const walkInCheckboxes = document.querySelectorAll(".walkin-table-checkbox");
            const selectedCountText = document.getElementById("walkInSelectedCount");
            function updateWalkInCount() {
                const selected = document.querySelectorAll(".walkin-table-checkbox:checked").length;
                if (selectedCountText) {
                    selectedCountText.textContent = "Đã chọn: " + selected + " bàn";
                }
            }
            walkInCheckboxes.forEach(function (checkbox) {
                checkbox.addEventListener("change", updateWalkInCount);
            });
            /* =====================================================
               VALIDATE WALK-IN GROUP
               ===================================================== */
            function validateWalkInGroup() {
                const selected = document.querySelectorAll(".walkin-table-checkbox:checked").length;
                if (selected < 2) {
                    alert("Vui lòng chọn ít nhất 2 bàn.");
                    return false;
                }
                if (selected > 8) {
                    alert("Chỉ được gộp tối đa 8 bàn.");
                    return false;
                }
                return confirm("Xác nhận gộp " + selected + " bàn cho khách walk-in?");
            }
        </script>
    </body>
</html>
