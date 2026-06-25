import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/app_path.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              onTap: () => context.go(AppPath.tuner),
              leading: Icon(Icons.tune),
              title: Text('Tuner'),
            ),

            ListTile(
              onTap: () => context.go(AppPath.beat),
              leading: Icon(Icons.timelapse_sharp),
              title: Text('Beat'),
            ),
          ],
        ),
      ),
    );
  }
}
