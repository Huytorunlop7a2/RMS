<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
            <%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

                <c:set var="ctx" value="${pageContext.request.contextPath}" />
                <fmt:setLocale value="en_US" scope="page" />

                <%-- THONG KE MENU --%>
                    <c:set var="totalItems" value="0" />
                    <c:set var="activeItems" value="0" />
                    <c:set var="availableItems" value="0" />
                    <c:set var="missingRecipes" value="0" />

                    <c:forEach var="m" items="${items}">
                        <c:set var="totalItems" value="${totalItems + 1}" />

                        <c:if test="${m.active}">
                            <c:set var="activeItems" value="${activeItems + 1}" />
                        </c:if>

                        <c:if test="${m.recipeConfigured and m.inventoryAvailable}">
                            <c:set var="availableItems" value="${availableItems + 1}" />
                        </c:if>

                        <c:if test="${not m.recipeConfigured}">
                            <c:set var="missingRecipes" value="${missingRecipes + 1}" />
                        </c:if>
                    </c:forEach>

                    <!doctype html>
                    <html lang="vi">

                    <head>
                        <meta charset="UTF-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1">

                        <title>Quản lý menu | RMS</title>

                        <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=menu-recipe-pro-3">
                    </head>

                    <body class="menu-app">
                        <div class="layout">

                            <!-- SIDEBAR -->
                            <aside class="sidebar">
                                <div class="brand">RMS · Quản lý</div>

                                <nav class="nav">
                                    <a href="${ctx}/manager/tables">Bàn &amp; QR</a>
                                    <a href="${ctx}/manager/menu" class="menu-nav-active">Menu</a>
                                    <a href="${ctx}/manager/inventory">Kho</a>
                                    <a href="${ctx}/manager/opening-hours">Giờ hoạt động</a>
                                    <a href="${ctx}/logout">Đăng xuất</a>
                                </nav>
                            </aside>

                            <!-- MAIN -->
                            <main class="main">
                                <div class="container">

                                    <!-- HEADER -->
                                    <div class="page-head menu-page-head">
                                        <div>
                                            <h1>Quản lý menu &amp; công thức</h1>
                                            <p class="muted">
                                                Quản lý món ăn, đồ uống và định lượng
                                                nguyên liệu cho từng phần.
                                            </p>
                                        </div>
                                    </div>

                                    <!-- STATISTICS -->
                                    <div class="menu-stats">

                                        <div class="card menu-stat">
                                            <span>Tổng số món</span>
                                            <strong>${totalItems}</strong>
                                            <small>Tất cả món trong menu</small>
                                        </div>

                                        <div class="card menu-stat">
                                            <span>Đang bật</span>
                                            <strong>${activeItems}</strong>
                                            <small>Món đã kích hoạt</small>
                                        </div>

                                        <div class="card menu-stat">
                                            <span>Đủ nguyên liệu</span>
                                            <strong>${availableItems}</strong>
                                            <small>Có công thức và đủ tồn khả dụng</small>
                                        </div>

                                        <div class="card menu-stat">
                                            <span>Chưa có công thức</span>
                                            <strong>${missingRecipes}</strong>
                                            <small>Cần cấu hình nguyên liệu</small>
                                        </div>

                                    </div>

                                    <!-- FLASH MESSAGE -->
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

                                    <!-- MENU LIST -->
                                    <section class="menu-surface">

                                        <div class="menu-section-head">
                                            <div>
                                                <h2>Danh sách món</h2>
                                                <p class="muted">
                                                    Tìm kiếm, cập nhật thông tin
                                                    và quản lý công thức.
                                                </p>
                                            </div>

                                            <button type="button" class="btn btn-primary" data-menu-open="menu-create">
                                                + Thêm món
                                            </button>
                                        </div>

                                        <!-- FILTER BAR -->
                                        <div class="menu-toolbar">

                                            <input type="search" id="menuSearch" class="menu-field menu-search"
                                                placeholder="Tìm tên món..." aria-label="Tìm tên món">

                                            <select id="menuCategoryFilter" class="menu-field menu-select"
                                                aria-label="Lọc danh mục">

                                                <option value="all">
                                                    Tất cả danh mục
                                                </option>

                                                <c:forEach var="cat" items="${categories}">
                                                    <option value="${cat.categoryId}">
                                                        <c:out value="${cat.name}" />
                                                    </option>
                                                </c:forEach>
                                            </select>

                                            <select id="menuStatusFilter" class="menu-field menu-select"
                                                aria-label="Lọc trạng thái">

                                                <option value="all">Tất cả trạng thái</option>
                                                <option value="active">Đang bật</option>
                                                <option value="inactive">Đang tắt</option>
                                                <option value="available">Đủ nguyên liệu</option>
                                                <option value="unavailable">Thiếu nguyên liệu</option>
                                                <option value="missing">Chưa có công thức</option>
                                            </select>

                                            <select id="menuSort" class="menu-field menu-select"
                                                aria-label="Sắp xếp món">

                                                <option value="name">Tên A–Z</option>
                                                <option value="priceAsc">Giá tăng dần</option>
                                                <option value="priceDesc">Giá giảm dần</option>
                                            </select>

                                        </div>

                                        <!-- TABLE -->
                                        <div class="menu-table-wrap">
                                            <table class="menu-table">

                                                <thead>
                                                    <tr>
                                                        <th>Món ăn / Đồ uống</th>
                                                        <th>Danh mục</th>
                                                        <th>Giá bán</th>
                                                        <th>Trạng thái bán</th>
                                                        <th>Nguyên liệu</th>
                                                        <th>Thao tác</th>
                                                    </tr>
                                                </thead>

                                                <tbody id="menuTableBody">

                                                    <c:forEach var="m" items="${items}">

                                                        <c:choose>
                                                            <c:when test="${not m.recipeConfigured}">
                                                                <c:set var="recipeStatus" value="missing" />
                                                            </c:when>
                                                            <c:when test="${m.inventoryAvailable}">
                                                                <c:set var="recipeStatus" value="available" />
                                                            </c:when>
                                                            <c:otherwise>
                                                                <c:set var="recipeStatus" value="unavailable" />
                                                            </c:otherwise>
                                                        </c:choose>

                                                        <tr class="menu-item-row" data-category="${m.categoryId}"
                                                            data-active="${m.active}" data-recipe="${recipeStatus}"
                                                            data-price="${m.price}">

                                                            <td>
                                                                <div class="menu-item-info">
                                                                    <strong data-menu-name>
                                                                        <c:out value="${m.name}" />
                                                                    </strong>

                                                                    <span class="menu-sub">
                                                                        <c:out value="${m.description}"
                                                                            default="Chưa có mô tả" />
                                                                    </span>
                                                                </div>
                                                            </td>

                                                            <td>
                                                                <span class="menu-category-label">
                                                                    <c:out value="${m.categoryName}" />
                                                                </span>
                                                            </td>

                                                            <td class="menu-nowrap">
                                                                <strong class="menu-price">
                                                                    <fmt:formatNumber value="${m.price}"
                                                                        maxFractionDigits="0" />
                                                                    ₫
                                                                </strong>
                                                            </td>

                                                            <td>
                                                                <c:choose>
                                                                    <c:when test="${m.active}">
                                                                        <span class="menu-badge active">
                                                                            Đang bật
                                                                        </span>
                                                                    </c:when>
                                                                    <c:otherwise>
                                                                        <span class="menu-badge inactive">
                                                                            Đang tắt
                                                                        </span>
                                                                    </c:otherwise>
                                                                </c:choose>
                                                            </td>

                                                            <td>
                                                                <c:choose>
                                                                    <c:when test="${recipeStatus eq 'missing'}">
                                                                        <span class="menu-badge missing">
                                                                            Chưa có công thức
                                                                        </span>
                                                                    </c:when>

                                                                    <c:when test="${recipeStatus eq 'available'}">
                                                                        <span class="menu-badge available">
                                                                            Đủ nguyên liệu
                                                                        </span>
                                                                    </c:when>

                                                                    <c:otherwise>
                                                                        <span class="menu-badge unavailable">
                                                                            Thiếu nguyên liệu
                                                                        </span>
                                                                    </c:otherwise>
                                                                </c:choose>

                                                                <span class="menu-sub">
                                                                    ${fn:length(m.ingredients)}
                                                                    nguyên liệu
                                                                </span>
                                                            </td>

                                                            <td class="menu-nowrap">
                                                                <button type="button" class="menu-action"
                                                                    data-menu-open="menu-edit-${m.menuItemId}">
                                                                    Sửa
                                                                </button>

                                                                <button type="button"
                                                                    class="menu-action menu-action-primary"
                                                                    data-menu-open="menu-recipe-${m.menuItemId}">
                                                                    Công thức
                                                                </button>
                                                            </td>

                                                        </tr>
                                                    </c:forEach>

                                                    <c:if test="${empty items}">
                                                        <tr>
                                                            <td colspan="6" class="menu-empty">
                                                                Chưa có món nào trong menu.
                                                            </td>
                                                        </tr>
                                                    </c:if>

                                                    <tr id="menuNoResults" hidden>
                                                        <td colspan="6" class="menu-empty">
                                                            Không tìm thấy món phù hợp.
                                                        </td>
                                                    </tr>

                                                </tbody>
                                            </table>
                                        </div>

                                        <div class="menu-table-footer">
                                            <span id="menuShowing">
                                                Tổng ${totalItems} món
                                            </span>
                                        </div>
                                    </section>

                                </div>
                            </main>
                        </div>

                        <dialog id="menu-create" class="menu-modal">

                            <div class="menu-modal-head">
                                <div>
                                    <h2>Thêm món mới</h2>
                                    <p class="muted">Nhập thông tin món ăn hoặc đồ uống.</p>
                                </div>

                                <button type="button" class="menu-modal-close" data-menu-close
                                    aria-label="Đóng">×</button>
                            </div>

                            <form method="post" action="${ctx}/manager/menu">

                                <input type="hidden" name="action" value="create">

                                <div class="form-group">
                                    <label>Danh mục</label>
                                    <select name="categoryId" required>
                                        <option value="" selected disabled>
                                            -- Chọn danh mục --
                                        </option>

                                        <c:forEach var="cat" items="${categories}">
                                            <c:if test="${cat.active}">
                                                <option value="${cat.categoryId}">
                                                    <c:out value="${cat.name}" />
                                                </option>
                                            </c:if>
                                        </c:forEach>
                                    </select>
                                </div>

                                <div class="form-group">
                                    <label>Tên món</label>
                                    <input type="text" name="name" maxlength="255" placeholder="Nhập tên món" required>
                                </div>

                                <div class="form-group">
                                    <label>Giá bán (VNĐ)</label>
                                    <input type="number" name="price" min="0" step="1000" placeholder="Ví dụ: 65000"
                                        required>
                                </div>

                                <div class="form-group">
                                    <label>Mô tả</label>
                                    <textarea name="description" maxlength="1000" rows="3"
                                        placeholder="Mô tả ngắn về món"></textarea>
                                </div>

                                <p class="menu-helper">
                                    Sau khi tạo món, hãy mở Công thức để khai báo
                                    định lượng nguyên liệu cho một phần.
                                </p>

                                <div class="menu-modal-footer">
                                    <button type="button" class="btn" data-menu-close>
                                        Hủy
                                    </button>

                                    <button type="submit" class="btn btn-primary">
                                        Tạo món
                                    </button>
                                </div>
                            </form>
                        </dialog>

                        <!-- EDIT ITEM MODAL & RECIPE MODAL -->
                        <c:forEach var="m" items="${items}">

                            <!-- EDIT ITEM MODAL -->
                            <dialog id="menu-edit-${m.menuItemId}" class="menu-modal">

                                <div class="menu-modal-head">
                                    <div>
                                        <h2>Chỉnh sửa món</h2>
                                        <p class="muted">
                                            <c:out value="${m.name}" />
                                        </p>
                                    </div>

                                    <button type="button" class="menu-modal-close" data-menu-close
                                        aria-label="Đóng">×</button>
                                </div>

                                <form method="post" action="${ctx}/manager/menu">

                                    <input type="hidden" name="action" value="update">

                                    <input type="hidden" name="id" value="${m.menuItemId}">

                                    <div class="form-group">
                                        <label>Danh mục</label>

                                        <select name="categoryId" required>
                                            <c:forEach var="cat" items="${categories}">
                                                <option value="${cat.categoryId}" ${cat.categoryId eq m.categoryId
                                                    ? 'selected' : '' }>
                                                    <c:out value="${cat.name}" />
                                                </option>
                                            </c:forEach>
                                        </select>
                                    </div>

                                    <div class="form-group">
                                        <label>Tên món</label>

                                        <input type="text" name="name" value="${fn:escapeXml(m.name)}" maxlength="255"
                                            required>
                                    </div>

                                    <div class="form-group">
                                        <label>Giá bán (VNĐ)</label>

                                        <input type="number" name="price" min="0" step="1000" value="${m.price}"
                                            required>
                                    </div>

                                    <div class="form-group">
                                        <label>Mô tả</label>

                                        <textarea name="description" maxlength="1000"
                                            rows="3"><c:out value="${m.description}" /></textarea>
                                    </div>

                                    <div class="menu-modal-footer">
                                        <button type="button" class="btn" data-menu-close>
                                            Đóng
                                        </button>

                                        <button type="submit" class="btn btn-primary">
                                            Lưu thay đổi
                                        </button>
                                    </div>
                                </form>

                                <div class="menu-toggle-section">
                                    <div>
                                        <strong>Trạng thái bán</strong>
                                        <p class="muted">
                                            Bật hoặc tắt món trong menu.
                                        </p>
                                    </div>

                                    <form method="post" action="${ctx}/manager/menu">

                                        <input type="hidden" name="action" value="toggle">

                                        <input type="hidden" name="id" value="${m.menuItemId}">

                                        <input type="hidden" name="active" value="${not m.active}">

                                        <button type="submit"
                                            class="btn btn-sm ${m.active ? 'btn-danger' : 'btn-success'}"
                                            data-menu-confirm-toggle="${m.active}">
                                            ${m.active ? 'Tắt món' : 'Bật món'}
                                        </button>
                                    </form>
                                </div>
                            </dialog>

                            <!-- RECIPE MODAL -->
                            <dialog id="menu-recipe-${m.menuItemId}" class="menu-modal menu-recipe-modal">

                                <div class="menu-modal-head">
                                    <div>
                                        <h2>
                                            Công thức:
                                            <c:out value="${m.name}" />
                                        </h2>

                                        <p class="muted">
                                            Định lượng nguyên liệu cho một phần ăn.
                                        </p>
                                    </div>

                                    <button type="button" class="menu-modal-close" data-menu-close
                                        aria-label="Đóng">×</button>
                                </div>

                                <div class="menu-recipe-summary">
                                    <span class="menu-recipe-category">
                                        <c:out value="${m.categoryName}" />
                                    </span>

                                    <span class="menu-recipe-price">
                                        <fmt:formatNumber value="${m.price}" maxFractionDigits="0" />
                                        ₫
                                    </span>

                                    <c:choose>
                                        <c:when test="${not m.recipeConfigured}">
                                            <span class="menu-badge missing">
                                                Chưa có công thức
                                            </span>
                                        </c:when>

                                        <c:when test="${m.inventoryAvailable}">
                                            <span class="menu-badge available">
                                                Đủ nguyên liệu
                                            </span>
                                        </c:when>

                                        <c:otherwise>
                                            <span class="menu-badge unavailable">
                                                Thiếu nguyên liệu
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </div>

                                <div class="menu-recipe-heading">
                                    <div>
                                        <h3>Thành phần nguyên liệu</h3>
                                        <p class="muted">
                                            ${fn:length(m.ingredients)}
                                            nguyên liệu trong công thức
                                        </p>
                                    </div>
                                </div>

                                <!-- RECIPE TABLE -->
                                <div class="menu-recipe-table-wrap">

                                    <table class="menu-recipe-table">
                                        <thead>
                                            <tr>
                                                <th>Nguyên liệu</th>
                                                <th>Định lượng / phần</th>
                                                <th>Thao tác</th>
                                            </tr>
                                        </thead>

                                        <tbody>
                                            <c:forEach var="r" items="${m.ingredients}">
                                                <tr>
                                                    <td>
                                                        <strong>
                                                            <c:out value="${r.inventoryItemName}" />
                                                        </strong>

                                                        <span class="menu-sub">
                                                            Đơn vị:
                                                            <c:out value="${r.unit}" />
                                                        </span>
                                                    </td>

                                                    <td>
                                                        <form method="post" class="menu-recipe-update-form"
                                                            action="${ctx}/manager/menu">

                                                            <input type="hidden" name="action" value="saveIngredient">

                                                            <input type="hidden" name="menuItemId"
                                                                value="${m.menuItemId}">

                                                            <input type="hidden" name="inventoryItemId"
                                                                value="${r.inventoryItemId}">

                                                            <input type="number" class="menu-recipe-quantity"
                                                                name="requiredQuantity" value="${r.requiredQuantity}"
                                                                step="0.001" min="0.001" required>

                                                            <span>
                                                                <c:out value="${r.unit}" />
                                                            </span>

                                                            <button class="btn btn-sm" type="submit">
                                                                Lưu
                                                            </button>
                                                        </form>
                                                    </td>

                                                    <td>
                                                        <form method="post" action="${ctx}/manager/menu"
                                                            class="menu-remove-form">

                                                            <input type="hidden" name="action" value="removeIngredient">

                                                            <input type="hidden" name="menuItemId"
                                                                value="${m.menuItemId}">

                                                            <input type="hidden" name="inventoryItemId"
                                                                value="${r.inventoryItemId}">

                                                            <button type="submit" class="menu-action menu-action-danger"
                                                                data-menu-remove>
                                                                Xóa
                                                            </button>
                                                        </form>
                                                    </td>
                                                </tr>
                                            </c:forEach>

                                            <c:if test="${empty m.ingredients}">
                                                <tr>
                                                    <td colspan="3" class="menu-empty">
                                                        Chưa có nguyên liệu trong công thức.
                                                        Hãy thêm nguyên liệu ở bên dưới.
                                                    </td>
                                                </tr>
                                            </c:if>
                                        </tbody>
                                    </table>
                                </div>

                                <!-- ADD INGREDIENT -->
                                <div class="menu-add-recipe">
                                    <h3>Thêm hoặc cập nhật nguyên liệu</h3>

                                    <p class="muted">
                                        Nếu nguyên liệu đã có trong công thức,
                                        hệ thống sẽ cập nhật định lượng của nguyên liệu đó.
                                    </p>

                                    <form method="post" action="${ctx}/manager/menu">

                                        <input type="hidden" name="action" value="saveIngredient">

                                        <input type="hidden" name="menuItemId" value="${m.menuItemId}">

                                        <div class="menu-recipe-add-grid">
                                            <div class="form-group menu-ingredient-picker">

                                                <label>Nguyên liệu</label>

                                                <input type="search" class="menu-ingredient-search"
                                                    placeholder="Tìm tên nguyên liệu..." autocomplete="off" required>

                                                <input type="hidden" name="inventoryItemId" class="menu-ingredient-id">

                                                <div class="menu-ingredient-results" hidden>

                                                    <c:forEach var="i" items="${inventory}">
                                                        <c:if test="${i.active}">

                                                            <button type="button" class="menu-ingredient-option"
                                                                data-id="${i.inventoryItemId}">

                                                                <span class="menu-ingredient-name">
                                                                    <c:out value="${i.name}" />
                                                                </span>

                                                                <span class="menu-ingredient-unit">
                                                                    <c:out value="${i.unit}" />
                                                                </span>

                                                            </button>

                                                        </c:if>
                                                    </c:forEach>

                                                    <div class="menu-ingredient-empty" hidden>
                                                        Không tìm thấy nguyên liệu.
                                                    </div>

                                                </div>

                                            </div>

                                            <div class="form-group">
                                                <label>Định lượng / phần</label>

                                                <input type="number" name="requiredQuantity" min="0.001" step="0.001"
                                                    placeholder="Ví dụ: 0.150" required>
                                            </div>

                                            <div class="form-group menu-add-button">
                                                <button type="submit" class="btn btn-primary">
                                                    + Lưu nguyên liệu
                                                </button>
                                            </div>
                                        </div>
                                    </form>
                                </div>

                                <div class="menu-recipe-footer">
                                    <span class="muted">
                                        Công thức được tính cho 1 phần.
                                    </span>

                                    <button type="button" class="btn" data-menu-close>
                                        Đóng
                                    </button>
                                </div>
                            </dialog>

                        </c:forEach>
                        
                        <script>
                            document.addEventListener("DOMContentLoaded", function () {

                                // =========================================
                                // 1. TIM KIEM, LOC VA SAP XEP
                                // =========================================

                                const search = document.getElementById("menuSearch");
                                const category = document.getElementById("menuCategoryFilter");
                                const status = document.getElementById("menuStatusFilter");
                                const sort = document.getElementById("menuSort");
                                const tbody = document.getElementById("menuTableBody");
                                const noResults = document.getElementById("menuNoResults");
                                const showing = document.getElementById("menuShowing");

                                const rows = Array.from(
                                    document.querySelectorAll(".menu-item-row")
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

                                function filterMenu() {
                                    if (!search || !category || !status || !sort || !tbody) {
                                        return;
                                    }

                                    const keyword = normalizeText(search.value);
                                    const categoryValue = category.value;
                                    const statusValue = status.value;
                                    const sortValue = sort.value;

                                    const sorted = [...rows];

                                    sorted.sort(function (a, b) {
                                        if (sortValue === "priceAsc") {
                                            return Number(a.dataset.price) -
                                                Number(b.dataset.price);
                                        }

                                        if (sortValue === "priceDesc") {
                                            return Number(b.dataset.price) -
                                                Number(a.dataset.price);
                                        }

                                        const nameA = normalizeText(
                                            a.querySelector("[data-menu-name]").textContent
                                        );

                                        const nameB = normalizeText(
                                            b.querySelector("[data-menu-name]").textContent
                                        );

                                        return nameA.localeCompare(nameB, "vi");
                                    });

                                    let visible = 0;

                                    sorted.forEach(function (row) {
                                        const name = normalizeText(
                                            row.querySelector("[data-menu-name]").textContent
                                        );

                                        const matchName = name.includes(keyword);

                                        const matchCategory =
                                            categoryValue === "all" ||
                                            row.dataset.category === categoryValue;

                                        let matchStatus = true;

                                        if (statusValue === "active") {
                                            matchStatus = row.dataset.active === "true";
                                        } else if (statusValue === "inactive") {
                                            matchStatus = row.dataset.active === "false";
                                        } else if (statusValue === "missing") {
                                            matchStatus = row.dataset.recipe === "missing";
                                        } else if (statusValue === "available") {
                                            matchStatus = row.dataset.recipe === "available";
                                        } else if (statusValue === "unavailable") {
                                            matchStatus = row.dataset.recipe === "unavailable";
                                        }

                                        row.hidden = !(matchName && matchCategory && matchStatus);

                                        if (!row.hidden) {
                                            visible++;
                                        }

                                        if (noResults) {
                                            tbody.insertBefore(row, noResults);
                                        } else {
                                            tbody.appendChild(row);
                                        }
                                    });

                                    if (noResults) {
                                        noResults.hidden =
                                            visible !== 0 || rows.length === 0;
                                    }

                                    if (showing) {
                                        showing.textContent =
                                            "Hiển thị " + visible + "/" + rows.length + " món";
                                    }
                                }

                                [search, category, status, sort].forEach(function (field) {
                                    if (!field) return;

                                    field.addEventListener(
                                        field === search ? "input" : "change",
                                        filterMenu
                                    );
                                });

                                filterMenu();

                                // =========================================
                                // 2. MO MODAL
                                // =========================================

                                document.querySelectorAll("[data-menu-open]")
                                    .forEach(function (button) {

                                        button.addEventListener("click", function () {

                                            const modalId = button.dataset.menuOpen;
                                            const modal = document.getElementById(modalId);

                                            if (!modal) return;

                                            modal.showModal();
                                        });
                                    });

                                // =========================================
                                // 3. DONG MODAL
                                // =========================================

                                document.querySelectorAll("[data-menu-close]")
                                    .forEach(function (button) {

                                        button.addEventListener("click", function () {
                                            const modal = button.closest("dialog");

                                            if (modal) {
                                                modal.close();
                                            }
                                        });
                                    });

                                document.querySelectorAll(".menu-modal")
                                    .forEach(function (modal) {

                                        modal.addEventListener("click", function (event) {
                                            if (event.target !== modal) return;

                                            const rect = modal.getBoundingClientRect();

                                            const outside =
                                                event.clientX < rect.left ||
                                                event.clientX > rect.right ||
                                                event.clientY < rect.top ||
                                                event.clientY > rect.bottom;

                                            if (outside) {
                                                modal.close();
                                            }
                                        });
                                    });

                                // =========================================
                                // 4. XAC NHAN XOA NGUYEN LIEU
                                // =========================================

                                document.querySelectorAll("[data-menu-remove]")
                                    .forEach(function (button) {

                                        const form = button.closest("form");

                                        if (!form) return;

                                        form.addEventListener("submit", function (event) {
                                            const confirmed = window.confirm(
                                                "Bạn có chắc muốn xóa nguyên liệu " +
                                                "này khỏi công thức?"
                                            );

                                            if (!confirmed) {
                                                event.preventDefault();
                                            }
                                        });
                                    });

                                // =========================================
                                // 5. XAC NHAN TAT MON
                                // =========================================

                                document.querySelectorAll("[data-menu-confirm-toggle]")
                                    .forEach(function (button) {

                                        if (button.dataset.menuConfirmToggle !== "true") {
                                            return;
                                        }

                                        const form = button.closest("form");

                                        if (!form) return;

                                        form.addEventListener("submit", function (event) {
                                            if (!window.confirm(
                                                "Bạn có chắc muốn tắt món này?"
                                            )) {
                                                event.preventDefault();
                                            }
                                        });
                                    });
                                // =========================================
                                // 6. GIU MO CONG THUC SAU KHI LUU
                                // =========================================

                                // Luu lai cong thuc dang mo truoc khi submit
                                document.querySelectorAll(".menu-recipe-modal form")
                                    .forEach(function (form) {

                                        form.addEventListener("submit", function () {

                                            const actionInput = form.querySelector(
                                                'input[name="action"]'
                                            );

                                            if (!actionInput) return;

                                            const action = actionInput.value;

                                            if (action === "saveIngredient" ||
                                                action === "removeIngredient") {

                                                const modal = form.closest("dialog");

                                                if (modal) {
                                                    sessionStorage.setItem(
                                                        "openMenuRecipe",
                                                        modal.id
                                                    );
                                                }
                                            }
                                        });
                                    });

                                // Sau khi Servlet redirect va tai lai trang,
                                // tu dong mo lai cong thuc cu
                                const savedRecipe = sessionStorage.getItem("openMenuRecipe");

                                if (savedRecipe) {

                                    sessionStorage.removeItem("openMenuRecipe");

                                    const modal = document.getElementById(savedRecipe);

                                    if (modal) {
                                        modal.showModal();
                                    }
                                }

                                // =========================================
                                // 7. TIM KIEM NGUYEN LIEU TRONG CONG THUC
                                // =========================================

                                document.querySelectorAll(".menu-ingredient-picker")
                                    .forEach(function (picker) {

                                        const search = picker.querySelector(
                                            ".menu-ingredient-search"
                                        );

                                        const hiddenId = picker.querySelector(
                                            ".menu-ingredient-id"
                                        );

                                        const results = picker.querySelector(
                                            ".menu-ingredient-results"
                                        );

                                        const options = Array.from(
                                            picker.querySelectorAll(".menu-ingredient-option")
                                        );

                                        const emptyMessage = picker.querySelector(
                                            ".menu-ingredient-empty"
                                        );

                                        function normalize(value) {
                                            return String(value || "")
                                                .normalize("NFD")
                                                .replace(/[\u0300-\u036f]/g, "")
                                                .replace(/đ/g, "d")
                                                .replace(/Đ/g, "D")
                                                .toLowerCase()
                                                .trim();
                                        }

                                        function filterIngredients() {

                                            const keyword = normalize(search.value);

                                            // Chua nhap gi thi an danh sach
                                            if (!keyword) {
                                                results.hidden = true;
                                                return;
                                            }

                                            let count = 0;

                                            options.forEach(function (option) {

                                                const name = option.querySelector(
                                                    ".menu-ingredient-name"
                                                ).textContent;

                                                const matches = normalize(name).includes(keyword);

                                                option.hidden = !matches;

                                                if (matches) {
                                                    count++;
                                                }
                                            });

                                            emptyMessage.hidden = count > 0;
                                            results.hidden = false;
                                        }

                                        // Khi nhap ten
                                        search.addEventListener("input", function () {

                                            // Xoa ID cu neu nguoi dung nhap lai
                                            hiddenId.value = "";

                                            filterIngredients();
                                        });

                                        // Khi click vao o tim kiem
                                        search.addEventListener("focus", function () {
                                            filterIngredients();
                                        });

                                        // Khi chon mot nguyen lieu
                                        options.forEach(function (option) {

                                            option.addEventListener("click", function () {

                                                const name = option.querySelector(
                                                    ".menu-ingredient-name"
                                                ).textContent.trim();

                                                const unit = option.querySelector(
                                                    ".menu-ingredient-unit"
                                                ).textContent.trim();

                                                search.value = name + " (" + unit + ")";

                                                hiddenId.value = option.dataset.id;

                                                results.hidden = true;
                                            });
                                        });

                                        // Khong cho gui form khi chua chon ID
                                        const form = picker.closest("form");

                                        if (form) {
                                            form.addEventListener("submit", function (event) {

                                                if (!hiddenId.value) {

                                                    event.preventDefault();

                                                    search.setCustomValidity(
                                                        "Vui lòng chọn nguyên liệu trong danh sách."
                                                    );

                                                    search.reportValidity();

                                                    search.focus();

                                                    return;
                                                }

                                                search.setCustomValidity("");
                                            });
                                        }

                                        search.addEventListener("input", function () {
                                            search.setCustomValidity("");
                                        });

                                        // Dong danh sach khi click ra ngoai
                                        document.addEventListener("click", function (event) {

                                            if (!picker.contains(event.target)) {
                                                results.hidden = true;
                                            }
                                        });

                                    });

                            });
                        </script>

                    </body>

                    </html>