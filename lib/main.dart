import 'dart:io';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/core/kernel.dart';
import 'package:cc98_ocean/core/themes/app_themes.dart';
import 'package:cc98_ocean/core/themes/setting_controller.dart';
import 'package:cc98_ocean/pages/home.dart';
import 'package:cc98_ocean/pages/login.dart';
import 'package:cc98_ocean/pages/vpn_setup.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

 void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  if(!kIsWeb){
    if(Platform.isWindows||Platform.isMacOS||Platform.isLinux){
    await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    titleBarStyle: TitleBarStyle.hidden, // 隐藏默认标题栏
    size: Size(800, 600),
    center: true,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  }
  }
  
  MediaKit.ensureInitialized();
  await AuthService().init();
  int appState=await AuthService().getAppState();
  runApp(CC98(appState:appState));
}

class CC98 extends StatelessWidget {
  final int appState;
  
  const CC98({super.key, required this.appState});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(), 
      child: Consumer<AppState>(
        builder: (context, appStateProvider, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CC98 Ocean',
          theme: AppThemes.light.copyWith(
            colorScheme: AppThemes.light.colorScheme.copyWith(
              primary: appStateProvider.primaryColor,
            ),
          ),
          darkTheme: AppThemes.dark.copyWith(
            colorScheme: AppThemes.dark.colorScheme.copyWith(
              primary: appStateProvider.primaryColor,
            ),
          ),
          themeMode: appStateProvider.themeModeEnum,
          home: buildAppBody(appState),                                               
        ),
      ),
    );
  }
}


Widget buildAppBody(int appState){
  if(kIsWeb)return appState==1?Home():(appState==2?VpnSetup():Login());
  if(Platform.isAndroid||Platform.isIOS)return appState==1?Home():(appState==2?VpnSetup():Login());
  return  Scaffold(
        body: Column(
          children: [
            SizedBox(
              height: 48.0, 
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        // 使标题栏可拖动
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (details) {
                          windowManager.startDragging();
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text('CC98 Ocean'),
                        ),)),
                        Row(
                      children: [
                        buildWindowOperation(FluentIcons.arrow_minimize_16_regular,windowManager.minimize),
                        buildWindowOperation(FluentIcons.maximize_16_regular,windowManager.maximize),
                        buildWindowOperation(FluentIcons.dismiss_16_regular,windowManager.close)
                      ],
                    ),
                        ]),
              )),
                      Expanded(child:appState==1?Home():(appState==2?VpnSetup():Login()) )
                      ]));
}
Widget buildWindowOperation(IconData icon,VoidCallback? onPressed) {
    return TextButton(
            onPressed:()=>{onPressed?.call()}, 
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              fixedSize: const Size.square(48),
              minimumSize: Size(32,32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Icon(icon,color: ColorTokens.softPurple));
  }
