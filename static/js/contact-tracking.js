(function() {
  var lastFired = { click:0, copy:0 };
  var cooldown = 5000; // ms to ignore duplicate events

  function now(){ return (new Date()).getTime(); }

  function safePushToDataLayer(evtName, payload) {
    window.dataLayer = window.dataLayer || [];
    var obj = Object.assign({ event: evtName, timestamp: now() }, payload || {});
    try { window.dataLayer.push(obj); } catch(e){ console.warn('datalayer push failed', e); }
  }

  function pushToMatomo(category, action, label) {
    if(window._paq && Array.isArray(window._paq)) {
      try { window._paq.push(['trackEvent', category, action, label]); }
      catch(e){ console.warn('Matomo trackEvent failed', e); }
    }
  }

  // mailto click detection
  document.addEventListener('click', function(e){
    var a = e.target.closest && e.target.closest('a[href^="mailto:"]');
    if(!a) return;
    var t = now();
    if(t - lastFired.click < cooldown) return;
    lastFired.click = t;

    var href = a.getAttribute('href') || '';
    var email = href.replace(/^mailto:/i,'').split('?')[0];

    // push safe event to GTM dataLayer (no PII to Google)
    safePushToDataLayer('contact_email_click', { email_obfuscated: email.replace(/(.).+@/,'$1***@') });

    // send event to Matomo (full email as label) - remove full email if you prefer no PII stored
    pushToMatomo('Contact','Email Click', email);
  }, false);

  // copy detection for user-highlight-and-copy
  document.addEventListener('copy', function(e){
    var t = now();
    if(t - lastFired.copy < cooldown) return;
    var selection = String(document.getSelection ? document.getSelection() : '');
    if(!selection) return;
    var emailMatch = selection.match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i);
    if(!emailMatch) return;
    lastFired.copy = t;
    var email = emailMatch[0];

    safePushToDataLayer('contact_email_copy', { email_obfuscated: email.replace(/(.).+@/,'$1***@') });
    pushToMatomo('Contact','Email Copy', email);
  }, false);
})();
