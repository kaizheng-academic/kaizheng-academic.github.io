(function () {
  function setupBibtexToggle() {
    var buttons = document.querySelectorAll('[data-bibtex-target]');
    buttons.forEach(function (btn) {
      btn.addEventListener('click', function () {
        var id = btn.getAttribute('data-bibtex-target');
        var target = document.getElementById(id);
        if (!target) return;
        var hidden = target.hasAttribute('hidden');
        if (hidden) {
          target.removeAttribute('hidden');
          btn.textContent = '隐藏 BibTeX';
        } else {
          target.setAttribute('hidden', 'hidden');
          btn.textContent = '显示 BibTeX';
        }
      });
    });
  }

  function setupCopyBibtex() {
    var copyButtons = document.querySelectorAll('[data-copy-target]');
    copyButtons.forEach(function (btn) {
      btn.addEventListener('click', async function () {
        var id = btn.getAttribute('data-copy-target');
        var target = document.getElementById(id);
        if (!target) return;
        var text = target.textContent || '';
        if (!text.trim()) return;
        try {
          await navigator.clipboard.writeText(text);
          var old = btn.textContent;
          btn.textContent = '已复制';
          setTimeout(function () { btn.textContent = old; }, 1200);
        } catch (e) {
          console.error('copy failed', e);
        }
      });
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    setupBibtexToggle();
    setupCopyBibtex();
  });
})();
