import 'dart:convert';
import 'dart:io';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/hyperlink_button.dart';
import 'package:cc98_ocean/controls/text_field.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/core/themes/app_themes.dart';
import 'package:cc98_ocean/home.dart';
import 'package:cc98_ocean/kernel.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

 void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await AuthService().init();
  
  // 检查登录状态
  final isLoggedIn = await AuthService().getLoginStatus();
  runApp(CC98(isLoggedIn: isLoggedIn));
}

class CC98 extends StatelessWidget {
  final bool isLoggedIn;
  
  const CC98({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'CC98 Ocean',
        theme: AppThemes.light,
        home:isLoggedIn?Home():Login()
      
      ),
    );
  }
}
class RouteGuard extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) async {
    await _checkAuth(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) async {
    if (newRoute != null) {
      await _checkAuth(newRoute);
    }
  }

  Future<void> _checkAuth(Route<dynamic> route) async {
    final settings = route.settings;
    
    // 需要认证的路由
    const protectedRoutes = ['/home', '/profile', '/settings'];
    
    if (protectedRoutes.contains(settings.name)) {
      final isLoggedIn = await AuthService().getLoginStatus();
      
      if (!isLoggedIn) {
        // 延迟执行以避免在路由变化过程中修改路由
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(
            navigator!.context,
            '/login',
            arguments: {'redirect': settings.name},
          );
        });
      }
    }
  }
}
class AppState extends ChangeNotifier {
  
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final Client client = Client();
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try 
    {
      final username = _idController.text.trim();
      final password = _passwordController.text.trim();
      String res=await AuthService.loginAsync(username,password);
      if(res=="1"){
        final r=await AuthService().setLoginStatus(true);
        if(r&&await AuthService().getLoginStatus()){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已保存凭据')),
          );
        }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Home()),
          );
      }
      else{
        String errorMessage=res;
        setState(() => _errorMessage = errorMessage);
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
      body: buildLayout()
    );
  }

  Widget buildLayout(){
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsGeometry.all(16),
          child: Column(
            spacing: 36,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(child: buildTitle()),
              Center(child: buildInputField()),
              buildTip(),
              buildOperation(),
            ],
          ),
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
                    SizedBox(
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
                        ):const Text("登录",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold))))]));
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
    return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              HyperlinkButton(icon:FluentIcons.document_16_regular,text: "文档"),
              SizedBox(height: 20,child: VerticalDivider(width: 16,thickness: 1,color: ColorTokens.dividerBlue,)),
              HyperlinkButton(icon:FluentIcons.home_16_regular,text: "主页",onPressed: () => launch("https://www.cc98.org/logon")),
              SizedBox(height: 20,child: VerticalDivider(width: 16,thickness: 1,color: ColorTokens.dividerBlue,)),
              HyperlinkButton(icon:FluentIcons.shape_intersect_16_regular,text: "网络"),
           
            ],
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





