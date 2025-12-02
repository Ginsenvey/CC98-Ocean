import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:cc98_ocean/controls/fluent_dialog.dart';
import 'package:cc98_ocean/controls/hyperlink_button.dart';
import 'package:cc98_ocean/controls/info_flower.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/core/kernel.dart';
import 'package:cc98_ocean/core/themes/app_themes.dart';
import 'package:cc98_ocean/core/themes/theme_controller.dart';
import 'package:cc98_ocean/pages/home.dart';
import 'package:cc98_ocean/pages/vpn_setup.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
                        buildWindowOperation(FluentIcons.arrow_exit_20_regular,windowManager.close)
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


class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}
class _LoginState extends State<Login> {
  @override
  void initState() {
    super.initState();
    checkState();
  }

  Future<void> checkState()async{
    final AppState=await AuthService().getAppState();
    dev.log(AppState.toString(),name: "应用状态");
    if(AppState==1){
      Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
    }
  }
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    
    try 
    {
      final username = _idController.text.trim();
      final password = _passwordController.text.trim();
      String res=await AuthService.loginAsync(username,password);
      
      if(res=="1"){
        final r=await AuthService().setLoginStatus(true);
        if(r&&await AuthService().getLoginStatus()){
          InfoFlower.showContent(context, child: Text("登录成功"));
          Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
        }
        
      }
      else{
        String errorMessage=res;
      }
    } 
    catch (e) 
    {
      _handleLoginError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  
  
  // 处理错误响应
  void handleError (http.Response response) {
    final statusCode = response.statusCode;
    String errorMessage;
    
    switch (statusCode) {
      case 400:
        errorMessage = '请求参数错误';
        break;
      case 401:
        errorMessage = '用户名或密码错误';
        break;
      case 403:
        errorMessage = '访问被拒绝';
        break;
      case 404:
        errorMessage = '服务未找到';
        break;
      case 500:
        errorMessage = '服务器内部错误';
        break;
      default:
        errorMessage = '登录失败 (错误代码: $statusCode)';
    }
    
    // 尝试解析错误详情
    try {
      final errorJson = json.decode(response.body);
      final errorDesc = errorJson['error_description'] as String?;
      if (errorDesc != null) {
        errorMessage += '\n$errorDesc';
      }
    } catch (_) {}
    
    setState(() => _errorMessage = errorMessage);
  }
  
  // 处理登录异常
  void _handleLoginError(Object e) {
    String errorMessage;
    
    if (e is http.ClientException) {
      errorMessage = '网络连接错误: ${e.message}';
    } else if (e is FormatException) {
      errorMessage = '服务器响应格式错误';
    } else {
      errorMessage = '发生未知错误: ${e.toString()}';
    }
    
    setState(() => _errorMessage = errorMessage);
  }
  

  // 表单控制器
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // 密码可见性
  bool _obscurePassword = true;
  
  // 登录状态
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildLayout(),
      bottomNavigationBar: buildOperation(),
    );
  }

  Widget buildLayout(){
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsGeometry.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(flex: 3,child: buildTitle()),
            Expanded(flex: 4, child: buildInputField()),
            Expanded(flex: 1, child: buildButton()),
            Expanded(flex: 2,child: Center(child: buildTip())),
            
          ],
        ),
        ),
    );
  }

  Widget buildTitle(){
    return Column(
      children: [
        SizedBox(height: 36),
        const Text(
              'CC98 Ocean',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: ColorTokens.primaryLight,
              ),
            ),
        SizedBox(height: 8),
        const Text(
              '欢迎回家',
              style: TextStyle(
                fontSize: 16,
                color: ColorTokens.softGrey,
              ),
            ),
      ],
    );
  }

  Widget buildInputField(){
    return Form(key: _formKey,
                child: Column(
                  children: [
                    // 邮箱/账号输入
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: '昵称',
                        prefixIcon: Icon(FluentIcons.weather_sunny_20_regular)
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入CC98昵称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // 密码输入
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '密码',
                        prefixIcon: Icon(FluentIcons.lock_open_20_regular),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword 
                              ? FluentIcons.eye_20_regular
                              : FluentIcons.eye_off_20_regular
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    
                    // 错误提示
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    // 忘记密码              
                    const SizedBox(height: 36),    
                    // 登录按钮
                    ]));
  }
  Widget buildButton(){
    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                        ),
                        
                          
                      ),
                        child: _isLoading?const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ):const Text("登录",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold))));
  }
  Widget buildTip(){
    return Card(
      elevation: 0,
      color: ColorTokens.dividerBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8)),
      child:Padding(padding: EdgeInsetsGeometry.all(8),
      child: Text("欢迎使用浙江大学校内论坛CC98的跨平台客户端。在登录之前,请阅读并遵守论坛规则。",style: TextStyle(color: ColorTokens.softGrey),),
      ));
  }
  Widget buildOperation(){
    return SafeArea( 
      child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                HyperlinkButton(icon:FluentIcons.toolbox_16_regular,text: "文档",onPressed: () async {
                  final bool loggedIn = await AuthService().getLoginStatus();
                  showDialog(
                    context: context,
                    builder: (context) => FluentDialog.text(
                      title: loggedIn ? "已登录" : "未登录",
                      content: Text("调试"),
                      cancelText: "取消",
                      confirmText: "确认",
                    ),
                  );
                },),
                SizedBox(height: 20,child: VerticalDivider(width: 16,thickness: 1,color: ColorTokens.dividerBlue,)),
                HyperlinkButton(icon:FluentIcons.home_16_regular,text: "主页",onPressed: () => launch("https://www.cc98.org/logon")),
                SizedBox(height: 20,child: VerticalDivider(width: 16,thickness: 1,color: ColorTokens.dividerBlue,)),
                HyperlinkButton(icon:FluentIcons.shape_intersect_16_regular,text: "网络",onPressed: ()async{
                  final appState=await AuthService().initializeNetwork();
                  if(appState==2||appState==3){
                    dev.log("未处于内网环境中，且vpn不可用",name: "网络检测");
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>VpnSetup()));
                  }else{
                    dev.log("处于内网环境中",name: "网络检测");
                  }
                },),
              ],
            ),
    );
  }

}



Future<void> launch(String url)async{
  await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication, // 在外部浏览器打开
      // 可选配置:
      // mode: LaunchMode.inAppWebView, // 在应用内WebView打开
      webViewConfiguration: const WebViewConfiguration(
        enableJavaScript: true, // 启用JavaScript
        enableDomStorage: true, // 启用DOM存储
      ),
      webOnlyWindowName: '_blank', // 网页版在新标签页打开
    );
}





