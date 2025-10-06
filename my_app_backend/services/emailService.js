const nodemailer = require('nodemailer');
const dotenv = require("dotenv");
dotenv.config();


// The transporter configuration is correct, using environment variables.
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    }
});

/**
 * Sends a welcome email with login credentials to the parent/student.
 * @param {string} recipientEmail - The email address to send the credentials to.
 * @param {string} studentName - The full name of the student.
 * @param {string} loginEmail - The login username/email for the student's account.
 * @param {string} password - The raw password set for the student's account.
 */
async function sendWelcomeEmail(recipientEmail, studentName, loginEmail, password) {
    if (!recipientEmail || !loginEmail || !password) {
        console.warn('Skipping student email: Missing required credentials.');
        return false;
    }

    const mailOptions = {
        from: `"School Administration" <${process.env.EMAIL_USER}>`,
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
        console.log('Student welcome email sent: %s', info.messageId);
        return true;
    } catch (error) {
        console.error('Error sending student welcome email:', error);
        return false;
    }
}

/**
 * Sends a welcome email with login credentials to a new teacher.
 */
async function sendTeacherWelcomeEmail(recipientEmail, teacherName, loginEmail, password) {
    if (!recipientEmail || !loginEmail || !password) {
        console.warn('Skipping teacher email: Missing required credentials.');
        return false;
    }

    const mailOptions = {
        from: `"School Administration" <${process.env.EMAIL_USER}>`,
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
                        <td style="border: 19x solid #ccc; padding: 8px; color: #D9534F;">${password}</td>
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


/**
 * Sends a welcome email with login credentials to a new driver.
 * @param {string} recipientEmail - The driver's email address.
 * @param {string} loginEmail - The login username/email for the driver's account.
 * @param {string} password - The raw password set for the driver's account.
 * @param {string} vehicleNumber - The vehicle assigned to the driver.
 */
async function sendDriverWelcomeEmail(recipientEmail, loginEmail, password, vehicleNumber) {
    if (!recipientEmail || !loginEmail || !password) {
        console.warn('Skipping driver email: Missing required credentials.');
        return false;
    }

    const mailOptions = {
        from: `"School Administration" <${process.env.EMAIL_USER}>`,
        to: recipientEmail,
        subject: `Welcome to the Transport Team! Your Portal Credentials`,
        html: `
            <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                <h2 style="color: #4CAF50;">Welcome to the Transport Team!</h2>
                <p>Dear Driver,</p>
                <p>Your account for the school transport portal has been successfully created. You have been assigned **Vehicle ${vehicleNumber}**.</p>

                <h3 style="color: #007BFF;">Login Credentials:</h3>
                <p>Please use the credentials below to log in to the driver application to update your location and status.</p>
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

                <p style="margin-top: 20px;">Please keep your account details secure.</p>
                <p>Best Regards,</p>
                <p>Transport Administration Team</p>
            </div>
        `
    };

    try {
        let info = await transporter.sendMail(mailOptions);
        console.log('Driver welcome email sent: %s', info.messageId);
        return true;
    } catch (error) {
        console.error('Error sending driver welcome email:', error);
        return false;
    }
}


module.exports = {
    sendWelcomeEmail,
    sendTeacherWelcomeEmail,
    sendDriverWelcomeEmail // <-- Added for driver functionality
};
