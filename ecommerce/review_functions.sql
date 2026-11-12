---CREATE_REVIEW FUNCTION----
CREATE OR REPLACE FUNCTION create_review(
    p_member_id INTEGER,
    p_product_id INTEGER,
    p_rating INTEGER,
    p_review_text TEXT
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_review_id INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM member WHERE id = p_member_id) THEN
        RAISE EXCEPTION 'Member does not exist';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM product WHERE id = p_product_id) THEN
        RAISE EXCEPTION 'Product does not exist';
    END IF;

    IF p_rating IS NULL OR p_rating < 1 OR p_rating > 5 THEN
        RAISE EXCEPTION 'Rating must be between 1 and 5';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM sale_order so
        JOIN sale_order_item soi ON soi.sale_order_id = so.id
        WHERE so.member_id = p_member_id
          AND soi.product_id = p_product_id
          AND so.status = 'COMPLETED'
    ) THEN
        RAISE EXCEPTION 'You can only review products from completed orders';
    END IF;

    IF EXISTS (
        SELECT 1 FROM review
        WHERE member_id = p_member_id AND product_id = p_product_id
    ) THEN
        RAISE EXCEPTION 'You have already reviewed this product';
    END IF;

    INSERT INTO review (member_id, product_id, rating, review_text)
    VALUES (p_member_id, p_product_id, p_rating, p_review_text)
    RETURNING id INTO v_review_id;

    RETURN v_review_id;
END;
$$;