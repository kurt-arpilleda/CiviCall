import 'dart:io';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class UserVerificationScreen extends StatefulWidget {
  const UserVerificationScreen({Key? key}) : super(key: key);

  @override
  State<UserVerificationScreen> createState() => _UserVerificationScreenState();
}

class _UserVerificationScreenState extends State<UserVerificationScreen> {
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
    'Valid ID'
  ];
  File? _selectedFile;
  String _selectedFileName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
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
  }

  Future<void> _pickFile() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
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
              'Select Document',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkGray,
              ),
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
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Document',
                    color: const Color(0xFF2E7D5E),
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocument();
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
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
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
      Fluttertoast.showToast(
        msg: 'Please select a document type',
        backgroundColor: AppTheme.redPink,
        textColor: Colors.white,
      );
      return;
    }
    if (_selectedFile == null) {
      Fluttertoast.showToast(
        msg: 'Please choose a file',
        backgroundColor: AppTheme.redPink,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isUploading = true);
    final result = await _apiService.uploadVerification(
      file: _selectedFile!,
      fileType: _selectedFileType! + 1,
    );
    setState(() => _isUploading = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(
        msg: 'Verification document uploaded. Please wait for admin approval.',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      await _loadData();
      setState(() {
        _selectedFile = null;
        _selectedFileName = '';
        _selectedFileType = null;
      });
    } else {
      Fluttertoast.showToast(
        msg: result['message'] ?? 'Upload failed',
        backgroundColor: AppTheme.redPink,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _reUpload() async {
    setState(() {
      _verificationData = null;
      _selectedFile = null;
      _selectedFileName = '';
      _selectedFileType = null;
    });
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_isVerified) ...[
              _buildVerifiedCard(),
            ] else if (_verificationData != null) ...[
              _buildPendingCard(),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _reUpload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Submit New Document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.redPink,
                  side: const BorderSide(color: AppTheme.redPink),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ] else ...[
              _buildReminderCard(),
              const SizedBox(height: 24),
              _buildUploadForm(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_rounded, color: Colors.green.shade600, size: 64),
          const SizedBox(height: 12),
          Text(
            'Your account is verified',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you for completing the verification process.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard() {
    final typeIndex = (_verificationData?['fileType'] as int?) ?? 0;
    final typeName = typeIndex >= 1 && typeIndex <= 4
        ? _fileTypes[typeIndex - 1]
        : 'Unknown';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
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
          const Icon(Icons.hourglass_empty_rounded, size: 48, color: AppTheme.redPink),
          const SizedBox(height: 12),
          const Text(
            'Verification Pending',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Document: $typeName',
            style: const TextStyle(fontSize: 14, color: AppTheme.darkGray),
          ),
          Text(
            'File: ${_verificationData?['fileName'] ?? ''}',
            style: const TextStyle(fontSize: 13, color: AppTheme.darkGray),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your document is under review by the admin. You may submit a new document if needed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.darkGray),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
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
              Icon(Icons.info_outline_rounded, color: AppTheme.redPink, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Reminders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Kindly indicate the document type you are submitting. Once the file name is displayed, feel free to change its name.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.darkGray.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _buildBullet('Must have a picture (ID)'),
          _buildBullet('Valid ID must be government-issued'),
          _buildBullet('Name must match with your App account'),
          _buildBullet('Documents must be issued by BSU'),
          _buildBullet('Account information must be provided completely'),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, color: AppTheme.redPink)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppTheme.darkGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
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
          const Text(
            'Submit Verification Document',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          _buildDropdown(),
          const SizedBox(height: 20),
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.darkGray.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF8F9FC),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 36, color: AppTheme.redPink),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFileName.isEmpty ? 'Choose File' : _selectedFileName,
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedFileName.isEmpty
                          ? AppTheme.darkGray.withOpacity(0.6)
                          : AppTheme.darkGray,
                    ),
                  ),
                  if (_selectedFileName.isNotEmpty)
                    const SizedBox(height: 4),
                  if (_selectedFileName.isNotEmpty)
                    Text(
                      'Tap to change',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.redPink.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _submitVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redPink,
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Text(
                'Send',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
        prefixIcon: const Icon(Icons.description_outlined, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.darkGray.withOpacity(0.12)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: _fileTypes.asMap().entries.map((entry) {
        return DropdownMenuItem<int>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedFileType = value),
      validator: (v) => v == null ? 'Required' : null,
    );
  }
}