import 'package:flutter/material.dart';
import 'home_tab.dart';

/// Clean MainShell presenting the LabLens dashboard without redundant navbars or sidebars.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeTab();
  }
}

