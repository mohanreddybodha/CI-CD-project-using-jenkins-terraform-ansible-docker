const pingBtn = document.getElementById("pingBtn");
const pingResult = document.getElementById("pingResult");
const fbForm = document.getElementById("fbForm");
const fbResult = document.getElementById("fbResult");

pingBtn.addEventListener("click", async () => {
  pingResult.textContent = "Checking…";
  try {
    const res = await fetch("/api/ping");
    const data = await res.json();
    pingResult.textContent = data.ok ? "✅ Healthy" : "❌ Unhealthy";
  } catch (e) {
    pingResult.textContent = "❌ Error";
  }
});

fbForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  const name = document.getElementById("name").value.trim();
  const message = document.getElementById("message").value.trim();
  const res = await fetch("/api/feedback", {
    method: "POST",
    headers: { "Content-Type": "application/json"},
    body: JSON.stringify({ name, message })
  });
  const data = await res.json();
  fbResult.textContent = JSON.stringify(data, null, 2);
  fbForm.reset();
});
