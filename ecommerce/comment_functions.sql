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

---GET_COMMENTS FUNCTION----
CREATE OR REPLACE FUNCTION get_comments(
    p_review_id INTEGER
)
RETURNS TABLE (
    comment_id INTEGER,
    review_id INTEGER,
    member_id INTEGER,
    username VARCHAR,
    parent_comment_id INTEGER,
    comment_text TEXT,
    created_at TIMESTAMP,
    depth INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM review r WHERE r.id = p_review_id) THEN
        RAISE EXCEPTION 'Review does not exist';
    END IF;

    RETURN QUERY
    WITH RECURSIVE thread AS (
        SELECT c.id, c.review_id, c.member_id, c.parent_comment_id,
               c.comment_text, c.created_at,
               0 AS depth,
               ARRAY[c.id] AS path
        FROM comment c
        WHERE c.review_id = p_review_id
          AND c.parent_comment_id IS NULL

        UNION ALL

        SELECT c.id, c.review_id, c.member_id, c.parent_comment_id,
               c.comment_text, c.created_at,
               t.depth + 1,
               t.path || c.id
        FROM comment c
        JOIN thread t ON c.parent_comment_id = t.id
    )
    SELECT t.id, t.review_id, t.member_id, m.username, t.parent_comment_id,
           t.comment_text, t.created_at, t.depth
    FROM thread t
    JOIN member m ON m.id = t.member_id
    ORDER BY t.path;
END;
$$;

---DELETE_COMMENT FUNCTION----
CREATE OR REPLACE FUNCTION delete_comment(
    p_member_id INTEGER,
    p_comment_id INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_owner_id INTEGER;
BEGIN
    SELECT member_id INTO v_owner_id
    FROM comment
    WHERE id = p_comment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Comment does not exist';
    END IF;

    IF v_owner_id <> p_member_id THEN
        RAISE EXCEPTION 'You can only delete your own comments';
    END IF;

    DELETE FROM comment
    WHERE id = p_comment_id;

    RETURN p_comment_id;
END;
$$;
