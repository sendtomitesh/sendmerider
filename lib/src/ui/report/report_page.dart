import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:intl/intl.dart';
import 'package:sendme_rider/src/ui/common/no_internet_screen.dart';

class ReportPage extends StatefulWidget {
  final int riderId;
  const ReportPage({super.key, required this.riderId});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late DateTime selectedStartDate;
  late DateTime selectedEndDate;
  int selectedPaymentMode = 0;

  List<Map<String, dynamic>> summaryList = [];
  List<Map<String, dynamic>> reportList = [];
  int pageIndex = 0;
  int totalPages = 0;

  bool isLoadingSummary = false;
  bool isLoadingList = false;
  bool isLoadingMore = false;

  final _apiService = RiderApiService();
  final _scrollController = ScrollController();

  final _paymentModes = ['Both', 'Cash', 'Online Payment'];
  final _apiDateFormat = DateFormat('MM-dd-yyyy');
  final _orderDateParser = DateFormat('MM/dd/yyyy HH:mm:ss');
  final _displayDateFormat = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedStartDate = DateTime(now.year, now.month, 1);
    selectedEndDate = now;
    _scrollController.addListener(_onScroll);
    _fetchData();
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
        pageIndex + 1 < totalPages) {
      _fetchMoreReports();
    }
  }

  String _formatApiDate(DateTime date) => _apiDateFormat.format(date);

  String _formatOrderDate(String orderOn) {
    try {
      final parsed = _orderDateParser.parse(orderOn);
      return _displayDateFormat.format(parsed);
    } catch (_) {
      return orderOn;
    }
  }

  Future<void> _fetchData() async {
    _fetchSummary();
    _fetchReports(reset: true);
  }

  Future<void> _fetchSummary() async {
    setState(() => isLoadingSummary = true);
    try {
      final result = await _apiService.getRiderReportSummary(
        riderId: widget.riderId,
        fromDate: _formatApiDate(selectedStartDate),
        toDate: _formatApiDate(selectedEndDate),
        paymentMode: selectedPaymentMode,
      );
      if (mounted) setState(() => summaryList = result);
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.message == 'No internet connection') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoInternetScreen()),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    } finally {
      if (mounted) setState(() => isLoadingSummary = false);
    }
  }

  Future<void> _fetchReports({bool reset = false}) async {
    if (reset) {
      setState(() {
        pageIndex = 0;
        reportList = [];
        isLoadingList = true;
      });
    }
    try {
      final result = await _apiService.getRiderReport(
        riderId: widget.riderId,
        fromDate: _formatApiDate(selectedStartDate),
        toDate: _formatApiDate(selectedEndDate),
        paymentMode: selectedPaymentMode,
        pageIndex: pageIndex,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            reportList = result.entries;
          } else {
            reportList = [...reportList, ...result.entries];
          }
          totalPages = result.totalPages;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => isLoadingList = false);
    }
  }

  Future<void> _fetchMoreReports() async {
    setState(() {
      isLoadingMore = true;
      pageIndex++;
    });
    try {
      final result = await _apiService.getRiderReport(
        riderId: widget.riderId,
        fromDate: _formatApiDate(selectedStartDate),
        toDate: _formatApiDate(selectedEndDate),
        paymentMode: selectedPaymentMode,
        pageIndex: pageIndex,
      );
      if (mounted) {
        setState(() {
          reportList = [...reportList, ...result.entries];
          totalPages = result.totalPages;
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: selectedEndDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.mainAppColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedStartDate) {
      setState(() => selectedStartDate = picked);
      _fetchData();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedEndDate,
      firstDate: selectedStartDate,
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.mainAppColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedEndDate) {
      setState(() => selectedEndDate = picked);
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.translate('report') ?? 'Report',
          style: const TextStyle(fontFamily: AssetsFont.textBold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummarySection(),
                  const SizedBox(height: 8),
                  _buildTableHeader(),
                  _buildTableBody(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Expanded(
            child: _buildDateButton('From', selectedStartDate, _pickStartDate),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildDateButton('To', selectedEndDate, _pickEndDate),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedPaymentMode,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.mainAppColor,
                  ),
                  style: TextStyle(
                    fontFamily: AssetsFont.textRegular,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  items: List.generate(
                    _paymentModes.length,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(
                        _paymentModes[i],
                        style: const TextStyle(
                          fontFamily: AssetsFont.textRegular,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null && value != selectedPaymentMode) {
                      setState(() => selectedPaymentMode = value);
                      _fetchData();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: AppColors.mainAppColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _displayDateFormat.format(date),
                style: const TextStyle(
                  fontFamily: AssetsFont.textMedium,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    if (isLoadingSummary) {
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
    if (summaryList.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: summaryList.length,
      itemBuilder: (context, index) {
        final item = summaryList[index];
        final currency = item['Currency'] ?? '';
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currency.toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    currency.toString(),
                    style: TextStyle(
                      fontFamily: AssetsFont.textBold,
                      fontSize: 14,
                      color: AppColors.mainAppColor,
                    ),
                  ),
                ),
              _summaryRow('Total Bill Amount', item['TotalBillAmount']),
              _summaryRow(
                'Delivery Charge Amount',
                item['DeliveryChargeAmount'],
              ),
              _summaryRow(
                'GST on Delivery Charges',
                item['GSTOnDeliveryCharge'],
              ),
              if (item['GSTOnBillAmount'] != null)
                _summaryRow('GST on Bill Amount', item['GSTOnBillAmount']),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AssetsFont.textRegular,
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            '${value ?? 0}',
            style: const TextStyle(
              fontFamily: AssetsFont.textMedium,
              fontSize: 13,
              color: AppColors.textColorBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mainAppColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderCell('Order ID')),
          Expanded(flex: 4, child: _HeaderCell('Date')),
          Expanded(flex: 3, child: _HeaderCell('Delivery')),
          Expanded(flex: 2, child: _HeaderCell('Bill')),
          Expanded(flex: 2, child: _HeaderCell('GST')),
        ],
      ),
    );
  }

  Widget _buildTableBody() {
    if (isLoadingList) {
      return Padding(
        padding: const EdgeInsets.all(32),
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
    if (reportList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No orders',
            style: TextStyle(
              fontFamily: AssetsFont.textRegular,
              fontSize: 15,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reportList.length,
            itemBuilder: (context, index) {
              final entry = reportList[index];
              final orderId = entry['orderId'] ?? '';
              final orderOn = entry['orderOn']?.toString() ?? '';
              final deliveryCharge = entry['deliveryCharge'] ?? 0;
              final totalBill = entry['totalBill'] ?? 0;
              final gst = entry['commissionOnDeliveryCharge'] ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  border: index < reportList.length - 1
                      ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        '$orderId',
                        style: TextStyle(
                          fontFamily: AssetsFont.textMedium,
                          fontSize: 12,
                          color: AppColors.mainAppColor,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        _formatOrderDate(orderOn),
                        style: TextStyle(
                          fontFamily: AssetsFont.textRegular,
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '$deliveryCharge',
                        style: const TextStyle(
                          fontFamily: AssetsFont.textMedium,
                          fontSize: 12,
                          color: AppColors.textColorBold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$totalBill',
                        style: const TextStyle(
                          fontFamily: AssetsFont.textMedium,
                          fontSize: 12,
                          color: AppColors.textColorBold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$gst',
                        style: TextStyle(
                          fontFamily: AssetsFont.textRegular,
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (isLoadingMore)
            Padding(
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
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AssetsFont.textBold,
        fontSize: 12,
        color: AppColors.mainAppColor,
      ),
    );
  }
}
