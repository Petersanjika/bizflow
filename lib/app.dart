import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/business_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/business_setup/business_setup_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessProvider>().loadBusiness();
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BusinessProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!provider.hasBusiness) {
          return const BusinessSetupScreen();
        }
        return const DashboardScreen();
      },
    );
  }
}
