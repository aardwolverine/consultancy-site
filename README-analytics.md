Analytics & Tagging — quick notes

Files added/used
- layouts/partials/gtm_head.html — Google Tag Manager head snippet (GTM container id)
- layouts/partials/gtm_body.html — Google Tag Manager noscript iframe
- layouts/partials/matomo.html — Matomo tracker snippet (base URL + site id)
- layouts/partials/extra_head.html — includes GTM head + Matomo partial (overrides theme extra_head)
- static/js/contact-tracking.js — tracks mailto: clicks and copy events; pushes obfuscated email to dataLayer and Matomo
- themes/quint/layouts/_default/baseof.html — now includes gtm_body and loads /js/contact-tracking.js before the footer

How to change values
- GTM container ID
  - Edit: layouts/partials/gtm_head.html and layouts/partials/gtm_body.html
  - Replace the GTM-WSZPXP string with your container ID (format GTM-XXXXX)

- Matomo base URL and site ID
  - Edit: layouts/partials/matomo.html
  - Replace the var u value (currently "//bee.pangolin-fence.ts.net:8081/") and the siteId (currently '1') if you move Matomo or change site id.
  - Use protocol-relative (//host) or explicit https://host if you will serve Matomo over HTTPS.

Contact tracking behaviour
- File: static/js/contact-tracking.js
  - Fires two dataLayer events: contact_email_click and contact_email_copy
  - Each event includes email_obfuscated (e.g., j***@domain.com)
  - Matomo receives the obfuscated email as event label (no raw PII is stored)
  - Cooldown: 5s dedupe for repeated actions

GTM setup (UI steps)
1. Create a GTM Container (Web) and get your container ID.
2. In GTM, create two Triggers (type: Custom Event):
   - contact_email_click
   - contact_email_copy
   (match Event name exactly)
3. Create Google Ads Conversion Tag(s) (or GA4/other tags) and set Trigger to the appropriate custom event.
   - Do NOT send raw email to Google Ads. Use event-only conversion triggers.
4. Use GTM Preview mode to verify the dataLayer events appear when clicking mailto: links and copying email text.

Matomo setup
- Matomo is deployed under apps/matomo (docker-compose + .env provided).
- Complete the Matomo web installer at the Matomo URL (e.g. http://bee.pangolin-fence.ts.net:8081)
- After creating a Site in Matomo, confirm the Site ID and update layouts/partials/matomo.html if needed.
- In Matomo admin, you can create Goals based on Event category/action (Contact / Email Click and Contact / Email Copy) to measure conversions.

Testing checklist
- Serve site and view source: GTM head, Matomo script and GTM body iframe should appear.
- Open GTM Preview to capture dataLayer events.
- In browser DevTools, verify network requests to /matomo.php on events.
- Check Matomo Real-time > Events to confirm events are received.

Privacy & Compliance notes
- Code currently obfuscates emails before sending to Matomo and dataLayer to avoid storing raw PII.
- If you need stricter compliance for GDPR, implement consent gating: call _paq.push(['requireConsent']) in matomo.html and call rememberConsentGiven() when consent is granted. Similarly, do not fire Google Ads/other third-party tags until consent is given.

If you want me to:
- replace GTM ID and Matomo URL/siteId with final values and push to a branch or master
- create a small PR with these changes
- add cookie-consent gating and conditional tag firing

Tell me which and I'll proceed.