<%@ page contentType="text/html;charset=UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

            <c:set var="ctx" value="${pageContext.request.contextPath}" />

            <!doctype html>

            <html lang="vi">

            <head>

                <meta charset="utf-8">

                <meta name="viewport" content="width=device-width,initial-scale=1">

                <title>
                    Quản lý bàn
                </title>

                <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=theme-all-ui-1">

            </head>

            <body>

                <div class="layout">

                    <aside class="sidebar">

                        <div class="brand">
                            RMS · Quản lý
                        </div>


                        <nav class="nav">

                            <a href="${ctx}/manager/tables">
                                Bàn & QR
                            </a>

                            <a href="${ctx}/manager/menu">
                                Menu
                            </a>

                            <a href="${ctx}/manager/inventory">
                                Kho
                            </a>

                            <a href="${ctx}/manager/opening-hours">
                                Giờ hoạt động
                            </a>

                            <a href="${ctx}/logout">
                                Đăng xuất
                            </a>

                        </nav>

                    </aside>


                    <main class="main">

                        <div class="container">

                            <div class="page-head">

                                <div>

                                    <h1>
                                        Quản lý bàn & sơ đồ ghép bàn
                                    </h1>


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


                            <div class="grid grid-2 section">


                                <section class="card">

                                    <h2>
                                        Tạo bàn mới
                                    </h2>


                                    <form method="post" action="${ctx}/manager/tables">

                                        <input type="hidden" name="action" value="create">


                                        <div class="form-group">

                                            <label>
                                                Số bàn
                                            </label>

                                            <input type="text" name="tableNumber" placeholder="Ví dụ: T09"
                                                maxlength="50" required>

                                        </div>


                                        <div class="form-group">

                                            <label>
                                                Sức chứa
                                            </label>

                                            <input type="number" name="capacity" min="1" max="100" placeholder="4"
                                                required>

                                        </div>


                                        <button type="submit" class="btn btn-primary">

                                            Tạo bàn

                                        </button>

                                    </form>

                                </section>


                                <section class="card">

                                    <h2>
                                        Cấu hình sơ đồ bàn
                                    </h2>



                                    <form method="post" action="${ctx}/manager/tables">

                                        <input type="hidden" name="action" value="saveRowLayout">


                                        <div class="form-group">

                                            <label>
                                                Khu vực
                                            </label>

                                            <input type="text" name="areaCode" placeholder="Ví dụ: A" maxlength="50"
                                                required>

                                        </div>


                                        <div class="form-group">

                                            <label>
                                                Hàng
                                            </label>

                                            <input type="number" name="rowNo" min="1" placeholder="1" required>

                                        </div>


                                        <div class="form-group">

                                            <label>
                                                Các bàn từ trái sang phải
                                            </label>

                                            <input type="text" name="tableNumbers" placeholder="T01,T02,T03,T04"
                                                required>

                                        </div>


                                        <button type="submit" class="btn btn-primary">

                                            Lưu sơ đồ hàng

                                        </button>

                                    </form>

                                </section>

                            </div>


                            <section class="card section">

                                <h2>
                                    Ghi đè quy tắc kề cận
                                </h2>

                                <form method="post" action="${ctx}/manager/tables">

                                    <input type="hidden" name="action" value="saveAdjacencyOverride">


                                    <div class="grid grid-2">

                                        <div class="form-group">

                                            <label>
                                                Bàn thứ nhất
                                            </label>

                                            <select name="tableNumber1" required>

                                                <option value="">
                                                    -- Chọn bàn --
                                                </option>

                                                <c:forEach var="t" items="${tables}">

                                                    <c:if test="${t.active}">

                                                        <option value="${fn:escapeXml(t.tableNumber)}">

                                                            <c:out value="${t.tableNumber}" />

                                                        </option>

                                                    </c:if>

                                                </c:forEach>

                                            </select>

                                        </div>


                                        <div class="form-group">

                                            <label>
                                                Bàn thứ hai
                                            </label>

                                            <select name="tableNumber2" required>

                                                <option value="">
                                                    -- Chọn bàn --
                                                </option>

                                                <c:forEach var="t" items="${tables}">

                                                    <c:if test="${t.active}">

                                                        <option value="${fn:escapeXml(t.tableNumber)}">

                                                            <c:out value="${t.tableNumber}" />

                                                        </option>

                                                    </c:if>

                                                </c:forEach>

                                            </select>

                                        </div>

                                    </div>


                                    <div class="form-group">

                                        <label>
                                            Quy tắc
                                        </label>

                                        <select name="allowed" required>

                                            <option value="false">
                                                BLOCK - Không cho phép ghép trực tiếp
                                            </option>

                                            <option value="true">
                                                ALLOW - Cho phép ghép trực tiếp
                                            </option>

                                        </select>

                                    </div>


                                    <button type="submit" class="btn btn-primary">

                                        Lưu rule

                                    </button>

                                </form>


                                <c:if test="${not empty adjacencyOverrides}">

                                    <div class="table-wrap" style="margin-top:20px">

                                        <table class="data-table">

                                            <thead>

                                                <tr>

                                                    <th>
                                                        Hai bàn
                                                    </th>

                                                    <th>
                                                        Rule
                                                    </th>

                                                    <th>
                                                        Ý nghĩa
                                                    </th>

                                                    <th>
                                                        Thao tác
                                                    </th>

                                                </tr>

                                            </thead>


                                            <tbody>

                                                <c:forEach var="rule" items="${adjacencyOverrides}">

                                                    <tr>

                                                        <td>

                                                            <b>

                                                                <c:out value="${rule.tableNumber1}" />

                                                                ↔

                                                                <c:out value="${rule.tableNumber2}" />

                                                            </b>

                                                        </td>


                                                        <td>

                                                            <c:choose>

                                                                <c:when test="${rule.allowed}">

                                                                    <span class="badge badge-success">

                                                                        ALLOW

                                                                    </span>

                                                                </c:when>


                                                                <c:otherwise>

                                                                    <span class="badge badge-danger">

                                                                        BLOCK

                                                                    </span>

                                                                </c:otherwise>

                                                            </c:choose>

                                                        </td>


                                                        <td>

                                                            <c:choose>

                                                                <c:when test="${rule.allowed}">

                                                                    Hai bàn được xem
                                                                    là nối trực tiếp.

                                                                </c:when>


                                                                <c:otherwise>

                                                                    Cạnh nối trực tiếp
                                                                    giữa hai bàn bị loại bỏ.

                                                                </c:otherwise>

                                                            </c:choose>

                                                        </td>


                                                        <td>

                                                            <form method="post" action="${ctx}/manager/tables">

                                                                <input type="hidden" name="action"
                                                                    value="removeAdjacencyOverride">

                                                                <input type="hidden" name="tableId1"
                                                                    value="${rule.tableId1}">

                                                                <input type="hidden" name="tableId2"
                                                                    value="${rule.tableId2}">


                                                                <button class="btn btn-sm btn-danger"
                                                                    onclick="return confirm('Xóa rule đặc biệt này?');">

                                                                    Xóa rule

                                                                </button>

                                                            </form>

                                                        </td>

                                                    </tr>

                                                </c:forEach>

                                            </tbody>

                                        </table>

                                    </div>

                                </c:if>

                            </section>


                            <section class="card section">

                                <h2>
                                    Danh sách bàn
                                </h2>


                                <div class="table-wrap">

                                    <table class="data-table">

                                        <thead>

                                            <tr>

                                                <th>
                                                    Bàn
                                                </th>

                                                <th>
                                                    Sức chứa
                                                </th>

                                                <th>
                                                    Trạng thái
                                                </th>

                                                <th>
                                                    QR
                                                </th>

                                                <th>
                                                    Cấu hình
                                                </th>

                                            </tr>

                                        </thead>


                                        <tbody>

                                            <c:forEach var="t" items="${tables}">

                                                <tr>

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

                                                        <c:choose>

                                                            <c:when test="${!t.active}">

                                                                <span class="badge">

                                                                    Ngừng dùng

                                                                </span>

                                                            </c:when>


                                                            <c:when test="${t.status eq 'AVAILABLE'}">

                                                                <span class="badge badge-success">

                                                                    Trống

                                                                </span>

                                                            </c:when>


                                                            <c:when test="${t.status eq 'OCCUPIED'}">

                                                                <span class="badge badge-warning">

                                                                    Đang sử dụng

                                                                </span>

                                                            </c:when>


                                                            <c:otherwise>

                                                                <span class="badge">

                                                                    <c:out value="${t.status}" />

                                                                </span>

                                                            </c:otherwise>

                                                        </c:choose>

                                                    </td>


                                                    <td>

                                                        <img src="${ctx}/manager/tables?action=qr&id=${t.tableId}"
                                                            alt="QR bàn ${fn:escapeXml(t.tableNumber)}" style="
                                                width:90px;
                                                height:90px;
                                                object-fit:contain;
                                            ">

                                                        <br>


                                                        <c:url var="customerMenuUrl" value="/customer/menu">

                                                            <c:param name="token" value="${t.qrToken}" />

                                                        </c:url>


                                                        <a class="btn btn-sm btn-outline"
                                                            href="${fn:escapeXml(customerMenuUrl)}" target="_blank">

                                                            Mở menu

                                                        </a>


                                                        <form method="post" action="${ctx}/manager/tables"
                                                            style="display:inline-block">

                                                            <input type="hidden" name="action" value="regenerate">

                                                            <input type="hidden" name="id" value="${t.tableId}">


                                                            <button type="submit" class="btn btn-sm"
                                                                onclick="return confirm('Tạo QR mới? QR cũ sẽ không còn sử dụng được.');">

                                                                Tạo lại QR

                                                            </button>

                                                        </form>

                                                    </td>


                                                    <td>

                                                        <form method="post" action="${ctx}/manager/tables">

                                                            <input type="hidden" name="action" value="update">

                                                            <input type="hidden" name="id" value="${t.tableId}">


                                                            <div class="form-group">

                                                                <label>
                                                                    Sức chứa
                                                                </label>

                                                                <input type="number" name="capacity" min="1" max="100"
                                                                    value="${t.capacity}" style="width:100px" required>

                                                            </div>


                                                            <div class="form-group">

                                                                <label>
                                                                    Hoạt động
                                                                </label>

                                                                <select name="active">

                                                                    <option value="true" ${t.active ? 'selected' : '' }>

                                                                        Hoạt động

                                                                    </option>

                                                                    <option value="false" ${!t.active ? 'selected' : ''
                                                                        }>

                                                                        Ngừng dùng

                                                                    </option>

                                                                </select>

                                                            </div>


                                                            <button type="submit" class="btn btn-sm btn-primary">

                                                                Lưu

                                                            </button>

                                                        </form>

                                                    </td>

                                                </tr>

                                            </c:forEach>


                                            <c:if test="${empty tables}">

                                                <tr>

                                                    <td colspan="5" class="muted">

                                                        Chưa có bàn.

                                                    </td>

                                                </tr>

                                            </c:if>

                                        </tbody>

                                    </table>

                                </div>

                            </section>


                            <section class="card section">

                                <h2>
                                    Sơ đồ vị trí bàn
                                </h2>

                                <div class="table-wrap">

                                    <table class="data-table">

                                        <thead>

                                            <tr>

                                                <th>
                                                    Khu vực
                                                </th>

                                                <th>
                                                    Hàng
                                                </th>

                                                <th>
                                                    Vị trí
                                                </th>

                                                <th>
                                                    Bàn
                                                </th>

                                                <th>
                                                    Ghép
                                                </th>

                                                <th>
                                                    Xóa hàng
                                                </th>

                                            </tr>

                                        </thead>


                                        <tbody>

                                            <c:forEach var="layout" items="${layouts}">

                                                <tr>

                                                    <td>

                                                        <c:out value="${layout.areaCode}" />

                                                    </td>


                                                    <td>

                                                        <c:out value="${layout.rowNo}" />

                                                    </td>


                                                    <td>

                                                        <c:out value="${layout.positionNo}" />

                                                    </td>


                                                    <td>

                                                        <b>

                                                            <c:out value="${layout.tableNumber}" />

                                                        </b>

                                                    </td>


                                                    <td>

                                                        <c:choose>

                                                            <c:when test="${layout.mergeEnabled}">

                                                                <span class="badge badge-success">

                                                                    Cho phép

                                                                </span>

                                                            </c:when>


                                                            <c:otherwise>

                                                                <span class="badge">

                                                                    Không

                                                                </span>

                                                            </c:otherwise>

                                                        </c:choose>

                                                    </td>


                                                    <td>

                                                        <form method="post" action="${ctx}/manager/tables">

                                                            <input type="hidden" name="action" value="removeRowLayout">

                                                            <input type="hidden" name="areaCode"
                                                                value="${fn:escapeXml(layout.areaCode)}">

                                                            <input type="hidden" name="rowNo" value="${layout.rowNo}">


                                                            <button class="btn btn-sm btn-danger"
                                                                onclick="return confirm('Xóa toàn bộ hàng này khỏi sơ đồ?');">

                                                                Xóa hàng

                                                            </button>

                                                        </form>

                                                    </td>

                                                </tr>

                                            </c:forEach>


                                            <c:if test="${empty layouts}">

                                                <tr>

                                                    <td colspan="6" class="muted">

                                                        Chưa cấu hình sơ đồ bàn.

                                                    </td>

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