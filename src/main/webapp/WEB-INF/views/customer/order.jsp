<%@ page contentType="text/html;charset=UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
            <%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

                <c:set var="ctx" value="${pageContext.request.contextPath}" />

                <c:url var="menuUrl" value="/customer/menu">
                    <c:param name="token" value="${token}" />
                </c:url>

                <c:url var="paymentUrl" value="/customer/payment">
                    <c:param name="token" value="${token}" />
                </c:url>

                <!doctype html>

                <html lang="vi">

                <head>

                    <meta charset="utf-8">

                    <meta name="viewport" content="width=device-width,initial-scale=1">

                    <title>
                        Đơn hàng ·
                        <c:out value="${table.tableNumber}" />
                    </title>

                    <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=rms-cart-fix-20261016">

                </head>

                <body>

                    <div class="customer-shell">

                        <div class="mobile-header">

                            <div class="brand">
                                RMS · Đơn hàng
                            </div>

                            <div>

                                Bàn

                                <c:choose>

                                    <c:when test="${not empty order}">

                                        <c:out value="${order.tableNumber}" />

                                    </c:when>

                                    <c:otherwise>

                                        <c:out value="${table.tableNumber}" />

                                    </c:otherwise>

                                </c:choose>

                            </div>

                        </div>


                        <div class="customer-content">

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


                            <div class="page-head">

                                <h1>
                                    Đơn hiện tại
                                </h1>


                                <c:choose>

                                    <c:when test="${paymentPending}">

                                        <button type="button" class="btn btn-outline" disabled>

                                            Đang chờ thanh toán

                                        </button>

                                    </c:when>

                                    <c:otherwise>

                                        <a class="btn btn-outline" href="${fn:escapeXml(menuUrl)}">

                                            Gọi thêm món

                                        </a>

                                    </c:otherwise>

                                </c:choose>

                            </div>


                            <c:if test="${paymentPending}">

                                <div class="alert alert-danger">

                                    <b>
                                        Đơn hàng đang chờ thanh toán.
                                    </b>

                                    <br>

                                    Trong thời gian này bạn không thể
                                    gọi thêm hoặc hủy món.

                                </div>

                            </c:if>


                            <c:choose>

                                <c:when test="${empty order}">

                                    <div class="card empty">

                                        Bàn chưa có đơn đang mở.

                                        <div style="margin-top:12px">

                                            <a class="btn btn-primary" href="${fn:escapeXml(menuUrl)}">

                                                Xem menu

                                            </a>

                                        </div>

                                    </div>

                                </c:when>


                                <c:otherwise>

                                    <div class="card section">

                                        <h2>

                                            Đơn #

                                            <c:out value="${order.orderId}" />

                                        </h2>


                                        <div class="muted" style="margin-bottom:12px">

                                            Bàn:

                                            <b>
                                                <c:out value="${order.tableNumber}" />
                                            </b>

                                        </div>


                                        <c:forEach var="d" items="${order.details}">

                                            <div style="
                            padding:12px 0;
                            border-bottom:1px solid #e2e8f0;
                        ">

                                                <div class="page-head" style="margin:0">

                                                    <div>

                                                        <b>

                                                            <c:out value="${d.menuItemName}" />

                                                            ×

                                                            <c:out value="${d.quantity}" />

                                                        </b>


                                                        <div class="muted">

                                                            <c:if test="${not empty d.note}">

                                                                Ghi chú:

                                                                <c:out value="${d.note}" />

                                                                ·

                                                            </c:if>


                                                            Trạng thái:

                                                            <c:choose>

                                                                <c:when test="${d.status eq 'PENDING'}">

                                                                    <span class="badge badge-warning">
                                                                        Chờ bếp
                                                                    </span>

                                                                </c:when>


                                                                <c:when test="${d.status eq 'READY'}">

                                                                    <span class="badge badge-warning">
                                                                        Đã sẵn sàng
                                                                    </span>

                                                                </c:when>


                                                                <c:when test="${d.status eq 'SERVED'}">

                                                                    <span class="badge badge-success">
                                                                        Đã phục vụ
                                                                    </span>

                                                                </c:when>


                                                                <c:when test="${d.status eq 'CANCELLED'}">

                                                                    <span class="badge">
                                                                        Đã hủy
                                                                    </span>

                                                                </c:when>


                                                                <c:otherwise>

                                                                    <c:out value="${d.status}" />

                                                                </c:otherwise>

                                                            </c:choose>

                                                        </div>

                                                    </div>


                                                    <div class="right">

                                                        <b>

                                                            <fmt:formatNumber value="${d.lineTotal}" type="number"
                                                                maxFractionDigits="0" />

                                                            ₫

                                                        </b>


                                                        <c:if test="${d.status eq 'PENDING' and !paymentPending}">

                                                            <form method="post" action="${ctx}/customer/cancel"
                                                                style="margin-top:6px">

                                                                <input type="hidden" name="token"
                                                                    value="${fn:escapeXml(token)}">

                                                                <input type="hidden" name="detailId"
                                                                    value="${d.orderDetailId}">


                                                                <button class="btn btn-sm btn-danger">

                                                                    Hủy món

                                                                </button>

                                                            </form>

                                                        </c:if>

                                                    </div>

                                                </div>

                                            </div>

                                        </c:forEach>


                                        <div class="right" style="margin-top:18px">

                                            <div class="muted">
                                                Tổng tạm tính
                                            </div>


                                            <div class="stat">

                                                <fmt:formatNumber value="${total}" type="number"
                                                    maxFractionDigits="0" />

                                                ₫

                                            </div>

                                        </div>

                                    </div>


                                    <c:choose>

                                        <c:when test="${paymentPending}">

                                            <a class="btn btn-primary" style="width:100%"
                                                href="${fn:escapeXml(paymentUrl)}">

                                                Xem trạng thái thanh toán

                                            </a>

                                        </c:when>


                                        <c:when test="${canPay}">

                                            <a class="btn btn-primary" style="width:100%"
                                                href="${fn:escapeXml(paymentUrl)}">

                                                Thanh toán

                                            </a>

                                        </c:when>


                                        <c:otherwise>

                                            <div class="alert alert-danger">

                                                Chỉ có thể thanh toán
                                                sau khi tất cả món đã được phục vụ.

                                            </div>

                                        </c:otherwise>

                                    </c:choose>

                                </c:otherwise>

                            </c:choose>

                        </div>

                    </div>


                    <c:if test="${not empty order}">

                        <script>

                            setTimeout(
                                function () {

                                    window.location.reload();

                                },
                                5000
                            );

                        </script>

                    </c:if>

                </body>

                </html>