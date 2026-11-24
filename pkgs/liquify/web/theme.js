(() => {
  const key = 'liquify-theme';
  const system = matchMedia('(prefers-color-scheme: dark)');
  const root = document.documentElement;
  let preference;

  function readPreference() {
    try {
      const stored = localStorage.getItem(key);
      return stored === 'light' || stored === 'dark' ? stored : null;
    } catch {
      return null;
    }
  }

  function update() {
    const dark = preference ? preference === 'dark' : system.matches;
    if (preference) {
      root.dataset.theme = preference;
    } else {
      delete root.dataset.theme;
    }
    const toggle = document.querySelector('[data-theme-toggle]');
    if (toggle && toggle.getAttribute('aria-pressed') !== String(dark)) {
      toggle.setAttribute('aria-pressed', String(dark));
    }
    return dark;
  }

  preference = readPreference();
  update();

  // Jaspr also updates the playground header when the workspace renders.
  new MutationObserver(update).observe(root, {
    childList: true,
    subtree: true,
    attributeFilter: ['aria-pressed', 'data-theme-toggle'],
  });

  system.addEventListener('change', update);
  window.addEventListener('storage', (event) => {
    if (event.key === key || event.key === null) {
      preference = readPreference();
      update();
    }
  });
  document.addEventListener('click', (event) => {
    if (!event.target.closest('[data-theme-toggle]')) return;
    preference = update() ? 'light' : 'dark';
    try {
      localStorage.setItem(key, preference);
    } catch {
      // The chosen theme still applies to this page.
    }
    update();
  });
})();
