import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionInfoDialog extends StatelessWidget {
  const SubscriptionInfoDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SubscriptionInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1D162B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Subscription Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Premium Subscription Details
                _buildSubscriptionSection(
                  title: 'SpookyAI Premium',
                  subtitle: 'Monthly Subscription',
                  features: [
                    'Unlimited AI image generation',
                    '20 premium tokens per month',
                    'Access to exclusive Halloween themes',
                    'Priority processing for image generation',
                    'Ad-free experience',
                    'Advanced prompt suggestions',
                  ],
                  price: 'Pricing varies by region',
                  period: '30 days',
                ),

                const SizedBox(height: 20),

                // Token Packages
                _buildTokenPackagesSection(),

                const SizedBox(height: 20),

                // Auto-Renewal Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1F3D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6A00).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.autorenew,
                            color: Color(0xFFFF6A00),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Auto-Renewal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Premium subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.',
                        style: TextStyle(
                          color: Color(0xFF8C7BA6),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You can manage your subscription in your Apple ID account settings.',
                        style: TextStyle(
                          color: Color(0xFF8C7BA6),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Legal Links
                _buildLegalLinksSection(),

                const SizedBox(height: 16),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection({
    required String title,
    required String subtitle,
    required List<String> features,
    required String price,
    required String period,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6A00).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFFF6A00),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Subscription Length:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            period,
            style: const TextStyle(color: Color(0xFF8C7BA6), fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Price:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            price,
            style: const TextStyle(color: Color(0xFF8C7BA6), fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            'Content & Services:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(color: Color(0xFFFF6A00), fontSize: 14),
                  ),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        color: Color(0xFF8C7BA6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenPackagesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_bag, color: Color(0xFF4CAF50), size: 20),
              SizedBox(width: 8),
              Text(
                'Token Packages',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'One-time purchases for image generation tokens:',
            style: TextStyle(color: Color(0xFF8C7BA6), fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildTokenPackage(
            '1 Token',
            'Single use token for one image generation',
          ),
          _buildTokenPackage(
            '10 Tokens',
            '10 tokens for multiple image generations',
          ),
          _buildTokenPackage('25 Tokens', '25 tokens for extended use'),
          _buildTokenPackage('60 Tokens', '60 tokens for heavy usage'),
          _buildTokenPackage('150 Tokens', '150 tokens for maximum value'),
        ],
      ),
    );
  }

  Widget _buildTokenPackage(String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Color(0xFF4CAF50), fontSize: 14),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$name: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(
                      color: Color(0xFF8C7BA6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLinksSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel, color: Color(0xFF2196F3), size: 20),
              SizedBox(width: 8),
              Text(
                'Legal Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLegalLink(
            'Terms of Use (EULA)',
            'https://github.com/furkanagess/SpookyAI/blob/main/TERMS_OF_USE.md',
            Icons.description,
          ),
          const SizedBox(height: 8),
          _buildLegalLink(
            'Privacy Policy',
            'https://github.com/furkanagess/SpookyAI/blob/main/PRIVACY_POLICY.md',
            Icons.privacy_tip,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String title, String url, IconData icon) {
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1D162B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF2196F3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.open_in_new, color: Color(0xFF2196F3), size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
