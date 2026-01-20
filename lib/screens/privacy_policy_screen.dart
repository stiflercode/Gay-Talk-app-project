import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Privacy Policy", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
              _privacyPolicyText,
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

const String _privacyPolicyText = '''
GUMBO TECH PRIVACY POLICY

Gumbo Tech Pvt Ltd recognizes the importance of maintaining your privacy. We value your privacy and appreciate your trust in us. This Privacy Policy applies to current and former visitors ("users" to our app and to our online customers). By visiting and/or using our website and app, you agree to this Privacy Policy.

The Service Provider may disclose User Provided and Automatically Collected Information:
• as required by law, such as to comply with a subpoena, or similar legal process;
• when they believe in good faith that disclosure is necessary to protect their rights, protect your safety or the safety of others, investigate fraud, or respond to a government request;
• with their trusted service providers who work on their behalf, do not have an independent use of the information we disclose to them, and have agreed to adhere to the rules set forth in this privacy statement.

Opt-Out Rights  
You can stop all collection of information by the Application easily by uninstalling it. You may use the standard uninstall processes available as part of your mobile device or via the mobile application marketplace or network.

Data Retention Policy  
The Service Provider will retain User Provided data for as long as you use the Application and for a reasonable time thereafter. If you'd like them to delete User Provided Data that you have provided via the Application, please contact them at support@gumbotech.in and they will respond in a reasonable time.

Children  
The Service Provider does not use the Application to knowingly solicit data from or market to children under the age of 18.

The Application does not address anyone under the age of 18. The Service Provider does not knowingly collect personally identifiable information from children under 18 years of age. In case the Service Provider discovers that a child under 18 has provided personal information, the Service Provider will immediately delete this from their servers. If you are a parent or guardian and are aware that your child has provided personal information, please contact the Service Provider (support@gumbotech.in) so that they can take the necessary actions.

Security  
The Service Provider is concerned about safeguarding the confidentiality of your information. The Service Provider provides physical, electronic, and procedural safeguards to protect information they process and maintain.

Changes  
This Privacy Policy may be updated from time to time for any reason. The Service Provider will notify you of any changes to the Privacy Policy by updating this page with the new Privacy Policy. You are advised to consult this Privacy Policy regularly for any changes, as continued use is deemed approval of all changes.

This privacy policy is effective as of December 2025.

Your Consent  
By using the Application, you are consenting to the processing of your information as set forth in this Privacy Policy now and as amended by the Service Provider.

Contact Us  
If you have any questions regarding privacy while using the Application, or have questions about the practices, please contact the Service Provider via email at support@gumbotech.in

Refund and Cancellation Policy
Cancellation of wallet payment can be done by mailing us at support@gumbotech.in

No Refund is allowed once the service taken by any user.

Alternate Account Deletion
Users can request the deletion of their account and associated data by sending request over mail on support@gumbotech.in


''';
