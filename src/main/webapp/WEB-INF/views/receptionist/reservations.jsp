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

                <title>Danh sách đặt bàn</title>

                <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=reservation-list-5">

                <style>
                    .filter-grid {
                        display: grid;
                        grid-template-columns:
                            minmax(220px, 2fr) minmax(150px, 1fr) minmax(170px, 1fr) minmax(120px, 0.7fr) auto;
                        gap: 14px;
                        align-items: end;
                        margin-top: 24px;
                    }

                    .filter-grid .form-group {
                        min-width: 0;
                        margin: 0;
                    }

                    .filter-grid input,
                    .filter-grid select {
                        width: 100%;
                        min-height: 46px;
                    }

                    .filter-actions {
                        display: flex;
                        gap: 10px;
                        margin-top: 18px;
                        flex-wrap: wrap;
                    }

                    .list-summary {
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                        flex-wrap: wrap;
                        gap: 12px;
                        margin: 22px 0 16px;
                    }

                    .list-summary span {
                        color: #64748b;
                        font-size: 14px;
                    }

                    .list-summary strong {
                        color: #172b4d;
                    }

                    .reservation-table {
                        min-width: 1000px;
                    }

                    .reservation-table td {
                        vertical-align: middle;
                    }

                    .reservation-actions {
                        display: flex;
                        align-items: center;
                        flex-wrap: wrap;
                        gap: 7px;
                    }

                    .reservation-pagination {
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        flex-wrap: wrap;
                        gap: 7px;
                        margin-top: 24px;
                    }

                    .reservation-pagination a,
                    .reservation-pagination span {
                        min-width: 38px;
                        height: 38px;
                        padding: 0 12px;
                        display: inline-flex;
                        align-items: center;
                        justify-content: center;
                        border: 1px solid #dce3ed;
                        border-radius: 8px;
                        text-decoration: none;
                        color: #263b59;
                        background: #fff;
                        font-weight: 600;
                    }

                    .reservation-pagination .current {
                        background: #f56612;
                        color: white;
                        border-color: #f56612;
                    }

                    .reservation-pagination .disabled {
                        color: #a0a8b5;
                        background: #f5f6f8;
                        pointer-events: none;
                    }

                    .reservation-empty {
                        text-align: center;
                        padding: 40px 15px;
                        color: #64748b;
                    }

                    .reservation-empty h3 {
                        margin-bottom: 8px;
                        color: #172b4d;
                    }

                    .reservation-empty p {
                        margin: 0;
                    }

                    @media (max-width: 1100px) {
                        .filter-grid {
                            grid-template-columns: repeat(2, minmax(0, 1fr));
                        }
                    }

                    @media (max-width: 550px) {
                        .filter-grid {
                            grid-template-columns: 1fr;
                        }
                    }
                </style>

            </head>

            <body>

                <div class="layout">

                    <%@ include file="sidebar.jsp" %>

                        <main class="main">

                            <div class="container">

                                <div class="page-head">

                                    <div>

                                        <h1>Danh sách đặt bàn</h1>

                                    </div>

                                    <div>

                                        <a href="${ctx}/receptionist/create-reservation" class="btn btn-primary">
                                            + Tạo đặt bàn
                                        </a>

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

                                    <h2>Bộ lọc Reservation</h2>
                                    
                                    <form method="get" action="${ctx}/receptionist/reservations"
                                        id="reservationFilterForm">

                                        <input type="hidden" name="page" value="1">

                                        <div class="filter-grid">

                                            <div class="form-group">

                                                <label for="keyword">
                                                    Tìm kiếm Reservation
                                                </label>

                                                <input type="search" id="keyword" name="keyword"
                                                    value="${fn:escapeXml(keyword)}"
                                                    placeholder="Mã đặt bàn, tên khách, số điện thoại, bàn...">

                                            </div>

                                            <div class="form-group">

                                                <label for="date">
                                                    Ngày đặt bàn
                                                </label>

                                                <input type="date" id="date" name="date" value="${filterDate}">

                                            </div>

                                            <div class="form-group">

                                                <label for="status">
                                                    Trạng thái
                                                </label>

                                                <select id="status" name="status">

                                                    <option value="" ${empty filterStatus ? 'selected' : '' }>
                                                        Tất cả trạng thái
                                                    </option>

                                                    <option value="CONFIRMED" ${filterStatus eq 'CONFIRMED' ? 'selected'
                                                        : '' }>
                                                        Đã xác nhận
                                                    </option>

                                                    <option value="CHECKED_IN" ${filterStatus eq 'CHECKED_IN'
                                                        ? 'selected' : '' }>
                                                        Đã check-in
                                                    </option>

                                                    <option value="COMPLETED" ${filterStatus eq 'COMPLETED' ? 'selected'
                                                        : '' }>
                                                        Hoàn tất
                                                    </option>

                                                    <option value="CANCELLED" ${filterStatus eq 'CANCELLED' ? 'selected'
                                                        : '' }>
                                                        Đã hủy
                                                    </option>

                                                    <option value="NO_SHOW" ${filterStatus eq 'NO_SHOW' ? 'selected'
                                                        : '' }>
                                                        No-show
                                                    </option>

                                                </select>

                                            </div>

                                            <div class="form-group">

                                                <label for="pageSize">
                                                    Số dòng/trang
                                                </label>

                                                <select id="pageSize" name="pageSize"
                                                    onchange="document.getElementById('reservationFilterForm').submit()">

                                                    <option value="10" ${pageSize eq 10 ? 'selected' : '' }>
                                                        10
                                                    </option>

                                                    <option value="20" ${pageSize eq 20 ? 'selected' : '' }>
                                                        20
                                                    </option>

                                                    <option value="50" ${pageSize eq 50 ? 'selected' : '' }>
                                                        50
                                                    </option>

                                                </select>

                                            </div>

                                            <div class="form-group">

                                                <button type="submit" class="btn btn-primary"
                                                    style="width:100%;min-height:46px">
                                                    Lọc
                                                </button>

                                            </div>

                                        </div>

                                        <div class="filter-actions">

                                            <a href="${ctx}/receptionist/reservations" class="btn btn-outline btn-sm">
                                                Xóa bộ lọc
                                            </a>

                                        </div>

                                    </form>

                                </section>

                                <section class="card section">

                                    <div class="list-summary">

                                        <span>

                                            Hiển thị

                                            <strong>${startRecord}</strong>

                                            -

                                            <strong>${endRecord}</strong>

                                            trong tổng số

                                            <strong>${totalRecords}</strong>

                                            Reservation

                                        </span>

                                        <span>
                                            Trang ${currentPage} / ${totalPages}
                                        </span>

                                    </div>

                                    <div class="table-wrap">

                                        <table class="data-table reservation-table">

                                            <thead>

                                                <tr>
                                                    <th>Khách hàng</th>
                                                    <th>Bàn</th>
                                                    <th>Ngày giờ</th>
                                                    <th>Số khách</th>
                                                    <th>Trạng thái</th>
                                                    <th>Thao tác</th>
                                                </tr>

                                            </thead>

                                            <tbody>

                                                <c:choose>

                                                    <c:when test="${empty reservations}">

                                                        <tr>

                                                            <td colspan="6">

                                                                <div class="reservation-empty">

                                                                    <h3>
                                                                        Không tìm thấy Reservation
                                                                    </h3>

                                                                    <p>
                                                                        Không có dữ liệu phù hợp
                                                                        với bộ lọc hiện tại.
                                                                    </p>

                                                                </div>

                                                            </td>

                                                        </tr>

                                                    </c:when>

                                                    <c:otherwise>

                                                        <c:forEach var="r" items="${reservations}">

                                                            <tr>

                                                                <td>

                                                                    <strong>
                                                                        <c:out value="${r.customerName}" />
                                                                    </strong>

                                                                    <br>

                                                                    <span class="muted">
                                                                        <c:out value="${r.phoneNumber}" />
                                                                    </span>

                                                                    <br>

                                                                    <small class="muted">
                                                                        Reservation #
                                                                        <c:out value="${r.reservationId}" />
                                                                    </small>

                                                                </td>

                                                                <td>

                                                                    <strong>
                                                                        <c:out value="${r.tableNumber}" />
                                                                    </strong>

                                                                    <br>

                                                                    <small class="muted">
                                                                        ID bàn chính:
                                                                        #
                                                                        <c:out value="${r.tableId}" />
                                                                    </small>

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

                                                                    <c:if
                                                                        test="${r.status eq 'CONFIRMED' and not empty r.actionHint}">

                                                                        <br>

                                                                        <small class="muted">
                                                                            <c:out value="${r.actionHint}" />
                                                                        </small>

                                                                    </c:if>

                                                                </td>

                                                                <td>

                                                                    <c:if test="${r.status eq 'CONFIRMED'}">

                                                                        <div class="reservation-actions">

                                                                            <c:if test="${r.canEdit}">

                                                                                <a class="btn btn-sm btn-outline"
                                                                                    href="${ctx}/receptionist/reservations/edit?id=${r.reservationId}">

                                                                                    <c:choose>

                                                                                        <c:when
                                                                                            test="${r.restrictedEdit}">
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

                                                                                    <input type="hidden" name="action"
                                                                                        value="checkin">

                                                                                    <input type="hidden" name="id"
                                                                                        value="${r.reservationId}">

                                                                                    <button
                                                                                        class="btn btn-sm btn-success">
                                                                                        Check-in
                                                                                    </button>

                                                                                </form>

                                                                            </c:if>

                                                                            <form method="post"
                                                                                action="${ctx}/receptionist/reservations"
                                                                                onsubmit="return confirm('Bạn có chắc chắn muốn hủy Reservation này?');">

                                                                                <input type="hidden" name="action"
                                                                                    value="cancel">

                                                                                <input type="hidden" name="id"
                                                                                    value="${r.reservationId}">

                                                                                <button class="btn btn-sm btn-danger">
                                                                                    Hủy
                                                                                </button>

                                                                            </form>

                                                                            <c:if test="${r.canNoShow}">

                                                                                <form method="post"
                                                                                    action="${ctx}/receptionist/reservations"
                                                                                    onsubmit="return confirm('Xác nhận khách không đến và chuyển Reservation sang No-show?');">

                                                                                    <input type="hidden" name="action"
                                                                                        value="noshow">

                                                                                    <input type="hidden" name="id"
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

                                                    </c:otherwise>

                                                </c:choose>

                                            </tbody>

                                        </table>

                                    </div>

                                    <c:if test="${totalPages gt 1}">

                                        <div class="reservation-pagination">

                                            <c:choose>

                                                <c:when test="${currentPage gt 1}">

                                                    <c:url var="prevPageUrl" value="/receptionist/reservations">

                                                        <c:param name="page" value="${currentPage - 1}" />

                                                        <c:param name="pageSize" value="${pageSize}" />

                                                        <c:param name="keyword" value="${keyword}" />

                                                        <c:param name="date" value="${filterDate}" />

                                                        <c:param name="status" value="${filterStatus}" />

                                                    </c:url>

                                                    <a href="${prevPageUrl}">
                                                        &laquo; Trước
                                                    </a>

                                                </c:when>

                                                <c:otherwise>

                                                    <span class="disabled">
                                                        &laquo; Trước
                                                    </span>

                                                </c:otherwise>

                                            </c:choose>

                                            <c:forEach var="p" items="${pageNumbers}">

                                                <c:choose>

                                                    <c:when test="${p eq currentPage}">

                                                        <span class="current">
                                                            ${p}
                                                        </span>

                                                    </c:when>

                                                    <c:otherwise>

                                                        <c:url var="pageUrl" value="/receptionist/reservations">

                                                            <c:param name="page" value="${p}" />

                                                            <c:param name="pageSize" value="${pageSize}" />

                                                            <c:param name="keyword" value="${keyword}" />

                                                            <c:param name="date" value="${filterDate}" />

                                                            <c:param name="status" value="${filterStatus}" />

                                                        </c:url>

                                                        <a href="${pageUrl}">
                                                            ${p}
                                                        </a>

                                                    </c:otherwise>

                                                </c:choose>

                                            </c:forEach>

                                            <c:choose>

                                                <c:when test="${currentPage lt totalPages}">

                                                    <c:url var="nextPageUrl" value="/receptionist/reservations">

                                                        <c:param name="page" value="${currentPage + 1}" />

                                                        <c:param name="pageSize" value="${pageSize}" />

                                                        <c:param name="keyword" value="${keyword}" />

                                                        <c:param name="date" value="${filterDate}" />

                                                        <c:param name="status" value="${filterStatus}" />

                                                    </c:url>

                                                    <a href="${nextPageUrl}">
                                                        Sau &raquo;
                                                    </a>

                                                </c:when>

                                                <c:otherwise>

                                                    <span class="disabled">
                                                        Sau &raquo;
                                                    </span>

                                                </c:otherwise>

                                            </c:choose>

                                        </div>

                                    </c:if>

                                </section>

                            </div>

                        </main>

                </div>

            </body>

            </html>