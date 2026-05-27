import 'dart:io';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:civicall/imageViewer.dart';

class UserVerificationScreen extends StatefulWidget {
  const UserVerificationScreen({Key? key}) : super(key: key);

  @override
  State<UserVerificationScreen> createState() => _UserVerificationScreenState();
}

class _UserVerificationScreenState extends State<UserVerificationScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isVerified = false;
  Map<String, dynamic>? _verificationData;
  bool _isUploading = false;
  int? _selectedFileType;
  final List<String> _fileTypes = [
    'Certificate of Registration',
    'Certificate of Graduation',
    'School ID',
    'Valid ID',
  ];
  File? _selectedFile;
  String _selectedFileName = '';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userRes = await _apiService.getUserData();
    if (userRes['success'] == true) {
      final user = userRes['user'];
      _isVerified = (user['isVerified'] == 1);
    }
    final verifRes = await _apiService.getVerificationStatus();
    if (verifRes['success'] == true && verifRes['data'] != null) {
      _verificationData = verifRes['data'];
    }
    setState(() => _isLoading = false);
    _animController.forward();
  }

  Future<void> _pickFile() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
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
              'Select Document Source',
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
                    onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF1565C0),
                    onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Document',
                    color: const Color(0xFF2E7D5E),
                    onTap: () { Navigator.pop(context); _pickDocument(); },
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
        _selectedFileName = picked.name;
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitVerification() async {
    if (_selectedFileType == null) {
      Fluttertoast.showToast(msg: 'Please select a document type', backgroundColor: AppTheme.redPink, textColor: Colors.white);
      return;
    }
    if (_selectedFile == null) {
      Fluttertoast.showToast(msg: 'Please choose a file', backgroundColor: AppTheme.redPink, textColor: Colors.white);
      return;
    }
    setState(() => _isUploading = true);
    final result = await _apiService.uploadVerification(file: _selectedFile!, fileType: _selectedFileType! + 1);
    setState(() => _isUploading = false);
    if (result['success'] == true) {
      Fluttertoast.showToast(msg: 'Document uploaded. Awaiting admin approval.', backgroundColor: Colors.green, textColor: Colors.white);
      await _loadData();
      setState(() { _selectedFile = null; _selectedFileName = ''; _selectedFileType = null; });
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? 'Upload failed', backgroundColor: AppTheme.redPink, textColor: Colors.white);
    }
  }

  Future<void> _reUpload() async {
    setState(() { _verificationData = null; _selectedFile = null; _selectedFileName = ''; _selectedFileType = null; });
  }

  String _getVerificationFileUrl(String fileName) {
    return '${ApiService.apiUrl}fileVerification/$fileName';
  }

  Future<void> _previewVerificationFile(String fileName) async {
    final url = _getVerificationFileUrl(fileName);
    final lower = fileName.toLowerCase();
    final isImage = lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp');
    if (isImage) {
      showFullScreenImage(context, NetworkImage(url));
    } else {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(msg: 'Could not open file', backgroundColor: AppTheme.redPink, textColor: Colors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Account Verification'),
        backgroundColor: AppTheme.redPink,
        foregroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.redPink))
          : FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(),
              const SizedBox(height: 20),
              if (_isVerified) ...[
                _buildVerifiedCard(),
              ] else if (_verificationData != null) ...[
                _buildPendingCard(),
                const SizedBox(height: 16),
                _buildResubmitButton(),
              ] else ...[
                _buildReminderCard(),
                const SizedBox(height: 16),
                _buildUploadForm(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusSub;

    if (_isVerified) {
      statusColor = const Color(0xFF43A047);
      statusIcon = Icons.verified_rounded;
      statusText = 'Account Verified';
      statusSub = 'Your identity has been confirmed';
    } else if (_verificationData != null) {
      statusColor = const Color(0xFFFFB300);
      statusIcon = Icons.hourglass_top_rounded;
      statusText = 'Under Review';
      statusSub = 'We are reviewing your document';
    } else {
      statusColor = AppTheme.redPink;
      statusIcon = Icons.shield_outlined;
      statusText = 'Not Yet Verified';
      statusSub = 'Submit a document to get verified';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
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
            child: Icon(statusIcon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  statusSub,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedCard() {
    return Container(
      padding: const EdgeInsets.all(28),
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
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded, color: Colors.green.shade600, size: 42),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re all set!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.green.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Your account has been verified. You now have full access to all CiviCall features.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.darkGray.withOpacity(0.6), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard() {
    final typeIndex = (_verificationData?['fileType'] as int?) ?? 0;
    final typeName = typeIndex >= 1 && typeIndex <= 4 ? _fileTypes[typeIndex - 1] : 'Unknown';
    final fileName = _verificationData?['fileName'] ?? '';
    final dateTime = _verificationData?['dateTime'] ?? '';

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
                  color: const Color(0xFFFFB300).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hourglass_empty_rounded, color: Color(0xFFFFB300), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Verification Pending',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkGray),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.description_outlined, 'Document Type', typeName),
          const SizedBox(height: 10),
          if (dateTime.isNotEmpty)
            _buildInfoRow(Icons.calendar_today_outlined, 'Submitted', _formatDate(dateTime)),
          const SizedBox(height: 10),
          _buildFilePreviewRow(fileName),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFF57F17), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your document is under review. You may submit a new document if needed.',
                    style: TextStyle(fontSize: 12, color: const Color(0xFFF57F17).withOpacity(0.9)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.redPink.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 13, color: AppTheme.darkGray.withOpacity(0.5), fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.darkGray, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildFilePreviewRow(String fileName) {
    return GestureDetector(
      onTap: fileName.isNotEmpty ? () => _previewVerificationFile(fileName) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.redPink.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.redPink.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file_rounded, size: 16, color: AppTheme.redPink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileName.isNotEmpty ? fileName : 'No file',
                style: const TextStyle(fontSize: 13, color: AppTheme.redPink, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.redPink),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildResubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _reUpload,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Submit New Document', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.redPink,
          side: const BorderSide(color: AppTheme.redPink),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildReminderCard() {
    final List<String> reminders = [
      'Must have a picture (ID)',
      'Valid ID must be government-issued',
      'Name must match your App account',
      'Documents must be issued by BSU',
      'Account information must be complete',
    ];

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
                child: const Icon(Icons.checklist_rounded, color: AppTheme.redPink, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Requirements',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkGray),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Indicate the document type before uploading. Accepted: JPG, PNG, WEBP, PDF (max 10MB)',
            style: TextStyle(fontSize: 12, color: AppTheme.darkGray.withOpacity(0.5), height: 1.5),
          ),
          const SizedBox(height: 14),
          ...reminders.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(color: AppTheme.redPink, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 11),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(r, style: const TextStyle(fontSize: 13, color: AppTheme.darkGray))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildUploadForm() {
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
                child: const Icon(Icons.upload_file_rounded, color: AppTheme.redPink, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Submit Document',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkGray),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDropdown(),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _selectedFile != null
                    ? AppTheme.redPink.withOpacity(0.05)
                    : const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedFile != null
                      ? AppTheme.redPink.withOpacity(0.4)
                      : AppTheme.darkGray.withOpacity(0.15),
                  width: _selectedFile != null ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                    size: 36,
                    color: _selectedFile != null ? AppTheme.redPink : AppTheme.darkGray.withOpacity(0.35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFileName.isEmpty ? 'Tap to choose a file' : _selectedFileName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedFileName.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                      color: _selectedFileName.isEmpty
                          ? AppTheme.darkGray.withOpacity(0.4)
                          : AppTheme.darkGray,
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _submitVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redPink,
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: AppTheme.redPink.withOpacity(0.3),
              ),
              child: _isUploading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Submit for Verification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedFileType,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Document Type',
        labelStyle: TextStyle(fontSize: 13, color: AppTheme.darkGray.withOpacity(0.5)),
        prefixIcon: const Icon(Icons.description_outlined, size: 20, color: AppTheme.redPink),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.redPink, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: _fileTypes.asMap().entries.map((entry) {
        return DropdownMenuItem<int>(
          value: entry.key,
          child: Text(entry.value, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedFileType = value),
    );
  }
}