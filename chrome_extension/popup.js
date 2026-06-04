document.addEventListener('DOMContentLoaded', () => {
  const dot = document.getElementById('dot');
  const statusText = document.getElementById('statusText');
  const openBtn = document.getElementById('openBtn');

  async function updateStatus() {
    dot.className = 'dot check';
    statusText.textContent = 'جاري الفحص...';
    openBtn.disabled = true;
    try {
      const resp = await chrome.runtime.sendMessage({ type: 'CHECK_CONNECTION' });
      if (resp && resp.connected) {
        dot.className = 'dot on';
        statusText.textContent = '🟢 متصل';
        openBtn.disabled = false;
      } else {
        dot.className = 'dot off';
        statusText.textContent = '🔴 البرنامج غير شغال';
        openBtn.disabled = false;
      }
    } catch {
      dot.className = 'dot off';
      statusText.textContent = '🔴 الإضافة غير جاهزة';
      openBtn.disabled = false;
    }
  }

  openBtn.addEventListener('click', () => {
    chrome.runtime.sendMessage({ type: 'OPEN_APP' });
  });

  updateStatus();
  setInterval(updateStatus, 5000);
});
