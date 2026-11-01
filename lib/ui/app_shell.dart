import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_session.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.location,
    required this.authSession,
    required this.child,
    super.key,
  });

  final String location;
  final AuthSession authSession;
  final Widget child;

  int get _selectedIndex {
    if (location.startsWith('/tags')) return 1;
    if (location.startsWith('/nomenclatures')) return 2;
    if (location.startsWith('/settings')) return 3;
    if (location.startsWith('/about')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    context.go(const ['/tasks', '/tags', '/nomenclatures', '/settings', '/about'][index]);
  }

  @override
  Widget build(BuildContext context) {
    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Tasks',
      ),
      NavigationDestination(
        icon: Icon(Icons.sell_outlined),
        selectedIcon: Icon(Icons.sell),
        label: 'Tags',
      ),
      NavigationDestination(
        icon: Icon(Icons.account_tree_outlined),
        selectedIcon: Icon(Icons.account_tree),
        label: 'Nomenclatures',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
      NavigationDestination(
        icon: Icon(Icons.info_outline),
        selectedIcon: Icon(Icons.info),
        label: 'About',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) => _navigate(context, index),
                    extended: constraints.maxWidth >= 1180,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Icon(
                        Icons.layers_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    trailing: authSession.isAuthenticated
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: IconButton(
                              onPressed: authSession.logout,
                              tooltip: 'Sign out ${authSession.user!.username}',
                              icon: const Icon(Icons.logout),
                            ),
                          )
                        : null,
                    destinations: destinations
                        .map(
                          (destination) => NavigationRailDestination(
                            icon: destination.icon,
                            selectedIcon: destination.selectedIcon,
                            label: Text(destination.label),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          body: child,
          bottomNavigationBar: Row(
            children: [
              Expanded(
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => _navigate(context, index),
                  destinations: destinations,
                ),
              ),
              if (authSession.isAuthenticated)
                SafeArea(
                  child: IconButton(
                    onPressed: authSession.logout,
                    tooltip: 'Sign out ${authSession.user!.username}',
                    icon: const Icon(Icons.logout),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}
