(function () {
  function markActiveNav() {
    var pathname = window.location.pathname;
    document.querySelectorAll('[data-nav]').forEach(function (el) {
      var href = el.getAttribute('href');
      if (!href) return;
      if (pathname === href || (href !== '/code/' && pathname.indexOf(href) === 0)) {
        el.classList.add('active');
      }
    });
  }

  document.addEventListener('DOMContentLoaded', markActiveNav);
})();
