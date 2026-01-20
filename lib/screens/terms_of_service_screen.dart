import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Terms of Service", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Text(
              _termsText,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const String _termsText = '''
Terms of Services
Last Updated: December 30, 2025

This Privacy Policy ("Policy") explains how Gumbo Tech Private Limited ("Company," "We," "Us," or "Our"), operating under the brand name "Gay Talk", collects, uses, stores, discloses, and protects your personal information when you use our mobile application ("Gay Talks") or website (collectively, the "Platform").

By accessing or using the Platform, you consent to the terms of this Privacy Policy. If you do not agree with any part of this Policy, please discontinue use of the Platform immediately.

1. Information We Collect

a. Information You Provide

Account Information: Name and email address obtained through Google authentication (Gmail login). Gay Talk does not collect or store passwords, phone numbers, OTPs, or any other third-party login credentials.

Profile Information: Optional details such as date of birth, gender, and city of residence.

User-Generated Content: Any data, text, or media you upload or share within Gay Talks.

Communication Data: Messages or inquiries you send to our support team.

b. Automatically Collected Information

Device Information: Device type, OS version, IP address, unique identifiers, and app version.

Usage Data: Information about how you interact with features, pages, and sections of the app.

Cookies & Analytics: Used to maintain sessions and improve user experience.

2. Purpose of Data Collection

We use your data to:
• Create and manage your account using Google authentication.
• Provide real-time conversations on the platform.
• Personalize your experience and improve app functionality.
• Communicate important updates and notifications.
• Maintain security and prevent fraudulent activity.
• Comply with applicable legal obligations.

3. Legal Basis for Processing

We process your data based on:
• Your consent.
• Contractual necessity to deliver requested services.
• Legal obligations under applicable law.
• Legitimate interests in improving and securing our services.

4. Data Sharing and Disclosure

We do not sell or rent your personal data. We may share limited data with:
• Service providers assisting in hosting, analytics, or technical operations.
• Legal authorities when required by law.
• Affiliates or partners with your explicit consent.

All third parties are bound by strict confidentiality and data protection obligations.

5. Data Security

We use industry-standard security measures to protect your data. However, no online system is completely secure. Users should maintain the confidentiality of their Google account credentials.

6. Data Retention

We retain your data only as long as necessary to provide services or as required by law. When no longer required, data is deleted, anonymized, or securely archived.

7. User Rights

You may:
• Access, update, or correct your personal information.
• Request deletion of your personal data.
• Withdraw consent at any time.
• Request information about data processing.

To exercise these rights, contact us at support@gumbotech.in.

8. Data Deletion Request (Play Store Requirement)

You may request complete deletion of your account and personal data by:
• Emailing support@gumbotech.in with the subject line “Data Deletion Request”.
• Using the in-app “Delete Account” option (if available).

After identity verification, we will delete your data within 30 days, except where retention is legally required. This action is irreversible.

9. Children’s Privacy

Gay Talks is intended for users aged 18 years and above. We do not knowingly collect data from minors. Any such data will be deleted immediately upon identification.

10. Third-Party Services and Links

The Platform may include third-party links or integrations. We are not responsible for their privacy practices. Please review their policies separately.

11. International Data Transfers

Some data may be processed or stored outside India. By using the Platform, you consent to such transfers in compliance with applicable law.

12. Changes to This Policy

We may update this Policy periodically. Changes will be reflected on this page with an updated “Last Updated” date. Continued use constitutes acceptance.

13. Contact Us

Gumbo Tech Private Limited  
Address: No.1202, 2nd Floor, 22nd Cross (HSR Club Road),  
3rd Sector, HSR Layout, Bangalore – 560102  
Email: support@gumbotech.in

Compliance Summary

This Policy complies with:
• Google Play Data Safety and Data Deletion Requirements (2024)
• Information Technology Act, 2000
• IT (Reasonable Security Practices and SPDI) Rules, 2011
''';
