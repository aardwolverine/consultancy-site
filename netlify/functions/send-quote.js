const sgMail = require('@sendgrid/mail');

exports.handler = async function(event, context) {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  // Parse form data (application/x-www-form-urlencoded)
  const params = new URLSearchParams(event.body);
  const name = params.get('name') || 'Unknown';
  const email = params.get('email') || 'no-reply@example.com';
  const organisation = params.get('organisation') || '';
  const message = params.get('message') || '';
  const website = params.get('website') || '';
  const ts = params.get('ts') || '';

  // Basic anti-spam checks
  if (website) {
    // Honeypot filled — silently accept
    return { statusCode: 200, body: 'OK' };
  }
  if (!ts || (Date.now() - parseInt(ts,10) < 3000)) {
    // Too fast — likely bot
    return { statusCode: 200, body: 'OK' };
  }

  const mailFrom = process.env.MAIL_FROM || 'info@acadsys.com.au';
  const mailTo = process.env.MAIL_TO || 'info@acadsys.com.au';
  const userEmailValid = email && email.indexOf('@') > -1;

  // If a reCAPTCHA token is present, verify it with Google before sending
  const recaptchaToken = params.get('g-recaptcha-response') || '';
  if (recaptchaToken && process.env.RECAPTCHA_SECRET) {
    const fetch = require('node-fetch');
    try {
      const resp = await fetch('https://www.google.com/recaptcha/api/siteverify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `secret=${encodeURIComponent(process.env.RECAPTCHA_SECRET)}&response=${encodeURIComponent(recaptchaToken)}`
      });
      const j = await resp.json();
      if (!j.success || (j.score && j.score < 0.3)) {
        // Rejected by reCAPTCHA
        console.warn('Recaptcha failed', j);
        return { statusCode: 200, body: 'OK' };
      }
    } catch (e) {
      console.warn('Recaptcha verification error', e);
      return { statusCode: 200, body: 'OK' };
    }
  }

  if (!process.env.SENDGRID_API_KEY) {
    console.error('SENDGRID_API_KEY not set');
    return { statusCode: 500, body: 'Email service not configured' };
  }

  sgMail.setApiKey(process.env.SENDGRID_API_KEY);

  const msg = {
    to: mailTo,
    from: mailFrom,
    replyTo: userEmailValid ? email : undefined,
    subject: 'Quote for Consulting Services',
    text: `Name: ${name}\nEmail: ${email}\nOrganisation: ${organisation}\n\nMessage:\n${message}`,
    html: `<p><strong>Name:</strong> ${name}</p><p><strong>Email:</strong> ${email}</p><p><strong>Organisation:</strong> ${organisation}</p><p><strong>Message:</strong></p><p>${message.replace(/\n/g,'<br/>')}</p>`
  };

  try {
    await sgMail.send(msg);
    return { statusCode: 200, body: 'OK' };
  } catch (err) {
    console.error('SendGrid send error', err);
    return { statusCode: 500, body: 'Error' };
  }
};
