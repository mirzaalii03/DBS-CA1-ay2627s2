---GET_SALE_ORDER_SUMMARY FUNCTION----
CREATE OR REPLACE FUNCTION get_sale_order_summary(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_product_type VARCHAR DEFAULT NULL,
    p_gender CHAR DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL,
    p_age_group VARCHAR DEFAULT NULL,
    p_sort_by VARCHAR DEFAULT 'DATE_DESC',
    p_group_by VARCHAR DEFAULT 'NONE'
)
RETURNS TABLE (
    group_label TEXT,
    order_id INTEGER,
    order_date TIMESTAMP,
    customer_name VARCHAR,
    gender CHAR(1),
    age_group TEXT,
    product_name VARCHAR,
    category VARCHAR,
    quantity NUMERIC,
    unit_price NUMERIC,
    total_amount NUMERIC,
    status VARCHAR,
    order_count BIGINT,
    avg_order_value NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_product_type := NULLIF(TRIM(p_product_type), '');
    p_gender := UPPER(NULLIF(TRIM(p_gender), ''));
    p_status := UPPER(NULLIF(TRIM(p_status), ''));
    p_age_group := NULLIF(TRIM(p_age_group), '');
    p_sort_by := UPPER(COALESCE(NULLIF(TRIM(p_sort_by), ''), 'DATE_DESC'));
    p_group_by := UPPER(COALESCE(NULLIF(TRIM(p_group_by), ''), 'NONE'));

    IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL
       AND p_start_date > p_end_date THEN
        RAISE EXCEPTION 'Start date cannot be after end date';
    END IF;

    IF p_gender IS NOT NULL AND p_gender NOT IN ('M', 'F') THEN
        RAISE EXCEPTION 'Gender must be M or F';
    END IF;

    IF p_status IS NOT NULL AND p_status NOT IN ('COMPLETED', 'PACKING', 'CANCELLED') THEN
        RAISE EXCEPTION 'Status must be COMPLETED, PACKING or CANCELLED';
    END IF;

    IF p_age_group IS NOT NULL AND p_age_group NOT IN ('Under 30', '30-39', '40 and above') THEN
        RAISE EXCEPTION 'Age group must be Under 30, 30-39 or 40 and above';
    END IF;

    IF p_sort_by NOT IN ('DATE_DESC', 'DATE_ASC', 'AMOUNT_DESC', 'AMOUNT_ASC', 'ORDERS_DESC', 'NAME_ASC') THEN
        RAISE EXCEPTION 'Invalid sort option';
    END IF;

    IF p_group_by NOT IN ('NONE', 'PRODUCT', 'CATEGORY', 'GENDER', 'AGE_GROUP', 'MEMBER') THEN
        RAISE EXCEPTION 'Invalid group option';
    END IF;

    IF p_group_by = 'NONE' THEN
        RETURN QUERY
        WITH base AS (
            SELECT so.id AS o_id,
                   so.order_datetime AS o_date,
                   m.username AS cust,
                   m.gender AS gen,
                   CASE WHEN DATE_PART('year', AGE(m.dob)) < 30 THEN 'Under 30'
                        WHEN DATE_PART('year', AGE(m.dob)) < 40 THEN '30-39'
                        ELSE '40 and above' END AS age_grp,
                   p.name AS p_name,
                   p.product_type AS p_type,
                   soi.quantity AS qty,
                   p.unit_price AS price,
                   soi.quantity * p.unit_price AS amount,
                   so.status AS st
            FROM sale_order so
            JOIN member m ON m.id = so.member_id
            JOIN sale_order_item soi ON soi.sale_order_id = so.id
            JOIN product p ON p.id = soi.product_id
            WHERE (p_start_date IS NULL OR so.order_datetime >= p_start_date)
              AND (p_end_date IS NULL OR so.order_datetime < p_end_date + 1)
              AND (p_product_type IS NULL OR p.product_type = p_product_type)
              AND (p_gender IS NULL OR m.gender = p_gender)
              AND (p_status IS NULL OR so.status = p_status)
        )
        SELECT NULL::TEXT, b.o_id, b.o_date, b.cust, b.gen, b.age_grp,
               b.p_name, b.p_type, b.qty, b.price, b.amount, b.st,
               NULL::BIGINT, NULL::NUMERIC
        FROM base b
        WHERE (p_age_group IS NULL OR b.age_grp = p_age_group)
        ORDER BY
            CASE WHEN p_sort_by = 'DATE_ASC' THEN b.o_date END ASC,
            CASE WHEN p_sort_by = 'DATE_DESC' THEN b.o_date END DESC,
            CASE WHEN p_sort_by = 'AMOUNT_ASC' THEN b.amount END ASC,
            CASE WHEN p_sort_by = 'AMOUNT_DESC' THEN b.amount END DESC,
            CASE WHEN p_sort_by = 'NAME_ASC' THEN b.cust END ASC,
            b.o_id, b.p_name;
    ELSE
        RETURN QUERY
        WITH base AS (
            SELECT so.id AS o_id,
                   m.username AS cust,
                   m.gender AS gen,
                   CASE WHEN DATE_PART('year', AGE(m.dob)) < 30 THEN 'Under 30'
                        WHEN DATE_PART('year', AGE(m.dob)) < 40 THEN '30-39'
                        ELSE '40 and above' END AS age_grp,
                   p.name AS p_name,
                   p.product_type AS p_type,
                   soi.quantity AS qty,
                   soi.quantity * p.unit_price AS amount
            FROM sale_order so
            JOIN member m ON m.id = so.member_id
            JOIN sale_order_item soi ON soi.sale_order_id = so.id
            JOIN product p ON p.id = soi.product_id
            WHERE (p_start_date IS NULL OR so.order_datetime >= p_start_date)
              AND (p_end_date IS NULL OR so.order_datetime < p_end_date + 1)
              AND (p_product_type IS NULL OR p.product_type = p_product_type)
              AND (p_gender IS NULL OR m.gender = p_gender)
              AND (p_status IS NULL OR so.status = p_status)
        )
        SELECT g.label,
               NULL::INTEGER, NULL::TIMESTAMP, NULL::VARCHAR, NULL::CHAR(1),
               NULL::TEXT, NULL::VARCHAR, NULL::VARCHAR,
               SUM(g.qty),
               NULL::NUMERIC,
               SUM(g.amount),
               NULL::VARCHAR,
               COUNT(DISTINCT g.o_id),
               ROUND(SUM(g.amount) / COUNT(DISTINCT g.o_id), 2)
        FROM (
            SELECT CASE p_group_by
                       WHEN 'PRODUCT' THEN b.p_name::TEXT
                       WHEN 'CATEGORY' THEN b.p_type::TEXT
                       WHEN 'GENDER' THEN b.gen::TEXT
                       WHEN 'AGE_GROUP' THEN b.age_grp
                       WHEN 'MEMBER' THEN b.cust::TEXT
                   END AS label,
                   b.o_id, b.qty, b.amount
            FROM base b
            WHERE (p_age_group IS NULL OR b.age_grp = p_age_group)
        ) g
        GROUP BY g.label
        ORDER BY
            CASE WHEN p_sort_by = 'AMOUNT_ASC' THEN SUM(g.amount) END ASC,
            CASE WHEN p_sort_by = 'AMOUNT_DESC' THEN SUM(g.amount) END DESC,
            CASE WHEN p_sort_by = 'ORDERS_DESC' THEN COUNT(DISTINCT g.o_id) END DESC,
            g.label;
    END IF;
END;
$$;

