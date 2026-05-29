/* reviews-display.js — Prime IPTV live reviews loader */
(function () {
  'use strict';

  var grid   = document.getElementById('live-reviews-grid');
  var avgEl  = document.getElementById('live-reviews-avg');
  var cntEl  = document.getElementById('live-reviews-count');
  if (!grid) return;

  /* Render stars as HTML */
  function renderStars(n) {
    var s = '';
    for (var i = 1; i <= 5; i++) {
      s += i <= n
        ? '<i class="fas fa-star" style="color:#f59e0b"></i>'
        : '<i class="far fa-star" style="color:rgba(255,255,255,0.2)"></i>';
    }
    return s;
  }

  /* Escape HTML to prevent XSS */
  function esc(str) {
    return String(str)
      .replace(/&/g,'&amp;').replace(/</g,'&lt;')
      .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  }

  /* Load reviews from Firestore */
  function loadReviews() {
    if (typeof firebase === 'undefined' || !firebase.apps.length) {
      grid.innerHTML = '';
      return;
    }

    var db = firebase.firestore();

    db.collection('reviews')
      .where('approved', '==', true)
      .orderBy('timestamp', 'desc')
      .limit(6)
      .get()
      .then(function (snapshot) {
        if (snapshot.empty) {
          grid.innerHTML = '<p class="lr-empty">كن أول من يضيف تقييماً!</p>';
          return;
        }

        var total = 0;
        var html  = '';

        snapshot.forEach(function (doc) {
          var r = doc.data();
          var stars = r.rating || r.number || 5;
          total += stars;
          html +=
            '<div class="lr-card">' +
              '<div class="lr-stars">' + renderStars(stars) + '</div>' +
              '<p class="lr-comment">&ldquo;' + esc(r.comment) + '&rdquo;</p>' +
              '<div class="lr-meta">' +
                '<span class="lr-name">' + esc(r.name) + '</span>' +
                '<span class="lr-country">' + esc(r.country) + '</span>' +
              '</div>' +
            '</div>';
        });

        var avg = (total / snapshot.size).toFixed(1);
        if (avgEl) avgEl.textContent = avg + '/5';
        if (cntEl) cntEl.textContent = '(' + snapshot.size + '+ تقييم)';
        grid.innerHTML = html;
      })
      .catch(function () {
        grid.innerHTML = '';
      });
  }

  /* Wait for Firebase to be ready */
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadReviews);
  } else {
    loadReviews();
  }

})();
