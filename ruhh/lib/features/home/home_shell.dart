import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:ruhh/core/icons/app_icons.dart';

import 'package:ruhh/core/theme/ruhh_tokens.dart';

import 'package:ruhh/core/widgets/ruhh_components.dart';



class HomeShell extends ConsumerWidget {

  const HomeShell({super.key, required this.navigationShell});



  final StatefulNavigationShell navigationShell;



  static final _destinations = [

    RuhhNavDestination(

      icon: AppIcons.home(),

      selectedIcon: AppIcons.home(filled: true),

      path: '/home',

    ),

    RuhhNavDestination(

      icon: AppIcons.wallet(),

      selectedIcon: AppIcons.wallet(filled: true),

      path: '/budget',

    ),

    RuhhNavDestination(

      icon: AppIcons.habit(),

      selectedIcon: AppIcons.habit(filled: true),

      path: '/habit',

    ),

    RuhhNavDestination(

      icon: AppIcons.prayer(),

      selectedIcon: AppIcons.prayer(filled: true),

      path: '/prayer',

    ),

    RuhhNavDestination(

      icon: AppIcons.movie(),

      selectedIcon: AppIcons.movie(filled: true),

      path: '/movie',

    ),

  ];



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final index = navigationShell.currentIndex;



    return Scaffold(

      backgroundColor: Colors.transparent,

      body: Stack(

        fit: StackFit.expand,

        children: [

          navigationShell,

          Positioned(

            left: 0,

            right: 0,

            bottom: 0,

            child: RuhhFloatingNav(

              selectedIndex: index,

              destinations: _destinations,

              onSelected: (i) {

                navigationShell.goBranch(

                  i,

                  initialLocation: i == navigationShell.currentIndex,

                );

              },

            ),

          ),

        ],

      ),

    );

  }

}


