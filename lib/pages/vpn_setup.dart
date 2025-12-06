import 'dart:developer' as dev;

import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/core/kernel.dart';
import 'package:cc98_ocean/pages/login.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VpnSetup extends StatefulWidget {
  const VpnSetup({super.key});

  @override
  State<VpnSetup> createState() => _VpnSetupState();
}
class _VpnSetupState extends State<VpnSetup>{

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // 密码可见性
  bool _obscurePassword = true;
  
  // 登录状态
  bool _isLoading = false;
  String? _errorMessage;
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
      String res=await Connector().vpn.loginAsync(username,password);
      dev.log("尝试登录", name: '调试', error: "");
      if(res=="1"){
        //将cookie保存到安全存储
        Connector().saveAllVpnToken(username,password);
        Connector().injectToken();
        if(await Connector().isVpnUsable()){
          Connector().isVpnEnabled=true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>Login()),
          );
        }
        else{
          String errorMessage=await Connector().getToken("VpnUserName");
          setState(() => _errorMessage = errorMessage);
        }
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
  @override
  Widget build(Object context) {
    return Scaffold(
      body: buildLayout(),
    );
  }
  
   Widget buildLayout() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsGeometry.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(flex: 2,child: Center(child: buildTitle())),
            Expanded(flex: 2,child: buildTip()),
            Expanded(flex: 6,child: buildInputField()),
            Expanded(flex: 4,child: Center(child: buildButton()))
          ],
        ),
        ),
    );
   }
  Widget buildTitle(){
    return const Text(
          '登录WebVPN',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: ColorTokens.primaryLight,
          ),
        );
  }

  Widget buildTip(){
    return Card(
      elevation: 0,
      color: ColorTokens.dividerBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8)),
      child:Padding(padding: EdgeInsetsGeometry.all(8),
      child: Text("使用内置VPN连接到校园网络,或者启用aTrust",style: TextStyle(color: ColorTokens.softGrey),),
      ));
  }
  Widget buildInputField(){
    return Form(key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'VPN账号',
                        prefixIcon: Icon(FluentIcons.weather_sunny_20_regular)
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入WebVPN账号';
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
}