document.addEventListener("DOMContentLoaded", () => {
  const token = localStorage.getItem("token");
  if (!token) {
    window.location.href = "/auth/login";
    return;
  }

  document.getElementById("navUsername").textContent =
    localStorage.getItem("username") || "User";

  const productId = localStorage.getItem("selectedProductId");
  const productName = localStorage.getItem("selectedProductName");

  if (!productId) {
    showMessage("Please pick a product from the Products page first.", "error");
  } else {
    document.getElementById("productId").value = productId;
    document.getElementById("productName").textContent = productName || "this product";
  }

  document.getElementById("reviewForm").addEventListener("submit", createReview);
});

async function createReview(e) {
  e.preventDefault();

  const token = localStorage.getItem("token");
  const productId = document.getElementById("productId").value;
  const rating = document.getElementById("rating").value.trim();
  const reviewText = document.getElementById("reviewText").value;

  try {
    const res = await fetch("/api/review/create", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ productId, rating, reviewText }),
    });

    const data = await res.json();

    if (data.success) {
      showMessage(data.message, "success");
      document.getElementById("rating").value = "";
      document.getElementById("reviewText").value = "";
    } else {
      showMessage(data.message, "error");
    }
  } catch (err) {
    showMessage("Cannot connect to server. Is the app running?", "error");
  }
}

function showMessage(msg, type) {
  const el = document.getElementById("message");
  el.textContent = msg;
  el.className = `message ${type}`;
}

function logout() {
  localStorage.clear();
  window.location.href = "/auth/login";
}
