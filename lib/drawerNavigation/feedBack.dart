import 'package:civicall/api_service.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FeedBackScreen extends StatefulWidget {
  const FeedBackScreen({Key? key}) : super(key: key);

  @override
  State<FeedBackScreen> createState() => _FeedBackScreenState();
}

class _FeedBackScreenState extends State<FeedBackScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _feedbackController = TextEditingController();
  final GlobalKey _starsKey = GlobalKey();

  double _selectedRating = 0;
  double _dragRating = 0;
  bool _isDragging = false;
  bool _isSending = false;
  bool _isLoading = true;
  Map<String, dynamic>? _existingFeedback;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const double _starSize = 48.0;
  static const double _starGap = 8.0;
  static const int _starCount = 5;

  final List<String> _ratingLabels = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];
  final List<Color> _ratingColors = [
    Colors.transparent,
    const Color(0xFFE53935),
    const Color(0xFFFF7043),
    const Color(0xFFFFB300),
    const Color(0xFF66BB6A),
    const Color(0xFF43A047),
  ];

  static const List<String> _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadExistingFeedback();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingFeedback() async {
    setState(() => _isLoading = true);
    final res = await _apiService.getFeedback();
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        _existingFeedback = data;
        _selectedRating = double.tryParse(data['starNum'].toString()) ?? 0;
        _feedbackController.text = data['feedBack'] ?? '';
      });
    }
    setState(() => _isLoading = false);
    _animController.forward();
  }

  bool _canSendFeedback() {
    if (_existingFeedback == null) return true;
    final dateTimeStr = _existingFeedback!['dateTime']?.toString();
    if (dateTimeStr == null) return true;
    final lastSent = DateTime.tryParse(dateTimeStr);
    if (lastSent == null) return true;
    return DateTime.now().difference(lastSent).inDays >= 7;
  }

  String _formatDate(DateTime dt) {
    return '${_months[dt.month]} ${dt.day}, ${dt.year}';
  }

  double _ratingFromLocalX(double localX) {
    final totalWidth = _starCount * _starSize + (_starCount - 1) * _starGap;
    final clampedX = localX.clamp(0.0, totalWidth);
    final starSlot = _starSize + _starGap;
    final rawIndex = clampedX / starSlot;
    final starIndex = rawIndex.floor();
    final posInStar = clampedX - starIndex * starSlot;
    final isHalf = posInStar < _starSize / 2;
    final rating = isHalf
        ? (starIndex + 0.5).clamp(0.5, 5.0)
        : (starIndex + 1.0).clamp(1.0, 5.0);
    return rating;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final box = _starsKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localX = box.globalToLocal(details.globalPosition).dx;
    setState(() {
      _isDragging = true;
      _dragRating = _ratingFromLocalX(localX);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDragging && _dragRating > 0) {
      setState(() {
        _selectedRating = _dragRating;
        _isDragging = false;
        _dragRating = 0;
      });
    }
  }

  void _handleTapDown(TapDownDetails details) {
    final box = _starsKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localX = box.globalToLocal(details.globalPosition).dx;
    setState(() => _selectedRating = _ratingFromLocalX(localX));
  }

  Future<void> _sendFeedback() async {
    if (_selectedRating == 0) {
      Fluttertoast.showToast(
          msg: 'Please select a star rating',
          backgroundColor: AppTheme.redPink,
          textColor: Colors.white);
      return;
    }
    if (_feedbackController.text.trim().isEmpty) {
      Fluttertoast.showToast(
          msg: 'Please write your feedback',
          backgroundColor: AppTheme.redPink,
          textColor: Colors.white);
      return;
    }
    if (!_canSendFeedback()) {
      Fluttertoast.showToast(
          msg: 'You can only send feedback once per week',
          backgroundColor: AppTheme.darkGray,
          textColor: Colors.white);
      return;
    }
    setState(() => _isSending = true);
    final res = await _apiService.sendFeedback(
      starNum: _selectedRating,
      feedback: _feedbackController.text.trim(),
    );
    setState(() => _isSending = false);
    if (res['success'] == true) {
      Fluttertoast.showToast(
          msg: 'Thank you for your feedback!',
          backgroundColor: Colors.green,
          textColor: Colors.white);
      await _loadExistingFeedback();
    } else {
      Fluttertoast.showToast(
          msg: res['message'] ?? 'Failed to send feedback',
          backgroundColor: AppTheme.redPink,
          textColor: Colors.white);
    }
  }

  double get _activeRating => _isDragging ? _dragRating : _selectedRating;

  String get _ratingLabel {
    final r = _activeRating;
    if (r <= 0) return 'Swipe or tap to rate';
    if (r <= 1) return _ratingLabels[1];
    if (r <= 2) return _ratingLabels[2];
    if (r <= 3) return _ratingLabels[3];
    if (r <= 4) return _ratingLabels[4];
    return _ratingLabels[5];
  }

  Color get _ratingColor {
    final r = _activeRating;
    if (r <= 0) return AppTheme.darkGray.withOpacity(0.35);
    if (r <= 1) return _ratingColors[1];
    if (r <= 2) return _ratingColors[2];
    if (r <= 3) return _ratingColors[3];
    if (r <= 4) return _ratingColors[4];
    return _ratingColors[5];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Feedback'),
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
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildRatingCard(),
              const SizedBox(height: 16),
              _buildFeedbackCard(),
              const SizedBox(height: 24),
              _buildSendButton(),
              if (_existingFeedback != null && !_canSendFeedback()) ...[
                const SizedBox(height: 14),
                _buildCooldownBadge(),
              ],
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
            child: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Share Your Experience',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your feedback helps us improve CiviCall',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.redPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_rounded, color: AppTheme.redPink, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rate Your Experience',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSwipeableStars(),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              _ratingLabel,
              key: ValueKey(_ratingLabel),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _ratingColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (_activeRating > 0) ...[
            const SizedBox(height: 6),
            Text(
              _activeRating == _activeRating.roundToDouble()
                  ? '${_activeRating.toInt()} / 5'
                  : '$_activeRating / 5',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.darkGray.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwipeableStars() {
    final totalWidth =
        _starCount * _starSize + (_starCount - 1) * _starGap;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: SizedBox(
        key: _starsKey,
        width: totalWidth,
        height: _starSize,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_starCount, (i) {
            final starNum = i + 1;
            final r = _activeRating;
            final filled = r >= starNum;
            final half = !filled && r >= starNum - 0.5;

            Color starColor;
            if (filled || half) {
              if (r <= 1) starColor = _ratingColors[1];
              else if (r <= 2) starColor = _ratingColors[2];
              else if (r <= 3) starColor = _ratingColors[3];
              else if (r <= 4) starColor = _ratingColors[4];
              else starColor = _ratingColors[5];
            } else {
              starColor = AppTheme.darkGray.withOpacity(0.15);
            }

            return Padding(
              padding: EdgeInsets.only(right: i < _starCount - 1 ? _starGap : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: _starSize,
                height: _starSize,
                child: AnimatedScale(
                  scale: (filled || half) && _isDragging ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  child: Icon(
                    half ? Icons.star_half_rounded : Icons.star_rounded,
                    color: starColor,
                    size: filled || half ? 44 : 36,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
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
                'Tell Us More',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkGray),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _feedbackController,
            maxLines: 5,
            maxLength: 500,
            style: const TextStyle(fontSize: 14, color: AppTheme.darkGray),
            decoration: InputDecoration(
              hintText: 'Write your feedback here...',
              hintStyle: TextStyle(
                  color: AppTheme.darkGray.withOpacity(0.35), fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                BorderSide(color: AppTheme.darkGray.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                BorderSide(color: AppTheme.darkGray.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                const BorderSide(color: AppTheme.redPink, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
              counterStyle: TextStyle(
                  color: AppTheme.darkGray.withOpacity(0.4), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = _canSendFeedback();
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (_isSending || !canSend) ? null : _sendFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.redPink,
          foregroundColor: AppTheme.white,
          disabledBackgroundColor: AppTheme.darkGray.withOpacity(0.15),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: canSend ? 4 : 0,
          shadowColor: AppTheme.redPink.withOpacity(0.3),
        ),
        child: _isSending
            ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5))
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              canSend ? 'Send Feedback' : 'Already Submitted',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCooldownBadge() {
    final dateTimeStr = _existingFeedback?['dateTime']?.toString();
    final lastSent =
    dateTimeStr != null ? DateTime.tryParse(dateTimeStr) : null;
    String nextDateText = '';
    if (lastSent != null) {
      final nextDate = lastSent.add(const Duration(days: 7));
      nextDateText = _formatDate(nextDate);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded,
              color: Color(0xFFF57F17), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nextDateText.isNotEmpty
                  ? 'You can submit again on $nextDateText'
                  : 'You can submit feedback once per week',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFF57F17),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}