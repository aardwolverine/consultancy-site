// Load this file in the page to integrate invisible reCAPTCHA v2
// Requires site to set window.RECAPTCHA_SITE_KEY from a safe source (e.g., templated via config or inline script in head)

function ensureRecaptchaLoaded(cb) {
  if (window.grecaptcha) return cb();
  var s = document.createElement('script');
  s.src = 'https://www.google.com/recaptcha/api.js?render=' + window.RECAPTCHA_SITE_KEY;
  s.onload = cb;
  document.head.appendChild(s);
}

function getRecaptchaToken(action) {
  return new Promise(function(resolve){
    if (!window.grecaptcha) return resolve('');
    window.grecaptcha.ready(function(){
      window.grecaptcha.execute(window.RECAPTCHA_SITE_KEY, {action: action}).then(function(token){
        resolve(token);
      }).catch(function(){ resolve(''); });
    });
  });
}

// Expose helpers
window._recaptcha = {
  ensureLoaded: ensureRecaptchaLoaded,
  getToken: getRecaptchaToken
};
