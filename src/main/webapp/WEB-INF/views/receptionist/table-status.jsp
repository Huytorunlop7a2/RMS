<%@ page contentType="text/html;charset=UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>

        <c:set var="ctx" value="${pageContext.request.contextPath}" />
        <c:set var="activePage" value="table-status" />

        <!doctype html>
        <html lang="vi">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Trạng thái bàn</title>
            <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=table-status-reservation-1">
        </head>

        <body>
            <div class="layout">
                <%@ include file="sidebar.jsp" %>

                    <main class="main">
                        <div class="container">
                            <div class="page-head">
                                <div>
                                    <h1>Trạng thái bàn</h1>
                                    <p class="muted">
                                        Theo dõi bàn đang sử dụng bởi khách Walk-in hoặc Reservation đã check-in.
                                        Có thể trả riêng từng bàn hoặc trả toàn bộ nhóm bàn.
                                    </p>
                                </div>
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

                            <section class="card section">
                                <div class="page-head">
                                    <div>
                                        <h2>Danh sách bàn</h2>
                                        <p class="muted">
                                            ID bàn là mã định danh trong hệ thống. Reservation chỉ chiếm bàn thực tế sau
                                            khi check-in.
                                        </p>
                                    </div>
                                </div>

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
                                                <c:set var="walkInGroupLabel"
                                                    value="${activeWalkInGroupLabels[t.tableNumber]}" />
                                                <c:set var="reservationInfo"
                                                    value="${activeReservationTables[t.tableId]}" />
                                                <c:set var="served" value="${servedTableIds.contains(t.tableId)}" />

                                                <tr>
                                                    <td>
                                                        <b>
                                                            <c:out value="${t.tableNumber}" />
                                                        </b>
                                                        <br>
                                                        <span class="muted" style="font-size:12px">
                                                            ID bàn:
                                                            <c:out value="${t.tableId}" />
                                                        </span>

                                                        <c:if test="${not empty walkInGroupLabel}">
                                                            <br>
                                                            <span class="badge badge-warning" style="margin-top:6px">
                                                                <c:out value="${walkInGroupLabel}" />
                                                            </span>
                                                        </c:if>

                                                        <c:if test="${not empty reservationInfo}">
                                                            <br>
                                                            <span class="badge badge-info" style="margin-top:6px">
                                                                Reservation #
                                                                <c:out value="${reservationInfo.reservationId}" />
                                                                ·
                                                                <c:out value="${reservationInfo.tableNumbers}" />
                                                            </span>
                                                            <br>
                                                            <span class="muted" style="font-size:12px">
                                                                Khách:
                                                                <c:out value="${reservationInfo.customerName}" />
                                                            </span>
                                                        </c:if>
                                                    </td>

                                                    <td>
                                                        <c:out value="${t.capacity}" /> chỗ
                                                    </td>

                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${not t.active}">
                                                                <span class="badge">Ngừng dùng</span>
                                                            </c:when>
                                                            <c:when test="${t.status eq 'AVAILABLE'}">
                                                                <span class="badge badge-success">Trống</span>
                                                            </c:when>
                                                            <c:when test="${t.status eq 'OCCUPIED' and served}">
                                                                <span class="badge badge-info">Đã phục vụ</span>
                                                            </c:when>
                                                            <c:when test="${t.status eq 'OCCUPIED'}">
                                                                <span class="badge badge-warning">Đang sử dụng</span>
                                                            </c:when>
                                                            <c:when test="${t.status eq 'RESERVED'}">
                                                                <span class="badge badge-info">Đã đặt</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge">
                                                                    <c:out value="${t.status}" />
                                                                </span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>

                                                    <td>
                                                        <div class="inline">
                                                            <c:if test="${t.status eq 'OCCUPIED'}">
                                                                <form method="post"
                                                                    action="${ctx}/receptionist/table-status">
                                                                    <input type="hidden" name="action"
                                                                        value="releaseOne">
                                                                    <input type="hidden" name="id" value="${t.tableId}">
                                                                    <c:if test="${t.status eq 'OCCUPIED' and served}">
                                                                        <a href="${ctx}/receptionist/payment?token=${t.qrToken}"
                                                                            class="btn btn-sm btn-primary">
                                                                            Thanh toán
                                                                        </a>
                                                                    </c:if>
                                                                    <button type="submit" class="btn btn-sm btn-outline"
                                                                        onclick="return confirm('Chỉ trả bàn này? Nếu đây là bàn cuối của Reservation, Reservation sẽ được hoàn tất.');">
                                                                        Trả bàn này
                                                                    </button>
                                                                </form>
                                                            </c:if>

                                                            <c:if
                                                                test="${t.status eq 'OCCUPIED' and (activeWalkInTableIds.contains(t.tableId) or (not empty reservationInfo and reservationInfo.tableCount gt 1))}">
                                                                <form method="post"
                                                                    action="${ctx}/receptionist/table-status">
                                                                    <input type="hidden" name="action"
                                                                        value="releaseGroup">
                                                                    <input type="hidden" name="id" value="${t.tableId}">
                                                                    <button type="submit" class="btn btn-sm btn-danger"
                                                                        onclick="return confirm('Trả toàn bộ nhóm bàn đang gắn với bàn này?');">
                                                                        Trả cả nhóm
                                                                    </button>
                                                                </form>
                                                            </c:if>
                                                        </div>
                                                    </td>
                                                </tr>
                                            </c:forEach>

                                            <c:if test="${empty tables}">
                                                <tr>
                                                    <td colspan="4" class="empty">Chưa có dữ liệu bàn.</td>
                                                </tr>
                                            </c:if>
                                        </tbody>
                                    </table>
                                </div>
                            </section>
                        </div>
                    </main>
            </div>
        </body>

        </html>