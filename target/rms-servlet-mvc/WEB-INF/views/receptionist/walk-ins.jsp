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
                                    <p class="muted">
                                        Quản lý ghép bàn và trạng thái bàn dành cho khách đến trực tiếp.
                                    </p>
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

                                <p class="muted">
                                    Chọn ít nhất hai bàn đang trống để ghép thành
                                    một nhóm bàn phục vụ khách.
                                </p>

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

                            <section class="card section">

                                <h2>Trạng thái bàn</h2>

                                <p class="muted">
                                    Theo dõi tình trạng sử dụng bàn và quản lý
                                    việc trả bàn hoặc trả nhóm bàn Walk-in.
                                </p>

                                <div class="table-wrap">

                                    <table class="data-table">

                                        <thead>
                                            <tr>
                                                <th>Bàn</th>
                                                <th>Sức chứa</th>
                                                <th>Trạng thái</th>
                                                <th>Thao tác</th>
                                            </tr>
                                        </thead>

                                        <tbody>

                                            <c:forEach var="t" items="${tables}">

                                                <c:set var="walkInGroupLabel"
                                                    value="${activeWalkInGroupLabels[t.tableNumber]}" />

                                                <tr>

                                                    <td>

                                                        <b>
                                                            <c:out value="${t.tableNumber}" />
                                                        </b>

                                                        <c:if test="${not empty walkInGroupLabel}">

                                                            <br>

                                                            <span class="badge badge-warning" style="margin-top:6px">

                                                                <c:out value="${walkInGroupLabel}" />

                                                            </span>

                                                        </c:if>

                                                    </td>

                                                    <td>
                                                        <c:out value="${t.capacity}" />
                                                        chỗ
                                                    </td>

                                                    <td>

                                                        <c:choose>

                                                            <c:when test="${not t.active}">
                                                                <span class="badge">
                                                                    Ngừng dùng
                                                                </span>
                                                            </c:when>

                                                            <c:when test="${t.status eq 'AVAILABLE'}">
                                                                <span class="badge badge-success">
                                                                    Trống
                                                                </span>
                                                            </c:when>

                                                            <c:when test="${t.status eq 'OCCUPIED'}">
                                                                <span class="badge badge-warning">
                                                                    Đang sử dụng
                                                                </span>
                                                            </c:when>

                                                            <c:otherwise>
                                                                <span class="badge">
                                                                    <c:out value="${t.status}" />
                                                                </span>
                                                            </c:otherwise>

                                                        </c:choose>

                                                    </td>

                                                    <td>

                                                        <div class="inline">

                                                            <c:if test="${t.status eq 'OCCUPIED'}">

                                                                <form method="post"
                                                                    action="${ctx}/receptionist/walk-ins">

                                                                    <input type="hidden" name="action"
                                                                        value="releaseOne">

                                                                    <input type="hidden" name="id" value="${t.tableId}">

                                                                    <button type="submit" class="btn btn-sm btn-outline"
                                                                        onclick="return confirm('Chỉ trả bàn này?');">

                                                                        Trả bàn này

                                                                    </button>

                                                                </form>

                                                            </c:if>

                                                            <c:if
                                                                test="${t.status eq 'OCCUPIED' and activeWalkInTableIds.contains(t.tableId)}">

                                                                <form method="post"
                                                                    action="${ctx}/receptionist/walk-ins">

                                                                    <input type="hidden" name="action"
                                                                        value="releaseGroup">

                                                                    <input type="hidden" name="id" value="${t.tableId}">

                                                                    <button type="submit" class="btn btn-sm btn-danger"
                                                                        onclick="return confirm('Trả toàn bộ nhóm bàn walk-in?');">

                                                                        Trả cả nhóm

                                                                    </button>

                                                                </form>

                                                            </c:if>

                                                        </div>

                                                    </td>

                                                </tr>

                                            </c:forEach>

                                        </tbody>

                                    </table>

                                </div>

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