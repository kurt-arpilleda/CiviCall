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
    {'value': 1, 'label': 'Technical Issue', 'icon': Icons.build_rounded},
    {'value': 2, 'label': 'UI / Design', 'icon': Icons.palette_rounded},
    {'value': 3, 'label': 'Others', 'icon': Icons.more_horiz_rounded},
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

  void _showReportsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F6FA),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.darkGray.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.redPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.history_rounded, color: AppTheme.redPink, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Reports',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.darkGray),
                            ),
                            Text(
                              '${_userReports.length} submitted',
                              style: TextStyle(fontSize: 12, color: AppTheme.darkGray.withOpacity(0.45)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded, color: AppTheme.darkGray.withOpacity(0.4)),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.darkGray.withOpacity(0.06),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(color: AppTheme.darkGray.withOpacity(0.08), height: 1),
                  ],
                ),
              ),
              Expanded(
                child: _userReports.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_rounded, size: 52, color: AppTheme.darkGray.withOpacity(0.15)),
                      const SizedBox(height: 12),
                      Text(
                        'No reports submitted yet',
                        style: TextStyle(fontSize: 14, color: AppTheme.darkGray.withOpacity(0.4)),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: _userReports.length,
                  itemBuilder: (context, index) => _buildReportCard(_userReports[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final typeMap = _reportTypes.firstWhere(
          (t) => t['value'] == report['reportType'],
      orElse: () => {'label': 'Unknown', 'icon': Icons.help_outline_rounded},
    );
    final typeLabel = typeMap['label'] as String;
    final typeIcon = typeMap['icon'] as IconData;
    final dateTime = report['dateTime'] ?? '';
    final text = report['reportText'] ?? '';
    final fileName = report['fileName'] ?? '';

    final typeColors = {
      1: const Color(0xFFE53935),
      2: const Color(0xFF1565C0),
      3: const Color(0xFF2E7D5E),
    };
    final color = typeColors[report['reportType']] ?? AppTheme.redPink;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 13, color: color),
                      const SizedBox(width: 5),
                      Text(
                        typeLabel,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: AppTheme.darkGray.withOpacity(0.35)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(dateTime),
                      style: TextStyle(fontSize: 11, color: AppTheme.darkGray.withOpacity(0.45)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 13.5, color: AppTheme.darkGray, height: 1.45),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (fileName.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  final url = '${ApiService.apiUrl}reportImage/$fileName';
                  showFullScreenImage(context, NetworkImage(url));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.redPink.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.redPink.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_rounded, size: 14, color: AppTheme.redPink),
                      const SizedBox(width: 6),
                      Text(
                        'View Screenshot',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.redPink),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: _showReportsBottomSheet,
                tooltip: 'My Reports',
              ),
              if (_userReports.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.redPink, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${_userReports.length > 9 ? '9+' : _userReports.length}',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.redPink),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderBanner(),
              const SizedBox(height: 14),
              _buildReportTypeRow(),
              const SizedBox(height: 12),
              Expanded(child: _buildDescriptionField()),
              const SizedBox(height: 12),
              _buildBottomRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.redPink, Color(0xFFE84757)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.redPink.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.report_problem_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Help Us Improve',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Report bugs, issues, or suggestions',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TYPE OF ISSUE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkGray.withOpacity(0.4),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _reportTypes.map((type) {
              final isSelected = _selectedReportType == type['value'];
              final color = isSelected ? AppTheme.redPink : AppTheme.darkGray;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type['value'] != _reportTypes.last['value'] ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedReportType = isSelected ? null : type['value'] as int;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.redPink : AppTheme.darkGray.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.redPink : AppTheme.darkGray.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(type['icon'] as IconData, size: 18, color: isSelected ? Colors.white : color.withOpacity(0.5)),
                          const SizedBox(height: 4),
                          Text(
                            type['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppTheme.darkGray.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              'DESCRIBE THE PROBLEM',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkGray.withOpacity(0.4),
                letterSpacing: 1.1,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _reportTextController,
              maxLines: null,
              expands: true,
              maxLength: 500,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 14, color: AppTheme.darkGray, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Please describe the issue in detail...',
                hintStyle: TextStyle(color: AppTheme.darkGray.withOpacity(0.3), fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                counterStyle: TextStyle(color: AppTheme.darkGray.withOpacity(0.35), fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        _buildImagePickerButton(),
        const SizedBox(width: 12),
        Expanded(child: _buildSendButton()),
      ],
    );
  }

  Widget _buildImagePickerButton() {
    final hasImage = _selectedImage != null;
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 56,
        height: 54,
        decoration: BoxDecoration(
          color: hasImage ? AppTheme.redPink.withOpacity(0.1) : AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? AppTheme.redPink.withOpacity(0.4) : AppTheme.darkGray.withOpacity(0.15),
            width: hasImage ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkGray.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              hasImage ? Icons.image_rounded : Icons.add_photo_alternate_outlined,
              color: hasImage ? AppTheme.redPink : AppTheme.darkGray.withOpacity(0.4),
              size: 24,
            ),
            if (hasImage)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedImage = null;
                    _selectedFileName = '';
                  }),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.redPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
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
            Icon(Icons.send_rounded, size: 18),
            SizedBox(width: 8),
            Text('Send Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}