import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/src/ui/navigation/rider_bottom_nav.dart';

class RiderDashboard extends StatelessWidget {
  final String riderName;
  const RiderDashboard({super.key, required this.riderName});

  @override
  Widget build(BuildContext context) {
    return RiderBottomNav(riderName: riderName);
  }
}
