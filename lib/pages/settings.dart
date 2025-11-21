import 'dart:io';

import 'package:cc98_ocean/controls/fluent_dialog.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
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
  // 状态变量
  ThemeMode _themeMode = ThemeMode.system;
  Color _themeColor = Colors.blue;
  bool _compactMode = false;
  bool _showAvatars = true;
  bool _useFooters = true;

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
    const url = 'https://github.com/yourusername/yourapp';
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('无法打开: $url');
    }
  }

  // 主题颜色选择器
  void _showColorPicker() {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                setState(() => _themeColor = colors[index]);
                Navigator.pop(context);
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colors[index],
                  borderRadius: BorderRadius.circular(8),
                  shape: BoxShape.rectangle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> list = ['跟随系统', '浅色模式', '深色模式'];
    final itemList= list.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList();
    String? selected="跟随系统";
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),       
        actionsPadding: EdgeInsets.only(right: 13),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
          child: FluentIconbutton(
            icon: FluentIcons.panel_left_expand_16_regular,
          ),
        ),
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
    value: selected,
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
        border: Border.all(color: ColorTokens.softPurple, width: 1),
      ),
    ),
    items:itemList,
    onChanged: (v) => setState(() => selected =itemList.firstWhere((e)=>e.value==v).value),
  ),
)
            ),
            ListTile(
              title: const Text('主题颜色'),
              leading: const Icon(FluentIcons.paint_brush_16_regular),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _themeColor,
                  borderRadius: BorderRadius.circular(5),
                  shape: BoxShape.rectangle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
              onTap: _showColorPicker,
            ),
        
        
            // 浏览偏好
            _buildSectionHeader('浏览偏好'),
            SwitchListTile(
              title: const Text('紧凑模式'),
              subtitle: const Text('减少内容间距，显示更多信息'),
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
              value: _useFooters,
              onChanged: (value) => setState(() => _useFooters = value),
              secondary: const Icon(FluentIcons.phone_desktop_16_regular),
            ),
        
            // 关于应用
            _buildSectionHeader('关于应用'),
            ListTile(
              title: const Text('版本信息'),
              subtitle: const Text('1.0.0 (build 2025.8)'),
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