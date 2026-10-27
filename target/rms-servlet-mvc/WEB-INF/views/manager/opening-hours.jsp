<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!doctype html>
<html lang="vi">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>Giờ hoạt động</title>
        <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=theme-all-ui-1">
    </head>

    <body>
        <div class="layout">
            <aside class="sidebar">
                <div class="brand">RMS · Quản lý</div>
                <nav class="nav">
                    <a href="${ctx}/manager/tables">Bàn & QR</a>
                    <a href="${ctx}/manager/menu">Menu</a>
                    <a href="${ctx}/manager/inventory">Kho</a>
                    <a href="${ctx}/manager/opening-hours">Giờ hoạt động</a>
                    <a href="${ctx}/logout">Đăng xuất</a>
                </nav>

            </aside>

            <main class="main">
                <div class="container">
                    <div class="page-head">
                        <div>
                            <h1>Giờ hoạt động</h1>
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
                        <h2>1. Lịch hoạt động hàng tuần</h2>
                        <form method="post" action="${ctx}/manager/opening-hours">
                            <input type="hidden" name="action" value="saveWeekly">
                            <div class="table-wrap">
                                <table class="data-table">
                                    <thead>
                                        <tr>
                                            <th>Ngày</th>
                                            <th>Mở cửa</th>
                                            <th>Đóng cửa</th>
                                            <th>Nghỉ cả ngày</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <c:forEach var="h" items="${openingHours}">
                                            <tr>
                                                <td>
                                                    <b>
                                                        <c:out value="${h.dayName}" />
                                                    </b>
                                                </td>
                                                <td>
                                                    <input
                                                        type="time"
                                                        name="openTime_${h.dayOfWeek}"
                                                        value="${h.openTimeValue}">
                                                </td>
                                                <td>
                                                    <input
                                                        type="time"
                                                        name="closeTime_${h.dayOfWeek}"
                                                        value="${h.closeTimeValue}">
                                                </td>
                                                <td>
                                                    <label class="inline">
                                                        <input
                                                            type="checkbox"
                                                            name="closed_${h.dayOfWeek}"
                                                            value="true"
                                                            ${h.closed ? 'checked' : '' }>
                                                        Đóng cửa
                                                    </label>
                                                </td>
                                            </tr>
                                        </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                            <div style="margin-top:16px">
                                <button class="btn btn-primary">Lưu lịch tuần</button>
                            </div>
                        </form>

                    </section>

                    <section class="card section">
                        <h2>2. Ngày hoạt động đặc biệt</h2>
                        <form method="post" action="${ctx}/manager/opening-hours">
                            <input type="hidden" name="action" value="saveException">
                            <div class="grid grid-2">
                                <div class="form-group">
                                    <label>Ngày</label>
                                    <input type="date" name="exceptionDate" required>
                                </div>
                                <div class="form-group">
                                    <label>Lý do</label>
                                    <input
                                        type="text"
                                        name="reason"
                                        maxlength="500"
                                        placeholder="Ví dụ: Bảo trì nhà hàng">
                                </div>
                            </div>
                            <div class="grid grid-2">
                                <div class="form-group">
                                    <label>Giờ mở</label>
                                    <input type="time" name="exceptionOpenTime" value="10:00">
                                </div>
                                <div class="form-group">
                                    <label>Giờ đóng</label>
                                    <input type="time" name="exceptionCloseTime" value="22:00">
                                </div>
                            </div>
                            <div class="form-group">
                                <label class="inline">
                                    <input type="checkbox" name="exceptionClosed" value="true">
                                    Đóng cửa cả ngày
                                </label>
                            </div>
                            <button class="btn btn-primary">Lưu ngày đặc biệt</button>
                        </form>

                    </section>

                    <section class="card section">
                        <h2>Danh sách ngày đặc biệt</h2>
                        <c:choose>
                            <c:when test="${empty exceptions}">
                                <div class="empty">Chưa có ngày hoạt động đặc biệt.</div>
                            </c:when>
                            <c:otherwise>
                                <div class="table-wrap">
                                    <table class="data-table">
                                        <thead>
                                            <tr>
                                                <th>Ngày</th>
                                                <th>Lịch</th>
                                                <th>Lý do</th>
                                                <th>Thao tác</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <c:forEach var="e" items="${exceptions}">
                                                <tr>
                                                    <td>
                                                        <b>
                                                            <c:out value="${e.exceptionDate}" />
                                                        </b>
                                                    </td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${e.closed}">
                                                                <span class="badge badge-danger">Đóng cửa</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge badge-success">
                                                                    <c:out value="${e.scheduleText}" />
                                                                </span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${not empty e.reason}">
                                                                <c:out value="${e.reason}" />
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="muted">Không có</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                    <td>
                                                        <form method="post" action="${ctx}/manager/opening-hours">
                                                            <input type="hidden" name="action" value="deleteException">
                                                            <input
                                                                type="hidden"
                                                                name="exceptionDate"
                                                                value="${e.exceptionDate}">
                                                            <button
                                                                class="btn btn-sm btn-danger"
                                                                onclick="return confirm('Xóa ngày đặc biệt này?');">
                                                                Xóa
                                                            </button>
                                                        </form>

                                                    </td>
                                                </tr>
                                            </c:forEach>
                                        </tbody>
                                    </table>
                                </div>
                            </c:otherwise>
                        </c:choose>
                    </section>

                </div>
            </main>
        </div>
    </body>
</html>
