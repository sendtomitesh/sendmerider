import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:intl/intl.dart';

class ReviewPage extends StatefulWidget {
  final int riderId;
  const ReviewPage({super.key, required this.riderId});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  List<Review> reviewList = [];
  double averageRating = 0.0;
  Map<String, dynamic>? paginationCursor;
  bool isLoading = true;
  bool isLoadingMore = false;

  final _apiService = RiderApiService();
  final _scrollController = ScrollController();
  final _dateParser = DateFormat('yyyy-MM-dd', 'en');
  final _displayDateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchReviews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isLoadingMore &&
        paginationCursor != null &&
        paginationCursor!.isNotEmpty) {
      _fetchMoreReviews();
    }
  }

  Future<void> _fetchReviews() async {
    setState(() => isLoading = true);
    try {
      final result = await _apiService.getRiderReviews(riderId: widget.riderId);
      if (mounted) {
        setState(() {
          reviewList = result.reviews;
          averageRating = result.averageRating;
          paginationCursor = result.pagination;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchMoreReviews() async {
    setState(() => isLoadingMore = true);
    try {
      final result = await _apiService.getRiderReviews(
        riderId: widget.riderId,
        pagination: paginationCursor,
      );
      if (mounted) {
        setState(() {
          reviewList = [...reviewList, ...result.reviews];
          paginationCursor = result.pagination;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => isLoadingMore = false);
    }
  }

  String _decodeComment(String comment) {
    try {
      return utf8.fuse(base64).decode(comment.replaceAll('\n', ''));
    } catch (_) {
      return '';
    }
  }

  String _formatDate(String dateTime) {
    try {
      final parsed = _dateParser.parse(dateTime);
      return _displayDateFormat.format(parsed);
    } catch (_) {
      return dateTime;
    }
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star_rounded, size: size, color: Colors.amber);
        } else if (index < rating) {
          return Icon(Icons.star_half_rounded, size: size, color: Colors.amber);
        }
        return Icon(
          Icons.star_outline_rounded,
          size: size,
          color: Colors.amber.shade200,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.translate('review') ?? 'Reviews',
          style: const TextStyle(fontFamily: AssetsFont.textBold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: isLoading ? _buildShimmer() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildAverageRating(),
        Expanded(
          child: reviewList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_outline_rounded,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No reviews yet',
                        style: TextStyle(
                          fontFamily: AssetsFont.textMedium,
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: reviewList.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == reviewList.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.mainAppColor,
                            ),
                          ),
                        ),
                      );
                    }
                    return _buildReviewItem(reviewList[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAverageRating() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: AssetsFont.textBold,
                  fontSize: 24,
                  color: AppColors.textColorBold,
                ),
              ),
              Text(
                'Average Rating',
                style: TextStyle(
                  fontFamily: AssetsFont.textRegular,
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildStarRating(averageRating, size: 18),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    final decodedComment = _decodeComment(review.comment);
    final formattedDate = _formatDate(review.dateTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.mainAppColor.withValues(alpha: 0.1),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontFamily: AssetsFont.textBold,
                    fontSize: 14,
                    color: AppColors.mainAppColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontFamily: AssetsFont.textMedium,
                        fontSize: 14,
                        color: AppColors.textColorBold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    _buildStarRating(review.rating, size: 14),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontFamily: AssetsFont.textRegular,
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
          if (decodedComment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              decodedComment,
              style: TextStyle(
                fontFamily: AssetsFont.textRegular,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Average rating skeleton
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Review card skeletons
          ...List.generate(4, (_) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
