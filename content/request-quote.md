+++
title = "Request a Quote"
draft = false
description = "Request a personalised quote from Academic Systems Consulting. Tell us about your project and we'll get back to you."
keywords = ["request quote", "consulting quote", "higher education consulting"]
+++

<form id="request-quote-form" method="POST" action="/request-quote/submit/">
  <label for="name">Your name</label>
  <input type="text" id="name" name="name" required />

  <label for="email">Email</label>
  <input type="email" id="email" name="email" required />

  <label for="organisation">Organisation</label>
  <input type="text" id="organisation" name="organisation" />

  <label for="message">Project details (brief)</label>
  <textarea id="message" name="message" rows="6" required></textarea>

  <button type="submit">Request Quote</button>
</form>

<script>
document.getElementById('request-quote-form').addEventListener('submit', function(e){
  e.preventDefault();
  // Simple client-side POST to the thank-you route using fetch
  const data = new URLSearchParams(new FormData(this));
  fetch(this.action, { method: 'POST', body: data })
    .then(r => {
      if (r.redirected) {
        window.location = r.url;
        return;
      }
      // fallback to manually navigate to the thank-you page
      window.location = '/request-quote/received/';
    })
    .catch(() => window.location = '/request-quote/received/');
});
</script>
