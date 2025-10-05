const nodemailer = require('nodemailer');
const dotenv = require("dotenv");
dotenv.config();


// TODO: Replace with your actual email configuration.
// It is best practice to use environment variables for sensitive data like auth.
const transporter = nodemailer.createTransport({
    service: 'gmail', // Example: Use 'gmail' or configure SMTP for your hosting provider
    auth: {
        user: process.env.EMAIL_USER, // Your outbound email address
        pass: process.env.EMAIL_PASS    // IMPORTANT: Use an App Password if using Gmail
    }
});

/**
 * Sends a welcome email with login credentials to the parent/student.
 * @param {string} recipientEmail - The email address to send the credentials to (usually father's email).
 * @param {string} studentName - The full name of the student.
 * @param {string} loginEmail - The login username/email for the student's account.
 * @param {string} password - The raw password set for the student's account.
 */
async function sendWelcomeEmail(recipientEmail, studentName, loginEmail, password) {
    if (!recipientEmail || !loginEmail || !password) {
        console.warn('Skipping email: Missing recipient email, login email, or password.');
        return;
    }

    const mailOptions = {
        from: '"School Administration" <YOUR_SCHOOL_EMAIL@gmail.com>',
        to: recipientEmail,
        subject: `Welcome! Your Account Credentials for ${studentName}`,
        html: `
            <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                <h2 style="color: #4CAF50;">Welcome to Our School Community!</h2>
                <p>Dear Parent/Guardian of <strong>${studentName}</strong>,</p>
                <p>We are delighted to welcome your child to our school. An account has been created for your child to access our student portal and stay updated on academic progress and school activities.</p>

                <h3 style="color: #007BFF;">Login Credentials:</h3>
                <table style="border: 1px solid #ccc; border-collapse: collapse; width: 100%; max-width: 400px;">
                    <tr>
                        <td style="border: 1px solid #ccc; padding: 8px; font-weight: bold;">Login Email:</td>
                        <td style="border: 1px solid #ccc; padding: 8px; color: #D9534F;">${loginEmail}</td>
                    </tr>
                    <tr>
                        <td style="border: 1px solid #ccc; padding: 8px; font-weight: bold;">Password:</td>
                        <td style="border: 1px solid #ccc; padding: 8px; color: #D9534F;">${password}</td>
                    </tr>
                </table>

                <p style="margin-top: 20px;">Please ensure you log in to the portal and change this temporary password immediately.</p>

                <p>If you have any questions, please contact the administration office.</p>
                <p>Best Regards,</p>
                <p>The School Administration Team</p>
            </div>
        `
    };

    try {
        let info = await transporter.sendMail(mailOptions);
        console.log('Welcome email sent: %s', info.messageId);
        return true;
    } catch (error) {
        console.error('Error sending welcome email:', error);
        // Do not throw an error here, as student creation should succeed even if email fails
        return false;
    }
}



async function sendTeacherWelcomeEmail(recipientEmail, teacherName, loginEmail, password) {
    if (!recipientEmail || !loginEmail || !password) {
        console.warn('Skipping teacher email: Missing recipient email, login email, or password.');
        return;
    }

    const mailOptions = {
        from: '"School Administration" <YOUR_SCHOOL_EMAIL@gmail.com>',
        to: recipientEmail,
        subject: `Welcome to the Team, ${teacherName}! Your Portal Credentials`,
        html: `
            <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                <h2 style="color: #007BFF;">Welcome to the Faculty!</h2>
                <p>Dear **${teacherName}**,</p>
                <p>We are excited to have you join our team. Your faculty portal account has been successfully created. You can now log in to access your teaching schedules, student records, and school communications.</p>

                <h3 style="color: #4CAF50;">Login Credentials:</h3>
                <table style="border: 1px solid #ccc; border-collapse: collapse; width: 100%; max-width: 400px;">
                    <tr>
                        <td style="border: 1px solid #ccc; padding: 8px; font-weight: bold;">Login Email:</td>
                        <td style="border: 1px solid #ccc; padding: 8px; color: #D9534F;">${loginEmail}</td>
                    </tr>
                    <tr>
                        <td style="border: 1px solid #ccc; padding: 8px; font-weight: bold;">Password:</td>
                        <td style="border: 1px solid #ccc; padding: 8px; color: #D9534F;">${password}</td>
                    </tr>
                </table>

                <p style="margin-top: 20px;">Please change your password immediately after your first successful login.</p>

                <p>We look forward to a successful academic year with you.</p>
                <p>Best Regards,</p>
                <p>The School Administration Team</p>
            </div>
        `
    };

    try {
        let info = await transporter.sendMail(mailOptions);
        console.log('Teacher welcome email sent: %s', info.messageId);
        return true;
    } catch (error) {
        console.error('Error sending teacher welcome email:', error);
        return false;
    }
}




module.exports = {
    sendWelcomeEmail, // If you kept the student function
    sendTeacherWelcomeEmail
};