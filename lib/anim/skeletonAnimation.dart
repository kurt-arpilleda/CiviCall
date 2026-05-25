import 'package:flutter/material.dart';
import 'package:civicall/theme/app_theme.dart';

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}

class SkeletonCircle extends StatefulWidget {
  final double size;

  const SkeletonCircle({Key? key, required this.size}) : super(key: key);

  @override
  State<SkeletonCircle> createState() => _SkeletonCircleState();
}

class _SkeletonCircleState extends State<SkeletonCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class DrawerHeaderSkeleton extends StatelessWidget {
  const DrawerHeaderSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.white.withOpacity(0.5),
              width: 2.5,
            ),
          ),
          child: ClipOval(
            child: _ShimmerCircle(size: 70),
          ),
        ),
        const SizedBox(height: 14),
        _ShimmerBox(width: 140, height: 14, borderRadius: 6),
        const SizedBox(height: 8),
        _ShimmerBox(width: 180, height: 11, borderRadius: 6),
      ],
    );
  }
}

class AccountDetailsSkeleton extends StatelessWidget {
  const AccountDetailsSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildSkeletonHeader(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSkeletonSection(5),
                const SizedBox(height: 16),
                _buildSkeletonSection(3),
                const SizedBox(height: 16),
                _buildSkeletonSection(7),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonHeader() {
    return Container(
      width: double.infinity,
      color: AppTheme.redPink,
      padding: const EdgeInsets.only(top: 100, bottom: 20),
      child: Column(
        children: [
          _ShimmerCircle(size: 90, lightMode: false),
          const SizedBox(height: 12),
          Center(child: _ShimmerBox(width: 160, height: 16, borderRadius: 8, lightMode: false)),
          const SizedBox(height: 8),
          Center(child: _ShimmerBox(width: 120, height: 12, borderRadius: 6, lightMode: false)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShimmerBox(width: 100, height: 22, borderRadius: 20, lightMode: false),
              const SizedBox(width: 8),
              _ShimmerBox(width: 120, height: 22, borderRadius: 20, lightMode: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonSection(int itemCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(width: 120, height: 13, borderRadius: 6),
            const SizedBox(height: 12),
            ...List.generate(itemCount, (i) => _buildSkeletonTile(i)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonTile(int index) {
    final widths = [160.0, 140.0, 180.0, 100.0, 90.0, 150.0, 110.0];
    final w = widths[index % widths.length];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _ShimmerBox(width: 34, height: 34, borderRadius: 9),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(width: 70, height: 10, borderRadius: 5),
              const SizedBox(height: 5),
              _ShimmerBox(width: w, height: 14, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool lightMode;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.lightMode = true,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.lightMode
                ? Colors.grey.shade300
                : AppTheme.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}

class _ShimmerCircle extends StatefulWidget {
  final double size;
  final bool lightMode;

  const _ShimmerCircle({required this.size, this.lightMode = true});

  @override
  State<_ShimmerCircle> createState() => _ShimmerCircleState();
}

class _ShimmerCircleState extends State<_ShimmerCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.lightMode
                ? Colors.grey.shade300
                : AppTheme.white.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}