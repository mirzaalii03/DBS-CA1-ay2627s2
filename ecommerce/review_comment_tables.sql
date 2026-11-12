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

