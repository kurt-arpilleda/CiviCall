import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:civicall/imageViewer.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({Key? key}) : super(key: key);

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _reportTextController = TextEditingController();
  int? _selectedReportType;
  File? _selectedImage;
  String _selectedFileName = '';
  bool _isUploading = false;
  List<Map<String, dynamic>> _userReports = [];

  final List<Map<String, dynamic>> _reportTypes = const [
    {'value': 1, 'label': 'Technical Issue'},
    {'value': 2, 'label': 'User Interface'},
    {'value': 3, 'label': 'Others'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserReports();
  }

  @override
  void dispose() {
    _reportTextController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserReports() async {
    final res = await _apiService.getUserReports();
    if (res['success'] == true && res['reports'] != null) {
      setState(() {
        _userReports = List<Map<String, dynamic>>.from(res['reports']);
      });
    }
  }

  void _showReportsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Reports',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.darkGray),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _userReports.isEmpty
                    ? const Center(child: Text('No reports found.'))
                    : ListView.separated(
                  itemCount: _userReports.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final report = _userReports[index];
                    return _buildReportItem(report);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> report) {
    final typeLabel = _reportTypes.firstWhere((t) => t['value'] == report['reportType'])['label'];
    final dateTime = report['dateTime'] ?? '';
    final text = report['reportText'] ?? '';
    final fileName = report['fileName'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.report_problem_rounded, size: 16, color: AppTheme.redPink),
            const SizedBox(width: 6),
            Text(
              typeLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkGray),
            ),
            const Spacer(),
            Text(
              _formatDate(dateTime),
              style: TextStyle(fontSize: 11, color: AppTheme.darkGray.withOpacity(0.5)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.darkGray)),
        if (fileName.isNotEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              final url = '${ApiService.apiUrl}reportImage/$fileName';
              showFullScreenImage(context, NetworkImage(url));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.redPink.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_outlined, size: 16, color: AppTheme.redPink),
                  const SizedBox(width: 6),
                  Text(fileName, style: TextStyle(fontSize: 11, color: AppTheme.redPink)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _selectedFileName = picked.name;
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.darkGray.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Image Source',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkGray),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: AppTheme.redPink,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReport() async {
    if (_selectedReportType == null) {
      Fluttertoast.showToast(
        msg: 'Please select a report type',
        backgroundColor: AppTheme.redPink,
        textColor: Colors.white,
      );
      return;
    }
    final reportText = _reportTextController.text.trim();
    if (reportText.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please describe the issue',
        backgroundColor: AppTheme.redPink,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isUploading = true);

    final result = await _apiService.sendReport(
      reportText: reportText,
      reportType: _selectedReportType!,
      imageFile: _selectedImage,
    );

    setState(() => _isUploading = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(
        msg: 'Report sent successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      _reportTextController.clear();
      setState(() {
        _selectedImage = null;
        _selectedFileName = '';
        _selectedReportType = null;
      });
      await _fetchUserReports();
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Failed to send report',
        backgroundColor: AppTheme.redPink,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Report a Problem'),
        backgroundColor: AppTheme.redPink,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: _showReportsDialog,
            tooltip: 'My Reports',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildReportTypeCard(),
            const SizedBox(height: 16),
            _buildImageCard(),
            const SizedBox(height: 16),
            _buildDescriptionCard(),
            const SizedBox(height: 24),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.redPink, Color(0xFFE84757)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.redPink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.report_problem_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Help Us Improve',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Report bugs, issues, or suggestions',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.redPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.category_outlined, color: AppTheme.redPink, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Type of Issue',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkGray),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _reportTypes.map((type) {
              final isSelected = _selectedReportType == type['value'];
              return ChoiceChip(
                label: Text(type['label']),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedReportType = selected ? type['value'] : null;
                  });
                },
                selectedColor: AppTheme.redPink,
                backgroundColor: AppTheme.darkGray.withOpacity(0.05),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.darkGray,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.redPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_outlined, color: AppTheme.redPink, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Screenshot (Optional)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkGray),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _selectedImage != null ? AppTheme.redPink.withOpacity(0.05) : const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedImage != null ? AppTheme.redPink.withOpacity(0.4) : AppTheme.darkGray.withOpacity(0.15),
                  width: _selectedImage != null ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedImage != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                    size: 36,
                    color: _selectedImage != null ? AppTheme.redPink : AppTheme.darkGray.withOpacity(0.35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFileName.isEmpty ? 'Tap to add an image' : _selectedFileName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedFileName.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                      color: _selectedFileName.isEmpty ? AppTheme.darkGray.withOpacity(0.4) : AppTheme.darkGray,
                    ),
                  ),
                  if (_selectedFileName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tap to change',
                      style: TextStyle(fontSize: 11, color: AppTheme.redPink.withOpacity(0.6)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.redPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded, color: AppTheme.redPink, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Describe the Problem',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkGray),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reportTextController,
            maxLines: 5,
            maxLength: 500,
            style: const TextStyle(fontSize: 14, color: AppTheme.darkGray),
            decoration: InputDecoration(
              hintText: 'Please describe the issue in detail...',
              hintStyle: TextStyle(color: AppTheme.darkGray.withOpacity(0.35), fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.redPink, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
              counterStyle: TextStyle(color: AppTheme.darkGray.withOpacity(0.4), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _sendReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.redPink,
          foregroundColor: AppTheme.white,
          elevation: 4,
          shadowColor: AppTheme.redPink.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isUploading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, size: 20),
            SizedBox(width: 8),
            Text('Send Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}