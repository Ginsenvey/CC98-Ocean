import 'dart:io';

import 'package:cc98_ocean/controls/fluent_dialog.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/core/themes/setting_controller.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';


class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _compactMode = false;
  List<String> themeList = ['跟随系统', '浅色模式', '深色模式'];
  
  @override
  void initState() {
    super.initState();
  }

  // 退出登录确认
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => FluentDialog(
        title: '确认退出登录？',
        content: const Text('退出后需要重新登录。'),
        cancelText: '取消',
        confirmText: '退出',
        onCancel: () => Navigator.pop(context),
        onConfirm: () {
          Navigator.pop(context);
          // 这里添加实际退出逻辑
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已退出登录')),
          );
        },
      )
    );
  }

  // 打开GitHub仓库
  Future<void> _openGithubRepo() async {
    const url = 'https://github.com/Ginsenvey/CC98-Ocean';
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('无法打开: $url');
    }
  }

  // 主题颜色选择器
  void _showColorPicker() {
    final colors = [
      ColorTokens.softPurple, Colors.red, ColorTokens.softPink,  ColorTokens.primaryLight, ColorTokens.primaryDark,
      Colors.blue, Colors.lightBlue, Colors.cyan, Colors.teal, Colors.green,
      Colors.lightGreen, Colors.lime, Colors.yellow, Colors.amber, Colors.orange,
      Colors.deepOrange, Colors.brown, Colors.grey, Colors.blueGrey,
    ];

    showDialog(
      context: context,
      builder: (context) {
        final appState = Provider.of<AppState>(context, listen: false);
        return AlertDialog(
          title: const Text('选择主题色'),
          content: SizedBox(
            width: double.minPositive,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  appState.setPrimaryColor(colors[index]); // 实时生效并持久化
                  Navigator.pop(context);
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(4),
                    shape: BoxShape.rectangle,
                  ),
                ),
              ),
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        );
      },
    );
  }
  String get platform => switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS     => 'IOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.macOS  => 'macOS',
      TargetPlatform.linux   => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  
  String get arch {
  final p = Platform.version; // 例：2.19.0-... (x64) linux-x64
  if (p.contains('x64'))  return 'x64';
  if (p.contains('arm64')) return 'arm64';
  if (p.contains('arm'))   return 'arm';
  if (p.contains('ia32'))  return 'ia32';
  return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final itemList = themeList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList();
    
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),       
        actionsPadding: EdgeInsets.only(right: 13),
        centerTitle: true,
        actions: [
          FluentIconbutton(icon: FluentIcons.more_horizontal_16_regular,iconColor: ColorTokens.softPurple,),
        ],
        title: const Text("设定",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: ColorTokens.primaryLight),)

      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            // 账户设置
            _buildSectionHeader('账户'),
            ListTile(
              title: const Text('退出登录'),
              leading: const Icon(FluentIcons.sign_out_20_regular),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
              onTap: _confirmLogout,
            ),
            
        
            // 个性化设置
            _buildSectionHeader('个性化'),
            ListTile(
              title: const Text('主题模式'),
              leading: const Icon(FluentIcons.weather_moon_16_regular),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
              trailing: DropdownButtonHideUnderline(
  child: DropdownButton2<String>(
    iconStyleData: IconStyleData(icon:Icon(FluentIcons.chevron_down_12_regular,size: 20)),
    value: themeList[appState.themeMode],
    dropdownStyleData: DropdownStyleData(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: kElevationToShadow[4],
      ),
    ),
    buttonStyleData: ButtonStyleData(
      height: 36,
      padding: EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
      ),
    ),
    items:itemList,
    onChanged: (v) {
      final idx = themeList.indexOf(v ?? '跟随系统');
      appState.setThemeMode(idx); // 实时生效并持久化
    },
  ),
)
            ),
            ListTile(
              title: const Text('主题颜色'),
              subtitle: const Text("实验性功能。仅部分区域生效"),
              leading: const Icon(FluentIcons.paint_brush_16_regular),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: appState.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                  shape: BoxShape.rectangle,
                ),
              ),
              onTap: _showColorPicker,
            ),
        
        
            // 浏览偏好
            _buildSectionHeader('浏览偏好'),
            SwitchListTile(
              title: const Text('无图模式'),
              subtitle: const Text('折叠所有帖子中的图片'),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
              value: _compactMode,
              onChanged: (value) => setState(() => _compactMode = value),
              secondary: const Icon(FluentIcons.line_horizontal_3_16_regular),
            ),
            
            SwitchListTile(
              title: const Text('使用小尾巴'),
              subtitle: const Text('发送消息显示客户端类型'),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
              value: appState.useTail,
              onChanged: (value) => appState.setTailMode(value),
              secondary: const Icon(FluentIcons.phone_desktop_16_regular),
            ),
        
            // 关于应用
            _buildSectionHeader('关于应用'),
            ListTile(
              title: const Text('版本信息'),
              subtitle: Text('1.1.0 (build 2025.11) $platform $arch'),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
              leading: const Icon(FluentIcons.info_16_regular),
            ),
            ListTile(
              title: const Text('GitHub仓库'),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
              leading: const Icon(FluentIcons.code_16_regular),
              trailing: const Icon(FluentIcons.open_16_regular),
              onTap: _openGithubRepo,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 分区标题组件
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}