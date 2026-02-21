(function () {
  function markActiveNav() {
    var pathname = window.location.pathname;
    document.querySelectorAll('.navbar-doc .nav-link').forEach(function (el) {
      var href = el.getAttribute('href');
      if (!href || href.startsWith('http')) return;
      if (pathname === href) el.classList.add('active');
    });
  }

  function annotateExternalLinks() {
    document.querySelectorAll('a[target="_blank"]').forEach(function (a) {
      if (!a.querySelector('.ext-icon')) {
        var span = document.createElement('span');
        span.className = 'ext-icon';
        span.textContent = ' ↗';
        a.appendChild(span);
      }
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    markActiveNav();
    annotateExternalLinks();
  });
})();
