/* =============================================================================
   Miqotul Khoir TV Masjid — Landing Page Scripts
   Ref: TASK-005
   ============================================================================= */

"use strict";

// --- Navbar scroll state -----------------------------------------------------
// Menambah class `.scrolled` pada navbar saat halaman di-scroll melebihi
// threshold, agar efek blur/shadow aktif (sesuai CSS .navbar-mkt.scrolled).
(function initNavbarScroll() {
  var navbar = document.querySelector(".navbar-mkt");
  if (!navbar) return;

  var SCROLL_THRESHOLD = 60;

  function onScroll() {
    if (window.scrollY > SCROLL_THRESHOLD) {
      navbar.classList.add("scrolled");
    } else {
      navbar.classList.remove("scrolled");
    }
  }

  window.addEventListener("scroll", onScroll, { passive: true });
  // Set state awal sesuai posisi scroll saat halaman dibuka
  onScroll();
})();

// --- Smooth scroll untuk anchor link ----------------------------------------
// Menangani klik pada semua `<a href="#section">` agar scroll halus ke target,
// dan menutup mobile navbar (Bootstrap collapse) jika sedang terbuka.
(function initSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach(function (anchor) {
    anchor.addEventListener("click", function (e) {
      var targetId = this.getAttribute("href");
      if (!targetId || targetId === "#") return;

      var targetEl = document.querySelector(targetId);
      if (!targetEl) return;

      e.preventDefault();

      // Tutup Bootstrap mobile navbar jika sedang terbuka
      var navbarCollapse = document.querySelector(".navbar-collapse");
      if (navbarCollapse && navbarCollapse.classList.contains("show")) {
        var toggler = document.querySelector(".navbar-toggler");
        if (toggler) toggler.click();
      }

      targetEl.scrollIntoView({ behavior: "smooth", block: "start" });
    });
  });
})();

// --- Footer copyright year --------------------------------------------------
// Menyetel tahun copyright secara otomatis berdasarkan tahun saat ini.
(function initFooterYear() {
  var yearEl = document.getElementById("footer-year");
  if (!yearEl) return;

  yearEl.textContent = String(new Date().getFullYear());
})();
