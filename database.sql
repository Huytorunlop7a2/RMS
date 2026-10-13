/* =========================================================
   RESTAURANT MANAGEMENT SYSTEM
   DATABASE: RMS_SERVLET

   Java Servlet + JSP + JDBC + SQL Server
   ========================================================= */

USE master;
GO

IF DB_ID('RMS_SERVLET') IS NULL
BEGIN
    CREATE DATABASE RMS_SERVLET;
END;
GO

USE RMS_SERVLET;
GO


/* =========================================================
   1. STAFF
   ========================================================= */

IF OBJECT_ID('dbo.staff', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.staff
    (
        staff_id BIGINT
            IDENTITY(1,1)
            NOT NULL
            PRIMARY KEY,

        full_name NVARCHAR(255)
            NOT NULL,

        username VARCHAR(100)
            NOT NULL,

        password VARCHAR(255)
            NOT NULL,

        role VARCHAR(30)
            NOT NULL,

        account_status VARCHAR(30)
            NOT NULL
            DEFAULT 'ACTIVE',

        CONSTRAINT uq_staff_username
            UNIQUE(username),

        CONSTRAINT ck_staff_role
            CHECK
            (
                role IN
                (
                    'MANAGER',
                    'WAITER',
                    'KITCHEN',
                    'RECEPTIONIST'
                )
            ),

        CONSTRAINT ck_staff_account_status
            CHECK
            (
                account_status IN
                (
                    'ACTIVE',
                    'INACTIVE'
                )
            )
    );
END;
GO


/* =========================================================
   2. RESTAURANT TABLES
   ========================================================= */

IF OBJECT_ID('dbo.restaurant_tables', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.restaurant_tables
    (
        table_id BIGINT
            IDENTITY(1,1)
            NOT NULL
            PRIMARY KEY,

        table_number VARCHAR(30)
            NOT NULL,

        capacity INT
            NOT NULL,

        status VARCHAR(30)
            NOT NULL
            DEFAULT 'AVAILABLE',

        qr_token VARCHAR(64)
            NOT NULL,

        active BIT
            NOT NULL
            DEFAULT 1,

        CONSTRAINT uq_restaurant_table_number
            UNIQUE(table_number),

        CONSTRAINT uq_restaurant_table_qr
            UNIQUE(qr_token),

        CONSTRAINT ck_restaurant_table_capacity
            CHECK(capacity > 0),

        CONSTRAINT ck_restaurant_table_status
            CHECK
            (
                status IN
                (
                    'AVAILABLE',
                    'RESERVED',
                    'OCCUPIED'
                )
            )
    );
END;
GO


/* =========================================================
   3. TABLE LAYOUT
   ========================================================= */

IF OBJECT_ID('dbo.table_layouts', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.table_layouts
    (
        table_id BIGINT
            NOT NULL
            PRIMARY KEY,

        area_code VARCHAR(50)
            NOT NULL,

        row_no INT
            NOT NULL,

        position_no INT
            NOT NULL,

        merge_enabled BIT
            NOT NULL
            DEFAULT 1,

        CONSTRAINT fk_table_layout_table
            FOREIGN KEY(table_id)
            REFERENCES dbo.restaurant_tables(table_id),

        CONSTRAINT uq_table_layout_position
            UNIQUE
            (
                area_code,
                row_no,
                position_no
            ),

        CONSTRAINT ck_table_layout_row
            CHECK(row_no > 0),

        CONSTRAINT ck_table_layout_position
            CHECK(position_no > 0)
    );
END;
GO


/* =========================================================
   4. TABLE ADJACENCY OVERRIDE
   ========================================================= */

IF OBJECT_ID(
    'dbo.table_adjacency_overrides',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.table_adjacency_overrides
    (
        table_id_1 BIGINT
            NOT NULL,

        table_id_2 BIGINT
            NOT NULL,

        allowed BIT
            NOT NULL
            DEFAULT 1,

        CONSTRAINT pk_table_adjacency_overrides
            PRIMARY KEY
            (
                table_id_1,
                table_id_2
            ),

        CONSTRAINT fk_adjacency_table_1
            FOREIGN KEY(table_id_1)
            REFERENCES dbo.restaurant_tables(table_id),

        CONSTRAINT fk_adjacency_table_2
            FOREIGN KEY(table_id_2)
            REFERENCES dbo.restaurant_tables(table_id),

        CONSTRAINT ck_adjacency_distinct_order
            CHECK(table_id_1 < table_id_2)
    );
END;
GO


/* =========================================================
   5. RESTAURANT OPENING HOURS

   1 = Monday
   ...
   7 = Sunday
   ========================================================= */

IF OBJECT_ID(
    'dbo.restaurant_opening_hours',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.restaurant_opening_hours
    (
        day_of_week TINYINT
            NOT NULL
            PRIMARY KEY,

        open_time TIME
            NULL,

        close_time TIME
            NULL,

        is_closed BIT
            NOT NULL
            DEFAULT 0,

        CONSTRAINT ck_opening_hours_day
            CHECK
            (
                day_of_week BETWEEN 1 AND 7
            ),

        CONSTRAINT ck_opening_hours_time
            CHECK
            (
                (
                    is_closed = 1
                    AND open_time IS NULL
                    AND close_time IS NULL
                )
                OR
                (
                    is_closed = 0
                    AND open_time IS NOT NULL
                    AND close_time IS NOT NULL
                    AND open_time < close_time
                )
            )
    );
END;
GO


/* =========================================================
   6. SPECIAL OPENING DATES
   ========================================================= */

IF OBJECT_ID(
    'dbo.restaurant_schedule_exceptions',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.restaurant_schedule_exceptions
    (
        exception_date DATE
            NOT NULL
            PRIMARY KEY,

        open_time TIME
            NULL,

        close_time TIME
            NULL,

        is_closed BIT
            NOT NULL
            DEFAULT 0,

        reason NVARCHAR(500)
            NULL,

        created_at DATETIME2
            NOT NULL
            DEFAULT SYSDATETIME(),

        CONSTRAINT ck_schedule_exception_time
            CHECK
            (
                (
                    is_closed = 1
                    AND open_time IS NULL
                    AND close_time IS NULL
                )
                OR
                (
                    is_closed = 0
                    AND open_time IS NOT NULL
                    AND close_time IS NOT NULL
                    AND open_time < close_time
                )
            )
    );
END;
GO


/* =========================================================
   7. MENU CATEGORIES
   ========================================================= */

IF OBJECT_ID(
    'dbo.menu_categories',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.menu_categories
    (
        category_id BIGINT
            IDENTITY(1,1)
            NOT NULL
            PRIMARY KEY,

        name NVARCHAR(255)
            NOT NULL,

        active BIT
            NOT NULL
            DEFAULT 1,

        CONSTRAINT uq_menu_category_name
            UNIQUE(name)
    );
END;
GO


/* =========================================================
   8. MENU ITEMS
   ========================================================= */

IF OBJECT_ID(
    'dbo.menu_items',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.menu_items
    (
        menu_item_id BIGINT
            IDENTITY(1,1)
            NOT NULL
            PRIMARY KEY,

        category_id BIGINT
            NOT NULL,

        name NVARCHAR(255)
            NOT NULL,

        description NVARCHAR(1000)
            NULL,

        price DECIMAL(18,2)
            NOT NULL,

        active BIT
            NOT NULL
            DEFAULT 1,

        inventory_available BIT
            NOT NULL
            DEFAULT 0,

        CONSTRAINT fk_menu_category
            FOREIGN KEY(category_id)
            REFERENCES dbo.menu_categories(category_id),

        CONSTRAINT ck_menu_item_price
            CHECK(price >= 0)
    );
END;
GO


/* =========================================================
   9. INVENTORY ITEMS

   quantity
       = lượng nguyên liệu vật lý thực tế trong kho.

   reserved_quantity
       = lượng nguyên liệu đã giữ cho OrderDetail PENDING.

   available
       = quantity - reserved_quantity
   ========================================================= */

IF OBJECT_ID(
    'dbo.inventory_items',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.inventory_items
    (
        inventory_item_id BIGINT
            IDENTITY(1,1)
            NOT NULL
            PRIMARY KEY,

        name NVARCHAR(255)
            NOT NULL,

        unit NVARCHAR(50)
            NOT NULL,

        quantity DECIMAL(18,3)
            NOT NULL
            DEFAULT 0,

        reserved_quantity DECIMAL(18,3)
            NOT NULL
            DEFAULT 0,

        low_stock_threshold DECIMAL(18,3)
            NOT NULL
            DEFAULT 0,

        active BIT
            NOT NULL
            DEFAULT 1,

        CONSTRAINT uq_inventory_item_name
            UNIQUE(name),

        CONSTRAINT ck_inventory_quantity
            CHECK(quantity >= 0),

        CONSTRAINT ck_inventory_reserved_quantity
            CHECK
            (
                reserved_quantity >= 0
                AND reserved_quantity <= quantity
            ),

        CONSTRAINT ck_inventory_low_stock_threshold
            CHECK(low_stock_threshold >= 0)
    );
END;
GO


/* =========================================================
   UPGRADE OLD DATABASE:
   ADD reserved_quantity IF MISSING
   ========================================================= */

IF COL_LENGTH(
    'dbo.inventory_items',
    'reserved_quantity'
) IS NULL
BEGIN
    ALTER TABLE dbo.inventory_items
    ADD reserved_quantity DECIMAL(18,3)
        NOT NULL
        CONSTRAINT df_inventory_reserved_quantity
        DEFAULT 0
        WITH VALUES;
END;
GO


IF OBJECT_ID(
    'dbo.ck_inventory_reserved_quantity',
    'C'
) IS NULL
BEGIN
    ALTER TABLE dbo.inventory_items
    WITH CHECK
    ADD CONSTRAINT ck_inventory_reserved_quantity
        CHECK
        (
            reserved_quantity >= 0
            AND reserved_quantity <= quantity
        );
END;
GO


/* =========================================================
   10. MENU ITEM INGREDIENTS / RECIPE
   ========================================================= */

IF OBJECT_ID(
    'dbo.menu_item_ingredients',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.menu_item_ingredients
    (
        id BIGINT
            IDENTITY(1,1)
            NOT NULL
            PRIMARY KEY,

        menu_item_id BIGINT
            NOT NULL,

        inventory_item_id BIGINT
            NOT NULL,

        required_quantity DECIMAL(18,3)
            NOT NULL,

        CONSTRAINT uq_menu_ingredient
            UNIQUE
            (
                menu_item_id,
                inventory_item_id
            ),

        CONSTRAINT fk_recipe_menu
            FOREIGN KEY(menu_item_id)
            REFERENCES dbo.menu_items(menu_item_id),

        CONSTRAINT fk_recipe_inventory
            FOREIGN KEY(inventory_item_id)
            REFERENCES dbo.inventory_items(inventory_item_id),

        CONSTRAINT ck_recipe_required_quantity
            CHECK(required_quantity > 0)
    );
END;
GO


/* =========================================================
   11. RESERVATIONS
   ========================================================= */

IF OBJECT_ID(
    'dbo.reservations',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.reservations
    (
        reservation_id BIGINT
            IDENTITY(1,1)
            NOT NULL
            PRIMARY KEY,

        /*
         * Anchor table.
         *
         * Tất cả bàn thật sự thuộc reservation
         * được lưu trong reservation_tables.
         */
        table_id BIGINT
            NOT NULL,

        created_by_staff_id BIGINT
            NOT NULL,

        customer_name NVARCHAR(255)
            NOT NULL,

        phone_number VARCHAR(20)
            NOT NULL,

        reservation_date DATE
            NOT NULL,

        start_time TIME
            NOT NULL,

        end_time TIME
            NOT NULL,

        party_size INT
            NOT NULL,

        status VARCHAR(30)
            NOT NULL
            DEFAULT 'CONFIRMED',

        created_at DATETIME2
            NOT NULL
            DEFAULT SYSDATETIME(),

        CONSTRAINT fk_res_table
            FOREIGN KEY(table_id)
            REFERENCES dbo.restaurant_tables(table_id),

        CONSTRAINT fk_res_staff
            FOREIGN KEY(created_by_staff_id)
            REFERENCES dbo.staff(staff_id),

        CONSTRAINT ck_reservation_party_size
            CHECK(party_size > 0),

        CONSTRAINT ck_reservation_status
            CHECK
            (
                status IN
                (
                    'CONFIRMED',
                    'CHECKED_IN',
                    'COMPLETED',
                    'CANCELLED',
                    'NO_SHOW'
                )
            ),

        CONSTRAINT ck_reservation_time_range
            CHECK(start_time < end_time)
    );
END;
GO


/* =========================================================
   12. RESERVATION TABLES
   ========================================================= */

IF OBJECT_ID(
    'dbo.reservation_tables',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.reservation_tables
    (
        reservation_id BIGINT
            NOT NULL,

        table_id BIGINT
            NOT NULL,

        CONSTRAINT pk_reservation_tables
            PRIMARY KEY
            (
                reservation_id,
                table_id
            ),

        CONSTRAINT fk_reservation_table_reservation
            FOREIGN KEY(reservation_id)
            REFERENCES dbo.reservations(reservation_id),

        CONSTRAINT fk_reservation_table_table
            FOREIGN KEY(table_id)
            REFERENCES dbo.restaurant_tables(table_id)
    );
END;
GO


/* =========================================================
   13. ORDERS
   ========================================================= */

IF OBJECT_ID(
    'dbo.orders',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.orders
    (
        order_id BIGINT
            IDENTITY(1,1)
            NOT NULL
            PRIMARY KEY,

        /*
         * Walk-in đơn:
         * table_id = bàn đang sử dụng.
         *
         * Reservation:
         * table_id = anchor table.
         *
         * Walk-in Group:
         * table_id = anchor table của group.
         */
        table_id BIGINT
            NOT NULL,

        /*
         * NULL:
         * Walk-in.
         *
         * NOT NULL:
         * Reservation.
         */
        reservation_id BIGINT
            NULL,

        order_status VARCHAR(20)
            NOT NULL
            DEFAULT 'OPEN',

        created_at DATETIME2
            NOT NULL
            DEFAULT SYSDATETIME(),

        closed_at DATETIME2
            NULL,

        CONSTRAINT fk_order_table
            FOREIGN KEY(table_id)
            REFERENCES dbo.restaurant_tables(table_id),

        CONSTRAINT fk_order_reservation
            FOREIGN KEY(reservation_id)
            REFERENCES dbo.reservations(reservation_id),

        CONSTRAINT ck_order_status
            CHECK
            (
                order_status IN
                (
                    'OPEN',
                    'CLOSED'
                )
            )
    );
END;
GO


/* =========================================================
   14. ORDER DETAILS
   ========================================================= */

IF OBJECT_ID(
    'dbo.order_details',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.order_details
    (
        order_detail_id BIGINT
            IDENTITY(1,1)
            NOT NULL
            PRIMARY KEY,

        order_id BIGINT
            NOT NULL,

        menu_item_id BIGINT
            NOT NULL,

        quantity INT
            NOT NULL,

        unit_price DECIMAL(18,2)
            NOT NULL,

        note NVARCHAR(500)
            NULL,

        status VARCHAR(20)
            NOT NULL
            DEFAULT 'PENDING',

        created_at DATETIME2
            NOT NULL
            DEFAULT SYSDATETIME(),

        ready_at DATETIME2
            NULL,

        served_at DATETIME2
            NULL,

        CONSTRAINT fk_detail_order
            FOREIGN KEY(order_id)
            REFERENCES dbo.orders(order_id),

        CONSTRAINT fk_detail_menu
            FOREIGN KEY(menu_item_id)
            REFERENCES dbo.menu_items(menu_item_id),

        CONSTRAINT ck_order_detail_quantity
            CHECK(quantity > 0),

        CONSTRAINT ck_order_detail_price
            CHECK(unit_price >= 0),

        CONSTRAINT ck_order_detail_status
            CHECK
            (
                status IN
                (
                    'PENDING',
                    'READY',
                    'SERVED',
                    'CANCELLED'
                )
            )
    );
END;
GO


/* =========================================================
   15. ORDER DETAIL INGREDIENTS

   Snapshot lượng nguyên liệu đã reserve cho từng
   OrderDetail tại thời điểm khách Submit Order.

   Ví dụ:
   Recipe Steak = 200g Beef
   Customer order = 3

   required_quantity = 600g

   Submit:
       reserved_quantity += 600

   Mark Ready:
       quantity          -= 600
       reserved_quantity -= 600

   Cancel PENDING:
       reserved_quantity -= 600
   ========================================================= */

IF OBJECT_ID(
    'dbo.order_detail_ingredients',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.order_detail_ingredients
    (
        order_detail_id BIGINT
            NOT NULL,

        inventory_item_id BIGINT
            NOT NULL,

        required_quantity DECIMAL(18,3)
            NOT NULL,

        created_at DATETIME2
            NOT NULL
            DEFAULT SYSDATETIME(),

        CONSTRAINT pk_order_detail_ingredients
            PRIMARY KEY
            (
                order_detail_id,
                inventory_item_id
            ),

        CONSTRAINT fk_order_detail_ingredient_detail
            FOREIGN KEY(order_detail_id)
            REFERENCES dbo.order_details(order_detail_id),

        CONSTRAINT fk_order_detail_ingredient_inventory
            FOREIGN KEY(inventory_item_id)
            REFERENCES dbo.inventory_items(inventory_item_id),

        CONSTRAINT ck_order_detail_ingredient_required
            CHECK(required_quantity > 0)
    );
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE
        object_id =
            OBJECT_ID(
                'dbo.order_detail_ingredients'
            )
        AND name =
            'ix_order_detail_ingredients_inventory'
)
BEGIN
    CREATE INDEX
        ix_order_detail_ingredients_inventory
    ON dbo.order_detail_ingredients
    (
        inventory_item_id,
        order_detail_id
    );
END;
GO


/* =========================================================
   16. PAYMENTS
   ========================================================= */

IF OBJECT_ID(
    'dbo.payments',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.payments
    (
        payment_id BIGINT
            IDENTITY(1,1)
            NOT NULL
            PRIMARY KEY,

        order_id BIGINT
            NOT NULL,

        amount DECIMAL(18,2)
            NOT NULL,

        payment_method VARCHAR(20)
            NOT NULL,

        payment_status VARCHAR(20)
            NOT NULL
            DEFAULT 'PENDING',

        created_at DATETIME2
            NOT NULL
            DEFAULT SYSDATETIME(),

        paid_at DATETIME2
            NULL,

        CONSTRAINT fk_payment_order
            FOREIGN KEY(order_id)
            REFERENCES dbo.orders(order_id),

        CONSTRAINT ck_payment_amount
            CHECK(amount >= 0),

        CONSTRAINT ck_payment_method
            CHECK
            (
                payment_method IN
                (
                    'CASH',
                    'ONLINE'
                )
            ),

        CONSTRAINT ck_payment_status
            CHECK
            (
                payment_status IN
                (
                    'PENDING',
                    'PAID',
                    'FAILED'
                )
            )
    );
END;
GO


/* =========================================================
   17. INVENTORY TRANSACTIONS
   ========================================================= */

IF OBJECT_ID(
    'dbo.inventory_transactions',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.inventory_transactions
    (
        transaction_id BIGINT
            IDENTITY(1,1)
            NOT NULL
            PRIMARY KEY,

        inventory_item_id BIGINT
            NOT NULL,

        reference_order_id BIGINT
            NULL,

        created_by_staff_id BIGINT
            NULL,

        quantity_change DECIMAL(18,3)
            NOT NULL,

        unit_cost DECIMAL(18,2)
            NULL,

        transaction_type VARCHAR(30)
            NOT NULL,

        description NVARCHAR(1000)
            NULL,

        created_at DATETIME2
            NOT NULL
            DEFAULT SYSDATETIME(),

        CONSTRAINT fk_tx_inventory
            FOREIGN KEY(inventory_item_id)
            REFERENCES dbo.inventory_items(inventory_item_id),

        CONSTRAINT fk_tx_order
            FOREIGN KEY(reference_order_id)
            REFERENCES dbo.orders(order_id),

        CONSTRAINT fk_tx_staff
            FOREIGN KEY(created_by_staff_id)
            REFERENCES dbo.staff(staff_id),

        CONSTRAINT ck_inventory_tx_quantity_change
            CHECK(quantity_change <> 0),

        CONSTRAINT ck_inventory_tx_unit_cost
            CHECK
            (
                unit_cost IS NULL
                OR unit_cost >= 0
            ),

        CONSTRAINT ck_inventory_tx_type
            CHECK
            (
                transaction_type IN
                (
                    'RESTOCK',
                    'WASTE_LOSS',
                    'ADJUSTMENT',
                    'USAGE'
                )
            )
    );
END;
GO


/* =========================================================
   18. WALK-IN GROUPS
   ========================================================= */

IF OBJECT_ID(
    'dbo.walk_in_groups',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.walk_in_groups
    (
        walk_in_group_id BIGINT
            IDENTITY(1,1)
            NOT NULL
            PRIMARY KEY,

        anchor_table_id BIGINT
            NOT NULL,

        created_by_staff_id BIGINT
            NOT NULL,

        status VARCHAR(20)
            NOT NULL
            DEFAULT 'ACTIVE',

        created_at DATETIME2
            NOT NULL
            DEFAULT SYSDATETIME(),

        closed_at DATETIME2
            NULL,

        CONSTRAINT fk_walk_in_group_anchor
            FOREIGN KEY(anchor_table_id)
            REFERENCES dbo.restaurant_tables(table_id),

        CONSTRAINT fk_walk_in_group_staff
            FOREIGN KEY(created_by_staff_id)
            REFERENCES dbo.staff(staff_id),

        CONSTRAINT ck_walk_in_group_status
            CHECK
            (
                status IN
                (
                    'ACTIVE',
                    'CLOSED'
                )
            )
    );
END;
GO


/* =========================================================
   19. WALK-IN GROUP TABLES
   ========================================================= */

IF OBJECT_ID(
    'dbo.walk_in_group_tables',
    'U'
) IS NULL
BEGIN
    CREATE TABLE dbo.walk_in_group_tables
    (
        walk_in_group_id BIGINT
            NOT NULL,

        table_id BIGINT
            NOT NULL,

        active BIT
            NOT NULL
            DEFAULT 1,

        CONSTRAINT pk_walk_in_group_tables
            PRIMARY KEY
            (
                walk_in_group_id,
                table_id
            ),

        CONSTRAINT fk_walk_in_group_tables_group
            FOREIGN KEY(walk_in_group_id)
            REFERENCES dbo.walk_in_groups(walk_in_group_id),

        CONSTRAINT fk_walk_in_group_tables_table
            FOREIGN KEY(table_id)
            REFERENCES dbo.restaurant_tables(table_id)
    );
END;
GO


/* =========================================================
   MIGRATION FOR OLD WALK-IN DATABASE
   ========================================================= */

IF OBJECT_ID(
    'dbo.walk_in_group_tables',
    'U'
) IS NOT NULL
AND COL_LENGTH(
    'dbo.walk_in_group_tables',
    'active'
) IS NULL
BEGIN
    ALTER TABLE dbo.walk_in_group_tables
    ADD active BIT NULL;
END;
GO


/* ---------------------------------------------------------
   Convert released_at -> active
   --------------------------------------------------------- */

IF OBJECT_ID(
    'dbo.walk_in_group_tables',
    'U'
) IS NOT NULL
AND COL_LENGTH(
    'dbo.walk_in_group_tables',
    'active'
) IS NOT NULL
BEGIN
    IF COL_LENGTH(
        'dbo.walk_in_group_tables',
        'released_at'
    ) IS NOT NULL
    BEGIN
        EXEC
        (
            '
            UPDATE dbo.walk_in_group_tables
            SET active =
                CASE
                    WHEN released_at IS NULL
                        THEN 1
                    ELSE 0
                END
            WHERE active IS NULL
            '
        );
    END
    ELSE
    BEGIN
        UPDATE dbo.walk_in_group_tables
        SET active = 1
        WHERE active IS NULL;
    END;
END;
GO


/* ---------------------------------------------------------
   Closed groups cannot have active members
   --------------------------------------------------------- */

UPDATE wgt
SET active = 0
FROM dbo.walk_in_group_tables wgt

JOIN dbo.walk_in_groups wg
    ON wg.walk_in_group_id =
       wgt.walk_in_group_id

WHERE
    wg.status = 'CLOSED'
    AND wgt.active = 1;
GO


/* ---------------------------------------------------------
   Remove duplicate active membership
   --------------------------------------------------------- */

;WITH duplicate_members AS
(
    SELECT
        walk_in_group_id,
        table_id,

        ROW_NUMBER() OVER
        (
            PARTITION BY table_id
            ORDER BY walk_in_group_id DESC
        ) AS rn

    FROM dbo.walk_in_group_tables

    WHERE active = 1
)

UPDATE wgt
SET active = 0

FROM dbo.walk_in_group_tables wgt

JOIN duplicate_members d
    ON d.walk_in_group_id =
       wgt.walk_in_group_id
   AND d.table_id =
       wgt.table_id

WHERE d.rn > 1;
GO


/* ---------------------------------------------------------
   Close empty active groups
   --------------------------------------------------------- */

UPDATE wg
SET
    status = 'CLOSED',
    closed_at =
        COALESCE(
            closed_at,
            SYSDATETIME()
        )

FROM dbo.walk_in_groups wg

WHERE
    wg.status = 'ACTIVE'

    AND NOT EXISTS
    (
        SELECT 1
        FROM dbo.walk_in_group_tables wgt

        WHERE
            wgt.walk_in_group_id =
                wg.walk_in_group_id

            AND wgt.active = 1
    );
GO


/* ---------------------------------------------------------
   Repair anchor
   --------------------------------------------------------- */

UPDATE wg

SET anchor_table_id =
(
    SELECT MIN(wgt.table_id)

    FROM dbo.walk_in_group_tables wgt

    WHERE
        wgt.walk_in_group_id =
            wg.walk_in_group_id

        AND wgt.active = 1
)

FROM dbo.walk_in_groups wg

WHERE
    wg.status = 'ACTIVE'

    AND NOT EXISTS
    (
        SELECT 1

        FROM dbo.walk_in_group_tables current_anchor

        WHERE
            current_anchor.walk_in_group_id =
                wg.walk_in_group_id

            AND current_anchor.table_id =
                wg.anchor_table_id

            AND current_anchor.active = 1
    );
GO


/* ---------------------------------------------------------
   Make active NOT NULL
   --------------------------------------------------------- */

IF EXISTS
(
    SELECT 1
    FROM sys.columns

    WHERE
        object_id =
            OBJECT_ID(
                'dbo.walk_in_group_tables'
            )

        AND name = 'active'
        AND is_nullable = 1
)
BEGIN
    ALTER TABLE dbo.walk_in_group_tables
    ALTER COLUMN active BIT NOT NULL;
END;
GO


/* ---------------------------------------------------------
   Default active = 1
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.default_constraints dc

    JOIN sys.columns c
        ON c.default_object_id =
           dc.object_id

    WHERE
        c.object_id =
            OBJECT_ID(
                'dbo.walk_in_group_tables'
            )

        AND c.name = 'active'
)
BEGIN
    ALTER TABLE dbo.walk_in_group_tables

    ADD CONSTRAINT
        DF_walk_in_group_tables_active

    DEFAULT 1 FOR active;
END;
GO


/* =========================================================
   20. INDEXES
   ========================================================= */


/* ---------------------------------------------------------
   Remove obsolete OPEN order index
   --------------------------------------------------------- */

IF EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name = 'ux_open_order_per_table'

        AND object_id =
            OBJECT_ID(
                'dbo.orders'
            )
)
BEGIN
    DROP INDEX
        ux_open_order_per_table
    ON dbo.orders;
END;
GO


/* ---------------------------------------------------------
   One OPEN walk-in order per table/anchor
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ux_open_order_per_walkin_table'

        AND object_id =
            OBJECT_ID(
                'dbo.orders'
            )
)
BEGIN
    CREATE UNIQUE INDEX
        ux_open_order_per_walkin_table

    ON dbo.orders(table_id)

    WHERE
        order_status = 'OPEN'
        AND reservation_id IS NULL;
END;
GO


/* ---------------------------------------------------------
   One OPEN Order per Reservation
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ux_open_order_per_reservation'

        AND object_id =
            OBJECT_ID(
                'dbo.orders'
            )
)
BEGIN
    CREATE UNIQUE INDEX
        ux_open_order_per_reservation

    ON dbo.orders(reservation_id)

    WHERE
        order_status = 'OPEN'
        AND reservation_id IS NOT NULL;
END;
GO


/* ---------------------------------------------------------
   Remove old Walk-in index
   --------------------------------------------------------- */

IF EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ux_active_walk_in_group_per_table'

        AND object_id =
            OBJECT_ID(
                'dbo.walk_in_group_tables'
            )
)
BEGIN
    DROP INDEX
        ux_active_walk_in_group_per_table

    ON dbo.walk_in_group_tables;
END;
GO


/* ---------------------------------------------------------
   Correct Walk-in active table index
   --------------------------------------------------------- */

IF EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ux_walk_in_group_active_table'

        AND object_id =
            OBJECT_ID(
                'dbo.walk_in_group_tables'
            )
)
BEGIN
    DROP INDEX
        ux_walk_in_group_active_table
    ON dbo.walk_in_group_tables;
END;
GO


CREATE UNIQUE INDEX
    ux_walk_in_group_active_table

ON dbo.walk_in_group_tables(table_id)

WHERE active = 1;
GO


/* ---------------------------------------------------------
   Walk-in group status
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ix_walk_in_group_status'

        AND object_id =
            OBJECT_ID(
                'dbo.walk_in_groups'
            )
)
BEGIN
    CREATE INDEX
        ix_walk_in_group_status

    ON dbo.walk_in_groups
    (
        status,
        walk_in_group_id
    );
END;
GO


/* ---------------------------------------------------------
   Walk-in group members
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ix_walk_in_group_tables_group_active'

        AND object_id =
            OBJECT_ID(
                'dbo.walk_in_group_tables'
            )
)
BEGIN
    CREATE INDEX
        ix_walk_in_group_tables_group_active

    ON dbo.walk_in_group_tables
    (
        walk_in_group_id,
        active,
        table_id
    );
END;
GO


/* ---------------------------------------------------------
   Unique Menu Item Name
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ux_menu_items_name'

        AND object_id =
            OBJECT_ID(
                'dbo.menu_items'
            )
)
BEGIN
    CREATE UNIQUE INDEX
        ux_menu_items_name

    ON dbo.menu_items(name);
END;
GO


/* ---------------------------------------------------------
   Pending Payment cleanup
   --------------------------------------------------------- */

;WITH pending_ranked AS
(
    SELECT
        payment_id,

        ROW_NUMBER() OVER
        (
            PARTITION BY order_id
            ORDER BY payment_id DESC
        ) AS rn

    FROM dbo.payments

    WHERE payment_status = 'PENDING'
)

UPDATE p

SET payment_status = 'FAILED'

FROM dbo.payments p

JOIN pending_ranked r
    ON r.payment_id =
       p.payment_id

WHERE r.rn > 1;
GO


/* ---------------------------------------------------------
   One Pending Payment per Order
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ux_pending_payment_per_order'

        AND object_id =
            OBJECT_ID(
                'dbo.payments'
            )
)
BEGIN
    CREATE UNIQUE INDEX
        ux_pending_payment_per_order

    ON dbo.payments(order_id)

    WHERE payment_status = 'PENDING';
END;
GO


/* ---------------------------------------------------------
   Reservation table lookup
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ix_reservation_tables_table'

        AND object_id =
            OBJECT_ID(
                'dbo.reservation_tables'
            )
)
BEGIN
    CREATE INDEX
        ix_reservation_tables_table

    ON dbo.reservation_tables
    (
        table_id,
        reservation_id
    );
END;
GO


/* ---------------------------------------------------------
   Reservation schedule
   --------------------------------------------------------- */

IF EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ix_reservation_schedule'

        AND object_id =
            OBJECT_ID(
                'dbo.reservations'
            )
)
BEGIN
    DROP INDEX
        ix_reservation_schedule

    ON dbo.reservations;
END;
GO


CREATE INDEX
    ix_reservation_schedule

ON dbo.reservations
(
    reservation_date,
    status,
    start_time,
    end_time
);
GO


/* ---------------------------------------------------------
   Reservation status/date
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ix_reservation_status_date'

        AND object_id =
            OBJECT_ID(
                'dbo.reservations'
            )
)
BEGIN
    CREATE INDEX
        ix_reservation_status_date

    ON dbo.reservations
    (
        status,
        reservation_date,
        start_time
    );
END;
GO


/* ---------------------------------------------------------
   Order detail lookup
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ix_order_details_order_status'

        AND object_id =
            OBJECT_ID(
                'dbo.order_details'
            )
)
BEGIN
    CREATE INDEX
        ix_order_details_order_status

    ON dbo.order_details
    (
        order_id,
        status
    );
END;
GO


/* ---------------------------------------------------------
   Payment lookup
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ix_payments_order_status'

        AND object_id =
            OBJECT_ID(
                'dbo.payments'
            )
)
BEGIN
    CREATE INDEX
        ix_payments_order_status

    ON dbo.payments
    (
        order_id,
        payment_status
    );
END;
GO


/* ---------------------------------------------------------
   Recipe reverse lookup
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ix_recipe_inventory'

        AND object_id =
            OBJECT_ID(
                'dbo.menu_item_ingredients'
            )
)
BEGIN
    CREATE INDEX
        ix_recipe_inventory

    ON dbo.menu_item_ingredients
    (
        inventory_item_id,
        menu_item_id
    );
END;
GO


/* ---------------------------------------------------------
   Inventory transaction history
   --------------------------------------------------------- */

IF NOT EXISTS
(
    SELECT 1

    FROM sys.indexes

    WHERE
        name =
            'ix_inventory_tx_item_date'

        AND object_id =
            OBJECT_ID(
                'dbo.inventory_transactions'
            )
)
BEGIN
    CREATE INDEX
        ix_inventory_tx_item_date

    ON dbo.inventory_transactions
    (
        inventory_item_id,
        created_at
    );
END;
GO


/* =========================================================
   21. DEMO STAFF
   ========================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.staff
)
BEGIN
    INSERT INTO dbo.staff
    (
        full_name,
        username,
        password,
        role,
        account_status
    )

    VALUES

    (
        N'Quản lý demo',
        'manager',
        '$2a$10$RM3jWaEhouB8kFmzfjzA1eTAUcPnPYiOWKIhG7yRqAQTR8PYmxWUe',
        'MANAGER',
        'ACTIVE'
    ),

    (
        N'Phục vụ demo',
        'waiter',
        '$2a$10$66y6hquJPKOCaERX53KCieskzwtcM8YkpKjJSWZc22uypHf91fvBy',
        'WAITER',
        'ACTIVE'
    ),

    (
        N'Bếp demo',
        'kitchen',
        '$2a$10$DTJHPSTSu71FEDQZl0jzSeQFr6S71/e3JPJY3ved5CRPcVPUD8n/2',
        'KITCHEN',
        'ACTIVE'
    ),

    (
        N'Lễ tân demo',
        'reception',
        '$2a$10$qyoW.TQoF3zFabxZfpU6guzO48Ez7B4naPtk7pe/Ve32ov4mfaN2a',
        'RECEPTIONIST',
        'ACTIVE'
    );
END;
GO


/* =========================================================
   22. DEMO RESTAURANT TABLES
   ========================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.restaurant_tables
)
BEGIN
    INSERT INTO dbo.restaurant_tables
    (
        table_number,
        capacity,
        status,
        qr_token,
        active
    )

    VALUES

    (
        'T01',
        4,
        'AVAILABLE',
        't01demo0123456789abcdef0123456789',
        1
    ),

    (
        'T02',
        4,
        'AVAILABLE',
        't02demo0123456789abcdef0123456789',
        1
    ),

    (
        'T03',
        4,
        'AVAILABLE',
        't03demo0123456789abcdef0123456789',
        1
    ),

    (
        'T04',
        4,
        'AVAILABLE',
        't04demo0123456789abcdef0123456789',
        1
    ),

    (
        'T05',
        6,
        'AVAILABLE',
        't05demo0123456789abcdef0123456789',
        1
    ),

    (
        'T06',
        6,
        'AVAILABLE',
        't06demo0123456789abcdef0123456789',
        1
    ),

    (
        'T07',
        6,
        'AVAILABLE',
        't07demo0123456789abcdef0123456789',
        1
    ),

    (
        'T08',
        6,
        'AVAILABLE',
        't08demo0123456789abcdef0123456789',
        1
    );
END;
GO


/* =========================================================
   23. TABLE LAYOUT

       C1    C2    C3    C4

   R1  T01   T02   T03   T04
   R2  T05   T06   T07   T08
   ========================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.table_layouts
)
BEGIN
    INSERT INTO dbo.table_layouts
    (
        table_id,
        area_code,
        row_no,
        position_no,
        merge_enabled
    )

    SELECT
        t.table_id,
        v.area_code,
        v.row_no,
        v.position_no,
        1

    FROM
    (
        VALUES
        ('T01','A',1,1),
        ('T02','A',1,2),
        ('T03','A',1,3),
        ('T04','A',1,4),

        ('T05','A',2,1),
        ('T06','A',2,2),
        ('T07','A',2,3),
        ('T08','A',2,4)
    ) v
    (
        table_number,
        area_code,
        row_no,
        position_no
    )

    JOIN dbo.restaurant_tables t
        ON t.table_number =
           v.table_number;
END;
GO


/* =========================================================
   24. DEFAULT OPENING HOURS
   ========================================================= */

INSERT INTO dbo.restaurant_opening_hours
(
    day_of_week,
    open_time,
    close_time,
    is_closed
)

SELECT
    v.day_of_week,
    v.open_time,
    v.close_time,
    v.is_closed

FROM
(
    VALUES

    (
        1,
        CAST('10:00' AS TIME),
        CAST('22:00' AS TIME),
        CAST(0 AS BIT)
    ),

    (
        2,
        CAST('10:00' AS TIME),
        CAST('22:00' AS TIME),
        CAST(0 AS BIT)
    ),

    (
        3,
        CAST('10:00' AS TIME),
        CAST('22:00' AS TIME),
        CAST(0 AS BIT)
    ),

    (
        4,
        CAST('10:00' AS TIME),
        CAST('22:00' AS TIME),
        CAST(0 AS BIT)
    ),

    (
        5,
        CAST('10:00' AS TIME),
        CAST('23:00' AS TIME),
        CAST(0 AS BIT)
    ),

    (
        6,
        CAST('09:00' AS TIME),
        CAST('23:00' AS TIME),
        CAST(0 AS BIT)
    ),

    (
        7,
        CAST('09:00' AS TIME),
        CAST('22:00' AS TIME),
        CAST(0 AS BIT)
    )

) v
(
    day_of_week,
    open_time,
    close_time,
    is_closed
)

WHERE NOT EXISTS
(
    SELECT 1

    FROM dbo.restaurant_opening_hours h

    WHERE
        h.day_of_week =
            v.day_of_week
);
GO


/* =========================================================
   25. DEMO MENU CATEGORIES
   ========================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.menu_categories
)
BEGIN
    INSERT INTO dbo.menu_categories
    (
        name,
        active
    )

    VALUES

    (
        N'Món chính',
        1
    ),

    (
        N'Món ăn kèm',
        1
    ),

    (
        N'Đồ uống',
        1
    );
END;
GO


/* =========================================================
   26. DEMO INVENTORY
   ========================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.inventory_items
)
BEGIN
    INSERT INTO dbo.inventory_items
    (
        name,
        unit,
        quantity,
        reserved_quantity,
        low_stock_threshold,
        active
    )

    VALUES

    (
        N'Thịt bò',
        N'gram',
        8000,
        0,
        1500,
        1
    ),

    (
        N'Gạo',
        N'gram',
        10000,
        0,
        2000,
        1
    ),

    (
        N'Khoai tây',
        N'gram',
        7000,
        0,
        1500,
        1
    ),

    (
        N'Nước ngọt',
        N'ml',
        12000,
        0,
        3000,
        1
    ),

    (
        N'Dầu ăn',
        N'ml',
        5000,
        0,
        1000,
        1
    );
END;
GO


/* =========================================================
   27. DEMO MENU ITEMS
   ========================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.menu_items
)
BEGIN
    DECLARE @main BIGINT =
    (
        SELECT category_id
        FROM dbo.menu_categories
        WHERE name = N'Món chính'
    );


    DECLARE @side BIGINT =
    (
        SELECT category_id
        FROM dbo.menu_categories
        WHERE name = N'Món ăn kèm'
    );


    DECLARE @drink BIGINT =
    (
        SELECT category_id
        FROM dbo.menu_categories
        WHERE name = N'Đồ uống'
    );


    INSERT INTO dbo.menu_items
    (
        category_id,
        name,
        description,
        price,
        active,
        inventory_available
    )

    VALUES

    (
        @main,
        N'Bò áp chảo',
        N'Thịt bò áp chảo dùng kèm sốt nhà hàng',
        220000,
        1,
        0
    ),

    (
        @main,
        N'Cơm chiên bò',
        N'Cơm chiên nóng với thịt bò',
        85000,
        1,
        0
    ),

    (
        @side,
        N'Khoai tây chiên',
        N'Khoai tây chiên giòn',
        45000,
        1,
        0
    ),

    (
        @drink,
        N'Nước ngọt',
        N'Ly nước ngọt 330ml',
        25000,
        1,
        0
    );
END;
GO


/* =========================================================
   28. DEMO RECIPES
   ========================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.menu_item_ingredients
)
BEGIN
    INSERT INTO dbo.menu_item_ingredients
    (
        menu_item_id,
        inventory_item_id,
        required_quantity
    )

    SELECT
        m.menu_item_id,
        i.inventory_item_id,
        v.qty

    FROM
    (
        VALUES

        (
            N'Bò áp chảo',
            N'Thịt bò',
            CAST(200 AS DECIMAL(18,3))
        ),

        (
            N'Bò áp chảo',
            N'Dầu ăn',
            CAST(15 AS DECIMAL(18,3))
        ),

        (
            N'Cơm chiên bò',
            N'Gạo',
            CAST(180 AS DECIMAL(18,3))
        ),

        (
            N'Cơm chiên bò',
            N'Thịt bò',
            CAST(80 AS DECIMAL(18,3))
        ),

        (
            N'Cơm chiên bò',
            N'Dầu ăn',
            CAST(10 AS DECIMAL(18,3))
        ),

        (
            N'Khoai tây chiên',
            N'Khoai tây',
            CAST(180 AS DECIMAL(18,3))
        ),

        (
            N'Khoai tây chiên',
            N'Dầu ăn',
            CAST(20 AS DECIMAL(18,3))
        ),

        (
            N'Nước ngọt',
            N'Nước ngọt',
            CAST(330 AS DECIMAL(18,3))
        )

    ) v
    (
        menu_name,
        inventory_name,
        qty
    )

    JOIN dbo.menu_items m
        ON m.name =
           v.menu_name

    JOIN dbo.inventory_items i
        ON i.name =
           v.inventory_name;
END;
GO


/* =========================================================
   29. INITIAL INVENTORY HISTORY
   ========================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.inventory_transactions
)
BEGIN
    DECLARE @managerId BIGINT =
    (
        SELECT TOP 1
            staff_id

        FROM dbo.staff

        WHERE role = 'MANAGER'

        ORDER BY staff_id
    );


    INSERT INTO dbo.inventory_transactions
    (
        inventory_item_id,
        reference_order_id,
        created_by_staff_id,
        quantity_change,
        unit_cost,
        transaction_type,
        description
    )

    SELECT
        i.inventory_item_id,
        NULL,
        @managerId,
        i.quantity,
        NULL,
        'RESTOCK',
        N'Tồn kho ban đầu'

    FROM dbo.inventory_items i

    WHERE i.quantity > 0;
END;
GO


/* =========================================================
   30. REFRESH MENU AVAILABILITY

   Available =
   quantity - reserved_quantity

   Một món bán được khi:
   - Có ít nhất một Recipe
   - Inventory Item active
   - Available đủ cho ít nhất một phần
   ========================================================= */

UPDATE m

SET inventory_available =
    CASE

        WHEN EXISTS
        (
            SELECT 1

            FROM dbo.menu_item_ingredients r

            WHERE
                r.menu_item_id =
                    m.menu_item_id
        )

        AND NOT EXISTS
        (
            SELECT 1

            FROM dbo.menu_item_ingredients r

            JOIN dbo.inventory_items i
                ON i.inventory_item_id =
                   r.inventory_item_id

            WHERE
                r.menu_item_id =
                    m.menu_item_id

                AND
                (
                    i.active = 0

                    OR

                    (
                        i.quantity
                        -
                        i.reserved_quantity
                    ) < r.required_quantity
                )
        )

        THEN 1

        ELSE 0

    END

FROM dbo.menu_items m;
GO


/* =========================================================
   31. CHECK INVENTORY STATUS
   ========================================================= */

SELECT
    inventory_item_id,
    name,
    quantity AS on_hand,
    reserved_quantity AS reserved,
    quantity - reserved_quantity AS available,
    unit,
    low_stock_threshold,

    CASE
        WHEN
            quantity - reserved_quantity
            <= low_stock_threshold
            THEN 'LOW STOCK'
        ELSE 'OK'
    END AS stock_status

FROM dbo.inventory_items

ORDER BY name;
GO


/* =========================================================
   32. WALK-IN GROUP CHECK
   ========================================================= */

SELECT
    wg.walk_in_group_id,
    wg.anchor_table_id,

    anchor_table.table_number
        AS anchor_table,

    wg.status,
    wg.created_at,
    wg.closed_at

FROM dbo.walk_in_groups wg

JOIN dbo.restaurant_tables anchor_table
    ON anchor_table.table_id =
       wg.anchor_table_id

ORDER BY
    wg.walk_in_group_id DESC;
GO


SELECT
    wgt.walk_in_group_id,
    wgt.table_id,
    t.table_number,
    wgt.active

FROM dbo.walk_in_group_tables wgt

JOIN dbo.restaurant_tables t
    ON t.table_id =
       wgt.table_id

ORDER BY
    wgt.walk_in_group_id,
    wgt.table_id;
GO


/* =========================================================
   33. DATABASE SUMMARY
   ========================================================= */

PRINT '';
PRINT '=========================================================';
PRINT 'RMS_SERVLET DATABASE READY';
PRINT '=========================================================';
PRINT '- Staff authentication & roles';
PRINT '- Restaurant table management';
PRINT '- Table QR codes';
PRINT '- Table layouts';
PRINT '- Table adjacency ALLOW / BLOCK';
PRINT '- Connected table merging';
PRINT '- Weekly opening hours';
PRINT '- Special opening dates';
PRINT '- Menu categories';
PRINT '- Menu items';
PRINT '- Menu recipes';
PRINT '- Inventory management';
PRINT '- Inventory On Hand / Reserved / Available';
PRINT '- Inventory reservation on Submit Order';
PRINT '- Inventory release on Cancel PENDING';
PRINT '- Inventory consume on Kitchen Mark Ready';
PRINT '- Order ingredient snapshot';
PRINT '- Inventory transaction history';
PRINT '- Reservations';
PRINT '- Multi-table reservation';
PRINT '- Reservation Best Fit';
PRINT '- Check-in';
PRINT '- Reservation cancel';
PRINT '- No-show';
PRINT '- Customer ordering';
PRINT '- Kitchen PENDING -> READY';
PRINT '- Waiter READY -> SERVED';
PRINT '- Cash / Online payment';
PRINT '- Walk-in group';
PRINT '- Shared walk-in order';
PRINT '- Table release';
PRINT '- Automatic anchor transfer';
PRINT '- Database indexes';
PRINT '=========================================================';
GO