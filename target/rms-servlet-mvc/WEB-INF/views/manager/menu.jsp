<%@ page contentType="text/html;charset=UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
            <%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

                <c:set var="ctx" value="${pageContext.request.contextPath}" />

                <!doctype html>

                <html lang="vi">

                <head>

                    <meta charset="utf-8">

                    <meta name="viewport" content="width=device-width,initial-scale=1">

                    <title>
                        Quản lý menu
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
                                            Quản lý menu & công thức
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


                                <section class="card section">

                                    <h2>
                                        Tạo món mới
                                    </h2>

                                    <form method="post" action="${ctx}/manager/menu">

                                        <input type="hidden" name="action" value="create">


                                        <div class="grid grid-2">

                                            <div class="form-group">

                                                <label>
                                                    Danh mục
                                                </label>

                                                <select name="categoryId" required>

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

                                                <label>
                                                    Tên món
                                                </label>

                                                <input name="name" maxlength="255" required>

                                            </div>

                                        </div>


                                        <div class="grid grid-2">

                                            <div class="form-group">

                                                <label>
                                                    Giá
                                                </label>

                                                <input type="number" name="price" min="0" step="1000" required>

                                            </div>


                                            <div class="form-group">

                                                <label>
                                                    Mô tả
                                                </label>

                                                <input name="description" maxlength="1000"
                                                    placeholder="Mô tả ngắn về món">

                                            </div>

                                        </div>


                                        <button class="btn btn-primary">

                                            Tạo món

                                        </button>

                                    </form>

                                </section>


                                <c:forEach var="m" items="${items}">

                                    <section class="card section">

                                        <div class="page-head">

                                            <div>

                                                <h2>

                                                    <c:out value="${m.name}" />

                                                </h2>


                                                <div class="muted">

                                                    <c:out value="${m.description}" />

                                                </div>


                                                <div style="margin-top:8px">

                                                    <span class="badge ${m.active ? 'badge-success' : 'badge-danger'}">

                                                        ${m.active ? 'Đang bật' : 'Đang tắt'}

                                                    </span>


                                                    <span
                                                        class="badge ${m.recipeConfigured ? 'badge-success' : 'badge-danger'}">

                                                        ${m.recipeConfigured ? 'Đã có công thức' : 'Chưa có công thức'}

                                                    </span>


                                                    <span
                                                        class="badge ${m.inventoryAvailable ? 'badge-success' : 'badge-danger'}">

                                                        ${m.inventoryAvailable ? 'Đủ nguyên liệu' : 'Chưa thể bán'}

                                                    </span>

                                                </div>

                                            </div>


                                            <div>

                                                <b>

                                                    <fmt:formatNumber value="${m.price}" type="number"
                                                        maxFractionDigits="0" />

                                                    ₫

                                                </b>

                                            </div>

                                        </div>


                                        <div class="grid grid-2">


                                            <div>

                                                <h3>
                                                    Thông tin món
                                                </h3>


                                                <form method="post" action="${ctx}/manager/menu">

                                                    <input type="hidden" name="action" value="update">

                                                    <input type="hidden" name="id" value="${m.menuItemId}">


                                                    <div class="form-group">

                                                        <label>
                                                            Danh mục
                                                        </label>

                                                        <select name="categoryId" required>

                                                            <c:forEach var="cat" items="${categories}">

                                                                <option value="${cat.categoryId}" ${cat.categoryId eq
                                                                    m.categoryId ? 'selected' : '' }>

                                                                    <c:out value="${cat.name}" />

                                                                </option>

                                                            </c:forEach>

                                                        </select>

                                                    </div>


                                                    <div class="form-group">

                                                        <label>
                                                            Tên món
                                                        </label>

                                                        <input name="name" value="${fn:escapeXml(m.name)}"
                                                            maxlength="255" required>

                                                    </div>


                                                    <div class="form-group">

                                                        <label>
                                                            Mô tả
                                                        </label>

                                                        <input name="description" value="${fn:escapeXml(m.description)}"
                                                            maxlength="1000">

                                                    </div>


                                                    <div class="form-group">

                                                        <label>
                                                            Giá
                                                        </label>

                                                        <input type="number" name="price" min="0" step="1000"
                                                            value="${m.price}" required>

                                                    </div>


                                                    <button class="btn btn-sm btn-primary">

                                                        Lưu thay đổi

                                                    </button>

                                                </form>


                                                <form method="post" action="${ctx}/manager/menu" style="margin-top:8px">

                                                    <input type="hidden" name="action" value="toggle">

                                                    <input type="hidden" name="id" value="${m.menuItemId}">

                                                    <input type="hidden" name="active" value="${!m.active}">


                                                    <button
                                                        class="btn btn-sm ${m.active ? 'btn-danger' : 'btn-success'}">

                                                        ${m.active ? 'Tắt món' : 'Bật món'}

                                                    </button>

                                                </form>

                                            </div>


                                            <div>

                                                <h3>
                                                    Công thức cho 1 phần
                                                </h3>


                                                <c:choose>

                                                    <c:when test="${empty m.ingredients}">

                                                        <div class="alert alert-danger">

                                                            Chưa có công thức.
                                                            Món này không được hiển thị cho khách.

                                                        </div>

                                                    </c:when>


                                                    <c:otherwise>

                                                        <div class="table-wrap">

                                                            <table class="data-table">

                                                                <thead>

                                                                    <tr>

                                                                        <th>
                                                                            Nguyên liệu
                                                                        </th>

                                                                        <th>
                                                                            Định lượng
                                                                        </th>

                                                                        <th>
                                                                        </th>

                                                                    </tr>

                                                                </thead>


                                                                <tbody>

                                                                    <c:forEach var="r" items="${m.ingredients}">

                                                                        <tr>

                                                                            <td>

                                                                                <c:out value="${r.inventoryItemName}" />

                                                                            </td>


                                                                            <td>

                                                                                ${r.requiredQuantity}

                                                                                <c:out value="${r.unit}" />

                                                                            </td>


                                                                            <td>

                                                                                <form method="post"
                                                                                    action="${ctx}/manager/menu">

                                                                                    <input type="hidden" name="action"
                                                                                        value="removeIngredient">

                                                                                    <input type="hidden"
                                                                                        name="menuItemId"
                                                                                        value="${m.menuItemId}">

                                                                                    <input type="hidden"
                                                                                        name="inventoryItemId"
                                                                                        value="${r.inventoryItemId}">


                                                                                    <button
                                                                                        class="btn btn-sm btn-danger">

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


                                                <form method="post" action="${ctx}/manager/menu"
                                                    style="margin-top:12px">

                                                    <input type="hidden" name="action" value="saveIngredient">

                                                    <input type="hidden" name="menuItemId" value="${m.menuItemId}">


                                                    <div class="grid grid-2">

                                                        <div class="form-group">

                                                            <label>
                                                                Nguyên liệu
                                                            </label>

                                                            <select name="inventoryItemId" required>

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


                                                        <div class="form-group">

                                                            <label>
                                                                Định lượng / phần
                                                            </label>

                                                            <input type="number" name="requiredQuantity" min="0.001"
                                                                step="0.001" required>

                                                        </div>

                                                    </div>


                                                    <button class="btn btn-sm btn-primary">

                                                        Thêm / cập nhật nguyên liệu

                                                    </button>

                                                </form>

                                            </div>

                                        </div>

                                    </section>

                                </c:forEach>

                            </div>

                        </main>

                    </div>

                </body>

                </html>