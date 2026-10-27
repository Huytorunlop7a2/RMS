<%@ page contentType="text/html;charset=UTF-8" %>

    <%@ taglib prefix="c" uri="jakarta.tags.core" %>

        <%@ taglib prefix="fn" uri="jakarta.tags.functions" %>


            <c:set var="ctx" value="${pageContext.request.contextPath}" />


            <!doctype html>

            <html lang="vi">


            <head>

                <meta charset="utf-8">


                <meta name="viewport" content="width=device-width, initial-scale=1">


                <title>
                    Bếp | RMS
                </title>


                <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=kitchen-final-1">

            </head>



            <body>


                <%--=========================================================TOP
                    BAR=========================================================--%>

                    <div class="topbar">


                        <span class="brand">

                            RMS · Bếp

                        </span>



                        <a class="btn btn-outline" href="${ctx}/logout">

                            Đăng xuất

                        </a>


                    </div>



                    <main class="container kitchen-page">


                        <%--=====================================================PAGE
                            HEADER=====================================================--%>

                            <div class="page-head kitchen-page-head">


                                <div>


                                    <div class="kitchen-page-label">

                                        KITCHEN

                                    </div>



                                    <h1>

                                        Đơn đang chờ chế biến

                                    </h1>



                                    <p class="kitchen-page-description">

                                    </p>


                                </div>



                                <div class="kitchen-refresh">


                                    <span class="kitchen-refresh-dot"></span>


                                    Tự làm mới mỗi 5 giây


                                </div>


                            </div>



                            <%--=====================================================SUCCESS=====================================================--%>

                                <c:if test="${not empty success}">


                                    <div class="alert alert-success">

                                        <c:out value="${success}" />

                                    </div>


                                </c:if>



                                <%--=====================================================ERROR=====================================================--%>

                                    <c:if test="${not empty error}">


                                        <div class="alert alert-danger">

                                            <c:out value="${error}" />

                                        </div>


                                    </c:if>



                                    <%--=====================================================ORDER
                                        SECTION=====================================================--%>

                                        <section class="section">


                                            <div class="kitchen-section-head">


                                                <div>


                                                    <h2>

                                                        Order đang chờ

                                                    </h2>



                                                </div>



                                                <c:if test="${not empty orders}">


                                                    <span class="kitchen-order-count">

                                                        <c:out value="${fn:length(orders)}" />

                                                        order

                                                    </span>


                                                </c:if>


                                            </div>



                                            <%--=================================================EMPTY=================================================--%>

                                                <c:if test="${empty orders}">


                                                    <div class="card kitchen-empty">


                                                        
                                                        <h3>

                                                            Không có món đang chờ

                                                        </h3>


                                                    </div>


                                                </c:if>



                                                <%--=================================================ORDER GRID
                                                    DESKTOP=3 ORDER /
                                                    ROW=================================================--%>

                                                    <div class="kitchen-order-grid">


                                                        <c:forEach var="o" items="${orders}">


                                                            <article class="kitchen-order-card">


                                                                <%--=====================================ORDER
                                                                    HEADER=====================================--%>

                                                                    <div class="kitchen-order-header">


                                                                        <div>


                                                                            <span class="kitchen-order-label">

                                                                                BÀN

                                                                            </span>



                                                                            <h2 class="kitchen-table-number">

                                                                                <c:out value="${o.tableNumber}" />

                                                                            </h2>



                                                                            <span class="kitchen-order-id">

                                                                                Đơn #

                                                                                <c:out value="${o.orderId}" />

                                                                            </span>


                                                                        </div>



                                                                        <span class="kitchen-pending-badge">

                                                                            PENDING

                                                                        </span>


                                                                    </div>



                                                                    <%--=====================================ORDER
                                                                        DETAILS=====================================--%>

                                                                        <div class="kitchen-item-list">


                                                                            <c:forEach var="d" items="${o.details}">


                                                                                <div class="kitchen-item">


                                                                                    <%--=========================ITEM
                                                                                        INFORMATION=========================--%>

                                                                                        <div class="kitchen-item-info">


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



                                                                                            <%--=====================NOTE=====================--%>

                                                                                                <c:if
                                                                                                    test="${not empty d.note}">


                                                                                                    <div
                                                                                                        class="kitchen-item-note">


                                                                                                        <span>

                                                                                                            Ghi chú:

                                                                                                        </span>


                                                                                                        <c:out
                                                                                                            value="${d.note}" />


                                                                                                    </div>


                                                                                                </c:if>



                                                                                                <div
                                                                                                    class="kitchen-detail-id">

                                                                                                    Món #

                                                                                                    <c:out
                                                                                                        value="${d.orderDetailId}" />

                                                                                                </div>


                                                                                        </div>



                                                                                        <%--=========================MARK
                                                                                            READY THIS
                                                                                            ITEM=========================--%>

                                                                                            <form method="post"
                                                                                                action="${ctx}/kitchen"
                                                                                                class="kitchen-ready-form">


                                                                                                <input type="hidden"
                                                                                                    name="action"
                                                                                                    value="readyDetail">


                                                                                                <input type="hidden"
                                                                                                    name="detailId"
                                                                                                    value="${d.orderDetailId}">


                                                                                                <button type="submit"
                                                                                                    class="kitchen-ready-button"
                                                                                                    onclick="return confirm('Xác nhận món này đã hoàn thành?');">

                                                                                                    Mark Ready

                                                                                                </button>


                                                                                            </form>


                                                                                </div>


                                                                            </c:forEach>


                                                                        </div>


                                                            </article>


                                                        </c:forEach>


                                                    </div>


                                        </section>



                                        <%--=====================================================INVENTORY=====================================================--%>

                                            <section class="section kitchen-inventory-section">


                                                <div class="kitchen-section-head">


                                                    <div>


                                                        <h2>

                                                            Tồn kho nhanh

                                                        </h2>



                                                        <p class="muted">
                                                        
                                                        </p>


                                                    </div>


                                                </div>



                                                <div class="card kitchen-inventory-card">


                                                    <div class="table-wrap">


                                                        <table class="data-table kitchen-inventory-table">


                                                            <thead>


                                                                <tr>


                                                                    <th>

                                                                        Nguyên liệu

                                                                    </th>


                                                                    <th>

                                                                        Số lượng tồn

                                                                    </th>


                                                                    <th>

                                                                        Trạng thái

                                                                    </th>


                                                                </tr>


                                                            </thead>



                                                            <tbody>


                                                                <c:forEach var="i" items="${inventory}">


                                                                    <tr>


                                                                        <td>


                                                                            <div class="kitchen-inventory-name">

                                                                                <c:out value="${i.name}" />

                                                                            </div>


                                                                        </td>



                                                                        <td>


                                                                            <span class="kitchen-stock-value">

                                                                                <c:out value="${i.quantity}" />

                                                                            </span>


                                                                            <span class="muted">

                                                                                <c:out value="${i.unit}" />

                                                                            </span>


                                                                        </td>



                                                                        <td>


                                                                            <c:choose>


                                                                                <%--=====================INACTIVE=====================--%>

                                                                                    <c:when test="${!i.active}">


                                                                                        <span class="badge">

                                                                                            Ngừng dùng

                                                                                        </span>


                                                                                    </c:when>



                                                                                    <%--=====================LOW
                                                                                        STOCK=====================--%>

                                                                                        <c:when test="${i.lowStock}">


                                                                                            <span
                                                                                                class="badge badge-danger">

                                                                                                Sắp hết

                                                                                            </span>


                                                                                        </c:when>



                                                                                        <%--=====================NORMAL=====================--%>

                                                                                            <c:otherwise>


                                                                                                <span
                                                                                                    class="badge badge-success">

                                                                                                    Ổn định

                                                                                                </span>


                                                                                            </c:otherwise>


                                                                            </c:choose>


                                                                        </td>


                                                                    </tr>


                                                                </c:forEach>



                                                                <%--=================================================EMPTY
                                                                    INVENTORY=================================================--%>

                                                                    <c:if test="${empty inventory}">


                                                                        <tr>


                                                                            <td colspan="3" class="muted">

                                                                                Chưa có dữ liệu nguyên liệu.

                                                                            </td>


                                                                        </tr>


                                                                    </c:if>


                                                            </tbody>


                                                        </table>


                                                    </div>


                                                </div>


                                            </section>


                    </main>



                    <%--=========================================================AUTO
                        REFRESH=========================================================--%>

                        <script>

                            setTimeout(
                                function () {

                                    window.location.reload();

                                },

                                5000
                            );

                        </script>


            </body>

            </html>