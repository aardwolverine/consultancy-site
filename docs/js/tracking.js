(function(){
  function pushGA(eventName, params){
    try { if (window.gtag) gtag('event', eventName, params || {}); } catch(e){}
  }
  function pushDL(eventName, props){
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push(Object.assign({ event: eventName }, props || {}));
  }
  function pushMatomo(category, action, name){
    try { window._paq = window._paq || []; window._paq.push(['trackEvent', category, action, name]); } catch(e){}
  }

  // Email link click
  document.addEventListener('click', function(e){
    var el = e.target.closest && e.target.closest('a[href^="mailto:"]');
    if (!el) return;
    pushGA('email_copy', { event_category: 'engagement', event_label: 'email_click' });
    pushDL('email_copy', { method: 'mailto' });
    pushMatomo('Engagement', 'Email Click', 'footer email');
  });

  // Copy button click (attr data-action="copy-email")
  document.addEventListener('click', function(e){
    var copyBtn = e.target.closest && e.target.closest('[data-action="copy-email"]');
    if (!copyBtn) return;
    pushGA('email_copy', { event_category: 'engagement', event_label: 'copy_button' });
    pushDL('email_copy', { method: 'copy_button' });
    pushMatomo('Engagement', 'Email Copy', 'copy_button');
  });
})();
