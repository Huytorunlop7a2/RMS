<%@ page contentType="text/html;charset=UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
<<<<<<< HEAD
        <%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

            <c:set var="ctx" value="${pageContext.request.contextPath}" />
            <fmt:setLocale value="en_US" scope="page" />
            <!doctype html>
            <html lang="vi">

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <title>Quản lý kho</title>
                <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=inventory-reserve-1">
            </head>

            <body>
                <div class="layout">

                    <!-- ===============================================
            SIDEBAR
            =============================================== -->
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

                    <!-- ===============================================
            MAIN
            =============================================== -->

                    <main class="main">
                        <div class="container">
                            <div class="page-head">
                                <div>
                                    <h1>Quản lý kho</h1>
                                    <p class="muted">
                                        Tồn thực tế = số lượng vật lý trong kho. Đã giữ chỗ = nguyên liệu đã reserve cho
                                        các
                                        món đang PENDING. Khả dụng = tồn thực tế - đã giữ chỗ.
                                    </p>
                                </div>
                            </div>

                            <!-- =========================================
                    ALERT
                    ========================================= -->
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

                            <!-- =========================================
                    CURRENT INVENTORY
                    ========================================= -->

                            <section class="card section">
                                <h2>Tồn kho hiện tại</h2>
                                <div class="table-wrap">
                                    <table class="data-table">
                                        <thead>
                                            <tr>
                                                <th>Nguyên liệu</th>
                                                <th>Tồn thực tế</th>
                                                <th>Đã giữ chỗ</th>
                                                <th>Khả dụng</th>
                                                <th>Ngưỡng thấp</th>
                                                <th>Trạng thái</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <c:forEach var="i" items="${inventory}">
                                                <tr>

                                                    <!-- NAME -->
                                                    <td>
                                                        <b>
                                                            <c:out value="${i.name}" />
                                                        </b>
                                                        <br>
                                                        <span class="muted">
                                                            Đơn vị:
                                                            <c:out value="${i.unit}" />
                                                        </span>
                                                    </td>

                                                    <!-- ON HAND -->
                                                    <td>
                                                        <b>
                                                            <fmt:formatNumber value="${i.quantity}"
                                                                minFractionDigits="0" maxFractionDigits="3"
                                                                groupingUsed="false" />
                                                        </b>
                                                        <c:out value="${i.unit}" />
                                                    </td>

                                                    <!-- RESERVED -->
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${i.reservedQuantity > 0}">
                                                                <b>
                                                                    <fmt:formatNumber value="${i.reservedQuantity}"
                                                                        minFractionDigits="0" maxFractionDigits="3"
                                                                        groupingUsed="false" />
                                                                </b>
                                                                <c:out value="${i.unit}" />
                                                                <br>
                                                                <span class="badge">Đang giữ</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                0
                                                                <c:out value="${i.unit}" />
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>

                                                    <!-- AVAILABLE -->
                                                    <td>
                                                        <b>
                                                            <fmt:formatNumber value="${i.availableQuantity}"
                                                                minFractionDigits="0" maxFractionDigits="3"
                                                                groupingUsed="false" />
                                                        </b>
                                                        <c:out value="${i.unit}" />
                                                    </td>

                                                    <!-- THRESHOLD -->
                                                    <td>
                                                        <form class="inline" method="post"
                                                            action="${ctx}/manager/inventory">
                                                            <input type="hidden" name="action" value="threshold">
                                                            <input type="hidden" name="id" value="${i.inventoryItemId}">
                                                            <fmt:formatNumber var="thresholdValue"
                                                                value="${i.lowStockThreshold}" minFractionDigits="0"
                                                                maxFractionDigits="3" groupingUsed="false" />

                                                            <input type="number" name="threshold" step="0.001" min="0"
                                                                value="${thresholdValue}" style="width:110px" required>
                                                            <button class="btn btn-sm" type="submit">Lưu</button>
                                                        </form>

                                                    </td>

                                                    <!-- STATUS -->
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${!i.active}">
                                                                <span class="badge">Ngừng sử dụng</span>
                                                            </c:when>
                                                            <c:when test="${i.lowStock}">
                                                                <span class="badge badge-danger">Sắp hết</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge badge-success">Ổn định</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                </tr>
                                            </c:forEach>
                                            <c:if test="${empty inventory}">
                                                <tr>
                                                    <td colspan="6" class="muted">Chưa có nguyên liệu.</td>
                                                </tr>
                                            </c:if>
                                        </tbody>
                                    </table>
                                </div>
                            </section>

                            <!-- =========================================
                    ACTION FORMS
                    ========================================= -->
                            <div class="grid grid-2">

                                <!-- =====================================
                        CREATE INGREDIENT
                        ===================================== -->

                                <section class="card">
                                    <h2>Tạo nguyên liệu</h2>
                                    <form method="post" action="${ctx}/manager/inventory">
                                        <input type="hidden" name="action" value="create">
                                        <div class="form-group">
                                            <label>Tên nguyên liệu</label>
                                            <input name="name" maxlength="255" required>
                                        </div>
                                        <div class="form-group">
                                            <label>Đơn vị</label>
                                            <select name="unit" required>
                                                <option value="" disabled selected>-- Chọn đơn vị --</option>
                                                <option value="kg">Kilogram (kg)</option>
                                                <option value="gram">Gram (g)</option>
                                                <option value="lit">Lít (L)</option>
                                                <option value="ml">Mili lít (ml)</option>
                                                <option value="lon">Lon</option>
                                                <option value="chai">Chai</option>
                                                <option value="hop">Hộp</option>
                                                <option value="goi">Gói</option>
                                                <option value="piece">Cái</option>
                                                <option value="qua">Quả</option>
                                            </select>
                                        </div>
                                        <div class="grid grid-2">
                                            <div class="form-group">
                                                <label>Tồn ban đầu</label>
                                                <input type="number" name="initialQuantity" step="0.001" min="0"
                                                    required>
                                            </div>
                                            <div class="form-group">
                                                <label>Ngưỡng thấp</label>
                                                <input type="number" name="lowStockThreshold" step="0.001" min="0"
                                                    required>
                                            </div>
                                        </div>
                                        <button class="btn btn-primary" type="submit">Tạo nguyên liệu</button>
                                    </form>

                                </section>

                                <!-- =====================================
                        STOCK IN
                        ===================================== -->

                                <section class="card">
                                    <h2>Nhập kho</h2>
                                    <form method="post" action="${ctx}/manager/inventory">
                                        <input type="hidden" name="action" value="stockin">
                                        <div class="form-group">
                                            <label>Nguyên liệu</label>
                                            <select name="id" required>
                                                <c:forEach var="i" items="${inventory}">
                                                    <c:if test="${i.active}">
                                                        <option value="${i.inventoryItemId}">
                                                            <c:out value="${i.name}" />
                                                            (
                                                            <c:out value="${i.unit}" />
                                                            )
                                                        </option>
                                                    </c:if>
                                                </c:forEach>
                                            </select>
                                        </div>
                                        <div class="grid grid-2">
                                            <div class="form-group">
                                                <label>Số lượng</label>
                                                <input type="number" name="quantity" step="0.001" min="0.001" required>
                                            </div>
                                            <div class="form-group">
                                                <label>Đơn giá nhập</label>
                                                <input type="number" name="unitCost" step="0.01" min="0">
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <label>Ghi chú</label>
                                            <input name="note" maxlength="500">
                                        </div>
                                        <button class="btn btn-primary" type="submit">Ghi nhận nhập kho</button>
                                    </form>

                                </section>

                                <!-- =====================================
                        ADJUST INVENTORY
                        ===================================== -->

                                <section class="card">
                                    <h2>Điều chỉnh tồn thực tế</h2>
                                    <p class="muted">
                                        Không thể điều chỉnh tồn thực tế xuống thấp hơn số lượng đang được giữ chỗ cho
                                        các
                                        món PENDING.
                                    </p>
                                    <form method="post" action="${ctx}/manager/inventory">
                                        <input type="hidden" name="action" value="adjust">
                                        <div class="form-group">
                                            <label>Nguyên liệu</label>
                                            <select name="id" required>
                                                <c:forEach var="i" items="${inventory}">
                                                    <c:if test="${i.active}">
                                                        <option value="${i.inventoryItemId}">
                                                            <c:out value="${i.name}" />
                                                            - khả dụng:
                                                            <c:out value="${i.availableQuantity}" />
                                                            <c:out value="${i.unit}" />
                                                        </option>
                                                    </c:if>
                                                </c:forEach>
                                            </select>
                                        </div>
                                        <div class="form-group">
                                            <label>Số lượng thực tế</label>
                                            <input type="number" name="actualQuantity" step="0.001" min="0" required>
                                        </div>
                                        <div class="form-group">
                                            <label>Lý do</label>
                                            <input name="note" maxlength="500">
                                        </div>
                                        <button class="btn btn-primary" type="submit">Điều chỉnh</button>
                                    </form>

                                </section>

                                <!-- =====================================
                        WASTE
                        ===================================== -->

                                <section class="card">
                                    <h2>Ghi nhận hao hụt</h2>
                                    <p class="muted">
                                        Hệ thống không cho phép hao hụt làm tồn kho thấp hơn lượng nguyên liệu đã giữ
                                        cho
                                        các Order đang PENDING.
                                    </p>
                                    <form method="post" action="${ctx}/manager/inventory">
                                        <input type="hidden" name="action" value="waste">
                                        <div class="form-group">
                                            <label>Nguyên liệu</label>
                                            <select name="id" required>
                                                <c:forEach var="i" items="${inventory}">
                                                    <c:if test="${i.active}">
                                                        <option value="${i.inventoryItemId}">
                                                            <c:out value="${i.name}" />
                                                            - khả dụng:
                                                            <c:out value="${i.availableQuantity}" />
                                                            <c:out value="${i.unit}" />
                                                        </option>
                                                    </c:if>
                                                </c:forEach>
                                            </select>
                                        </div>
                                        <div class="form-group">
                                            <label>Số lượng hao hụt</label>
                                            <input type="number" name="quantity" step="0.001" min="0.001" required>
                                        </div>
                                        <div class="form-group">
                                            <label>Lý do</label>
                                            <input name="note" maxlength="500">
                                        </div>
                                        <button class="btn btn-danger" type="submit">Ghi nhận hao hụt</button>
                                    </form>

                                </section>

                            </div>
                        </div>
                    </main>
                </div>
            </body>

            </html>
=======

        <c:set var="ctx" value="${pageContext.request.contextPath}" />
        <!doctype html>
        <html lang="vi">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Quản lý kho</title>
            <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=inventory-reserve-1">
        </head>

        <body>
            <div class="layout">

                <!-- ===============================================
            SIDEBAR
            =============================================== -->
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

                <!-- ===============================================
            MAIN
            =============================================== -->

                <main class="main">
                    <div class="container">
                        <div class="page-head">
                            <div>
                                <h1>Quản lý kho</h1>
                                <p class="muted">
                                    Tồn thực tế = số lượng vật lý trong kho. Đã giữ chỗ = nguyên liệu đã reserve cho các
                                    món đang PENDING. Khả dụng = tồn thực tế - đã giữ chỗ.
                                </p>
                            </div>
                        </div>

                        <!-- =========================================
                    ALERT
                    ========================================= -->
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

                        <!-- =========================================
                    CURRENT INVENTORY
                    ========================================= -->

                        <section class="card section">
                            <h2>Tồn kho hiện tại</h2>
                            <div class="table-wrap">
                                <table class="data-table">
                                    <thead>
                                        <tr>
                                            <th>Nguyên liệu</th>
                                            <th>Tồn thực tế</th>
                                            <th>Đã giữ chỗ</th>
                                            <th>Khả dụng</th>
                                            <th>Ngưỡng thấp</th>
                                            <th>Trạng thái</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <c:forEach var="i" items="${inventory}">
                                            <tr>

                                                <!-- NAME -->
                                                <td>
                                                    <b>
                                                        <c:out value="${i.name}" />
                                                    </b>
                                                    <br>
                                                    <span class="muted">
                                                        Đơn vị:
                                                        <c:out value="${i.unit}" />
                                                    </span>
                                                </td>

                                                <!-- ON HAND -->
                                                <td>
                                                    <b>
                                                        <c:out value="${i.quantity}" />
                                                    </b>
                                                    <c:out value="${i.unit}" />
                                                </td>

                                                <!-- RESERVED -->
                                                <td>
                                                    <c:choose>
                                                        <c:when test="${i.reservedQuantity > 0}">
                                                            <b>
                                                                <c:out value="${i.reservedQuantity}" />
                                                            </b>
                                                            <c:out value="${i.unit}" />
                                                            <br>
                                                            <span class="badge">Đang giữ</span>
                                                        </c:when>
                                                        <c:otherwise>
                                                            0
                                                            <c:out value="${i.unit}" />
                                                        </c:otherwise>
                                                    </c:choose>
                                                </td>

                                                <!-- AVAILABLE -->
                                                <td>
                                                    <b>
                                                        <c:out value="${i.availableQuantity}" />
                                                    </b>
                                                    <c:out value="${i.unit}" />
                                                </td>

                                                <!-- THRESHOLD -->
                                                <td>
                                                    <form class="inline" method="post"
                                                        action="${ctx}/manager/inventory">
                                                        <input type="hidden" name="action" value="threshold">
                                                        <input type="hidden" name="id" value="${i.inventoryItemId}">
                                                        <input type="number" name="threshold" step="0.001" min="0"
                                                            value="${i.lowStockThreshold}" style="width:110px" required>
                                                        <button class="btn btn-sm" type="submit">Lưu</button>
                                                    </form>

                                                </td>

                                                <!-- STATUS -->
                                                <td>
                                                    <c:choose>
                                                        <c:when test="${!i.active}">
                                                            <span class="badge">Ngừng sử dụng</span>
                                                        </c:when>
                                                        <c:when test="${i.lowStock}">
                                                            <span class="badge badge-danger">Sắp hết</span>
                                                        </c:when>
                                                        <c:otherwise>
                                                            <span class="badge badge-success">Ổn định</span>
                                                        </c:otherwise>
                                                    </c:choose>
                                                </td>
                                            </tr>
                                        </c:forEach>
                                        <c:if test="${empty inventory}">
                                            <tr>
                                                <td colspan="6" class="muted">Chưa có nguyên liệu.</td>
                                            </tr>
                                        </c:if>
                                    </tbody>
                                </table>
                            </div>
                        </section>

                        <!-- =========================================
                    ACTION FORMS
                    ========================================= -->
                        <div class="grid grid-2">

                            <!-- =====================================
                        CREATE INGREDIENT
                        ===================================== -->

                            <section class="card">
                                <h2>Tạo nguyên liệu</h2>
                                <form method="post" action="${ctx}/manager/inventory">
                                    <input type="hidden" name="action" value="create">
                                    <div class="form-group">
                                        <label>Tên nguyên liệu</label>
                                        <input name="name" maxlength="255" required>
                                    </div>
                                    <div class="form-group">
                                        <label>Đơn vị</label>
                                        <select name="unit" required>
                                            <option value="" disabled selected>-- Chọn đơn vị --</option>
                                            <option value="kg">Kilogram (kg)</option>
                                            <option value="gram">Gram (g)</option>
                                            <option value="lit">Lít (L)</option>
                                            <option value="ml">Mili lít (ml)</option>
                                            <option value="lon">Lon</option>
                                            <option value="chai">Chai</option>
                                            <option value="hop">Hộp</option>
                                            <option value="goi">Gói</option>
                                            <option value="piece">Cái</option>
                                            <option value="qua">Quả</option>
                                        </select>
                                    </div>
                                    <div class="grid grid-2">
                                        <div class="form-group">
                                            <label>Tồn ban đầu</label>
                                            <input type="number" name="initialQuantity" step="0.001" min="0" required>
                                        </div>
                                        <div class="form-group">
                                            <label>Ngưỡng thấp</label>
                                            <input type="number" name="lowStockThreshold" step="0.001" min="0" required>
                                        </div>
                                    </div>
                                    <button class="btn btn-primary" type="submit">Tạo nguyên liệu</button>
                                </form>

                            </section>

                            <!-- =====================================
                        STOCK IN
                        ===================================== -->

                            <section class="card">
                                <h2>Nhập kho</h2>
                                <form method="post" action="${ctx}/manager/inventory">
                                    <input type="hidden" name="action" value="stockin">
                                    <div class="form-group">
                                        <label>Nguyên liệu</label>
                                        <select name="id" required>
                                            <c:forEach var="i" items="${inventory}">
                                                <c:if test="${i.active}">
                                                    <option value="${i.inventoryItemId}">
                                                        <c:out value="${i.name}" />
                                                        (
                                                        <c:out value="${i.unit}" />
                                                        )
                                                    </option>
                                                </c:if>
                                            </c:forEach>
                                        </select>
                                    </div>
                                    <div class="grid grid-2">
                                        <div class="form-group">
                                            <label>Số lượng</label>
                                            <input type="number" name="quantity" step="0.001" min="0.001" required>
                                        </div>
                                        <div class="form-group">
                                            <label>Đơn giá nhập</label>
                                            <input type="number" name="unitCost" step="0.01" min="0">
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label>Ghi chú</label>
                                        <input name="note" maxlength="500">
                                    </div>
                                    <button class="btn btn-primary" type="submit">Ghi nhận nhập kho</button>
                                </form>

                            </section>

                            <!-- =====================================
                        ADJUST INVENTORY
                        ===================================== -->

                            <section class="card">
                                <h2>Điều chỉnh tồn thực tế</h2>
                                <p class="muted">
                                    Không thể điều chỉnh tồn thực tế xuống thấp hơn số lượng đang được giữ chỗ cho các
                                    món PENDING.
                                </p>
                                <form method="post" action="${ctx}/manager/inventory">
                                    <input type="hidden" name="action" value="adjust">
                                    <div class="form-group">
                                        <label>Nguyên liệu</label>
                                        <select name="id" required>
                                            <c:forEach var="i" items="${inventory}">
                                                <c:if test="${i.active}">
                                                    <option value="${i.inventoryItemId}">
                                                        <c:out value="${i.name}" />
                                                        - khả dụng:
                                                        <c:out value="${i.availableQuantity}" />
                                                        <c:out value="${i.unit}" />
                                                    </option>
                                                </c:if>
                                            </c:forEach>
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        <label>Số lượng thực tế</label>
                                        <input type="number" name="actualQuantity" step="0.001" min="0" required>
                                    </div>
                                    <div class="form-group">
                                        <label>Lý do</label>
                                        <input name="note" maxlength="500">
                                    </div>
                                    <button class="btn btn-primary" type="submit">Điều chỉnh</button>
                                </form>

                            </section>

                            <!-- =====================================
                        WASTE
                        ===================================== -->

                            <section class="card">
                                <h2>Ghi nhận hao hụt</h2>
                                <p class="muted">
                                    Hệ thống không cho phép hao hụt làm tồn kho thấp hơn lượng nguyên liệu đã giữ cho
                                    các Order đang PENDING.
                                </p>
                                <form method="post" action="${ctx}/manager/inventory">
                                    <input type="hidden" name="action" value="waste">
                                    <div class="form-group">
                                        <label>Nguyên liệu</label>
                                        <select name="id" required>
                                            <c:forEach var="i" items="${inventory}">
                                                <c:if test="${i.active}">
                                                    <option value="${i.inventoryItemId}">
                                                        <c:out value="${i.name}" />
                                                        - khả dụng:
                                                        <c:out value="${i.availableQuantity}" />
                                                        <c:out value="${i.unit}" />
                                                    </option>
                                                </c:if>
                                            </c:forEach>
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        <label>Số lượng hao hụt</label>
                                        <input type="number" name="quantity" step="0.001" min="0.001" required>
                                    </div>
                                    <div class="form-group">
                                        <label>Lý do</label>
                                        <input name="note" maxlength="500">
                                    </div>
                                    <button class="btn btn-danger" type="submit">Ghi nhận hao hụt</button>
                                </form>

                            </section>

                        </div>
                    </div>
                </main>
            </div>
        </body>

        </html>
>>>>>>> a787867 (10/11/2026)
