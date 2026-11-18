---CREATE_COMMENT FUNCTION----
CREATE OR REPLACE FUNCTION create_comment(
    p_member_id INTEGER,
    p_review_id INTEGER,
    p_comment_text TEXT,
    p_parent_comment_id INTEGER DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_review_owner INTEGER;
    v_parent_review INTEGER;
    v_comment_id INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM member WHERE id = p_member_id) THEN
        RAISE EXCEPTION 'Member does not exist';
    END IF;

    SELECT member_id INTO v_review_owner
    FROM review
    WHERE id = p_review_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Review does not exist';
    END IF;

    IF p_comment_text IS NULL OR TRIM(p_comment_text) = '' THEN
        RAISE EXCEPTION 'Comment cannot be empty';
    END IF;

    IF p_parent_comment_id IS NULL THEN
        IF v_review_owner = p_member_id THEN
            RAISE EXCEPTION 'You cannot comment on your own review, but you can reply to other comments';
        END IF;
    ELSE
        SELECT review_id INTO v_parent_review
        FROM comment
        WHERE id = p_parent_comment_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Parent comment does not exist';
        END IF;

        IF v_parent_review <> p_review_id THEN
            RAISE EXCEPTION 'Parent comment belongs to a different review';
        END IF;
    END IF;

    INSERT INTO comment (review_id, member_id, parent_comment_id, comment_text)
    VALUES (p_review_id, p_member_id, p_parent_comment_id, p_comment_text)
    RETURNING id INTO v_comment_id;

    RETURN v_comment_id;
END;
$$;

