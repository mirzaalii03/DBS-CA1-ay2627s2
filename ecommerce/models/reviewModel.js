const { query } = require("../config/database");

const createReview = async (memberId, productId, rating, reviewText) => {
  const result = await query(
    "SELECT create_review($1, $2, $3, $4) AS id",
    [memberId, productId, rating, reviewText]
  );
  return result.rows[0].id;
};

const updateReview = async (memberId, reviewId, rating, reviewText) => {
  const result = await query(
    "SELECT update_review($1, $2, $3, $4) AS id",
    [memberId, reviewId, rating, reviewText]
  );
  return result.rows[0].id;
};

const deleteReview = async (memberId, reviewId) => {
  const result = await query(
    "SELECT delete_review($1, $2) AS id",
    [memberId, reviewId]
  );
  return result.rows[0].id;
};

const getReviews = async (memberId) => {
  const result = await query(
    `SELECT review_id, product_id, product_name, rating, review_text, last_updated
     FROM get_reviews($1)`,
    [memberId]
  );
  return result.rows;
};

module.exports = { createReview, updateReview, deleteReview, getReviews };