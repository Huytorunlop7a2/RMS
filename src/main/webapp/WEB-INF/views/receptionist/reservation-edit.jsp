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

                <title>Chỉnh sửa Reservation</title>

                <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=receptionist-sidebar-2">
            </head>

            <body>

                <div class="layout">

                    <%@ include file="sidebar.jsp" %>

                        <main class="main">

                            <div class="container">

                                <div class="page-head">

                                    <div>

                                        <h1>
                                            Chỉnh sửa Reservation #
                                            <c:out value="${editingReservation.reservationId}" />
                                        </h1>

                                        <p class="muted">
                                            Chỉ Reservation đã xác nhận và chưa đến giờ bắt đầu
                                            mới được chỉnh sửa.
                                        </p>

                                    </div>

                                    <a class="btn btn-outline" href="${ctx}/receptionist/reservations">
                                        Quay lại
                                    </a>

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

                                    <h2>Thông tin Reservation hiện tại</h2>

                                    <div class="grid grid-3">

                                        <div>
                                            <span class="muted">Trạng thái</span>
                                            <p>
                                                <span class="badge badge-warning">
                                                    Đã xác nhận
                                                </span>
                                            </p>
                                        </div>

                                        <div>
                                            <span class="muted">Bàn hiện tại</span>
                                            <p>
                                                <strong>
                                                    <c:out value="${editingReservation.tableNumber}" />
                                                </strong>
                                            </p>
                                        </div>

                                        <div>
                                            <span class="muted">Số khách hiện tại</span>
                                            <p>
                                                <strong>
                                                    <c:out value="${editingReservation.partySize}" />
                                                    khách
                                                </strong>
                                            </p>
                                        </div>

                                    </div>

                                </section>

                                <section class="card section">

                                    <h2>1. Thông tin cần chỉnh sửa</h2>

                                    <p class="muted">
                                        Thay đổi thông tin rồi nhấn kiểm tra bàn phù hợp.
                                        Thời lượng Reservation hiện tại là 2 tiếng.
                                    </p>

                                    <form method="get" action="${ctx}/receptionist/reservations/edit">

                                        <input type="hidden" name="id" value="${editingReservation.reservationId}">

                                        <div class="grid grid-2">

                                            <div class="form-group">

                                                <label for="customerName">
                                                    Tên khách hàng
                                                </label>

                                                <input id="customerName" name="customerName" maxlength="255"
                                                    value="${fn:escapeXml(editCustomerName)}" required>

                                            </div>

                                            <div class="form-group">

                                                <label for="phoneNumber">
                                                    Số điện thoại
                                                </label>

                                                <input id="phoneNumber" name="phoneNumber" maxlength="20"
                                                    value="${fn:escapeXml(editPhoneNumber)}" required>

                                            </div>

                                            <div class="form-group">

                                                <label for="reservationDate">
                                                    Ngày đặt
                                                </label>

                                                <input id="reservationDate" type="date" name="reservationDate"
                                                    value="${editDate}" min="${today}" required>

                                            </div>

                                            <div class="form-group">

                                                <label for="startTime">
                                                    Giờ bắt đầu
                                                </label>

                                                <input id="startTime" type="time" name="startTime" value="${editStart}"
                                                    required>

                                            </div>

                                            <div class="form-group">

                                                <label for="partySize">
                                                    Số lượng khách
                                                </label>

                                                <input id="partySize" type="number" name="partySize" min="1" max="100"
                                                    value="${editPartySize}" required>

                                            </div>

                                            <div class="form-group">

                                                <label>
                                                    Giờ kết thúc dự kiến
                                                </label>

                                                <input type="time" value="${editEnd}" disabled>

                                            </div>

                                        </div>

                                        <div class="form-group">

                                            <label for="reason">
                                                Lý do chỉnh sửa
                                            </label>

                                            <input id="reason" name="reason" maxlength="500"
                                                value="${fn:escapeXml(editReason)}"
                                                placeholder="Ví dụ: Khách tăng số lượng người">

                                        </div>

                                        <button class="btn btn-primary" type="submit" name="search" value="1">

                                            Kiểm tra bàn phù hợp

                                        </button>

                                    </form>

                                </section>

                                <section class="card section">

                                    <h2>2. Chọn phương án bàn</h2>

                                    <p class="muted">
                                        Hệ thống không tính những bàn đang được chính
                                        Reservation này giữ là bàn bận.
                                        Các Reservation khác vẫn được kiểm tra bình thường.
                                    </p>

                                    <c:if test="${not empty editSearchError}">

                                        <div class="alert alert-danger">
                                            <c:out value="${editSearchError}" />
                                        </div>

                                    </c:if>

                                    <c:choose>

                                        <c:when test="${empty suggestions}">

                                            <div class="alert alert-danger">

                                                Không có bàn hoặc nhóm bàn phù hợp
                                                với thông tin mới.

                                                Hãy thay đổi ngày, giờ hoặc số lượng khách
                                                rồi kiểm tra lại.

                                            </div>

                                        </c:when>

                                        <c:otherwise>

                                            <form method="post" action="${ctx}/receptionist/reservations/edit">

                                                <input type="hidden" name="action" value="update">

                                                <input type="hidden" name="id"
                                                    value="${editingReservation.reservationId}">

                                                <input type="hidden" name="customerName"
                                                    value="${fn:escapeXml(editCustomerName)}">

                                                <input type="hidden" name="phoneNumber"
                                                    value="${fn:escapeXml(editPhoneNumber)}">

                                                <input type="hidden" name="reservationDate" value="${editDate}">

                                                <input type="hidden" name="startTime" value="${editStart}">

                                                <input type="hidden" name="partySize" value="${editPartySize}">

                                                <input type="hidden" name="reason" value="${fn:escapeXml(editReason)}">

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

                                                            <c:forEach var="candidate" items="${suggestions}"
                                                                varStatus="loop">

                                                                <tr>

                                                                    <td>

                                                                        <input type="radio" name="candidateKey"
                                                                            value="${candidate.candidateKey}"
                                                                            ${candidate.candidateKey eq
                                                                            selectedCandidateKey ? 'checked' : '' }
                                                                            required>

                                                                    </td>

                                                                    <td>

                                                                        <strong>
                                                                            <c:out value="${candidate.name}" />
                                                                        </strong>

                                                                        <c:if
                                                                            test="${candidate.candidateKey eq currentTableIds}">

                                                                            <br>

                                                                            <span class="badge badge-info">
                                                                                Bàn hiện tại
                                                                            </span>

                                                                        </c:if>

                                                                        <c:if test="${loop.first}">

                                                                            <br>

                                                                            <span class="badge badge-success">
                                                                                Phương án tối ưu
                                                                            </span>

                                                                        </c:if>

                                                                    </td>

                                                                    <td>
                                                                        <c:out value="${candidate.tableDisplay}" />
                                                                    </td>

                                                                    <td>
                                                                        <c:out value="${candidate.totalCapacity}" />
                                                                    </td>

                                                                    <td>
                                                                        <c:out value="${candidate.waste}" />
                                                                    </td>

                                                                    <td>

                                                                        <c:choose>

                                                                            <c:when test="${candidate.tableCount gt 1}">
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

                                                <div class="inline" style="margin-top:18px">

                                                    <button class="btn btn-primary" type="submit"
                                                        onclick="return confirm('Bạn xác nhận lưu thay đổi Reservation này?');">

                                                        Lưu thay đổi

                                                    </button>

                                                    <a class="btn btn-outline" href="${ctx}/receptionist/reservations">

                                                        Hủy chỉnh sửa

                                                    </a>

                                                </div>

                                            </form>

                                        </c:otherwise>

                                    </c:choose>

                                </section>

                            </div>

                        </main>

                </div>

            </body>

            </html>