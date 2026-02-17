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
          return Icon(Icons.star, size: size, color: Colors.amber);
        } else if (index < rating) {
          return Icon(Icons.star_half, size: size, color: Colors.amber);
        }
        return Icon(Icons.star_border, size: size, color: Colors.amber);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: AppColors.mainAppColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: isLoading ? _buildShimmer() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildAverageRating(),
        const Divider(height: 1),
        Expanded(
          child: reviewList.isEmpty
              ? Center(
                  child: Text(
                    'No reviews',
                    style: TextStyle(
                      fontFamily: AssetsFont.textRegular,
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: reviewList.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == reviewList.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.mainAppColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(
              averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontFamily: AssetsFont.textBold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    final decodedComment = _decodeComment(review.comment);
    final formattedDate = _formatDate(review.dateTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(
                    fontFamily: AssetsFont.textBold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  fontFamily: AssetsFont.textRegular,
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildStarRating(review.rating),
          if (decodedComment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              decodedComment,
              style: const TextStyle(
                fontFamily: AssetsFont.textRegular,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(4, (_) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 200,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
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
