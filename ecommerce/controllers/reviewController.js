const reviewModel = require("../models/reviewModel");

const toNull = (value) => (value === "" || value === undefined ? null : value);

const handleError = (res, err) => {
  if (err.code === "P0001") {
    return res.status(400).json({ success: false, message: err.message });
  }
  if (err.code === "22P02") {
    return res.status(400).json({ success: false, message: "Please enter valid numbers." });
  }
  console.error(err);
  res.status(500).json({ success: false, message: "Server error." });
};

const createReview = async (req, res) => {
  try {
    const memberId = req.user.id;
    const { productId, rating, reviewText } = req.body;
    const reviewId = await reviewModel.createReview(
      memberId,
      toNull(productId),
      toNull(rating),
      reviewText
    );
    res.status(201).json({ success: true, message: "Review created.", reviewId });
  } catch (err) {
    handleError(res, err);
  }
};

const getReviews = async (req, res) => {
  try {
    const reviews = await reviewModel.getReviews(req.user.id);
    res.json({ success: true, reviews });
  } catch (err) {
    handleError(res, err);
  }
};

const updateReview = async (req, res) => {
  try {
    const memberId = req.user.id;
    const { id } = req.params;
    const { rating, reviewText } = req.body;
    await reviewModel.updateReview(memberId, id, toNull(rating), reviewText);
    res.json({ success: true, message: "Review updated." });
  } catch (err) {
    handleError(res, err);
  }
};

const deleteReview = async (req, res) => {
  try {
    const memberId = req.user.id;
    const { id } = req.params;
    await reviewModel.deleteReview(memberId, id);
    res.json({ success: true, message: "Review deleted." });
  } catch (err) {
    handleError(res, err);
  }
};

module.exports = { createReview, getReviews, updateReview, deleteReview };
