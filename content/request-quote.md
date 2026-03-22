+++
title = "Request a Quote"
draft = false
unlisted = true
image = "images/request-quote.jpg"
description = "Request a personalised quote from Academic Systems Consulting. Tell us about your project and we'll get back to you."
keywords = ["request quote", "consulting quote", "higher education consulting"]
+++

<form id="request-quote-form" name="request-quote" method="POST" action="/request-quote/" data-netlify="true" data-netlify-honeypot="website">
  <input type="hidden" name="form-name" value="request-quote" />
  <label for="name">Your name</label>
  <input type="text" id="name" name="name" required />

  <label for="email">Email</label>
  <input type="email" id="email" name="email" required />

  <label for="organisation">Organisation</label>
  <input type="text" id="organisation" name="organisation" />

  <label for="message">Project details (brief)</label>
  <textarea id="message" name="message" rows="6" required></textarea>

  <!-- Honeypot field to trap bots (should be left empty) -->
  <div style="display:none;">
    <label for="website">Website</label>
    <input type="text" id="website" name="website" />
  </div>

  <!-- Timestamp to help detect automated/bot submissions -->
  <input type="hidden" id="ts" name="ts" value="" />

  <!-- Invisible reCAPTCHA token -->
  <input type="hidden" id="g-recaptcha-response" name="g-recaptcha-response" value="" />

  <button type="submit">Request Quote</button>
</form>

<script>
// Minimal analytics and simple anti-spam using a honeypot and a time threshold
(function(){
  var form = document.getElementById('request-quote-form');
  var tsField = document.getElementById('ts');
  tsField.value = Date.now();

  function pushEvent(name, props){
    try {
      if (window.gtag) {
        gtag('event', name, props || {});
      }
    } catch (e) {}
    try {
      window.dataLayer = window.dataLayer || [];
      window.dataLayer.push(Object.assign({ event: name }, props || {}));
    } catch (e) {}
  }

  form.addEventListener('submit', function(e){
    e.preventDefault();

    pushEvent('quote_submit_attempt');

    var formData = new FormData(form);

    // Basic honeypot check
    if (formData.get('website')){
      pushEvent('quote_submit_spam', { reason: 'honeypot' });
      // pretend success to avoid giving bots feedback
      window.location = '/request-quote/received/';
      return;
    }

    // Time-based check: require at least 3 seconds between form load and submit
    var ts = parseInt(formData.get('ts') || '0', 10);
    if (!ts || (Date.now() - ts) < 3000){
      pushEvent('quote_submit_spam', { reason: 'timing' });
      window.location = '/request-quote/received/';
      return;
    }

      // Ensure reCAPTCHA token if available
    (window._recaptcha && window.RECAPTCHA_SITE_KEY ? window._recaptcha.ensureLoaded(function(){
      window._recaptcha.getToken('request_quote').then(function(token){
        if (token) formData.set('g-recaptcha-response', token);
        sendRequest(formData);
      });
    }) : sendRequest(formData));

    function sendRequest(formData){
      // Send to serverless function
      fetch(form.action, {
        method: 'POST',
        body: formData
      }).then(function(res){
        if (res.ok) {
          pushEvent('quote_submit_success');
          window.location = '/request-quote/received/';
        } else {
          pushEvent('quote_submit_failure');
          window.location = '/request-quote/received/';
        }
      }).catch(function(){
        pushEvent('quote_submit_error');
        window.location = '/request-quote/received/';
      });
    }
    });
})();
</script>
