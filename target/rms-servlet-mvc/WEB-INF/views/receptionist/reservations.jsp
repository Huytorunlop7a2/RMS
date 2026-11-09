
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="activePage" value="reservations" />

<!doctype html>
<html lang="vi">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>Quản lý đặt bàn</title>

    <link rel="stylesheet"
          href="${ctx}/assets/css/app.css?v=receptionist-sidebar-2">
</head>

<body>

<div class="layout">

    <%@ include file="sidebar.jsp" %>

    <main class="main">

        <div class="container">

            <div class="page-head">

                <div>
                    <h1>Quản lý đặt bàn</h1>

                    <p class="muted">
                        Tiếp nhận và quản lý lịch đặt bàn của khách hàng.
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

                <h2>Tìm bàn phù hợp</h2>

                <p class="muted">
                    Tìm bàn đơn hoặc nhóm bàn phù hợp với số khách
                    và thời gian đặt bàn.
                </p>

                <form method="get"
                      action="${ctx}/receptionist/reservations">

                    <input type="hidden"
                           name="search"
                           value="1">

                    <div class="grid grid-3">

                        <div class="form-group">

                            <label>Ngày</label>

                            <input type="date"
                                   name="reservationDate"
                                   value="${searchDate}"
                                   required>

                        </div>

                        <div class="form-group">

                            <label>Giờ bắt đầu</label>

                            <input type="time"
                                   name="startTime"
                                   value="${searchStart}"
                                   required>

                        </div>

                        <div class="form-group">

                            <label>Số khách</label>

                            <input type="number"
                                   min="1"
                                   name="partySize"
                                   value="${searchPartySize}"
                                   required>

                        </div>

                    </div>

                    <button class="btn btn-primary" type="submit">
                        Tìm bàn
                    </button>

                </form>

            </section>

            <c:if test="${searched}">

                <section class="card section">

                    <h2>Chọn phương án bàn</h2>

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

                            <div class="alert alert-danger">
                                Không có bàn hoặc nhóm bàn phù hợp.
                            </div>

                        </c:when>

                        <c:otherwise>

                            <form method="post"
                                  action="${ctx}/receptionist/reservations">

                                <input type="hidden"
                                       name="action"
                                       value="create">

                                <input type="hidden"
                                       name="reservationDate"
                                       value="${searchDate}">

                                <input type="hidden"
                                       name="startTime"
                                       value="${searchStart}">

                                <input type="hidden"
                                       name="partySize"
                                       value="${searchPartySize}">

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

                                            <c:forEach var="s"
                                                       items="${suggestions}"
                                                       varStatus="loop">

                                                <tr>

                                                    <td>

                                                        <input type="radio"
                                                               name="candidateKey"
                                                               value="${s.candidateKey}"
                                                               ${loop.first ? 'checked' : ''}>

                                                    </td>

                                                    <td>

                                                        <b>
                                                            <c:out value="${s.name}" />
                                                        </b>

                                                        <c:if test="${loop.first}">
                                                            <br>

                                                            <span class="badge badge-success">
                                                                Khuyến nghị
                                                            </span>
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

                                                            <c:when test="${s.tableCount gt 1}">
                                                                Ghép bàn
                                                            </c:when>

                                                            <c:otherwise>
                                                                Bàn đơn
                                                            </c:otherwise>

                                                        </c:choose>

                                                    </td>

                                                </tr>

                                            </c:forEach>

                                        </tbody>

                                    </table>

                                </div>

                                <h3 style="margin-top:22px">
                                    Thông tin khách
                                </h3>

                                <div class="grid grid-2">

                                    <div class="form-group">

                                        <label>Tên khách</label>

                                        <input name="customerName"
                                               required>

                                    </div>

                                    <div class="form-group">

                                        <label>Số điện thoại</label>

                                        <input name="phoneNumber"
                                               maxlength="20"
                                               required>

                                    </div>

                                </div>

                                <button class="btn btn-primary"
                                        type="submit">
                                    Ghi nhận đặt bàn
                                </button>

                            </form>

                        </c:otherwise>

                    </c:choose>

                </section>

            </c:if>

            <section class="card section">

                <h2>Danh sách đặt bàn</h2>

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

                                        <br>

                                        <span class="muted" style="font-size:12px">
                                            ID bàn chính: #
                                            <c:out value="${r.tableId}" />
                                        </span>

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

                                            <c:when test="${r.status eq 'CONFIRMED'}">

                                                <span class="badge badge-warning">
                                                    Đã xác nhận
                                                </span>

                                            </c:when>

                                            <c:when test="${r.status eq 'CHECKED_IN'}">

                                                <span class="badge badge-success">
                                                    Đã check-in
                                                </span>

                                            </c:when>

                                            <c:when test="${r.status eq 'COMPLETED'}">

                                                <span class="badge badge-info">
                                                    Hoàn tất
                                                </span>

                                            </c:when>

                                            <c:when test="${r.status eq 'CANCELLED'}">

                                                <span class="badge badge-danger">
                                                    Đã hủy
                                                </span>

                                            </c:when>

                                            <c:when test="${r.status eq 'NO_SHOW'}">

                                                <span class="badge">
                                                    No-show
                                                </span>

                                            </c:when>

                                            <c:otherwise>

                                                <span class="badge">
                                                    <c:out value="${r.status}" />
                                                </span>

                                            </c:otherwise>

                                        </c:choose>

                                        <c:if test="${r.status eq 'CONFIRMED'
                                                and not empty r.actionHint}">

                                            <br>

                                            <small class="muted">
                                                <c:out value="${r.actionHint}" />
                                            </small>

                                        </c:if>

                                    </td>

                                    <td>

                                        <c:if test="${r.status eq 'CONFIRMED'}">

                                            <div class="inline">

                                                <c:if test="${r.canEdit}">

                                                    <a class="btn btn-sm btn-outline"
                                                       href="${ctx}/receptionist/reservations/edit?id=${r.reservationId}">

                                                        <c:choose>

                                                            <c:when test="${r.restrictedEdit}">
                                                                Sửa hạn chế
                                                            </c:when>

                                                            <c:otherwise>
                                                                Sửa
                                                            </c:otherwise>

                                                        </c:choose>

                                                    </a>

                                                </c:if>

                                                <c:if test="${r.canCheckIn}">

                                                    <form method="post"
                                                          action="${ctx}/receptionist/reservations">

                                                        <input type="hidden"
                                                               name="action"
                                                               value="checkin">

                                                        <input type="hidden"
                                                               name="id"
                                                               value="${r.reservationId}">

                                                        <button class="btn btn-sm btn-success">
                                                            Check-in
                                                        </button>

                                                    </form>

                                                </c:if>

                                                <form method="post"
                                                      action="${ctx}/receptionist/reservations">

                                                    <input type="hidden"
                                                           name="action"
                                                           value="cancel">

                                                    <input type="hidden"
                                                           name="id"
                                                           value="${r.reservationId}">

                                                    <button class="btn btn-sm btn-danger">
                                                        Hủy
                                                    </button>

                                                </form>

                                                <c:if test="${r.canNoShow}">

                                                    <form method="post"
                                                          action="${ctx}/receptionist/reservations"
                                                          onsubmit="return confirm('Xác nhận khách không đến và chuyển Reservation sang No-show?');">

                                                        <input type="hidden"
                                                               name="action"
                                                               value="noshow">

                                                        <input type="hidden"
                                                               name="id"
                                                               value="${r.reservationId}">

                                                        <button class="btn btn-sm">
                                                            Xác nhận No-show
                                                        </button>

                                                    </form>

                                                </c:if>

                                            </div>

                                        </c:if>

                                    </td>

                                </tr>

                            </c:forEach>

                        </tbody>

                    </table>

                </div>

            </section>

        </div>

    </main>

</div>

</body>
</html>
