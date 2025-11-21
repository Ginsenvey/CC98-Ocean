import 'dart:io';
import 'package:cc98_ocean/pages/boards.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/core/themes/app_themes.dart';
import 'package:cc98_ocean/pages/discover.dart';
import 'package:cc98_ocean/pages/focus.dart';
import 'package:cc98_ocean/pages/index.dart';
import 'package:cc98_ocean/pages/profile.dart';
import 'package:cc98_ocean/pages/settings.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}


class _HomeState extends State<Home> {
  late SidebarXController _controller;
  var selectedIndex = 0; 
  

  @override
  void initState() {
    super.initState();

    _controller = SidebarXController(selectedIndex: 0, extended: false);
    // 1. 监听控制器变化
    _controller.addListener(_onMenuChanged);

    
  }

  void _onMenuChanged() {
    setState(() {
      selectedIndex = _controller.selectedIndex;

    });
  }
  @override
  void dispose() {
    _controller.removeListener(_onMenuChanged);
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    Widget page;
switch (selectedIndex) {
  case 0:
    page = Index();
    break;
  case 1:
    page = Moments();
    break;
  case 2:
    page = Discover();
    break;
  case 3:
    page = Boards();
    break;
  case 4:
    page=Profile(userId: 0,canEscape: false,);
    break;
  case 5:
    page = Settings();
    break;
  default:
    throw UnimplementedError('no widget for $selectedIndex');
}
    
    return LayoutBuilder(
      builder: (context,constraints) {
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if(!kIsWeb)if(Platform.isWindows||Platform.isLinux||Platform.isMacOS)
                  buildSideBar(),
                if(kIsWeb)buildSideBar(),
                Expanded(child: page),
              ],
            ),
          ),
          bottomNavigationBar:kIsWeb?null:(Platform.isAndroid||Platform.isIOS)?BottomNavigationBar(
            type: BottomNavigationBarType.fixed, 
            onTap: (i) =>setState(() {
              selectedIndex=i;
            }),
        currentIndex: selectedIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(FluentIcons.design_ideas_16_regular), label: '首页',),
          BottomNavigationBarItem(icon: Icon(FluentIcons.animal_paw_print_16_regular), label: '动态'),
          BottomNavigationBarItem(icon: Icon(FluentIcons.leaf_one_16_regular), label: '发现'),
          BottomNavigationBarItem(icon: Icon(FluentIcons.board_16_regular), label: '版面'),
          BottomNavigationBarItem(icon: Icon(FluentIcons.person_16_regular), label: '我的'),]
      ):null,
          );
          
      }
    );
  }
  Widget buildSideBar(){
    return SafeArea(
      child: SidebarX(controller: _controller,items: [
                          SidebarXItem(icon: FluentIcons.design_ideas_16_regular,label: '首页',),
                          SidebarXItem(icon: FluentIcons.animal_paw_print_16_regular,label: '收藏'),
                          SidebarXItem(icon: FluentIcons.leaf_one_16_regular,label: '发现'),
                          SidebarXItem(icon: FluentIcons.board_16_regular,label: '版块'),
                        ],
                        extendIcon: FluentIcons.chevron_right_16_regular,
                        collapseIcon: FluentIcons.chevron_left_16_regular,
                        showToggleButton: MediaQuery.of(context).size.width>600,
                        footerItems: [SidebarXItem(icon:FluentIcons.mail_all_read_20_regular,label: '我'),SidebarXItem(icon:FluentIcons.star_settings_20_regular,label: '设置'),],
                        //展开时的主题
                        extendedTheme: SidebarXTheme(width: 200,
                        itemTextPadding: const EdgeInsets.only(left: 16),
                        textStyle: TextStyle(
                          color: ColorTokens.softPurple,
                        ),
                        selectedTextStyle: TextStyle(
                          color:  ColorTokens.softOrange,
                        ),
                        selectedItemDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color:Colors.grey.withOpacity(0.12),
                        ),
                        selectedItemTextPadding: const EdgeInsets.only(left: 16),
                        margin: kIsWeb?const EdgeInsets.fromLTRB(10, 12, 10, 12):((Platform.isAndroid||Platform.isIOS)?const EdgeInsets.fromLTRB(10, 120, 10, 120):const EdgeInsets.fromLTRB(10, 12, 10, 12)),
                        padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                        //此装饰作用于整个导航板
                        decoration: BoxDecoration(    
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                        ),
                        ),
                        ),
                        
                  
                        theme: SidebarXTheme(
                        selectedItemMargin:EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        itemMargin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        margin: kIsWeb?const EdgeInsets.fromLTRB(10, 12, 10, 12):((Platform.isAndroid||Platform.isIOS)?const EdgeInsets.fromLTRB(10, 120, 10, 120):const EdgeInsets.fromLTRB(10, 12, 10, 12)),
                        padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                        textStyle: TextStyle(
                          color: ColorTokens.softPurple,
                        ),
                        selectedItemDecoration: BoxDecoration(
                          
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.withOpacity(0.12),
                        ),
                        decoration: BoxDecoration(
                          color: AppThemes.light.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        width: 64,  
                        
                        iconTheme: const IconThemeData(color: Color.fromARGB(255, 196, 171, 212)),
                        selectedIconTheme: const IconThemeData(color: Color.fromARGB(255, 240, 128, 128)),
                    ),
                      ),
    );
  }
  
}