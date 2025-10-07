import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/services/content_reporting_service.dart';
import '../../../../core/services/notification_service.dart';

/// Detail page for content reporting with comprehensive reporting options
/// Required by Google Play Console AI-Generated Content Policy
class ContentReportDetailPage extends StatefulWidget {
  final String prompt;
  final Uint8List? imageBytes;
  final String? imageId;
  final String? imagePath;

  const ContentReportDetailPage({
    super.key,
    required this.prompt,
    this.imageBytes,
    this.imageId,
    this.imagePath,
  });

  @override
  State<ContentReportDetailPage> createState() => _ContentReportDetailPageState();
}

class _ContentReportDetailPageState extends State<ContentReportDetailPage>
    with TickerProviderStateMixin {
  ReportCategory? _selectedCategory;
  ReportReason? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null || _selectedReason == null) {
      NotificationService.warning(
        context,
        message: 'Please select a category and reason for your report.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await ContentReportingService.submitReport(
        prompt: widget.prompt,
        imageBytes: widget.imageBytes,
        category: _selectedCategory!,
        reason: _selectedReason!,
        additionalDetails: _detailsController.text.trim().isEmpty
            ? null
            : _detailsController.text.trim(),
        imageId: widget.imageId,
      );

      if (mounted) {
        if (success) {
          NotificationService.success(
            context,
            message:
                'Thank you for your report. We will review it and take appropriate action.',
          );
          Navigator.of(context).pop(true);
        } else {
          NotificationService.error(
            context,
            message: 'Unable to submit report. Please try again later.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error(
          context,
          message: 'An error occurred while submitting your report.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1A),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0F0B1A),
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Report Content',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF0F0B1A),
                          Color(0xFF1D162B),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (_isSubmitting)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF6A00),
                        ),
                      ),
                    ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      _buildHeaderCard(),
                      const SizedBox(height: 32),

                      // Content Preview
                      _buildContentPreview(),
                      const SizedBox(height: 32),

                      // Category Selection
                      _buildCategorySection(),
                      const SizedBox(height: 32),

                      // Reason Selection
                      if (_selectedCategory != null) ...[
                        _buildReasonSection(),
                        const SizedBox(height: 32),
                      ],

                      // Additional Details
                      _buildDetailsSection(),
                      const SizedBox(height: 32),

                      // Policy Information
                      _buildPolicySection(),
                      const SizedBox(height: 32),

                      // Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.report_problem_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Help Keep SpookyAI Safe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Report inappropriate content to help us maintain a safe and enjoyable community for everyone.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Content Being Reported',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1F3D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFFFF6A00),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Prompt:',
                    style: TextStyle(
                      color: Color(0xFFFF6A00),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.prompt,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What type of content is this?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...ReportCategory.values.map((category) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCategoryCard(category),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryCard(ReportCategory category) {
    final isSelected = _selectedCategory == category;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category;
            _selectedReason = null;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF6A00).withOpacity(0.1)
                : const Color(0xFF2A1F3D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF6A00)
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6A00).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFFFF6A00)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF6A00)
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is the specific issue?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...ReportReason.values
            .where((reason) => reason.category == _selectedCategory)
            .map((reason) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildReasonCard(reason),
          );
        }),
      ],
    );
  }

  Widget _buildReasonCard(ReportReason reason) {
    final isSelected = _selectedReason == reason;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedReason = reason;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF6A00).withOpacity(0.1)
                : const Color(0xFF2A1F3D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF6A00)
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFFFF6A00)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF6A00)
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  reason.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Details (Optional)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _detailsController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText:
                'Provide any additional context that might help us understand your concern...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFF2A1F3D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFFF6A00),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F3D).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6A00).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFFF6A00),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Our Commitment',
                style: TextStyle(
                  color: Color(0xFFFF6A00),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'We take content moderation seriously. All reports are reviewed by our team, and appropriate action will be taken in accordance with our community guidelines. Your report helps us maintain a safe environment for all users.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Submit Button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submitReport,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: const Color(0xFFFF6A00).withOpacity(0.3),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Cancel Button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isSubmitting
                ? null
                : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
