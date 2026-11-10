<%@ page contentType="text/html;charset=UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
            <fmt:setLocale value="en_US" scope="page" />
            <%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

                <c:set var="ctx" value="${pageContext.request.contextPath}" />
                <fmt:setLocale value="en_US" scope="page" />
                <!doctype html>
                <html lang="vi">

                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <title>Quản lý kho</title>
                    <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=inventory-history-1">
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
                                            Tồn thực tế = số lượng vật lý trong kho. Đã giữ chỗ = nguyên liệu đã reserve
                                            cho
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
                                                                <input type="hidden" name="id"
                                                                    value="${i.inventoryItemId}">
                                                                <fmt:formatNumber var="thresholdValue"
                                                                    value="${i.lowStockThreshold}" minFractionDigits="0"
                                                                    maxFractionDigits="3" groupingUsed="false" />

                                                                <input type="number" name="threshold" step="0.001"
                                                                    min="0" value="${thresholdValue}"
                                                                    style="width:110px" required>
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

                                <!-- INVENTORY TRANSACTION HISTORY -->

                                <c:url var="historyBackUrl" value="/manager/inventory">
                                    <c:param name="tab" value="history" />
                                    <c:param name="page" value="${currentPage}" />
                                    <c:param name="pageSize" value="${pageSize}" />
                                    <c:param name="fromDate" value="${fromDate}" />
                                    <c:param name="toDate" value="${toDate}" />
                                    <c:param name="type" value="${selectedType}" />
                                    <c:param name="keyword" value="${keyword}" />
                                </c:url>

                                <section class="card section" id="inventory-history">

                                    <div class="inventory-history-heading">
                                        <h2>Lịch sử giao dịch kho</h2>
                                    </div>

                                    <!-- FILTER -->
                                    <form method="get" action="${ctx}/manager/inventory#inventory-history"
                                        class="inventory-history-filter">

                                        <input type="hidden" name="tab" value="history">

                                        <div class="form-group">
                                            <label>Từ ngày</label>
                                            <input type="date" name="fromDate" value="<c:out value='${fromDate}' />">
                                        </div>

                                        <div class="form-group">
                                            <label>Đến ngày</label>
                                            <input type="date" name="toDate" value="<c:out value='${toDate}' />">
                                        </div>

                                        <div class="form-group">
                                            <label>Loại giao dịch</label>

                                            <select name="type">
                                                <option value="">Tất cả</option>

                                                <option value="RESTOCK" ${selectedType eq 'RESTOCK' ? 'selected' : '' }>
                                                    Nhập kho
                                                </option>

                                                <option value="USAGE" ${selectedType eq 'USAGE' ? 'selected' : '' }>
                                                    Xuất sử dụng
                                                </option>

                                                <option value="WASTE_LOSS" ${selectedType eq 'WASTE_LOSS' ? 'selected'
                                                    : '' }>
                                                    Hao hụt
                                                </option>

                                                <option value="ADJUSTMENT" ${selectedType eq 'ADJUSTMENT' ? 'selected'
                                                    : '' }>
                                                    Điều chỉnh tồn
                                                </option>
                                            </select>
                                        </div>

                                        <div class="form-group">
                                            <label>Tìm nguyên liệu</label>
                                            <input type="search" name="keyword" maxlength="100"
                                                placeholder="Tên nguyên liệu" value="<c:out value='${keyword}' />">
                                        </div>

                                        <div class="form-group">
                                            <label>Số dòng/trang</label>

                                            <select name="pageSize">
                                                <option value="20" ${pageSize==20 ? 'selected' : '' }>
                                                    20
                                                </option>
                                                <option value="50" ${pageSize==50 ? 'selected' : '' }>
                                                    50
                                                </option>
                                                <option value="80" ${pageSize==80 ? 'selected' : '' }>
                                                    80
                                                </option>
                                            </select>
                                        </div>

                                        <div class="inventory-filter-buttons">
                                            <button class="btn btn-primary" type="submit">
                                                Áp dụng
                                            </button>

                                            <a class="btn"
                                                href="${ctx}/manager/inventory?tab=history#inventory-history">
                                                Xóa lọc
                                            </a>
                                        </div>
                                    </form>

                                    <!-- TABLE -->
                                    <div class="table-wrap">

                                        <table class="data-table inventory-history-table">

                                            <thead>
                                                <tr>
                                                    <th>Mã GD</th>
                                                    <th>Thời gian</th>
                                                    <th>Nguyên liệu</th>
                                                    <th>Loại giao dịch</th>
                                                    <th>Thay đổi</th>
                                                    <th>Đơn hàng</th>
                                                    <th>Ghi chú</th>
                                                    <th>Chi tiết</th>
                                                </tr>
                                            </thead>

                                            <tbody>

                                                <c:forEach var="tx" items="${transactions}">

                                                    <c:url var="detailUrl" value="/manager/inventory">
                                                        <c:param name="tab" value="history" />
                                                        <c:param name="page" value="${currentPage}" />
                                                        <c:param name="pageSize" value="${pageSize}" />
                                                        <c:param name="fromDate" value="${fromDate}" />
                                                        <c:param name="toDate" value="${toDate}" />
                                                        <c:param name="type" value="${selectedType}" />
                                                        <c:param name="keyword" value="${keyword}" />
                                                        <c:param name="detailId" value="${tx.transactionId}" />
                                                    </c:url>

                                                    <tr>

                                                        <td>
                                                            #
                                                            <c:out value="${tx.transactionId}" />
                                                        </td>

                                                        <td>
                                                            <fmt:formatDate value="${tx.createdAt}"
                                                                pattern="dd/MM/yyyy HH:mm" />
                                                        </td>

                                                        <td>
                                                            <strong>
                                                                <c:out value="${tx.inventoryName}" />
                                                            </strong>
                                                            <span class="muted">
                                                                (
                                                                <c:out value="${tx.unit}" />)
                                                            </span>
                                                        </td>

                                                        <td>
                                                            <c:choose>
                                                                <c:when test="${tx.transactionType eq 'RESTOCK'}">
                                                                    <span class="badge badge-success">
                                                                        Nhập kho
                                                                    </span>
                                                                </c:when>

                                                                <c:when test="${tx.transactionType eq 'USAGE'}">
                                                                    <span class="badge">
                                                                        Xuất sử dụng
                                                                    </span>
                                                                </c:when>

                                                                <c:when test="${tx.transactionType eq 'WASTE_LOSS'}">
                                                                    <span class="badge badge-danger">
                                                                        Hao hụt
                                                                    </span>
                                                                </c:when>

                                                                <c:when test="${tx.transactionType eq 'ADJUSTMENT'}">
                                                                    <span class="badge badge-warning">
                                                                        Điều chỉnh
                                                                    </span>
                                                                </c:when>

                                                                <c:otherwise>
                                                                    <c:out value="${tx.transactionType}" />
                                                                </c:otherwise>
                                                            </c:choose>
                                                        </td>

                                                        <td>
                                                            <strong class="${tx.quantityChange gt 0
                                    ? 'inventory-qty-positive'
                                    : 'inventory-qty-negative'}">

                                                                <c:if test="${tx.quantityChange gt 0}">
                                                                    +
                                                                </c:if>

                                                                <fmt:formatNumber value="${tx.quantityChange}"
                                                                    minFractionDigits="0" maxFractionDigits="3"
                                                                    groupingUsed="false" />

                                                                <c:out value="${tx.unit}" />
                                                            </strong>
                                                        </td>

                                                        <td>
                                                            <c:choose>
                                                                <c:when test="${not empty tx.referenceOrderId}">
                                                                    #
                                                                    <c:out value="${tx.referenceOrderId}" />
                                                                </c:when>
                                                                <c:otherwise>—</c:otherwise>
                                                            </c:choose>
                                                        </td>

                                                        <td class="inventory-history-note">
                                                            <c:out value="${tx.description}" default="—" />
                                                        </td>

                                                        <td>
                                                            <a class="inventory-detail-link"
                                                                href="${detailUrl}#inventory-history">
                                                                Chi tiết
                                                            </a>
                                                        </td>

                                                    </tr>
                                                </c:forEach>

                                                <c:if test="${empty transactions}">
                                                    <tr>
                                                        <td colspan="8" class="muted">
                                                            Không có giao dịch phù hợp.
                                                        </td>
                                                    </tr>
                                                </c:if>

                                            </tbody>
                                        </table>
                                    </div>

                                    <!-- PAGINATION -->
                                    <div class="inventory-history-pagination">

                                        <span class="muted">
                                            Tổng:
                                            <strong>${totalTransactions}</strong>
                                            giao dịch
                                        </span>

                                        <div class="inventory-history-pages">

                                            <c:if test="${currentPage > 1}">
                                                <c:url var="previousUrl" value="/manager/inventory">
                                                    <c:param name="tab" value="history" />
                                                    <c:param name="page" value="${currentPage - 1}" />
                                                    <c:param name="pageSize" value="${pageSize}" />
                                                    <c:param name="fromDate" value="${fromDate}" />
                                                    <c:param name="toDate" value="${toDate}" />
                                                    <c:param name="type" value="${selectedType}" />
                                                    <c:param name="keyword" value="${keyword}" />
                                                </c:url>

                                                <a class="btn btn-sm" href="${previousUrl}#inventory-history">
                                                    Trước
                                                </a>
                                            </c:if>

                                            <span>
                                                Trang ${currentPage} / ${totalPages}
                                            </span>

                                            <c:if test="${currentPage < totalPages}">
                                                <c:url var="nextUrl" value="/manager/inventory">
                                                    <c:param name="tab" value="history" />
                                                    <c:param name="page" value="${currentPage + 1}" />
                                                    <c:param name="pageSize" value="${pageSize}" />
                                                    <c:param name="fromDate" value="${fromDate}" />
                                                    <c:param name="toDate" value="${toDate}" />
                                                    <c:param name="type" value="${selectedType}" />
                                                    <c:param name="keyword" value="${keyword}" />
                                                </c:url>

                                                <a class="btn btn-sm" href="${nextUrl}#inventory-history">
                                                    Sau
                                                </a>
                                            </c:if>

                                        </div>

                                    </div>

                                </section>

                                <c:if test="${not empty transactionDetail}">

                                    <div class="inventory-detail-overlay">

                                        <section class="card inventory-detail-dialog">

                                            <div class="inventory-detail-header">
                                                <h2>
                                                    Chi tiết giao dịch
                                                    #
                                                    <c:out value="${transactionDetail.transactionId}" />
                                                </h2>

                                                <a href="${historyBackUrl}#inventory-history"
                                                    class="inventory-detail-close" aria-label="Đóng">
                                                    ×
                                                </a>
                                            </div>

                                            <h3>Thông tin chung</h3>

                                            <dl class="inventory-detail-fields">

                                                <dt>Thời gian</dt>
                                                <dd>
                                                    <fmt:formatDate value="${transactionDetail.createdAt}"
                                                        pattern="dd/MM/yyyy HH:mm:ss" />
                                                </dd>

                                                <dt>Nguyên liệu</dt>
                                                <dd>
                                                    <c:out value="${transactionDetail.inventoryName}" />
                                                </dd>

                                                <dt>Đơn vị</dt>
                                                <dd>
                                                    <c:out value="${transactionDetail.unit}" />
                                                </dd>

                                                <dt>Loại giao dịch</dt>
                                                <dd>
                                                    <c:choose>
                                                        <c:when
                                                            test="${transactionDetail.transactionType eq 'RESTOCK'}">
                                                            Nhập kho
                                                        </c:when>
                                                        <c:when test="${transactionDetail.transactionType eq 'USAGE'}">
                                                            Xuất sử dụng
                                                        </c:when>
                                                        <c:when
                                                            test="${transactionDetail.transactionType eq 'WASTE_LOSS'}">
                                                            Hao hụt
                                                        </c:when>
                                                        <c:when
                                                            test="${transactionDetail.transactionType eq 'ADJUSTMENT'}">
                                                            Điều chỉnh tồn
                                                        </c:when>
                                                        <c:otherwise>
                                                            <c:out value="${transactionDetail.transactionType}" />
                                                        </c:otherwise>
                                                    </c:choose>
                                                </dd>

                                            </dl>

                                            <h3>Biến động kho</h3>

                                            <dl class="inventory-detail-fields">

                                                <dt>Số lượng thay đổi</dt>
                                                <dd class="inventory-detail-quantity
                    ${transactionDetail.quantityChange gt 0
                        ? 'inventory-qty-positive'
                        : 'inventory-qty-negative'}">

                                                    <c:if test="${transactionDetail.quantityChange gt 0}">
                                                        +
                                                    </c:if>

                                                    <fmt:formatNumber value="${transactionDetail.quantityChange}"
                                                        minFractionDigits="0" maxFractionDigits="3"
                                                        groupingUsed="false" />

                                                    <c:out value="${transactionDetail.unit}" />
                                                </dd>

                                                <c:if test="${not empty transactionDetail.unitCost}">
                                                    <dt>Đơn giá nhập</dt>
                                                    <dd>
                                                        <fmt:formatNumber value="${transactionDetail.unitCost}"
                                                            minFractionDigits="0" maxFractionDigits="2"
                                                            groupingUsed="true" />
                                                        đ
                                                    </dd>
                                                </c:if>

                                            </dl>

                                            <h3>Tham chiếu và lý do</h3>

                                            <dl class="inventory-detail-fields">

                                                <dt>Đơn hàng liên quan</dt>
                                                <dd>
                                                    <c:choose>
                                                        <c:when test="${not empty transactionDetail.referenceOrderId}">
                                                            #
                                                            <c:out value="${transactionDetail.referenceOrderId}" />
                                                        </c:when>
                                                        <c:otherwise>Không có</c:otherwise>
                                                    </c:choose>
                                                </dd>

                                            </dl>

                                            <div class="inventory-detail-reason">
                                                <strong>Lý do / Ghi chú</strong>

                                                <p>
                                                    <c:out value="${transactionDetail.description}"
                                                        default="Không có ghi chú." />
                                                </p>
                                            </div>

                                            <div class="inventory-detail-footer">
                                                <a href="${historyBackUrl}#inventory-history" class="btn">
                                                    Đóng
                                                </a>
                                            </div>

                                        </section>

                                    </div>

                                </c:if>


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
                                                    <input type="number" name="quantity" step="0.001" min="0.001"
                                                        required>
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
                                            Không thể điều chỉnh tồn thực tế xuống thấp hơn số lượng đang được giữ chỗ
                                            cho
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
                                                <input type="number" name="actualQuantity" step="0.001" min="0"
                                                    required>
                                            </div>
                                            <div class="form-group">
                                                <label>Lý do <span class="required-mark">*</span></label>
                                                <input type="text" name="note" maxlength="500"
                                                    placeholder="Ví dụ: Chênh lệch kiểm kê, chưa xác định nguyên nhân"
                                                    required>
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
                                            Hệ thống không cho phép hao hụt làm tồn kho thấp hơn lượng nguyên liệu đã
                                            giữ
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
                                                <label>Lý do <span class="required-mark">*</span></label>
                                                <input type="text" name="note" maxlength="500"
                                                    placeholder="Ví dụ: Nguyên liệu bị hỏng trong quá trình bảo quản"
                                                    required>
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