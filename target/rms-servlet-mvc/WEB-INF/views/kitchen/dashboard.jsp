<%@ page contentType="text/html;charset=UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

            <c:set var="ctx" value="${pageContext.request.contextPath}" />
            <!doctype html>
            <html lang="vi">

            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <title>Bếp | RMS</title>
                <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=kitchen-group-4">
            </head>

            <body>

                <%-- Top bar --%>
                    <div class="topbar">
                        <span class="brand">RMS · Bếp</span>
                        <a class="btn btn-outline" href="${ctx}/logout">Đăng xuất</a>
                    </div>

                    <main class="container kitchen-page">

                        <%-- Page header --%>
                            <div class="page-head kitchen-page-head">
                                <div>
                                    <div class="kitchen-page-label">KITCHEN</div>
                                    <h1>Đơn đang chờ chế biến</h1>
                                    <p class="kitchen-page-description"></p>
                                </div>
                                <div class="kitchen-refresh">
                                    <span class="kitchen-refresh-dot"></span>
                                    Tự làm mới mỗi 5 giây
                                </div>
                            </div>

                            <%-- Flash messages --%>
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

                                <%-- Pending orders --%>

                                    <section class="section">
                                        <div class="kitchen-section-head">
                                            <div>
                                                <h2>Order đang chờ</h2>
                                            </div>
                                            <c:if test="${not empty orders}">
                                                <span class="kitchen-order-count">
                                                    <c:out value="${fn:length(orders)}" />
                                                    order
                                                </span>
                                            </c:if>
                                        </div>
                                        <div class="kitchen-mode-switch">

                                            <a href="${ctx}/kitchen?mode=table"
                                                class="kitchen-mode-button ${kitchenMode eq 'table' ? 'active' : ''}">
                                                Theo đơn
                                            </a>

                                            <a href="${ctx}/kitchen?mode=group"
                                                class="kitchen-mode-button ${kitchenMode eq 'group' ? 'active' : ''}">
                                                Theo nhóm món
                                            </a>

                                        </div>
                                        <c:if test="${kitchenMode eq 'table' and empty orders}">
                                            <div class="card kitchen-empty">
                                                <h3>Không có món đang chờ</h3>
                                            </div>
                                        </c:if>

                                        <%-- Order grid: 3 orders per row on desktop --%>
                                            <c:if test="${kitchenMode eq 'table'}">
                                                <div id="kitchen-orders-by-table" class="kitchen-order-grid">
                                                    <c:forEach var="o" items="${orders}">
                                                        <article class="kitchen-order-card">

                                                            <%-- Order header --%>
                                                                <div class="kitchen-order-header">
                                                                    <div>
                                                                        <span class="kitchen-order-label">BÀN</span>
                                                                        <h2 class="kitchen-table-number">
                                                                            <c:out value="${o.tableNumber}" />
                                                                        </h2>
                                                                        <span class="kitchen-order-id">
                                                                            Đơn #
                                                                            <c:out value="${o.orderId}" />
                                                                        </span>
                                                                        <div class="kds-received">
                                                                            Nhận lúc
                                                                            <c:out
                                                                                value="${o.createdAt.toString().substring(11,16)}" />
                                                                        </div>
                                                                    </div>
                                                                    <div class="kds-header-actions">
                                                                        <span
                                                                            class="kitchen-pending-badge">PENDING</span>

                                                                        <form method="post" action="${ctx}/kitchen">
                                                                            <input type="hidden" name="action"
                                                                                value="readyOrder">
                                                                            <input type="hidden" name="orderId"
                                                                                value="${o.orderId}">

                                                                            <button type="submit"
                                                                                class="kitchen-ready-button"
                                                                                onclick="return confirm('Tất cả món trong đơn đã hoàn thành?');">
                                                                                Hoàn thành
                                                                            </button>
                                                                        </form>
                                                                    </div>
                                                                </div>

                                                                <%-- Order details --%>
                                                                    <div class="kitchen-item-list">
                                                                        <c:forEach var="group" items="${o.details}"
                                                                            varStatus="pos">

                                                                            <%-- Chỉ tạo nhóm tại lần xuất hiện đầu tiên
                                                                                --%>
                                                                                <c:set var="firstGroup" value="true" />

                                                                                <c:forEach var="prev"
                                                                                    items="${o.details}"
                                                                                    varStatus="prevPos"
                                                                                    end="${pos.index}">

                                                                                    <c:if
                                                                                        test="${prevPos.index lt pos.index and prev.categoryName eq group.categoryName}">
                                                                                        <c:set var="firstGroup"
                                                                                            value="false" />
                                                                                    </c:if>

                                                                                </c:forEach>

                                                                                <c:if test="${firstGroup}">

                                                                                    <c:set var="totalQty" value="0" />
                                                                                    <c:set var="totalLines" value="0" />
                                                                                    <c:set var="readyLines" value="0" />

                                                                                    <c:forEach var="d"
                                                                                        items="${o.details}">
                                                                                        <c:if
                                                                                            test="${d.categoryName == group.categoryName}">
                                                                                            <c:set var="totalQty"
                                                                                                value="${totalQty + d.quantity}" />
                                                                                            <c:set var="totalLines"
                                                                                                value="${totalLines + 1}" />
                                                                                            <c:if
                                                                                                test="${d.status == 'READY'}">
                                                                                                <c:set var="readyLines"
                                                                                                    value="${readyLines + 1}" />
                                                                                            </c:if>
                                                                                        </c:if>
                                                                                    </c:forEach>

                                                                                    <details class="kds-category"
                                                                                        data-group-key="${o.orderId}-${group.categoryName}">
                                                                                        <summary
                                                                                            class="kds-category-summary">
                                                                                            <span
                                                                                                class="kds-category-left">
                                                                                                <span
                                                                                                    class="kds-category-name">
                                                                                                    <c:out
                                                                                                        value="${group.categoryName}" />
                                                                                                </span>
                                                                                                <span
                                                                                                    class="kds-category-quantity">
                                                                                                    ·
                                                                                                    <c:out
                                                                                                        value="${totalQty}" />
                                                                                                    phần
                                                                                                </span>
                                                                                            </span>

                                                                                            <span
                                                                                                class="kds-category-progress">
                                                                                                <c:out
                                                                                                    value="${readyLines}" />
                                                                                                /
                                                                                                <c:out
                                                                                                    value="${totalLines}" />
                                                                                                xong
                                                                                            </span>
                                                                                        </summary>

                                                                                        <div class="kds-category-items">
                                                                                            <c:forEach var="d"
                                                                                                items="${o.details}">
                                                                                                <c:if
                                                                                                    test="${d.categoryName == group.categoryName}">
                                                                                                    <div
                                                                                                        class="kitchen-item">
                                                                                                        <div
                                                                                                            class="kitchen-item-info">
                                                                                                            <div
                                                                                                                class="kitchen-item-title">
                                                                                                                <span
                                                                                                                    class="kitchen-item-name">
                                                                                                                    <c:out
                                                                                                                        value="${d.menuItemName}" />
                                                                                                                </span>
                                                                                                                <span
                                                                                                                    class="kitchen-item-quantity">
                                                                                                                    ×
                                                                                                                    <c:out
                                                                                                                        value="${d.quantity}" />
                                                                                                                </span>
                                                                                                            </div>

                                                                                                            <c:if
                                                                                                                test="${not empty d.note}">
                                                                                                                <div
                                                                                                                    class="kitchen-item-note">
                                                                                                                    <c:out
                                                                                                                        value="${d.note}" />
                                                                                                                </div>
                                                                                                            </c:if>
                                                                                                        </div>

                                                                                                        <c:choose>
                                                                                                            <c:when
                                                                                                                test="${d.status eq 'READY'}">
                                                                                                                <span
                                                                                                                    class="kds-item-done">
                                                                                                                    ✓
                                                                                                                    Đã
                                                                                                                    xong
                                                                                                                </span>
                                                                                                            </c:when>

                                                                                                            <c:otherwise>
                                                                                                                <form
                                                                                                                    method="post"
                                                                                                                    action="${ctx}/kitchen">
                                                                                                                    <input
                                                                                                                        type="hidden"
                                                                                                                        name="action"
                                                                                                                        value="readyDetail" />
                                                                                                                    <input
                                                                                                                        type="hidden"
                                                                                                                        name="detailId"
                                                                                                                        value="${d.orderDetailId}" />

                                                                                                                    <button
                                                                                                                        type="submit"
                                                                                                                        class="kitchen-ready-button">
                                                                                                                        Xong
                                                                                                                    </button>
                                                                                                                </form>
                                                                                                            </c:otherwise>
                                                                                                        </c:choose>
                                                                                                    </div>
                                                                                                </c:if>
                                                                                            </c:forEach>
                                                                                        </div>
                                                                                    </details>

                                                                                </c:if>
                                                                        </c:forEach>

                                                                    </div>
                                                        </article>

                                                    </c:forEach>
                                                </div>
                                            </c:if>
                                            <%-- CHẾ ĐỘ THEO NHÓM MÓN --%>

                                                <c:if test="${kitchenMode eq 'group'}">

                                                    <div class="kds-group-grid">

                                                        <c:if test="${empty dishGroups}">
                                                            <div class="card kitchen-empty">
                                                                <h3>Không có món cần chế biến</h3>
                                                            </div>
                                                        </c:if>

                                                        <c:forEach var="g" items="${dishGroups}">

                                                            <article class="kds-group-card">

                                                                <div class="kds-group-header">

                                                                    <div>
                                                                        <span class="kds-group-category">
                                                                            <c:out value="${g.categoryName}" />
                                                                        </span>

                                                                        <h3>
                                                                            <c:out value="${g.menuItemName}" />
                                                                        </h3>
                                                                    </div>

                                                                    <div class="kds-group-total">
                                                                        <strong>
                                                                            <c:out value="${g.totalQuantity}" />
                                                                        </strong>
                                                                        <span>phần cần làm</span>
                                                                    </div>

                                                                </div>

                                                                <div class="kds-group-details">

                                                                    <c:forEach var="d" items="${g.details}">

                                                                        <div class="kds-group-detail">

                                                                            <div class="kds-group-detail-info">

                                                                                <strong>
                                                                                    Bàn
                                                                                    <c:out value="${d.tableNumber}" />
                                                                                </strong>

                                                                                <span>
                                                                                    · Đơn #
                                                                                    <c:out value="${d.orderId}" />
                                                                                </span>

                                                                                <div class="kds-group-quantity">
                                                                                    <c:out value="${d.quantity}" /> phần
                                                                                </div>

                                                                                <c:if test="${not empty d.note}">
                                                                                    <div class="kds-group-note">
                                                                                        Ghi chú:
                                                                                        <c:out value="${d.note}" />
                                                                                    </div>
                                                                                </c:if>

                                                                            </div>

                                                                            <form method="post" action="${ctx}/kitchen">

                                                                                <input type="hidden" name="action"
                                                                                    value="readyDetail">

                                                                                <input type="hidden" name="detailId"
                                                                                    value="${d.orderDetailId}">

                                                                                <button type="submit"
                                                                                    class="kitchen-ready-button">
                                                                                    Xong
                                                                                </button>

                                                                            </form>

                                                                        </div>

                                                                    </c:forEach>

                                                                </div>

                                                            </article>

                                                        </c:forEach>

                                                    </div>

                                                </c:if>
                                    </section>

                    </main>

                    <script>
                        // Ghi nhớ các nhóm món đang mở
                        document.querySelectorAll("details.kds-category").forEach(function (group) {

                            const key = "kitchen-group-" + group.dataset.groupKey;

                            // Khôi phục trạng thái sau khi reload
                            if (sessionStorage.getItem(key) === "open") {
                                group.open = true;
                            }

                            // Lưu trạng thái khi mở hoặc đóng nhóm
                            group.addEventListener("toggle", function () {
                                if (group.open) {
                                    sessionStorage.setItem(key, "open");
                                } else {
                                    sessionStorage.removeItem(key);
                                }
                            });

                        });

                        // Giữ nguyên tự làm mới mỗi 5 giây
                        setTimeout(function () {
                            window.location.reload();
                        }, 5000);
                    </script>

            </body>

            </html>