<%@ page contentType="text/html;charset=UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>

        <c:set var="ctx" value="${pageContext.request.contextPath}" />
        <c:set var="activePage" value="create-reservation" />

        <!doctype html>
        <html lang="vi">

        <head>

            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">

            <title>Tạo đặt bàn</title>

            <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=create-reservation-4">

        </head>

        <body>

            <div class="layout">

                <%@ include file="sidebar.jsp" %>

                    <main class="main">

                        <div class="container">

                            <div class="page-head">

                                <div>

                                    <h1>Tạo đặt bàn</h1>

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

                                <h2>Thông tin tìm bàn</h2>

                                <form method="get" action="${ctx}/receptionist/create-reservation">

                                    <input type="hidden" name="search" value="1">

                                    <div class="grid grid-3">

                                        <div class="form-group">

                                            <label>Ngày đặt bàn</label>

                                            <input type="date" name="reservationDate" value="${searchDate}" required>

                                        </div>

                                        <div class="form-group">

                                            <label>Giờ bắt đầu</label>

                                            <input type="time" name="startTime" value="${searchStart}" required>

                                        </div>

                                        <div class="form-group">

                                            <label>Số khách</label>

                                            <input type="number" name="partySize" min="1" value="${searchPartySize}"
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

                                    <h2>Danh sách bàn phù hợp</h2>

                                    <p class="muted">

                                        Ngày:
                                        <c:out value="${searchDate}" />

                                        · Giờ:

                                        <c:out value="${searchStart}" />

                                        -

                                        <c:out value="${searchEnd}" />

                                        · Số khách:

                                        <c:out value="${searchPartySize}" />

                                    </p>

                                    <c:choose>

                                        <c:when test="${empty suggestions}">

                                            <div class="alert alert-danger">
                                                Không có bàn hoặc nhóm bàn phù hợp
                                                với yêu cầu.
                                            </div>

                                        </c:when>

                                        <c:otherwise>

                                            <form method="post" action="${ctx}/receptionist/reservations">

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

                                                                        <input type="radio" name="candidateKey"
                                                                            value="${s.candidateKey}" ${loop.first
                                                                            ? 'checked' : '' } required>

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

                                                <h3 style="margin-top:24px">
                                                    Thông tin khách hàng
                                                </h3>

                                                <div class="grid grid-2">

                                                    <div class="form-group">

                                                        <label>Tên khách hàng</label>

                                                        <input type="text" name="customerName" maxlength="255" required>

                                                    </div>

                                                    <div class="form-group">

                                                        <label>Số điện thoại</label>

                                                        <input type="tel" name="phoneNumber" maxlength="20" required>

                                                    </div>

                                                </div>

                                                <div class="inline" style="margin-top:20px">

                                                    <button class="btn btn-primary" type="submit"
                                                        onclick="return confirm('Bạn xác nhận tạo Reservation này?');">
                                                        Ghi nhận đặt bàn
                                                    </button>

                                                    <a href="${ctx}/receptionist/reservations" class="btn btn-outline">
                                                        Xem danh sách đặt bàn
                                                    </a>

                                                </div>

                                            </form>

                                        </c:otherwise>

                                    </c:choose>

                                </section>

                            </c:if>

                        </div>

                    </main>

            </div>

        </body>

        </html>