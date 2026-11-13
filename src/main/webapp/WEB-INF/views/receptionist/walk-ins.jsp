<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

        <c:set var="ctx" value="${pageContext.request.contextPath}" />
        <c:set var="activePage" value="walk-ins" />

        <!doctype html>
        <html lang="vi">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Quản lý Walk-in</title>
            <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=receptionist-sidebar-2">
        </head>

        <body>

            <div class="layout">

                <%@ include file="sidebar.jsp" %>

                    <main class="main">
                        <div class="container">

                            <div class="page-head">
                                <div>
                                    <h1>Quản lý khách Walk-in</h1>
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

                                <h2>Gộp bàn cho khách Walk-in</h2>

                                <form method="post" action="${ctx}/receptionist/walk-ins"
                                    onsubmit="return validateWalkInGroup();">

                                    <input type="hidden" name="action" value="createWalkInGroup">

                                    <div class="table-wrap">

                                        <table class="data-table">

                                            <thead>
                                                <tr>
                                                    <th>Chọn</th>
                                                    <th>Bàn</th>
                                                    <th>Sức chứa</th>
                                                    <th>Trạng thái</th>
                                                </tr>
                                            </thead>

                                            <tbody>

                                                <c:forEach var="t" items="${tables}">

                                                    <c:if test="${t.active and t.status eq 'AVAILABLE'}">

                                                        <tr>

                                                            <td>
                                                                <input class="walkin-table-checkbox" type="checkbox"
                                                                    name="tableIds" value="${t.tableId}">
                                                            </td>

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
                                                                <span class="badge badge-success">
                                                                    Trống
                                                                </span>
                                                            </td>

                                                        </tr>

                                                    </c:if>

                                                </c:forEach>

                                            </tbody>

                                        </table>

                                    </div>

                                    <div class="inline" style="margin-top:16px">

                                        <button type="submit" class="btn btn-primary">
                                            Gộp các bàn đã chọn
                                        </button>

                                        <span id="walkInSelectedCount" class="muted">
                                            Đã chọn: 0 bàn
                                        </span>

                                    </div>

                                </form>

                            </section>

                        </div>
                    </main>

            </div>

            <script>
                const walkInCheckboxes = document.querySelectorAll(
                    ".walkin-table-checkbox"
                );

                const selectedCountText = document.getElementById(
                    "walkInSelectedCount"
                );

                function updateWalkInCount() {
                    const selected = document.querySelectorAll(
                        ".walkin-table-checkbox:checked"
                    ).length;

                    if (selectedCountText) {
                        selectedCountText.textContent =
                            "Đã chọn: " + selected + " bàn";
                    }
                }

                walkInCheckboxes.forEach(function (checkbox) {
                    checkbox.addEventListener("change", updateWalkInCount);
                });

                function validateWalkInGroup() {
                    const selected = document.querySelectorAll(
                        ".walkin-table-checkbox:checked"
                    ).length;

                    if (selected < 2) {
                        alert("Vui lòng chọn ít nhất 2 bàn.");
                        return false;
                    }

                    if (selected > 8) {
                        alert("Chỉ được gộp tối đa 8 bàn.");
                        return false;
                    }

                    return confirm(
                        "Xác nhận gộp " + selected + " bàn cho khách walk-in?"
                    );
                }
            </script>

        </body>

        </html>