/* footer.js — Prime IPTV */
(function () {
  'use strict';

  const footer = document.querySelector('footer');
  if (!footer) return;

  /* ── Inject ambient layer (orbs + particles) ── */
  const ambient = document.createElement('div');
  ambient.className = 'ft-ambient';
  ambient.setAttribute('aria-hidden', 'true');
  ambient.innerHTML =
    '<span class="ft-orb ft-orb--1"></span>' +
    '<span class="ft-orb ft-orb--2"></span>' +
    '<span class="ft-orb ft-orb--3"></span>' +
    '<span class="ft-orb ft-orb--4"></span>' +
    '<div class="ft-particles"></div>';

  footer.insertBefore(ambient, footer.firstChild);

  /* ── Seed rising particles ── */
  const container = ambient.querySelector('.ft-particles');
  for (let i = 0; i < 12; i++) {
    const p = document.createElement('span');
    p.className = 'ft-particle';
    p.style.left            = (Math.random() * 100).toFixed(1) + '%';
    p.style.width           = (1.2 + Math.random() * 1.4).toFixed(1) + 'px';
    p.style.height          = p.style.width;
    p.style.animationDuration  = (16 + Math.random() * 20).toFixed(1) + 's';
    p.style.animationDelay     = (Math.random() * 14).toFixed(1) + 's';
    container.appendChild(p);
  }
})();
