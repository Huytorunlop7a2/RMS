<%@ page contentType="text/html;charset=UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
            <%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
                <c:set var="ctx" value="${pageContext.request.contextPath}" />
                <c:url var="tableStatusUrl" value="/receptionist/table-status" />
                <!doctype html>
                <html lang="vi">

                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width,initial-scale=1">
                    <title>Thanh toán</title>
                    <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=theme-all-ui-1">
                </head>

                <body>
                    <div class="customer-shell">
                        <div class="mobile-header">
                            <div class="brand">RMS · Thanh toán</div>
                            <div>
                                Bàn
                                <c:choose>
                                    <c:when test="${not empty order}">
                                        <c:out value="${order.tableNumber}" />
                                    </c:when>
                                    <c:when test="${not empty paidPayment}">
                                        <c:out value="${paidPayment.tableNumber}" />
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
                            <c:choose>
                                <c:when test="${paidSuccess}">
                                    <div class="card empty">
                                        <h2 class="success-text">Thanh toán thành công</h2>
                                        <c:if test="${not empty paidPayment}">
                                            <p>
                                                Mã thanh toán:
                                                <b>
                                                    #
                                                    <c:out value="${paidPayment.paymentId}" />
                                                </b>
                                            </p>
                                            <p>
                                                Số tiền:
                                                <b>
                                                    <fmt:formatNumber value="${paidPayment.amount}" type="number"
                                                        maxFractionDigits="0" />
                                                    ₫
                                                </b>
                                            </p>
                                            <p>
                                                Phương thức:
                                                <c:choose>
                                                    <c:when test="${paidPayment.paymentMethod eq 'CASH'}">Tiền mặt
                                                    </c:when>
                                                    <c:when test="${paidPayment.paymentMethod eq 'ONLINE'}">Trực tuyến
                                                    </c:when>
                                                    <c:otherwise>
                                                        <c:out value="${paidPayment.paymentMethod}" />
                                                    </c:otherwise>
                                                </c:choose>
                                            </p>
                                        </c:if>
                                        <p>Đơn hàng đã được đóng.</p>
                                        <p class="muted">
                                            Bàn vẫn giữ trạng thái đang sử dụng cho đến khi nhân viên thực hiện trả bàn.
                                        </p>
                                        <a class="btn btn-primary" href="${ctx}/receptionist/table-status">
                                            Quay về danh sách bàn
                                        </a>
                                    </div>
                                </c:when>
                                <c:when test="${noOpenOrder}">
                                    <div class="card empty">
                                        <h2>Không có đơn đang mở</h2>
                                        <p class="muted">Hiện tại không có đơn hàng nào cần thanh toán.</p>
                                        <a class="btn btn-primary" href="${ctx}/receptionist/table-status">
                                            Quay về danh sách bàn
                                        </a>
                                    </div>
                                </c:when>
                                <c:otherwise>
                                    <div class="card section">
                                        <div class="page-head">
                                            <div>
                                                <h2>
                                                    Đơn #
                                                    <c:out value="${order.orderId}" />
                                                </h2>
                                                <div class="muted">
                                                    Bàn
                                                    <c:out value="${order.tableNumber}" />
                                                </div>
                                            </div>

                                        </div>
                                        <c:forEach var="d" items="${order.details}">
                                            <c:if test="${d.status ne 'CANCELLED'}">
                                                <div class="page-head" style="
                                        margin:0;
                                        padding:10px 0;
                                        border-bottom:1px solid #e2e8f0;
                                    ">
                                                    <div>
                                                        <c:out value="${d.menuItemName}" />
                                                        ×
                                                        <c:out value="${d.quantity}" />
                                                        <c:if test="${not empty d.note}">
                                                            <div class="muted">
                                                                Ghi chú:
                                                                <c:out value="${d.note}" />
                                                            </div>
                                                        </c:if>
                                                    </div>
                                                    <b>
                                                        <fmt:formatNumber value="${d.lineTotal}" type="number"
                                                            maxFractionDigits="0" />
                                                        ₫
                                                    </b>
                                                </div>
                                            </c:if>
                                        </c:forEach>
                                        <div class="right" style="margin-top:16px">
                                            <div class="muted">Tổng thanh toán</div>
                                            <div class="stat">
                                                <fmt:formatNumber value="${total}" type="number"
                                                    maxFractionDigits="0" />
                                                ₫
                                            </div>
                                        </div>
                                    </div>
                                    <c:if test="${!canPay}">
                                        <div class="alert alert-danger">
                                            Còn món chưa được phục vụ. Vui lòng chờ nhân viên hoàn thành phục vụ trước
                                            khi thanh toán.
                                        </div>
                                    </c:if>
                                    <c:if test="${canPay}">
                                        <c:choose>

                                            <c:when
                                                test="${not empty pendingPayment and pendingPayment.paymentMethod eq 'CASH'}">
                                                <div class="card">
                                                    <h2>Chờ xác nhận nhận tiền</h2>

                                                    <p class="muted">
                                                        Khách hàng đã chọn thanh toán tiền mặt.
                                                        Vui lòng nhận tiền trực tiếp từ khách hàng.
                                                    </p>

                                                    <div class="price">
                                                        <fmt:formatNumber value="${pendingPayment.amount}" type="number"
                                                            maxFractionDigits="0" />
                                                        ₫
                                                    </div>

                                                    <div class="muted" style="margin-top:8px">
                                                        Mã thanh toán:
                                                        #
                                                        <c:out value="${pendingPayment.paymentId}" />
                                                    </div>

                                                    <form method="post"
                                                        action="${ctx}/receptionist/payment/cash-confirm"
                                                        style="margin-top:20px">

                                                        <input type="hidden" name="token"
                                                            value="${fn:escapeXml(token)}">

                                                        <input type="hidden" name="paymentId"
                                                            value="${pendingPayment.paymentId}">

                                                        <button class="btn btn-success" type="submit"
                                                            style="width:100%">
                                                            Xác nhận đã nhận tiền
                                                        </button>
                                                    </form>
                                                </div>
                                            </c:when>
                                            <c:when
                                                test="${ not empty pendingPayment and pendingPayment.paymentMethod eq 'ONLINE' }">
                                                <div class="card">
                                                    <h2>Thanh toán trực tuyến · Demo</h2>
                                                    <p class="muted">
                                                        Đây là cổng thanh toán mô phỏng. Project không kết nối API ngân
                                                        hàng thật.
                                                    </p>
                                                    <div class="price">
                                                        <fmt:formatNumber value="${pendingPayment.amount}" type="number"
                                                            maxFractionDigits="0" />
                                                        ₫
                                                    </div>
                                                    <div class="muted" style="margin-top:8px">
                                                        Mã thanh toán: #
                                                        <c:out value="${pendingPayment.paymentId}" />
                                                    </div>
                                                    <div class="grid grid-2" style="margin-top:18px">
                                                        <form method="post"
                                                            action="${ctx}/receptionist/payment/online-success">
                                                            <input type="hidden" name="token"
                                                                value="${fn:escapeXml(token)}">
                                                            <input type="hidden" name="paymentId"
                                                                value="${pendingPayment.paymentId}">
                                                            <button class="btn btn-success" style="width:100%">
                                                                Mô phỏng thành công
                                                            </button>
                                                        </form>

                                                        <form method="post"
                                                            action="${ctx}/receptionist/payment/online-fail">
                                                            <input type="hidden" name="token"
                                                                value="${fn:escapeXml(token)}">
                                                            <input type="hidden" name="paymentId"
                                                                value="${pendingPayment.paymentId}">
                                                            <button class="btn btn-danger" style="width:100%">
                                                                Mô phỏng thất bại
                                                            </button>
                                                        </form>

                                                    </div>
                                                </div>
                                            </c:when>
                                            <c:otherwise>
                                                <div class="grid grid-2">
                                                    <form class="card" method="post"
                                                        action="${ctx}/receptionist/payment/cash">
                                                        <input type="hidden" name="token"
                                                            value="${fn:escapeXml(token)}">
                                                        <h2>Tiền mặt</h2>
                                                        <p class="muted">Thanh toán trực tiếp cho nhân viên phục vụ.</p>
                                                        <button class="btn btn-primary" style="width:100%">Chọn tiền
                                                            mặt</button>
                                                    </form>

                                                    <form class="card" method="post"
                                                        action="${ctx}/receptionist/payment/online">
                                                        <input type="hidden" name="token"
                                                            value="${fn:escapeXml(token)}">
                                                        <h2>Thanh toán trực tuyến</h2>
                                                        <p class="muted">Demo cổng thanh toán mô phỏng.</p>
                                                        <button class="btn btn-success" style="width:100%">
                                                            Thanh toán trực tuyến
                                                        </button>
                                                    </form>

                                                </div>
                                            </c:otherwise>
                                        </c:choose>
                                    </c:if>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>
                </body>

                </html>