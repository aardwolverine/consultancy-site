Netlify deployment and form function setup for consultancy-site

Overview
--------
This site uses Hugo for static content and a Netlify Function (serverless) to accept "Request a Quote" form submissions and send them to your Outlook email via SMTP. The setup is intentionally minimal: invisible reCAPTCHA, a honeypot, and a short time-check to reduce spam while keeping user friction low.

What is included
-----------------
- content/request-quote.md: The public form page users fill out.
- content/request-quote/received.md: The confirmation page.
- netlify/functions/send-quote.js: Serverless function to validate form data, verify reCAPTCHA, and send an email via SMTP (nodemailer).
- static/js/recaptcha.js: Helper to load/execute Google reCAPTCHA.
- package.json: Lists nodemailer dependency for the Netlify Function.
- config.toml: Placeholder param for recaptcha_site_key (set this during build / in Netlify settings as described below).

Environment variables to configure (Netlify site settings -> Build & deploy -> Environment)
-------------------------------------------------------------------------------------------
Set the following environment variables in your Netlify site settings (Environment -> Variables):

- MAIL_HOST: e.g., smtp.office365.com
- MAIL_PORT: e.g., 587
- MAIL_SECURE: "false" (for STARTTLS on 587)
- MAIL_USER: SMTP username (your Outlook account or SMTP user)
- MAIL_PASS: SMTP password or app password
- MAIL_FROM: Optional. Default: info@acadsys.com.au
- MAIL_TO: Where to send quote emails (set to your Outlook alias/address)
- RECAPTCHA_SECRET: secret key from Google reCAPTCHA admin
- OPTIONAL: set SiteParams recaptcha_site_key in the site config (or add as an environment variable and paste into config during build)

Netlify-specific steps
----------------------
1. Create or connect your Git repository in Netlify.
2. In Site settings -> Build & deploy -> Continuous Deployment, confirm the build command (usually none for Hugo-generated output if you commit "docs"; otherwise set the Hugo build command if you build on Netlify) and the publish directory (docs).
3. Add Environment variables (see list above).
4. Add the reCAPTCHA site key to config.toml or use the Netlify UI to set it at build time (safer to set it as an env var and inject in templates if you prefer).
5. Deploy. Netlify will install dependencies (nodemailer) and deploy the function.

reCAPTCHA configuration
-----------------------
- Register your domain at https://www.google.com/recaptcha/admin to obtain SITE_KEY and SECRET.
- Set RECAPTCHA_SECRET in Netlify environment variables.
- Set the SITE_KEY in config.toml `params.recaptcha_site_key` or inject into the head during build.
- The client-side will request a token and include it in the form data. The function verifies the token with Google.

Analytics and Tracking
----------------------
- The form pushes events to gtag and dataLayer (quote_submit_attempt, quote_submit_success, quote_submit_failure, quote_submit_spam, quote_submit_error).
- Ensure your GTAG / Google Analytics and Google Tag Manager code are loaded on the site (they are included elsewhere in the header partials). Events will be available in GTM and Analytics.
- For Matomo via GTAG, map GTAG events to Matomo via your Tag Manager setup.

Testing
-------
- Deploy to a staging Netlify site with environment variables set (use a test MAIL_TO for verification).
- Submit the form and confirm it arrives in the mailbox and that GTAG events appear in your realtime analytics.

Security notes
--------------
- Do not commit reCAPTCHA secret or SMTP credentials to the repo. Always set via Netlify environment variables.
- If using Office365, you may need an app password if your account enforces MFA. Alternatively, use an SMTP relay.

Support
-------
If you'd like, I can:
- Add the snippet to head to load the reCAPTCHA site key (done already), or instead inject it from environment variables at build time.
- Configure a small serverless backup (store submissions in a CSV or Google Sheet).
- Add reCAPTCHA score thresholds tuning or other anti-spam.

Files you may want to inspect
-----------------------------
- content/request-quote.md
- netlify/functions/send-quote.js
- static/js/recaptcha.js
- package.json
- themes/quint/layouts/partials/head.html (where the site key is exposed)

