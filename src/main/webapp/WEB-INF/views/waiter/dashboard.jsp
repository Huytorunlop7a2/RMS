<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!doctype html>
<html lang="vi">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Phục vụ</title>
        <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=walkin-label-2">
    </head>

    <body>
        <div class="topbar">
            <span class="brand">RMS · Phục vụ</span>
            <a class="btn btn-outline" href="${ctx}/logout">Đăng xuất</a>
        </div>

        <main class="container">
            <div class="page-head">
                <div>
                    <h1>Bảng điều khiển phục vụ</h1>
                </div>
                <span class="muted">Tự làm mới mỗi 5 giây</span>
            </div>
            <c:if test="${not empty success}">
                <div class="alert alert-success">
                    <c:out value="${success}" />
                </div>
            </c:if>
            <c:if test="${not empty error}">
                <div class="alert alert-danger">
                    <c:out value="${error}" />
                </div>
            </c:if>

            <%--=====================================================1.
            READY=====================================================--%>

            <section class="section">
                <h2>1. Món đã sẵn sàng</h2>
                <c:if test="${empty readyDetails}">
                    <div class="card empty">Chưa có món nào cần phục vụ.</div>
                </c:if>
                <div class="grid grid-2">
                    <c:forEach var="d" items="${readyDetails}">
                        <div class="card ready-order">
                            <div class="page-head">
                                <div>
                                    <h3>
                                        Bàn
                                        <c:out value="${d.tableNumber}" />
                                    </h3>
                                    <span class="muted">
                                        Đơn #
                                        <c:out value="${d.orderId}" />
                                    </span>
                                </div>
                                <span class="badge badge-success">READY</span>
                            </div>
                            <b>
                                <c:out value="${d.menuItemName}" />
                                ×
                                <c:out value="${d.quantity}" />
                            </b>
                            <c:if test="${not empty d.note}">
                                <div class="muted" style="margin-top:6px">
                                    Ghi chú:
                                    <c:out value="${d.note}" />
                                </div>
                            </c:if>
                            <form method="post" action="${ctx}/waiter" style="margin-top:14px">
                                <input type="hidden" name="action" value="served">
                                <input type="hidden" name="id" value="${d.orderDetailId}">
                                <button class="btn btn-success" type="submit">Đã phục vụ</button>
                            </form>

                        </div>
                    </c:forEach>
                </div>
            </section>

            <%--=====================================================2.
            CASH=====================================================--%>

            <section class="section">
                <h2>2. Thanh toán tiền mặt chờ xác nhận</h2>
                <c:if test="${empty cashPayments}">
                    <div class="card empty">Không có yêu cầu thanh toán tiền mặt.</div>
                </c:if>
                <div class="grid grid-2">
                    <c:forEach var="p" items="${cashPayments}">
                        <div class="card">
                            <h3>
                                Đơn #
                                <c:out value="${p.orderId}" />
                            </h3>
                            <p class="muted">
                                Bàn
                                <c:out value="${p.tableNumber}" />
                            </p>
                            <div class="price">
                                <fmt:formatNumber value="${p.amount}" type="number" maxFractionDigits="0" />
                                ₫
                            </div>
                            <form method="post" action="${ctx}/waiter" style="margin-top:14px">
                                <input type="hidden" name="action" value="confirmCash">
                                <input type="hidden" name="id" value="${p.paymentId}">
                                <button
                                    class="btn btn-primary"
                                    type="submit"
                                    onclick="return confirm('Bạn đã nhận đủ tiền từ khách?');">
                                    Xác nhận đã nhận tiền
                                </button>
                            </form>

                        </div>
                    </c:forEach>
                </div>
            </section>

            <%--=====================================================3. WALK-IN
            MERGE=====================================================--%>

            <section class="card section">
                <h2>3. Gộp bàn cho khách walk-in</h2>
                <p class="muted">Chọn từ 2 đến 8 bàn trống. Các bàn phải có thể ghép theo layout.</p>
                <form method="post" action="${ctx}/waiter" onsubmit="return validateWalkInGroup();">
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
                        <span class="muted" id="walkInSelectedCount">Đã chọn: 0 bàn</span>
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

                                <%--=====================================QUAN TRỌNG MAP THEO
                                TABLE NUMBER=====================================--%>
                                <c:set var="walkInGroupLabel" value="${activeWalkInGroupLabels[t.tableNumber]}" />
                                <c:set var="reservationInfo" value="${activeReservationTables[t.tableId]}" />
                                <tr>

                                    <%-- TABLE --%>
                                    <td>
                                        <b>
                                            <c:out value="${t.tableNumber}" />
                                        </b>
                                        <br>
                                        <span class="muted" style="font-size:12px">
                                            ID bàn: <c:out value="${t.tableId}" />
                                        </span>

                                        <%-- WALK-IN GROUP LABEL --%>
                                        <c:if test="${not empty walkInGroupLabel}">
                                            <br>
                                            <span class="badge badge-warning" style="margin-top:6px">
                                                <c:out value="${walkInGroupLabel}" />
                                            </span>
                                        </c:if>

                                        <c:if test="${not empty reservationInfo}">
                                            <br>
                                            <span class="badge badge-info" style="margin-top:6px">
                                                Reservation #<c:out value="${reservationInfo.reservationId}" />
                                                · <c:out value="${reservationInfo.tableNumbers}" />
                                            </span>
                                            <br>
                                            <span class="muted" style="font-size:12px">
                                                Khách: <c:out value="${reservationInfo.customerName}" />
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
                                            <c:when test="${ t.status eq 'AVAILABLE' }">
                                                <span class="badge badge-success">Trống</span>
                                            </c:when>
                                            <c:when test="${ t.status eq 'OCCUPIED' }">
                                                <span class="badge badge-warning">Đang sử dụng</span>
                                            </c:when>
                                            <c:when test="${ t.status eq 'RESERVED' }">
                                                <span class="badge badge-info">Đã đặt</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge">
                                                    <c:out value="${t.status}" />
                                                </span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>

                                    <%-- ACTIONS --%>
                                    <td>
                                        <div class="inline">

                                            <%-- CALL ORDER --%>
                                            <c:if test="${t.active}">
                                                <c:url var="customerMenuUrl" value="/customer/menu">
                                                    <c:param name="token" value="${t.qrToken}" />
                                                </c:url>
                                                <a
                                                    class="btn btn-sm btn-primary"
                                                    href="${fn:escapeXml(customerMenuUrl)}"
                                                    target="_blank">
                                                    Gọi món hộ
                                                </a>
                                            </c:if>

                                            <%-- RELEASE SINGLE
                                            TABLE --%>
                                            <c:if test="${ t.status eq 'OCCUPIED' }">
                                                <form method="post" action="${ctx}/waiter">
                                                    <input type="hidden" name="action" value="releaseOne">
                                                    <input type="hidden" name="id" value="${t.tableId}">
                                                    <button
                                                        type="submit"
                                                        class="btn btn-sm btn-outline"
                                                        onclick="return confirm('Chỉ trả bàn này? Nếu đây là bàn cuối của Reservation, Reservation sẽ được hoàn tất.');">
                                                        Trả bàn này
                                                    </button>
                                                </form>

                                            </c:if>

                                            <%-- RELEASE WALK-IN OR RESERVATION GROUP --%>
                                            <c:if test="${t.status eq 'OCCUPIED' and (activeWalkInTableIds.contains(t.tableId) or (not empty reservationInfo and reservationInfo.tableCount gt 1))}">
                                                <form method="post" action="${ctx}/waiter">
                                                    <input type="hidden" name="action" value="releaseGroup">
                                                    <input type="hidden" name="id" value="${t.tableId}">
                                                    <button
                                                        type="submit"
                                                        class="btn btn-sm btn-danger"
                                                        onclick="return confirm('Trả toàn bộ nhóm bàn đang gắn với bàn này?');">
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

        </main>

        <script>
            const walkInCheckboxes = document.querySelectorAll(".walkin-table-checkbox");
            const selectedCountText = document.getElementById("walkInSelectedCount");
            function updateSelectedCount() {
                const selected = document.querySelectorAll(".walkin-table-checkbox:checked").length;
                if (selectedCountText) {
                    selectedCountText.textContent = "Đã chọn: " + selected + " bàn";
                }
            }
            walkInCheckboxes.forEach(function (checkbox) {
                checkbox.addEventListener("change", updateSelectedCount);
            });
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
                return confirm("Xác nhận gộp " + selected + " bàn?");
            }
            /*
               * Tự refresh nhưng không refresh
               * khi Waiter đang tick bàn.
               */
            setTimeout(function refreshPage() {
                const selected = document.querySelectorAll(".walkin-table-checkbox:checked").length;
                if (selected === 0) {
                    window.location.reload();
                } else {
                    setTimeout(refreshPage, 5000);
                }
            }, 5000);
        </script>
    </body>
</html>