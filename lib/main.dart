import 'dart:convert';
import 'dart:io';
import 'package:cc98_ocean/boards.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/core/themes/app_themes.dart';
import 'package:cc98_ocean/discover.dart';
import 'package:cc98_ocean/focus.dart';
import 'package:cc98_ocean/index.dart';
import 'package:cc98_ocean/kernel.dart';
import 'package:cc98_ocean/network.dart';
import 'package:cc98_ocean/profile.dart';
import 'package:cc98_ocean/settings.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:sidebarx/sidebarx.dart';
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
      create: (context) => MyAppState(),
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
class MyAppState extends ChangeNotifier {
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final Client client = Client();
  Future<void> _login() async {
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

  // 模拟登录验证
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 标题
              const Text(
                '欢迎回家',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CC98 Ocean',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              
              // 登录表单
              Form(
                key: _formKey,
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // 实际应用中跳转到密码重置页面
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('密码重置功能待实现'),
                            ),
                          );
                        },
                        child: const Text('忘记密码?'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 登录按钮
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                        ),
                        
                          
                      ),
                        child: _isLoading?const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ):const Text("登录",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                    ),
                )],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // 其他登录方式
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '其他',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              
              ElevatedButton(onPressed:()async {
                String status=await Network.checkNetwork();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status)));
              }, child: Text("检查网络")),
              const SizedBox(height: 20),
              
              // 注册链接
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('还没有账号?'),
                  TextButton(
                    onPressed: ()async {
                      await launchUrl(
      Uri.parse("https://www.cc98.org/logon"),
      mode: LaunchMode.externalApplication, // 在外部浏览器打开
      // 可选配置:
      // mode: LaunchMode.inAppWebView, // 在应用内WebView打开
      webViewConfiguration: const WebViewConfiguration(
        enableJavaScript: true, // 启用JavaScript
        enableDomStorage: true, // 启用DOM存储
      ),
      webOnlyWindowName: '_blank', // 网页版在新标签页打开
    );
                    },
                    child: const Text('立即注册'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final model = context.read<MyAppState>();
    return LayoutBuilder(
      builder: (context,constraints) {
        return Scaffold(
          key:model.drawerKey,
          drawer:kIsWeb? null:(Platform.isAndroid||Platform.isIOS ? buildSideBar() : null),
          body: SafeArea(
            child: Row(
              children: [
                if(!kIsWeb)if(Platform.isWindows||Platform.isLinux||Platform.isMacOS)
                  buildSideBar(),
                if(kIsWeb)buildSideBar(),

                Expanded(child: page),
              ],
            ),
          ));
          
      }
    );
  }
  Widget buildSideBar(){
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SidebarX(controller: _controller,items: [
                          SidebarXItem(icon: FluentIcons.design_ideas_16_regular,label: '首页',),
                          SidebarXItem(icon: FluentIcons.star_line_horizontal_3_16_regular,label: '收藏'),
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




