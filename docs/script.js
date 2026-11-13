// Google Drive APK indirme bağlantısını buraya yapıştırın:
const DRIVE_DOWNLOAD_URL = 'https://drive.google.com/drive/folders/1p6Bit4Gzi1WCAHVhuxZX_8epwRBz1jCQ?usp=sharing';

document.querySelectorAll('#drive-download-btn, #drive-download-btn-bottom').forEach((el) => {
  el.setAttribute('href', DRIVE_DOWNLOAD_URL);
});

// Canlı örnek oturum sayacı
const clockEl = document.getElementById('hero-clock');
if (clockEl) {
  let seconds = 1 * 3600 + 42 * 60 + 18;
  const pad = (n) => String(n).padStart(2, '0');
  setInterval(() => {
    seconds += 1;
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    clockEl.textContent = `${pad(h)}:${pad(m)}:${pad(s)}`;
  }, 1000);
}

