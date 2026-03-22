SendGrid setup instructions (for Netlify function)

Overview
--------
These instructions walk you through creating a SendGrid account, validating a sender identity or domain, generating an API key, and configuring Netlify environment variables so the site’s serverless function can send emails.

Why SendGrid
------------
- Reliable transactional email delivery
- Simple API (no SMTP or app-passwords required)
- SendGrid activity log for debugging

Steps
-----
1) Create a SendGrid account
   - Go to https://sendgrid.com and sign up for a free account.

2) Verify a sender identity or domain
   Option A: Single Sender Verification (quick)
     - In SendGrid dashboard, go to Settings → Sender Authentication → Single Sender Verification.
     - Add the exact MAIL_FROM email (e.g., info@acadsys.com.au) and confirm via the verification email SendGrid sends.
   Option B: Domain Authentication (recommended)
     - Settings → Sender Authentication → Authenticate Your Domain.
     - Follow instructions to add the required DNS records (SPF/DKIM) at your DNS provider for acadsys.com.au.
     - This is more robust and avoids per-sender verification.

3) Create an API key
   - In SendGrid dashboard: Settings → API Keys → Create API Key.
   - Choose "Full Access" or limited access for Mail Send; copy the key now (you will not be able to see it again).

4) Configure Netlify environment variables
   - In your Netlify site dashboard, go to Site settings → Build & deploy → Environment → Environment variables.
   - Add these variables (exact names):
       SENDGRID_API_KEY = <your SendGrid API key>
       MAIL_FROM = info@acadsys.com.au   # or verified sender
       MAIL_TO = info@acadsys.com.au     # where quotes should be delivered
       RECAPTCHA_SECRET = <your recaptcha secret>
   - Save the variables and trigger a deploy (or redeploy site manually)

5) Test the form
   - Visit https://<your-site>.netlify.app/request-quote/
   - Submit a test request and check:
       - Netlify Functions logs (Site → Functions → send-quote → Logs)
       - SendGrid Activity (Dashboard → Activity) — the message should appear
       - Your inbox (MAIL_TO) for the quote email

Troubleshooting
---------------
- If SendGrid reports a rejection, check that MAIL_FROM is verified or domain-authenticated.
- If Netlify function returns 500, check function logs for the error message and ensure SENDGRID_API_KEY is set.
- If emails appear in SendGrid Activity as accepted but do not land in inbox, check spam folder and verify SPF/DKIM records for the domain.

Security
--------
- Never commit SENDGRID_API_KEY or RECAPTCHA_SECRET to the repository. Store them in Netlify environment variables.

