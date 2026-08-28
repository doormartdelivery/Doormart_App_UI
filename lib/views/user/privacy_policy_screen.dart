import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../widgets/bottom_nav_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const routeName = '/privacy-policy';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        index: 4,
        onTap: (index) => BottomNavBar.navigate(context, index),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        children: const [
          _PolicyHero(),
          SizedBox(height: 16),
          _PolicySection(
            title: '1. Information We Collect',
            body:
                'We collect information you provide directly when you create an account, place an order, contact support, or update your profile. This may include your name, phone number, email address, delivery address, payment details, and support messages.',
          ),
          _PolicySection(
            title: '2. How We Use Your Information',
            body:
                'Your information is used to process orders, deliver products, personalize your shopping experience, provide customer support, send order updates, and improve app performance and security.',
          ),
          _PolicySection(
            title: '3. Sharing of Information',
            body:
                'We share your details only when necessary to complete your order, deliver products, process payments, comply with legal obligations, or support platform operations. We do not sell your personal data.',
          ),
          _PolicySection(
            title: '4. Delivery and Payment Data',
            body:
                'Delivery address and contact details are shared with delivery personnel only to complete the order. Payment processing is handled through trusted third-party providers, and we do not store card credentials on our servers.',
          ),
          _PolicySection(
            title: '5. Security',
            body:
                'We use reasonable technical and organizational safeguards to protect your information. However, no method of transmission or storage is completely secure, so we cannot guarantee absolute security.',
          ),
          _PolicySection(
            title: '6. Cookies and Analytics',
            body:
                'We may use cookies, app analytics, and similar technologies to understand usage patterns, improve features, and keep the app reliable. You can manage device-level permissions through your phone settings.',
          ),
          _PolicySection(
            title: '7. Data Retention',
            body:
                'We retain your information for as long as your account is active or as needed to provide services, comply with legal obligations, resolve disputes, and enforce agreements.',
          ),
          _PolicySection(
            title: '8. Your Rights',
            body:
                'You may request access, correction, or deletion of your personal data where applicable. You can also update your profile and address details directly in the app.',
          ),
          _PolicySection(
            title: '9. Children’s Privacy',
            body:
                'The DoorMart app is intended for adults and is not directed to children under the legal age of consent in your region.',
          ),
          _PolicySection(
            title: '10. Changes to This Policy',
            body:
                'We may update this policy from time to time. When we do, we will revise the content in the app and the changes will apply from the date of publication.',
          ),
          _PolicySection(
            title: '11. Contact Us',
            body:
                'If you have any questions about this Privacy Policy or want to request account deletion, please reach out through Help & Support in the user dashboard or email ${AppConstants.supportEmail}.',
          ),
          _PolicySection(
            title: '12. Account Deletion',
            body:
                'You can request account deletion by contacting ${AppConstants.supportEmail}. Please include the email address or phone number associated with your account. Once we verify the request, we will delete the account and associated user data unless we are required to retain limited information for legal, security, or fraud-prevention purposes.',
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PolicyHero extends StatelessWidget {
  const _PolicyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF26522), Color(0xFFE8541A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your privacy matters',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This page explains what data we collect, why we collect it, and how we protect it.',
            style: TextStyle(
              color: Colors.white,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.7,
              color: Colors.black.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
