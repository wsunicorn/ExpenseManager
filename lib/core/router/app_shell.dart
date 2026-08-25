import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Khung ngoài chứa thanh điều hướng 5 tab ở đáy.
///
/// Thứ tự tab giữ nguyên như MoneyNote (`00_TONG_QUAN.md` mục 2, phần "Giữ
/// lại"): Nhập vào / Lịch / Báo cáo / Ngân sách / Khác. Không phải vì MoneyNote
/// đúng về lý thuyết, mà vì chủ dự án đã quen tay — đổi thứ tự chỉ tạo ma sát
/// vô ích.
///
/// Tab đầu là **Nhập vào**, không phải Tổng quan: chỉ số thành công thật sự của
/// app này là bạn có ghi chi tiêu đều đặn hay không (file 07 mục 1.4). Mở app ra
/// là nhập được ngay, không phải chạm thêm lần nào.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Chạm lại tab đang mở thì quay về gốc của tab đó — hành vi người
          // dùng mong đợi ở mọi app có thanh tab.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: 'Nhập vào',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Báo cáo',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Ngân sách',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Khác',
          ),
        ],
      ),
    );
  }
}
