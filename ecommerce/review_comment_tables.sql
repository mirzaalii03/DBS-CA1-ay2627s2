---CREATING A REVIEW TABLE----
CREATE TABLE review (
    id SERIAL PRIMARY KEY,
    member_id INTEGER NOT NULL REFERENCES member(id),
    product_id INTEGER NOT NULL REFERENCES product(id),
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    last_updated TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (member_id, product_id)
);

---CREATING A COMMENT TABLE----
CREATE TABLE comment (
    id SERIAL PRIMARY KEY,
    review_id INTEGER NOT NULL REFERENCES review(id) ON DELETE CASCADE,
    member_id INTEGER NOT NULL REFERENCES member(id),
    parent_comment_id INTEGER REFERENCES comment(id) ON DELETE CASCADE,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);