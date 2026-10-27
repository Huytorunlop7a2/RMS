<%@ page contentType="text/html;charset=UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

            <c:set var="ctx" value="${pageContext.request.contextPath}" />

            <!doctype html>

            <html lang="vi">

            <head>

                <meta charset="utf-8">

                <meta name="viewport" content="width=device-width, initial-scale=1">

                <title>
                    Thực đơn
                </title>

                <link rel="stylesheet" href="${ctx}/assets/css/app.css?v=cart-ui-3">

            </head>


            <body class="customer-menu-page">


                <div class="cm-shell">


                    <%--=====================================================HEADER=====================================================--%>

                        <header class="cm-header">


                            <div class="cm-header-main">


                                <div>


                                    <div class="cm-mini-label">
                                        QR ORDER
                                    </div>


                                    <h1 class="cm-table-title">

                                        Bàn

                                        <c:out value="${table.tableNumber}" />

                                    </h1>


                                </div>



                                <div>


                                    <c:choose>

                                        <c:when test="${not empty openOrder}">

                                            <span class="cm-service-status cm-status-active">

                                                <span class="cm-status-dot"></span>

                                                Đang phục vụ

                                            </span>

                                        </c:when>


                                        <c:otherwise>

                                            <span class="cm-service-status">

                                                <span class="cm-status-dot"></span>

                                                Sẵn sàng gọi món

                                            </span>

                                        </c:otherwise>

                                    </c:choose>


                                </div>


                            </div>


                        </header>



                        <%--=====================================================MESSAGE=====================================================--%>

                            <div class="cm-message-area">


                                <c:if test="${not empty success}">

                                    <div class="cm-alert cm-alert-success">

                                        <c:out value="${success}" />

                                    </div>

                                </c:if>


                                <c:if test="${not empty error}">

                                    <div class="cm-alert cm-alert-danger">

                                        <c:out value="${error}" />

                                    </div>

                                </c:if>


                                <c:if test="${paymentPending}">

                                    <div class="cm-alert cm-alert-danger">

                                        Đơn hàng đang chờ thanh toán.
                                        Bạn chưa thể gọi thêm món.

                                    </div>

                                </c:if>


                            </div>



                            <%--=====================================================CATEGORY
                                BAR=====================================================--%>

                                <div class="cm-category-bar">


                                    <div id="categoryTabs" class="cm-category-tabs">

                                        <button type="button" class="cm-category-tab active" data-category-filter="all">

                                            Tất cả

                                            <span class="cm-tab-count" id="allItemCount">

                                                0

                                            </span>

                                        </button>

                                    </div>


                                </div>



                                <%--=====================================================PAGE
                                    CONTENT=====================================================--%>

                                    <main class="cm-main">


                                        <%--=================================================LEFT
                                            CONTENT=================================================--%>

                                            <section class="cm-menu-area">


                                                <div class="cm-menu-heading">


                                                    <div>


                                                        <h2>
                                                            Thực đơn
                                                        </h2>


                                                        <p>
                                                            Chọn món yêu thích,
                                                            thêm vào giỏ rồi gửi xuống bếp.
                                                        </p>


                                                    </div>



                                                </div>



                                                <%-- OPEN ORDER --%>

                                                    <c:if test="${not empty openOrder}">

                                                        <div class="cm-current-order">

                                                            <strong>

                                                                Đơn #

                                                                <c:out value="${openOrder.orderId}" />

                                                            </strong>

                                                            <span>

                                                                · Món gọi thêm sẽ được
                                                                thêm vào cùng đơn hiện tại.

                                                            </span>

                                                        </div>

                                                    </c:if>



                                                    <%--=============================================EMPTY
                                                        MENU=============================================--%>

                                                        <c:if test="${empty items}">

                                                            <div class="cm-empty-menu">

                                                                Hiện chưa có món nào có thể đặt.

                                                            </div>

                                                        </c:if>



                                                        <%--=============================================MENU
                                                            GRID=============================================--%>

                                                            <div id="menuGrid" class="cm-menu-grid">


                                                                <c:forEach var="m" items="${items}">


                                                                    <article class="cm-menu-card"
                                                                        data-category-id="${m.categoryId}"
                                                                        data-price="${m.price}">


                                                                        <%-- CATEGORY NAME FOR JS --%>

                                                                            <span class="cm-card-category-name"
                                                                                style="display:none">

                                                                                <c:out value="${m.categoryName}" />

                                                                            </span>



                                                                            <div class="cm-card-top">


                                                                                <span class="cm-food-category">

                                                                                    <c:out value="${m.categoryName}" />

                                                                                </span>


                                                                            </div>



                                                                            <div class="cm-food-content">


                                                                                <h3 id="menu-name-${m.menuItemId}">

                                                                                    <c:out value="${m.name}" />

                                                                                </h3>



                                                                                <c:if test="${not empty m.description}">

                                                                                    <p class="cm-food-description">

                                                                                        <c:out
                                                                                            value="${m.description}" />

                                                                                    </p>

                                                                                </c:if>



                                                                                <div class="cm-food-bottom">


                                                                                    <div class="cm-food-price">

                                                                                        <fmt:formatNumber
                                                                                            value="${m.price}"
                                                                                            type="number"
                                                                                            maxFractionDigits="0" />

                                                                                        ₫

                                                                                    </div>



                                                                                    <button type="button"
                                                                                        class="cm-add-button js-add-button"
                                                                                        onclick="addItem('${m.menuItemId}')">

                                                                                        <span>
                                                                                            +
                                                                                        </span>

                                                                                        Thêm

                                                                                    </button>


                                                                                </div>



                                                                                <%--=================================QUANTITY=================================--%>

                                                                                    <div class="cm-item-options">


                                                                                        <div class="cm-quantity-box">


                                                                                            <span>
                                                                                                Số lượng
                                                                                            </span>


                                                                                            <div
                                                                                                class="cm-quantity-control">


                                                                                                <button type="button"
                                                                                                    onclick="changeMenuQuantity('${m.menuItemId}', -1)">

                                                                                                    −

                                                                                                </button>


                                                                                                <input
                                                                                                    id="qty-${m.menuItemId}"
                                                                                                    type="number"
                                                                                                    min="1" max="99"
                                                                                                    value="1">


                                                                                                <button type="button"
                                                                                                    onclick="changeMenuQuantity('${m.menuItemId}', 1)">

                                                                                                    +

                                                                                                </button>


                                                                                            </div>


                                                                                        </div>



                                                                                        <%--=================================NOTE=================================--%>

                                                                                            <details
                                                                                                class="cm-note-box">


                                                                                                <summary>
                                                                                                    Ghi chú món
                                                                                                </summary>


                                                                                                <input
                                                                                                    id="note-${m.menuItemId}"
                                                                                                    type="text"
                                                                                                    maxlength="500"
                                                                                                    placeholder="Ví dụ: ít cay, không hành...">


                                                                                            </details>


                                                                                    </div>


                                                                            </div>


                                                                    </article>


                                                                </c:forEach>


                                                            </div>


                                            </section>



                                            <%--=================================================RIGHT
                                                CART=================================================--%>

                                                <aside class="cm-cart-column">


                                                    <div class="cm-cart-card">


                                                        <div class="cm-cart-header">


                                                            <div>


                                                                <h2>
                                                                    Giỏ món của bạn
                                                                </h2>


                                                                <p>
                                                                    Kiểm tra món trước khi gửi bếp.
                                                                </p>


                                                            </div>


                                                        </div>



                                                        <div class="cm-cart-summary">





                                                            <div>


                                                                <span id="cartCount" class="cm-cart-count">

                                                                    Giỏ hàng: 0 món

                                                                </span>


                                                                <strong id="cartTotal" class="cm-cart-total">

                                                                    0 ₫

                                                                </strong>


                                                            </div>


                                                        </div>



                                                        <div id="cartList" class="cm-cart-list">


                                                            <div class="cm-cart-empty">

                                                                Giỏ đang trống.
                                                                Chọn món từ thực đơn.

                                                            </div>


                                                        </div>



                                                        <form id="orderForm" method="post"
                                                            action="${ctx}/customer/order"
                                                            onsubmit="return prepareSubmit();">


                                                            <input type="hidden" name="token" value="${token}">


                                                            <div id="hiddenCart"></div>



                                                            <button id="submitOrderButton" type="submit"
                                                                class="cm-submit-order">

                                                                Gửi món xuống bếp

                                                            </button>


                                                        </form>



                                                        <a class="cm-cart-view-order"
                                                            href="${ctx}/customer/order?token=${token}">

                                                            Xem đơn hiện tại

                                                        </a>


                                                        <c:if test="${paymentPending}">

                                                            <p class="cm-cart-warning">

                                                                Đơn đang chờ thanh toán.
                                                                Không thể gọi thêm món.

                                                            </p>

                                                        </c:if>


                                                    </div>


                                                </aside>


                                    </main>


                </div>



                <%--=========================================================SCRIPT=========================================================--%>

                    <script>

                        (function () {

                            const cart = {};

                            const paymentPending =
                                "${paymentPending}" === "true";


                            const menuCards =
                                document.querySelectorAll(
                                    ".cm-menu-card"
                                );


                            const addButtons =
                                document.querySelectorAll(
                                    ".js-add-button"
                                );


                            const submitButton =
                                document.getElementById(
                                    "submitOrderButton"
                                );


                            /* =====================================================
                               CURRENCY
                               ===================================================== */

                            function formatMoney(value) {

                                return new Intl.NumberFormat(
                                    "vi-VN"
                                ).format(value)
                                    + " ₫";
                            }



                            /* =====================================================
                               CATEGORY
                               ===================================================== */

                            function buildCategoryTabs() {

                                const container =
                                    document.getElementById(
                                        "categoryTabs"
                                    );


                                const allCount =
                                    document.getElementById(
                                        "allItemCount"
                                    );


                                if (!container) {
                                    return;
                                }


                                const categories =
                                    new Map();


                                menuCards.forEach(
                                    function (card) {

                                        const id =
                                            card.dataset.categoryId;


                                        const nameElement =
                                            card.querySelector(
                                                ".cm-card-category-name"
                                            );


                                        const name =
                                            nameElement
                                                ? nameElement.textContent.trim()
                                                : "Khác";


                                        if (!categories.has(id)) {

                                            categories.set(
                                                id,
                                                {
                                                    name: name,
                                                    count: 0
                                                }
                                            );
                                        }


                                        categories.get(id).count++;
                                    }
                                );


                                if (allCount) {

                                    allCount.textContent =
                                        String(
                                            menuCards.length
                                        );
                                }


                                categories.forEach(
                                    function (category, id) {

                                        const button =
                                            document.createElement(
                                                "button"
                                            );


                                        button.type =
                                            "button";


                                        button.className =
                                            "cm-category-tab";


                                        button.dataset.categoryFilter =
                                            id;


                                        const text =
                                            document.createElement(
                                                "span"
                                            );


                                        text.textContent =
                                            category.name;


                                        const count =
                                            document.createElement(
                                                "span"
                                            );


                                        count.className =
                                            "cm-tab-count";


                                        count.textContent =
                                            category.count;


                                        button.appendChild(
                                            text
                                        );


                                        button.appendChild(
                                            count
                                        );


                                        button.addEventListener(
                                            "click",
                                            function () {

                                                filterCategory(
                                                    id,
                                                    button
                                                );
                                            }
                                        );


                                        container.appendChild(
                                            button
                                        );
                                    }
                                );


                                const allButton =
                                    container.querySelector(
                                        '[data-category-filter="all"]'
                                    );


                                if (allButton) {

                                    allButton.addEventListener(
                                        "click",
                                        function () {

                                            filterCategory(
                                                "all",
                                                allButton
                                            );
                                        }
                                    );
                                }
                            }



                            function filterCategory(
                                categoryId,
                                selectedButton
                            ) {

                                document
                                    .querySelectorAll(
                                        ".cm-category-tab"
                                    )
                                    .forEach(
                                        function (button) {

                                            button.classList.remove(
                                                "active"
                                            );
                                        }
                                    );


                                selectedButton.classList.add(
                                    "active"
                                );


                                menuCards.forEach(
                                    function (card) {

                                        const visible =
                                            categoryId === "all"
                                            ||
                                            card.dataset.categoryId
                                            === categoryId;


                                        card.style.display =
                                            visible
                                                ? ""
                                                : "none";
                                    }
                                );
                            }



                            /* =====================================================
                               QUANTITY ON MENU
                               ===================================================== */

                            window.changeMenuQuantity =
                                function (
                                    id,
                                    amount
                                ) {

                                    const input =
                                        document.getElementById(
                                            "qty-" + id
                                        );


                                    if (!input) {
                                        return;
                                    }


                                    let value =
                                        parseInt(
                                            input.value,
                                            10
                                        );


                                    if (isNaN(value)) {

                                        value = 1;
                                    }


                                    value += amount;


                                    if (value < 1) {

                                        value = 1;
                                    }


                                    if (value > 99) {

                                        value = 99;
                                    }


                                    input.value =
                                        value;
                                };



                            /* =====================================================
                               CART KEY
                               ===================================================== */

                            function createCartKey(
                                id,
                                note
                            ) {

                                return String(id)
                                    + "::"
                                    + String(note || "")
                                        .trim();
                            }



                            /* =====================================================
                               ADD ITEM
                               ===================================================== */

                            window.addItem =
                                function (id) {

                                    if (paymentPending) {

                                        alert(
                                            "Đơn hàng đang chờ thanh toán."
                                        );

                                        return;
                                    }


                                    const qtyInput =
                                        document.getElementById(
                                            "qty-" + id
                                        );


                                    const noteInput =
                                        document.getElementById(
                                            "note-" + id
                                        );


                                    const nameNode =
                                        document.getElementById(
                                            "menu-name-" + id
                                        );


                                    if (
                                        !qtyInput
                                        ||
                                        !noteInput
                                        ||
                                        !nameNode
                                    ) {

                                        alert(
                                            "Không tìm thấy thông tin món."
                                        );

                                        return;
                                    }


                                    const card =
                                        nameNode.closest(
                                            ".cm-menu-card"
                                        );


                                    if (!card) {

                                        return;
                                    }


                                    let qty =
                                        parseInt(
                                            qtyInput.value,
                                            10
                                        );


                                    if (
                                        isNaN(qty)
                                        ||
                                        qty < 1
                                    ) {

                                        alert(
                                            "Số lượng phải lớn hơn 0."
                                        );

                                        return;
                                    }


                                    if (qty > 99) {

                                        qty = 99;
                                    }


                                    const note =
                                        String(
                                            noteInput.value || ""
                                        ).trim();


                                    const name =
                                        nameNode.textContent.trim();


                                    const price =
                                        Number(
                                            card.dataset.price
                                        );


                                    const key =
                                        createCartKey(
                                            id,
                                            note
                                        );


                                    if (cart[key]) {

                                        cart[key].qty += qty;


                                    } else {

                                        cart[key] = {

                                            id:
                                                String(id),

                                            name:
                                                name,

                                            qty:
                                                qty,

                                            note:
                                                note,

                                            price:
                                                isNaN(price)
                                                    ? 0
                                                    : price

                                        };
                                    }


                                    qtyInput.value =
                                        "1";


                                    noteInput.value =
                                        "";


                                    renderCart();
                                };



                            /* =====================================================
                               CART QUANTITY
                               ===================================================== */

                            window.changeCartQuantity =
                                function (
                                    key,
                                    amount
                                ) {

                                    if (!cart[key]) {
                                        return;
                                    }


                                    cart[key].qty +=
                                        amount;


                                    if (
                                        cart[key].qty <= 0
                                    ) {

                                        delete cart[key];
                                    }


                                    renderCart();
                                };



                            window.removeCartItem =
                                function (key) {

                                    if (cart[key]) {

                                        delete cart[key];
                                    }


                                    renderCart();
                                };



                            /* =====================================================
                               TOTAL
                               ===================================================== */

                            function getTotalQuantity() {

                                let total = 0;


                                Object.values(cart)
                                    .forEach(
                                        function (item) {

                                            total +=
                                                item.qty;
                                        }
                                    );


                                return total;
                            }



                            function getCartTotal() {

                                let total = 0;


                                Object.values(cart)
                                    .forEach(
                                        function (item) {

                                            total +=
                                                item.price
                                                *
                                                item.qty;
                                        }
                                    );


                                return total;
                            }



                            /* =====================================================
                               RENDER CART
                               ===================================================== */

                            function renderCart() {

                                const cartList =
                                    document.getElementById(
                                        "cartList"
                                    );


                                const countText =
                                    document.getElementById(
                                        "cartCount"
                                    );


                                const totalText =
                                    document.getElementById(
                                        "cartTotal"
                                    );


                                const badge =
                                    document.getElementById(
                                        "cartBadge"
                                    );


                                const totalQuantity =
                                    getTotalQuantity();


                                if (countText) {

                                    countText.textContent =
                                        "Giỏ hàng: "
                                        + totalQuantity
                                        + " món";
                                }


                                if (badge) {

                                    badge.textContent =
                                        totalQuantity;
                                }


                                if (totalText) {

                                    totalText.textContent =
                                        formatMoney(
                                            getCartTotal()
                                        );
                                }


                                if (!cartList) {
                                    return;
                                }


                                cartList.innerHTML =
                                    "";


                                const entries =
                                    Object.entries(cart);


                                if (
                                    entries.length === 0
                                ) {

                                    const empty =
                                        document.createElement(
                                            "div"
                                        );


                                    empty.className =
                                        "cm-cart-empty";


                                    empty.textContent =
                                        "Giỏ đang trống. Chọn món từ thực đơn.";


                                    cartList.appendChild(
                                        empty
                                    );


                                    return;
                                }


                                entries.forEach(
                                    function (entry) {

                                        const key =
                                            entry[0];


                                        const item =
                                            entry[1];


                                        const row =
                                            document.createElement(
                                                "div"
                                            );


                                        row.className =
                                            "cm-cart-item";


                                        const information =
                                            document.createElement(
                                                "div"
                                            );


                                        information.className =
                                            "cm-cart-item-info";


                                        const top =
                                            document.createElement(
                                                "div"
                                            );


                                        top.className =
                                            "cm-cart-item-top";


                                        const name =
                                            document.createElement(
                                                "strong"
                                            );


                                        name.textContent =
                                            item.name;


                                        const remove =
                                            document.createElement(
                                                "button"
                                            );


                                        remove.type =
                                            "button";


                                        remove.className =
                                            "cm-cart-remove";


                                        remove.textContent =
                                            "×";


                                        remove.addEventListener(
                                            "click",
                                            function () {

                                                window.removeCartItem(
                                                    key
                                                );
                                            }
                                        );


                                        top.appendChild(
                                            name
                                        );


                                        top.appendChild(
                                            remove
                                        );


                                        information.appendChild(
                                            top
                                        );


                                        if (
                                            item.note
                                            !== ""
                                        ) {

                                            const note =
                                                document.createElement(
                                                    "div"
                                                );


                                            note.className =
                                                "cm-cart-item-note";


                                            note.textContent =
                                                "Ghi chú: "
                                                + item.note;


                                            information.appendChild(
                                                note
                                            );
                                        }


                                        const bottom =
                                            document.createElement(
                                                "div"
                                            );


                                        bottom.className =
                                            "cm-cart-item-bottom";


                                        const controls =
                                            document.createElement(
                                                "div"
                                            );


                                        controls.className =
                                            "cm-cart-qty";


                                        const minus =
                                            document.createElement(
                                                "button"
                                            );


                                        minus.type =
                                            "button";


                                        minus.textContent =
                                            "−";


                                        minus.addEventListener(
                                            "click",
                                            function () {

                                                window.changeCartQuantity(
                                                    key,
                                                    -1
                                                );
                                            }
                                        );


                                        const qty =
                                            document.createElement(
                                                "span"
                                            );


                                        qty.textContent =
                                            item.qty;


                                        const plus =
                                            document.createElement(
                                                "button"
                                            );


                                        plus.type =
                                            "button";


                                        plus.textContent =
                                            "+";


                                        plus.addEventListener(
                                            "click",
                                            function () {

                                                window.changeCartQuantity(
                                                    key,
                                                    1
                                                );
                                            }
                                        );


                                        controls.appendChild(
                                            minus
                                        );


                                        controls.appendChild(
                                            qty
                                        );


                                        controls.appendChild(
                                            plus
                                        );


                                        const linePrice =
                                            document.createElement(
                                                "strong"
                                            );


                                        linePrice.className =
                                            "cm-cart-line-price";


                                        linePrice.textContent =
                                            formatMoney(
                                                item.price
                                                *
                                                item.qty
                                            );


                                        bottom.appendChild(
                                            controls
                                        );


                                        bottom.appendChild(
                                            linePrice
                                        );


                                        information.appendChild(
                                            bottom
                                        );


                                        row.appendChild(
                                            information
                                        );


                                        cartList.appendChild(
                                            row
                                        );
                                    }
                                );
                            }



                            /* =====================================================
                               SUBMIT
                               ===================================================== */

                            window.prepareSubmit =
                                function () {

                                    if (paymentPending) {

                                        alert(
                                            "Đơn hàng đang chờ thanh toán."
                                        );

                                        return false;
                                    }


                                    const rows =
                                        Object.values(
                                            cart
                                        );


                                    if (
                                        rows.length === 0
                                    ) {

                                        alert(
                                            "Vui lòng chọn ít nhất một món."
                                        );

                                        return false;
                                    }


                                    const hiddenCart =
                                        document.getElementById(
                                            "hiddenCart"
                                        );


                                    if (!hiddenCart) {

                                        return false;
                                    }


                                    hiddenCart.innerHTML =
                                        "";


                                    rows.forEach(
                                        function (item) {

                                            addHiddenInput(
                                                hiddenCart,
                                                "itemId",
                                                item.id
                                            );


                                            addHiddenInput(
                                                hiddenCart,
                                                "quantity",
                                                item.qty
                                            );


                                            addHiddenInput(
                                                hiddenCart,
                                                "note",
                                                item.note
                                            );
                                        }
                                    );


                                    return true;
                                };



                            function addHiddenInput(
                                parent,
                                name,
                                value
                            ) {

                                const input =
                                    document.createElement(
                                        "input"
                                    );


                                input.type =
                                    "hidden";


                                input.name =
                                    name;


                                input.value =
                                    value === null
                                        ||
                                        value === undefined

                                        ? ""

                                        : String(value);


                                parent.appendChild(
                                    input
                                );
                            }



                            /* =====================================================
                               INIT
                               ===================================================== */

                            document.addEventListener(
                                "DOMContentLoaded",
                                function () {

                                    buildCategoryTabs();

                                    renderCart();


                                    if (paymentPending) {

                                        addButtons.forEach(
                                            function (button) {

                                                button.disabled =
                                                    true;
                                            }
                                        );


                                        if (submitButton) {

                                            submitButton.disabled =
                                                true;
                                        }
                                    }

                                }
                            );

                        })();

                    </script>


            </body>

            </html>
