
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<fmt:setLocale value="en_US" scope="page" />
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- THONG KE --%>
<c:set var="activeItems" value="0" />
<c:set var="lowItems" value="0" />
<c:set var="outItems" value="0" />

<c:forEach var="i" items="${inventory}">
    <c:if test="${i.active}">
        <c:set var="activeItems" value="${activeItems + 1}" />
        <c:choose>
            <c:when test="${i.availableQuantity le 0}">
                <c:set var="outItems" value="${outItems + 1}" />
            </c:when>
            <c:when test="${i.lowStock}">
                <c:set var="lowItems" value="${lowItems + 1}" />
            </c:when>
        </c:choose>
    </c:if>
</c:forEach>

<%-- GIU BO LOC LICH SU --%>
<c:url var="historyUrl" value="/manager/inventory">
    <c:param name="tab" value="history" />
    <c:param name="page" value="${currentPage}" />
    <c:param name="pageSize" value="${pageSize}" />
    <c:param name="fromDate" value="${fromDate}" />
    <c:param name="toDate" value="${toDate}" />
    <c:param name="type" value="${selectedType}" />
    <c:param name="keyword" value="${keyword}" />
</c:url>

<c:url var="historyBackUrl" value="/manager/inventory">
    <c:param name="tab" value="history" />
    <c:param name="page" value="${currentPage}" />
    <c:param name="pageSize" value="${pageSize}" />
    <c:param name="fromDate" value="${fromDate}" />
    <c:param name="toDate" value="${toDate}" />
    <c:param name="type" value="${selectedType}" />
    <c:param name="keyword" value="${keyword}" />
</c:url>

<!doctype html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Quản lý kho | RMS</title>
    <link rel="stylesheet"
          href="${ctx}/assets/css/app.css?v=inventory-mau-a-3">
</head>

<body class="inv-app">
<div class="layout">

    <!-- SIDEBAR -->
    <aside class="sidebar">
        <div class="brand">RMS · Quản lý</div>
        <nav class="nav">
            <a href="${ctx}/manager/tables">Bàn &amp; QR</a>
            <a href="${ctx}/manager/menu">Menu</a>
            <a href="${ctx}/manager/inventory" class="inv-nav-active">Kho</a>
            <a href="${ctx}/manager/opening-hours">Giờ hoạt động</a>
            <a href="${ctx}/logout">Đăng xuất</a>
        </nav>
    </aside>

    <!-- MAIN -->
    <main class="main">
        <div class="container">

            <div class="page-head inv-page-head">
                <div>
                    <h1>Quản lý kho</h1>
                    <p class="muted">
                        Theo dõi nguyên liệu, tồn kho và lịch sử giao dịch.
                    </p>
                </div>
            </div>

            <!-- THONG KE -->
            <div class="inv-stats">
                <div class="card inv-stat">
                    <span>Tổng nguyên liệu</span>
                    <strong>${activeItems}</strong>
                    <small>Đang hoạt động</small>
                </div>

                <div class="card inv-stat">
                    <span>Sắp hết hàng</span>
                    <strong>${lowItems}</strong>
                    <small>Còn hàng nhưng dưới ngưỡng</small>
                </div>

                <div class="card inv-stat">
                    <span>Hết hàng</span>
                    <strong>${outItems}</strong>
                    <small>Không còn khả dụng</small>
                </div>

                <div class="card inv-stat">
                    <span>Giao dịch kho</span>
                    <strong>${totalTransactions}</strong>
                    <small>Theo bộ lọc lịch sử hiện tại</small>
                </div>
            </div>

            <!-- THONG BAO -->
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

            <section class="inv-surface">

                <!-- TABS -->
                <div class="inv-tabs">
                    <a href="${ctx}/manager/inventory?tab=inventory"
                       class="inv-tab ${activeTab ne 'history' ? 'active' : ''}">
                        Danh sách nguyên liệu
                    </a>

                    <a href="${historyUrl}#inventory-history"
                       class="inv-tab ${activeTab eq 'history' ? 'active' : ''}">
                        Lịch sử giao dịch
                    </a>
                </div>

                <!-- TAB DANH SACH -->
                <c:if test="${activeTab ne 'history'}">
                    <div id="inventory-list">

                        <!-- THANH CONG CU -->
                        <div class="inv-toolbar">
                            <input type="search"
                                   id="invSearch"
                                   class="inv-field inv-search"
                                   placeholder="Tìm nguyên liệu..."
                                   aria-label="Tìm nguyên liệu">

                            <select id="invStatus"
                                    class="inv-field inv-select">
                                <option value="all">Tất cả trạng thái</option>
                                <option value="normal">Ổn định</option>
                                <option value="low">Sắp hết</option>
                                <option value="out">Hết hàng</option>
                                <option value="inactive">Ngừng sử dụng</option>
                            </select>

                            <select id="invSort"
                                    class="inv-field inv-select">
                                <option value="name">Tên A–Z</option>
                                <option value="qtyAsc">Khả dụng tăng dần</option>
                                <option value="qtyDesc">Khả dụng giảm dần</option>
                            </select>

                            <button type="button"
                                    class="btn"
                                    data-inv-open="inv-create">
                                + Nguyên liệu
                            </button>

                            <button type="button"
                                    class="btn btn-primary"
                                    data-inv-open="inv-stockin"
                                    ${activeItems eq 0 ? 'disabled' : ''}>
                                + Nhập kho
                            </button>
                        </div>

                        <!-- BANG NGUYEN LIEU -->
                        <div class="inv-table-wrap">
                            <table class="inv-table">
                                <thead>
                                <tr>
                                    <th>Nguyên liệu</th>
                                    <th>Tồn thực tế</th>
                                    <th>Đã giữ chỗ</th>
                                    <th>Khả dụng</th>
                                    <th>Ngưỡng thấp</th>
                                    <th>Trạng thái</th>
                                    <th>Thao tác</th>
                                </tr>
                                </thead>

                                <tbody id="invTableBody">
                                <c:forEach var="i" items="${inventory}">

                                    <c:choose>
                                        <c:when test="${not i.active}">
                                            <c:set var="rowStatus" value="inactive" />
                                        </c:when>
                                        <c:when test="${i.availableQuantity le 0}">
                                            <c:set var="rowStatus" value="out" />
                                        </c:when>
                                        <c:when test="${i.lowStock}">
                                            <c:set var="rowStatus" value="low" />
                                        </c:when>
                                        <c:otherwise>
                                            <c:set var="rowStatus" value="normal" />
                                        </c:otherwise>
                                    </c:choose>

                                    <fmt:formatNumber
                                        var="actualNum"
                                        value="${i.quantity}"
                                        maxFractionDigits="3"
                                        groupingUsed="false" />

                                    <fmt:formatNumber
                                        var="thresholdNum"
                                        value="${i.lowStockThreshold}"
                                        maxFractionDigits="3"
                                        groupingUsed="false" />

                                    <tr class="inv-row"
                                        data-id="${i.inventoryItemId}"
                                        data-status="${rowStatus}"
                                        data-available="${i.availableQuantity}"
                                        data-actual="${actualNum}">

                                        <td>
                                            <strong class="inv-name"
                                                    data-inv-name>
                                                <c:out value="${i.name}" />
                                            </strong>
                                            <span class="inv-sub">
                                                Đơn vị:
                                                <c:out value="${i.unit}" />
                                            </span>
                                        </td>

                                        <td>
                                            <strong>
                                                <fmt:formatNumber
                                                    value="${i.quantity}"
                                                    maxFractionDigits="3"
                                                    groupingUsed="false" />
                                            </strong>
                                            <c:out value="${i.unit}" />
                                        </td>

                                        <td>
                                            <c:choose>
                                                <c:when test="${i.reservedQuantity gt 0}">
                                                    <strong>
                                                        <fmt:formatNumber
                                                            value="${i.reservedQuantity}"
                                                            maxFractionDigits="3"
                                                            groupingUsed="false" />
                                                    </strong>
                                                    <c:out value="${i.unit}" />
                                                    <span class="inv-sub">
                                                        Đang giữ
                                                    </span>
                                                </c:when>
                                                <c:otherwise>
                                                    0 <c:out value="${i.unit}" />
                                                </c:otherwise>
                                            </c:choose>
                                        </td>

                                        <td>
                                            <strong>
                                                <fmt:formatNumber
                                                    value="${i.availableQuantity}"
                                                    maxFractionDigits="3"
                                                    groupingUsed="false" />
                                            </strong>
                                            <c:out value="${i.unit}" />
                                        </td>

                                        <td>
                                            <strong>${thresholdNum}</strong>
                                            <c:out value="${i.unit}" />
                                            <button type="button"
                                                    class="inv-action"
                                                    data-inv-open="inv-threshold"
                                                    data-id="${i.inventoryItemId}">
                                                Sửa
                                            </button>
                                        </td>

                                        <td>
                                            <c:choose>
                                                <c:when test="${rowStatus eq 'inactive'}">
                                                    <span class="inv-badge inactive">
                                                        Ngừng sử dụng
                                                    </span>
                                                </c:when>
                                                <c:when test="${rowStatus eq 'out'}">
                                                    <span class="inv-badge out">
                                                        Hết hàng
                                                    </span>
                                                </c:when>
                                                <c:when test="${rowStatus eq 'low'}">
                                                    <span class="inv-badge low">
                                                        Sắp hết
                                                    </span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="inv-badge normal">
                                                        Ổn định
                                                    </span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>

                                        <td class="inv-nowrap">
                                            <c:choose>
                                                <c:when test="${i.active}">
                                                    <button type="button"
                                                            class="inv-action"
                                                            data-inv-open="inv-adjust"
                                                            data-id="${i.inventoryItemId}">
                                                        Điều chỉnh
                                                    </button>

                                                    <button type="button"
                                                            class="inv-action"
                                                            data-inv-open="inv-waste"
                                                            data-id="${i.inventoryItemId}">
                                                        Hao hụt
                                                    </button>
                                                </c:when>
                                                <c:otherwise>—</c:otherwise>
                                            </c:choose>
                                        </td>

                                    </tr>
                                </c:forEach>

                                <c:if test="${empty inventory}">
                                    <tr>
                                        <td colspan="7" class="inv-empty">
                                            Chưa có nguyên liệu.
                                        </td>
                                    </tr>
                                </c:if>

                                <tr id="invNoResults" hidden>
                                    <td colspan="7" class="inv-empty">
                                        Không tìm thấy nguyên liệu phù hợp.
                                    </td>
                                </tr>

                                </tbody>
                            </table>
                        </div>

                        <div class="inv-table-bottom">
                            <span id="invShowing">
                                Tổng ${activeItems} nguyên liệu đang hoạt động
                            </span>
                        </div>
                    </div>
                </c:if>

                <!-- TAB LICH SU -->
                <c:if test="${activeTab eq 'history'}">
                    <div id="inventory-history">

                        <div class="inv-history-heading">
                            <h2>Lịch sử giao dịch kho</h2>
                            <p class="muted">
                                Theo dõi các lần nhập, sử dụng,
                                điều chỉnh và hao hụt nguyên liệu.
                            </p>
                        </div>

                        <!-- BO LOC LICH SU -->
                        <form method="get"
                              action="${ctx}/manager/inventory"
                              class="inv-history-filter">

                            <input type="hidden"
                                   name="tab" value="history">

                            <div class="inv-history-field">
                                <label for="fromDate">Từ ngày</label>
                                <input type="date"
                                       id="fromDate"
                                       name="fromDate"
                                       class="inv-field"
                                       value="<c:out value='${fromDate}' />">
                            </div>

                            <div class="inv-history-field">
                                <label for="toDate">Đến ngày</label>
                                <input type="date"
                                       id="toDate"
                                       name="toDate"
                                       class="inv-field"
                                       value="<c:out value='${toDate}' />">
                            </div>

                            <div class="inv-history-field">
                                <label for="historyType">Loại giao dịch</label>
                                <select id="historyType"
                                        name="type"
                                        class="inv-field">
                                    <option value="">Tất cả</option>

                                    <option value="RESTOCK"
                                        ${selectedType eq 'RESTOCK' ? 'selected' : ''}>
                                        Nhập kho
                                    </option>

                                    <option value="USAGE"
                                        ${selectedType eq 'USAGE' ? 'selected' : ''}>
                                        Sử dụng cho món
                                    </option>

                                    <option value="WASTE_LOSS"
                                        ${selectedType eq 'WASTE_LOSS' ? 'selected' : ''}>
                                        Hao hụt
                                    </option>

                                    <option value="ADJUSTMENT"
                                        ${selectedType eq 'ADJUSTMENT' ? 'selected' : ''}>
                                        Điều chỉnh
                                    </option>
                                </select>
                            </div>

                            <div class="inv-history-field">
                                <label for="historyKeyword">Nguyên liệu</label>
                                <input type="search"
                                       id="historyKeyword"
                                       name="keyword"
                                       class="inv-field"
                                       maxlength="100"
                                       placeholder="Tên nguyên liệu"
                                       value="<c:out value='${keyword}' />">
                            </div>

                            <div class="inv-history-field inv-page-size">
                                <label for="historyPageSize">Dòng/trang</label>
                                <select id="historyPageSize"
                                        name="pageSize"
                                        class="inv-field">
                                    <option value="20"
                                        ${pageSize eq 20 ? 'selected' : ''}>20</option>
                                    <option value="50"
                                        ${pageSize eq 50 ? 'selected' : ''}>50</option>
                                    <option value="80"
                                        ${pageSize eq 80 ? 'selected' : ''}>80</option>
                                </select>
                            </div>

                            <div class="inv-history-buttons">
                                <button type="submit"
                                        class="btn btn-primary">
                                    Áp dụng
                                </button>
                                <a class="btn"
                                   href="${ctx}/manager/inventory?tab=history#inventory-history">
                                    Xóa lọc
                                </a>
                            </div>
                        </form>

                        <!-- BANG LICH SU -->
                        <div class="inv-table-wrap">
                            <table class="inv-table inv-history-table">
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
                                            <strong>
                                                #<c:out value="${tx.transactionId}" />
                                            </strong>
                                        </td>

                                        <td class="inv-nowrap">
                                            <fmt:formatDate
                                                value="${tx.createdAt}"
                                                pattern="dd/MM/yyyy HH:mm" />
                                        </td>

                                        <td>
                                            <strong class="inv-name">
                                                <c:out value="${tx.inventoryName}" />
                                            </strong>
                                            <span class="inv-sub">
                                                <c:out value="${tx.unit}" />
                                            </span>
                                        </td>

                                        <td>
                                            <c:choose>
                                                <c:when test="${tx.transactionType eq 'RESTOCK'}">
                                                    <span class="inv-badge normal">
                                                        Nhập kho
                                                    </span>
                                                </c:when>
                                                <c:when test="${tx.transactionType eq 'USAGE'}">
                                                    <span class="inv-badge usage">
                                                        Sử dụng cho món
                                                    </span>
                                                </c:when>
                                                <c:when test="${tx.transactionType eq 'WASTE_LOSS'}">
                                                    <span class="inv-badge out">
                                                        Hao hụt
                                                    </span>
                                                </c:when>
                                                <c:when test="${tx.transactionType eq 'ADJUSTMENT'}">
                                                    <span class="inv-badge low">
                                                        Điều chỉnh
                                                    </span>
                                                </c:when>
                                                <c:otherwise>
                                                    <c:out value="${tx.transactionType}" />
                                                </c:otherwise>
                                            </c:choose>
                                        </td>

                                        <td class="inv-nowrap">
                                            <strong class="${tx.quantityChange gt 0
                                                ? 'inventory-qty-positive'
                                                : 'inventory-qty-negative'}">
                                                <c:if test="${tx.quantityChange gt 0}">+</c:if>
                                                <fmt:formatNumber
                                                    value="${tx.quantityChange}"
                                                    maxFractionDigits="3"
                                                    groupingUsed="false" />
                                                <c:out value="${tx.unit}" />
                                            </strong>
                                        </td>

                                        <td>
                                            <c:choose>
                                                <c:when test="${not empty tx.referenceOrderId}">
                                                    #<c:out value="${tx.referenceOrderId}" />
                                                </c:when>
                                                <c:otherwise>—</c:otherwise>
                                            </c:choose>
                                        </td>

                                        <td class="inv-history-note">
                                            <c:out value="${tx.description}" default="—" />
                                        </td>

                                        <td>
                                            <a class="inv-action"
                                               href="${detailUrl}#inventory-history">
                                                Chi tiết
                                            </a>
                                        </td>
                                    </tr>

                                </c:forEach>

                                <c:if test="${empty transactions}">
                                    <tr>
                                        <td colspan="8" class="inv-empty">
                                            Không có giao dịch phù hợp.
                                        </td>
                                    </tr>
                                </c:if>
                                </tbody>
                            </table>
                        </div>

                        <!-- PHAN TRANG -->
                        <div class="inv-table-bottom">
                            <span>
                                Tổng:
                                <strong>${totalTransactions}</strong>
                                giao dịch
                            </span>

                            <div class="inv-pagination">

                                <c:if test="${currentPage gt 1}">
                                    <c:url var="previousUrl"
                                           value="/manager/inventory">
                                        <c:param name="tab" value="history" />
                                        <c:param name="page" value="${currentPage - 1}" />
                                        <c:param name="pageSize" value="${pageSize}" />
                                        <c:param name="fromDate" value="${fromDate}" />
                                        <c:param name="toDate" value="${toDate}" />
                                        <c:param name="type" value="${selectedType}" />
                                        <c:param name="keyword" value="${keyword}" />
                                    </c:url>

                                    <a class="btn btn-sm"
                                       href="${previousUrl}#inventory-history">
                                        Trước
                                    </a>
                                </c:if>

                                <span>
                                    Trang ${currentPage} / ${totalPages}
                                </span>

                                <c:if test="${currentPage lt totalPages}">
                                    <c:url var="nextUrl"
                                           value="/manager/inventory">
                                        <c:param name="tab" value="history" />
                                        <c:param name="page" value="${currentPage + 1}" />
                                        <c:param name="pageSize" value="${pageSize}" />
                                        <c:param name="fromDate" value="${fromDate}" />
                                        <c:param name="toDate" value="${toDate}" />
                                        <c:param name="type" value="${selectedType}" />
                                        <c:param name="keyword" value="${keyword}" />
                                    </c:url>

                                    <a class="btn btn-sm"
                                       href="${nextUrl}#inventory-history">
                                        Sau
                                    </a>
                                </c:if>

                            </div>
                        </div>

                    </div>
                </c:if>

            </section>
        </div>
    </main>
</div>

<!-- =====================================
     HOP THOAI TAO NGUYEN LIEU
     ===================================== -->
<dialog id="inv-create" class="inv-modal">
    <div class="inv-modal-head">
        <h2>Thêm nguyên liệu</h2>
        <button type="button"
                class="inv-modal-close"
                data-inv-close>×</button>
    </div>

    <form method="post" action="${ctx}/manager/inventory">
        <input type="hidden" name="action" value="create">

        <div class="form-group">
            <label>Tên nguyên liệu</label>
            <input type="text"
                   name="name"
                   maxlength="255"
                   required>
        </div>

        <div class="form-group">
            <label>Đơn vị</label>
            <select name="unit" id="createUnit" required>
                <option value="" disabled selected>-- Chọn đơn vị --</option>
                <option value="kg">Kilogram (kg)</option>
                <option value="gram">Gram (g)</option>
                <option value="lít">Lít (L)</option>
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
                <input type="number"
                       name="initialQuantity"
                       id="createQuantity"
                       step="0.001"
                       min="0"
                       required>
            </div>

            <div class="form-group">
                <label>Ngưỡng thấp</label>
                <input type="number"
                       name="lowStockThreshold"
                       id="createThreshold"
                       step="0.001"
                       min="0"
                       required>
            </div>
        </div>

        <div class="inv-modal-footer">
            <button type="button" class="btn" data-inv-close>Hủy</button>
            <button type="submit" class="btn btn-primary">
                Tạo nguyên liệu
            </button>
        </div>
    </form>
</dialog>

<!-- HOP THOAI NHAP KHO -->
<dialog id="inv-stockin" class="inv-modal">
    <div class="inv-modal-head">
        <h2>Nhập kho</h2>
        <button type="button"
                class="inv-modal-close"
                data-inv-close>×</button>
    </div>

    <form method="post" action="${ctx}/manager/inventory">
        <input type="hidden" name="action" value="stockin">

        <div class="form-group">
            <label>Nguyên liệu</label>
            <select name="id" required>
                <option value="" disabled selected>-- Chọn nguyên liệu --</option>

                <c:forEach var="i" items="${inventory}">
                    <c:if test="${i.active}">
                        <option value="${i.inventoryItemId}"
                                data-unit="<c:out value='${i.unit}' />"
                                data-available="${i.availableQuantity}">
                            <c:out value="${i.name}" />
                            (<c:out value="${i.unit}" />)
                        </option>
                    </c:if>
                </c:forEach>
            </select>
        </div>

        <p class="inv-stock-hint" data-available-hint></p>

        <div class="grid grid-2">
            <div class="form-group">
                <label>Số lượng nhập</label>
                <input type="number"
                       name="quantity"
                       step="0.001"
                       min="0.001"
                       required>
            </div>

            <div class="form-group">
                <label>Đơn giá nhập</label>
                <input type="number"
                       name="unitCost"
                       step="0.01"
                       min="0">
            </div>
        </div>

        <div class="form-group">
            <label>Ghi chú</label>
            <input type="text"
                   name="note"
                   maxlength="500"
                   placeholder="Nhập nguyên liệu từ nhà cung cấp">
        </div>

        <div class="inv-modal-footer">
            <button type="button" class="btn" data-inv-close>Hủy</button>
            <button type="submit" class="btn btn-primary">
                Ghi nhận nhập kho
            </button>
        </div>
    </form>
</dialog>

<!-- HOP THOAI DIEU CHINH -->
<dialog id="inv-adjust" class="inv-modal">
    <div class="inv-modal-head">
        <h2>Điều chỉnh tồn thực tế</h2>
        <button type="button"
                class="inv-modal-close"
                data-inv-close>×</button>
    </div>

    <p class="muted">
        Không thể điều chỉnh tồn thực tế thấp hơn
        lượng nguyên liệu đang giữ chỗ.
    </p>

    <form method="post" action="${ctx}/manager/inventory">
        <input type="hidden" name="action" value="adjust">

        <div class="form-group">
            <label>Nguyên liệu</label>
            <select name="id" required>
                <option value="" disabled selected>-- Chọn nguyên liệu --</option>

                <c:forEach var="i" items="${inventory}">
                    <c:if test="${i.active}">
                        <option value="${i.inventoryItemId}"
                                data-unit="<c:out value='${i.unit}' />"
                                data-available="${i.availableQuantity}"
                                data-reserved="${i.reservedQuantity}"
                                data-actual="${i.quantity}">
                            <c:out value="${i.name}" />
                        </option>
                    </c:if>
                </c:forEach>
            </select>
        </div>

        <p class="inv-stock-hint" data-available-hint></p>

        <div class="form-group">
            <label>Tồn thực tế sau kiểm kê</label>
            <input type="number"
                   name="actualQuantity"
                   step="0.001"
                   min="0"
                   required>
        </div>

        <div class="form-group">
            <label>Lý do điều chỉnh *</label>
            <input type="text"
                   name="note"
                   maxlength="500"
                   placeholder="Ví dụ: Chênh lệch kiểm kê"
                   required>
        </div>

        <div class="inv-modal-footer">
            <button type="button" class="btn" data-inv-close>Hủy</button>
            <button type="submit" class="btn btn-primary">
                Lưu điều chỉnh
            </button>
        </div>
    </form>
</dialog>

<!-- HOP THOAI HAO HUT -->
<dialog id="inv-waste" class="inv-modal">
    <div class="inv-modal-head">
        <h2>Ghi nhận hao hụt</h2>
        <button type="button"
                class="inv-modal-close"
                data-inv-close>×</button>
    </div>

    <p class="muted">
        Chỉ được ghi nhận hao hụt trong số lượng khả dụng,
        không ảnh hưởng lượng đang giữ chỗ.
    </p>

    <form method="post" action="${ctx}/manager/inventory">
        <input type="hidden" name="action" value="waste">

        <div class="form-group">
            <label>Nguyên liệu</label>
            <select name="id" required>
                <option value="" disabled selected>-- Chọn nguyên liệu --</option>

                <c:forEach var="i" items="${inventory}">
                    <c:if test="${i.active}">
                        <option value="${i.inventoryItemId}"
                                data-unit="<c:out value='${i.unit}' />"
                                data-available="${i.availableQuantity}">
                            <c:out value="${i.name}" />
                        </option>
                    </c:if>
                </c:forEach>
            </select>
        </div>

        <p class="inv-stock-hint" data-available-hint></p>

        <div class="form-group">
            <label>Số lượng hao hụt</label>
            <input type="number"
                   name="quantity"
                   step="0.001"
                   min="0.001"
                   required>
        </div>

        <div class="form-group">
            <label>Lý do hao hụt *</label>
            <input type="text"
                   name="note"
                   maxlength="500"
                   placeholder="Ví dụ: Nguyên liệu bị hỏng"
                   required>
        </div>

        <div class="inv-modal-footer">
            <button type="button" class="btn" data-inv-close>Hủy</button>
            <button type="submit" class="btn btn-danger">
                Ghi nhận hao hụt
            </button>
        </div>
    </form>
</dialog>

<!-- HOP THOAI SUA NGUONG THAP -->
<dialog id="inv-threshold" class="inv-modal">
    <div class="inv-modal-head">
        <h2>Cập nhật ngưỡng thấp</h2>
        <button type="button"
                class="inv-modal-close"
                data-inv-close>×</button>
    </div>

    <form method="post" action="${ctx}/manager/inventory">
        <input type="hidden" name="action" value="threshold">

        <div class="form-group">
            <label>Nguyên liệu</label>
            <select name="id" required>
                <option value="" disabled selected>-- Chọn nguyên liệu --</option>

                <c:forEach var="i" items="${inventory}">
                    <option value="${i.inventoryItemId}"
                            data-unit="<c:out value='${i.unit}' />"
                            data-threshold="${i.lowStockThreshold}">
                        <c:out value="${i.name}" />
                    </option>
                </c:forEach>
            </select>
        </div>

        <div class="form-group">
            <label>Ngưỡng thấp mới</label>
            <input type="number"
                   name="threshold"
                   step="0.001"
                   min="0"
                   required>
        </div>

        <div class="inv-modal-footer">
            <button type="button" class="btn" data-inv-close>Hủy</button>
            <button type="submit" class="btn btn-primary">
                Lưu thay đổi
            </button>
        </div>
    </form>
</dialog>

<!-- CHI TIET GIAO DICH -->
<c:if test="${not empty transactionDetail}">
    <div class="inventory-detail-overlay">

        <section class="card inventory-detail-dialog">
            <div class="inventory-detail-header">
                <h2>
                    Chi tiết giao dịch
                    #<c:out value="${transactionDetail.transactionId}" />
                </h2>

                <a href="${historyBackUrl}#inventory-history"
                   class="inventory-detail-close"
                   aria-label="Đóng">
                    ×
                </a>
            </div>

            <h3>Thông tin chung</h3>

            <dl class="inventory-detail-fields">
                <dt>Thời gian</dt>
                <dd>
                    <fmt:formatDate
                        value="${transactionDetail.createdAt}"
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
                        <c:when test="${transactionDetail.transactionType eq 'RESTOCK'}">
                            Nhập kho
                        </c:when>
                        <c:when test="${transactionDetail.transactionType eq 'USAGE'}">
                            Sử dụng cho món
                        </c:when>
                        <c:when test="${transactionDetail.transactionType eq 'WASTE_LOSS'}">
                            Hao hụt
                        </c:when>
                        <c:when test="${transactionDetail.transactionType eq 'ADJUSTMENT'}">
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

                    <fmt:formatNumber
                        value="${transactionDetail.quantityChange}"
                        maxFractionDigits="3"
                        groupingUsed="false" />

                    <c:out value="${transactionDetail.unit}" />
                </dd>

                <c:if test="${not empty transactionDetail.unitCost}">
                    <dt>Đơn giá nhập</dt>
                    <dd>
                        <fmt:formatNumber
                            value="${transactionDetail.unitCost}"
                            maxFractionDigits="2"
                            groupingUsed="true" />
                        đ
                    </dd>
                </c:if>
            </dl>

            <h3>Tham chiếu và ghi chú</h3>

            <dl class="inventory-detail-fields">
                <dt>Đơn hàng liên quan</dt>
                <dd>
                    <c:choose>
                        <c:when test="${not empty transactionDetail.referenceOrderId}">
                            #<c:out value="${transactionDetail.referenceOrderId}" />
                        </c:when>
                        <c:otherwise>
                            Không có
                        </c:otherwise>
                    </c:choose>
                </dd>
            </dl>

            <div class="inventory-detail-reason">
                <strong>Lý do / Ghi chú</strong>
                <p>
                    <c:out
                        value="${transactionDetail.description}"
                        default="Không có ghi chú." />
                </p>
            </div>

            <div class="inventory-detail-footer">
                <a href="${historyBackUrl}#inventory-history"
                   class="btn">
                    Đóng
                </a>
            </div>
        </section>
    </div>
</c:if>

<!-- JAVASCRIPT CHI CHO MAN HINH KHO -->
<script>
document.addEventListener("DOMContentLoaded", function () {

    // 1. TIM KIEM, LOC, SAP XEP DANH SACH
    const search = document.getElementById("invSearch");
    const status = document.getElementById("invStatus");
    const sort = document.getElementById("invSort");
    const tbody = document.getElementById("invTableBody");
    const noResults = document.getElementById("invNoResults");
    const showing = document.getElementById("invShowing");

    const rows = Array.from(
        document.querySelectorAll("#invTableBody .inv-row")
    );

    function normalizeText(value) {
        return String(value || "")
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "")
            .replace(/đ/g, "d")
            .replace(/Đ/g, "D")
            .toLowerCase()
            .trim();
    }

    function updateTable() {
        if (!tbody || !search || !status || !sort) return;

        const keyword = normalizeText(search.value);
        const selectedStatus = status.value;
        const selectedSort = sort.value;

        const sorted = [...rows];

        sorted.sort(function (a, b) {
            if (selectedSort === "qtyAsc") {
                return Number(a.dataset.available) -
                       Number(b.dataset.available);
            }

            if (selectedSort === "qtyDesc") {
                return Number(b.dataset.available) -
                       Number(a.dataset.available);
            }

            const aName = normalizeText(
                a.querySelector("[data-inv-name]").textContent
            );
            const bName = normalizeText(
                b.querySelector("[data-inv-name]").textContent
            );

            return aName.localeCompare(bName, "vi");
        });

        let visible = 0;

        sorted.forEach(function (row) {
            const rowName = normalizeText(
                row.querySelector("[data-inv-name]").textContent
            );

            const matchesName = rowName.includes(keyword);
            const matchesStatus =
                selectedStatus === "all" ||
                row.dataset.status === selectedStatus;

            row.hidden = !(matchesName && matchesStatus);

            if (!row.hidden) visible++;

            if (noResults) {
                tbody.insertBefore(row, noResults);
            } else {
                tbody.appendChild(row);
            }
        });

        if (noResults) {
            noResults.hidden = visible > 0 || rows.length === 0;
        }

        if (showing) {
            showing.textContent =
                "Hiển thị " + visible + "/" + rows.length + " nguyên liệu";
        }
    }

    if (search && status && sort) {
        search.addEventListener("input", updateTable);
        status.addEventListener("change", updateTable);
        sort.addEventListener("change", updateTable);
        updateTable();
    }

    // 2. CAP NHAT DON VI NHAP LIEU
    const countUnits = new Set([
        "lon", "chai", "hop", "goi", "piece", "qua"
    ]);

    function updateStep(input, unit, minValue) {
        if (!input) return;
        input.step = countUnits.has(unit) ? "1" : "0.001";

        if (minValue !== undefined) {
            input.min = String(minValue);
        }
    }

    // 3. TU DIEN THONG TIN NGUYEN LIEU TRONG MODAL
    function updateModalFields(modal) {
        const select = modal.querySelector('select[name="id"]');

        if (!select || !select.selectedOptions.length) return;

        const option = select.selectedOptions[0];
        const unit = option.dataset.unit || "";
        const available = option.dataset.available || "0";
        const hint = modal.querySelector("[data-available-hint]");

        if (hint) {
            hint.textContent = option.value
                ? "Tồn khả dụng: " + available + " " + unit
                : "";
        }

        if (modal.id === "inv-stockin" ||
            modal.id === "inv-waste") {

            const input = modal.querySelector(
                'input[name="quantity"]'
            );

            updateStep(
                input,
                unit,
                countUnits.has(unit) ? 1 : 0.001
            );

            if (modal.id === "inv-waste" && input) {
                input.max = available;
            }
        }

        if (modal.id === "inv-adjust") {
            const input = modal.querySelector(
                'input[name="actualQuantity"]'
            );

            updateStep(
                input,
                unit,
                option.dataset.reserved || "0"
            );

            if (input) {
                input.value = option.dataset.actual || "0";
            }

            if (hint && option.value) {
                hint.textContent +=
                    " | Đã giữ chỗ: " +
                    (option.dataset.reserved || "0") +
                    " " + unit;
            }
        }

        if (modal.id === "inv-threshold") {
            const input = modal.querySelector(
                'input[name="threshold"]'
            );

            updateStep(input, unit, 0);

            if (input) {
                input.value = option.dataset.threshold || "0";
            }
        }
    }

    document.querySelectorAll(".inv-modal")
        .forEach(function (modal) {

            const select = modal.querySelector(
                'select[name="id"]'
            );

            if (select) {
                select.addEventListener("change", function () {
                    updateModalFields(modal);
                });
            }
        });

    const createUnit = document.getElementById("createUnit");

    if (createUnit) {
        createUnit.addEventListener("change", function () {
            updateStep(
                document.getElementById("createQuantity"),
                createUnit.value,
                0
            );

            updateStep(
                document.getElementById("createThreshold"),
                createUnit.value,
                0
            );
        });
    }

    // 4. MO HOP THOAI
    document.querySelectorAll("[data-inv-open]")
        .forEach(function (button) {

            button.addEventListener("click", function () {
                const modal = document.getElementById(
                    button.dataset.invOpen
                );

                if (!modal) return;

                const form = modal.querySelector("form");

                if (form) form.reset();

                if (button.dataset.id) {
                    const select = modal.querySelector(
                        'select[name="id"]'
                    );

                    if (select) {
                        select.value = button.dataset.id;
                    }
                }

                updateModalFields(modal);
                modal.showModal();
            });
        });

    // 5. DONG HOP THOAI
    document.querySelectorAll("[data-inv-close]")
        .forEach(function (button) {

            button.addEventListener("click", function () {
                const modal = button.closest("dialog");

                if (modal) modal.close();
            });
        });

    // 6. DONG BANG CACH NHAN BEN NGOAI
    document.querySelectorAll(".inv-modal")
        .forEach(function (modal) {

            modal.addEventListener("click", function (event) {
                if (event.target !== modal) return;

                const rect = modal.getBoundingClientRect();

                const outside =
                    event.clientX < rect.left ||
                    event.clientX > rect.right ||
                    event.clientY < rect.top ||
                    event.clientY > rect.bottom;

                if (outside) modal.close();
            });
        });

});
</script>

</body>
</html>
