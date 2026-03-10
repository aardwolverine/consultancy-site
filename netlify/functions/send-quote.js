const nodemailer = require('nodemailer');

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

  // Configure transporter using environment variables (recommended)
  // Set MAIL_HOST, MAIL_PORT, MAIL_USER, MAIL_PASS, MAIL_FROM, MAIL_TO in Netlify environment
  const transporter = nodemailer.createTransport({
    host: process.env.MAIL_HOST,
    port: Number(process.env.MAIL_PORT || 587),
    secure: process.env.MAIL_SECURE === 'true',
    auth: {
      user: process.env.MAIL_USER,
      pass: process.env.MAIL_PASS,
    }
  });

  const mailOptions = {
    from: process.env.MAIL_FROM || 'info@acadsys.com.au',
    to: process.env.MAIL_TO || 'info@acadsys.com.au',
    subject: `Quote request from ${name}`,
    text: `Name: ${name}\nEmail: ${email}\nOrganisation: ${organisation}\n\nMessage:\n${message}`,
    html: `<p><strong>Name:</strong> ${name}</p><p><strong>Email:</strong> ${email}</p><p><strong>Organisation:</strong> ${organisation}</p><p><strong>Message:</strong></p><p>${message.replace(/\n/g,'<br/>')}</p>`
  };

  try {
    await transporter.sendMail(mailOptions);
    return {
      statusCode: 200,
      body: 'OK'
    };
  } catch (err) {
    console.error('Mail send error', err);
    return {
      statusCode: 500,
      body: 'Error'
    };
  }
};
