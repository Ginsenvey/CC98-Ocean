import 'dart:convert';
import 'package:cc98_ocean/core/network/vpn_service.dart';
import 'package:cc98_ocean/pages/focus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;
///API连接器
class Connector {
  static final Connector _instance = Connector._internal();
  factory Connector() => _instance;
  bool isVpnEnabled = false;
  VpnService vpn=VpnService();
  static const FlutterSecureStorage vault = FlutterSecureStorage();
  String? _accessToken;
  String vpnHeader="";
  Connector._internal() {
    _loadToken();
  }
  Future<void> _loadToken() async {
    _accessToken = await vault.read(key: 'access');
  }
  Future<void> saveToken(String name,String token) async {
    _accessToken = token;
    await vault.write(key: name, value: token);
  }
  Future<void> clearToken() async {
    _accessToken = null;
    await vault.delete(key: 'access');
    await vault.delete(key: 'refresh');
  }
  ///将cookie映射连接为可用的cookie字符串
  String getCookieHeader(Map<String,String> cookies) {
    if (cookies.isEmpty) return '';
    return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }
  ///注入VPN凭据.必须先确保isVpnUsable==true,否则注入的是空字符串
  Future<void> injectToken()async{
    String ticket=await getToken("ticket");
    String route=await getToken("route");
    final cookies=<String,String>{
      "wengine_vpn_ticketwebvpn_zju_edu_cn":ticket,
      "route":route,
    };
    dev.log(ticket=="0"?"凭据为空":ticket,name: "凭据注入");
    vpnHeader=getCookieHeader(cookies);
  }
  void saveAllVpnToken(String id,String pass){
    Connector().saveToken("vpnUserName",id);
    Connector().saveToken("vpnPassword", pass);
    Connector().saveToken("ticket", vpn.ticket??"");
    Connector().saveToken("route", vpn.route??"");
  }
  Future<bool> isVpnUsable() async{
    String id=await getToken("vpnUserName");
    String pass=await getToken("vpnPassword");
    String ticket=await getToken("ticket");
    String route=await getToken("route");
    return id!="0"&&pass!="0"&&ticket!="0"&&route!="0";
  }
  Future<String> getToken(String key) async{
    final value = await vault.read(key: key);
    if(value!=null&&value.isNotEmpty){
      return value;
    }
    else{
      return "0";
    }
  }
  Future<String> checkNetwork(bool useVpn) async {
    const mirrorUrl = "https://mirrors.zju.edu.cn/api/is_campus_network";
    final targetUri = useVpn ?VpnService.convertUrl(mirrorUrl) : mirrorUrl;
    
    try {
      final header=<String,String>{
        "Cookie":vpnHeader
      };
      final response = await http.get(Uri.parse(targetUri),headers: header);
      if (response.statusCode == 200) {
        final resText = response.body.trim();
        dev.log("检测vpn网络,url为$targetUri",name:"网络检测");
        dev.log(resText[0],name: "网络检测结果");
        if (resText == "0") {
          return "0";
        } else if (resText == "1" || resText == "2") {
          return "1";
        } else if(resText.contains("WebVPN")){
          return "0";//cookie过期的情况
        }
        else {
          return "404:非法返回";
        }
      } else {
        return "404:请求失败";
      }
    } catch (e) {
      return "404:${e.toString()}";
    }
  }
  // 封装 GET 请求
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    return await _request('GET', url, headers: headers);
  }
  
  // 封装 POST 请求
  Future<http.Response> post(String url, {Map<String, String>? headers, Object? body}) async {
    return await _request('POST', url, headers: headers, body: body);
  }

  // 封装 PUT 请求
  Future<http.Response> put(String url, {Map<String, String>? headers, Object? body}) async {
    return await _request('PUT', url, headers: headers, body: body);
  }
  
  //封装 DELETE 请求
  Future<http.Response> delete(String url, {Map<String, String>? headers, Object? body}) async {
    return await _request('DELETE', url, headers: headers, body: body);
  }
  Future<bool> refreshToken() async {
    try {
      const refreshUrl = "https://openid.cc98.org/connect/token";
      final refreshToken = await vault.read(key: 'refresh');
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }
      
      final response = await post(
        refreshUrl,
        body: {
          "grant_type": "refresh_token",
          "refresh_token": refreshToken,
          "client_id": "9a1fd200-8687-44b1-4c20-08d50a96e5cd",
          "client_secret": "8b53f727-08e2-4509-8857-e34bf92b27f2",
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final newAccessToken = jsonResponse['access_token'] as String?; 
        if (newAccessToken != null) {
          _accessToken = newAccessToken;
          saveToken("access", newAccessToken);
          return true;
        } else {
          throw Exception('Failed to refresh token: missing tokens in response');
        }
      } else {
        throw Exception('Token refresh failed: ${response.statusCode}');
      }
    } catch (e) {
      await clearToken();
      rethrow;
    }
    
  }
  String _encodeFormData(Map<String, String> data) {
    return data.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
  }
  // 统一请求方法
  Future<http.Response> _request(
    String method,
    String originUrl, {
    Map<String, String>? headers,
    Object? body,
    int retryCount = 0,
    
  }) async {
    if (_accessToken == null) {
      await _loadToken();
    }
    String url=isVpnEnabled?VpnService.convertUrl(originUrl):originUrl;
    // 如果设置了内容类型，则使用此类型
    final contentType = headers?['Content-Type'] ?? '';
    dev.log(url);
    // 处理请求体
    Object? finalBody;
    //如果未设置类型，判断内容是否为映射表，并进行转换
    if (contentType == 'application/x-www-form-urlencoded' && body is Map<String, String>) {
      finalBody = _encodeFormData(body);// 编码为表单数据
    } else if (body != null) {
      finalBody = body; // 其他类型直接使用
    }
    
    //设置内容和鉴权请求头
    final defaultHeaders = {
      if (contentType != 'multipart/form-data'&&contentType!="") 'Content-Type': contentType,// 避免 multipart/form-data 重复设置
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      if(vpnHeader!="")'Cookie':vpnHeader
    };
    
    //headers为请求参数中自定义的请求头；defaultHeaders用于自动填充内容类型和鉴权令牌
    final mergedHeaders = {...defaultHeaders, ...?headers};
    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: mergedHeaders);
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: mergedHeaders,
            body: finalBody,
          );
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: mergedHeaders,
            body: finalBody,
          );
          break;
        case 'DELETE':
          response = await http.delete(
            Uri.parse(url),
            headers: mergedHeaders,
            body: finalBody,
          );
          break;
        default:
          throw UnsupportedError('不支持此类型的HTTP方法: $method');
      }
      
      
      
      // 处理未授权错误
      if (response.statusCode == 401 && retryCount == 0) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return _request(method, url, headers: headers, body: body, retryCount: retryCount + 1);
        }
      }
      
      // 处理400错误，提供更多信息
      if (response.statusCode == 400) {
        String errorDetails = '请求参数错误';
        try {
          final errorJson = json.decode(response.body);
          errorDetails += ': ${errorJson['error']} - ${errorJson['error_description']}';
        } catch (_) {
          errorDetails += ': ${response.body}';
        }
        throw Exception(errorDetails);
      }
      
      return response;
    } catch (e) {
      
      rethrow;
    }
  }
}
class AuthService
{
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  static SharedPreferences? set;
  AuthService._internal();
  
  //初始化配置
  Future<void> init() async {
    set = await SharedPreferences.getInstance();
  }
  Future<int> getAppState()async{
    final networkStatus=await initializeNetwork();
    final loginStatus=await getLoginStatus();
    final String log=loginStatus?"已登录":"未登录";
    dev.log(log,name: "登录检查");
    if(networkStatus==0){
      return loginStatus?1:0;
    }
    else if(networkStatus==1){
      Connector().isVpnEnabled=true;
      return loginStatus?1:0;
    }
    else if(networkStatus==2){
      return 2;//跳转VPN设置
    }
    else{
      return 0;//跳转登录
    }
  }
  Future<bool> getLoginStatus() async {
    if(await Connector().getToken("access")=="0"||await Connector().getToken("refresh")=="0")return false;
    return set?.getBool('isActive') ?? false; 
  }
  Future<int> initializeNetwork()async{
    //检查网络
    String status=await Connector().checkNetwork(false);
    dev.log("使用以下凭据${Connector().vpnHeader}",name: "网络检测");
    if(status=="1"){
      dev.log("处于内网中",name:"网络检测");
      return 0;
    }
    //无网络
    else if(status=="0"){
      //检查是否存在VPN鉴权令牌
      if(await Connector().isVpnUsable()){
        dev.log("存在相关凭据,vpn可用");
        //注入
        Connector().injectToken();
        dev.log("已注入凭据，重试${Connector().vpnHeader}");
        String newStatus=await Connector().checkNetwork(true);
        if(newStatus=="1"){
          Connector().isVpnEnabled=true;
          dev.log("启用vpn",name: "网络检测");
          return 1;
        }
        else if(newStatus=="0"){
          //注入令牌无网络,可能是令牌过期，需要重登VPN.
          //注意通常注入凭据后返回值由VPN托管，0不是镜像站返回的，而是checkNetwork判断得到的。
          //尝试自动刷新
          dev.log("令牌过期，尝试刷新",name: "网络检测");
          String id=await Connector().getToken("vpnUserName");
            String pass=await Connector().getToken("vpnPassword");
            final res=await Connector().vpn.loginAsync(id,pass);
            if(res=="1"){
              Connector().saveToken("ticket", Connector().vpn.ticket??"");
              Connector().saveToken("route", Connector().vpn.route??"");
              await Connector().injectToken();
              Connector().isVpnEnabled=true;
              dev.log("令牌刷新成功,重新启用vpn",name: "网络检测");
              return 1;
            }
            else{
              //VPN密码可能被修改，需要重新配置VPN
              dev.log("vpn凭据错误,或者vpn套餐到期",name: "网络检测");
              return 2;
            }
        }
        else{
          //注入VPN凭据后仍然不处于内网中
          dev.log("使用vpn检查网络失败,未成功连接内网",name: "网络检测");
          return 3;
        }
      }
      //没有存储VPN凭据，需要配置VPN
      else{
        dev.log("未配置vpn",name: "网络检测");
        return 2;
      }
    }
    else{
      dev.log("不使用vpn检查网络失败,无互联网连接",name: "网络检测");
      return 3;
    }
  }
  Future<bool> setLoginStatus(bool newValue) async {
    return await set?.setBool('isActive', newValue) ?? false;
  }
  static Future<String> loginAsync(String id,String password)async{
    const String loginUrl = "https://openid.cc98.org/connect/token";
    final response = await Connector().post(
      loginUrl,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "grant_type": "password",
        "username": id,
        "password": password,
        "client_id": "9a1fd200-8687-44b1-4c20-08d50a96e5cd",
        "client_secret": "8b53f727-08e2-4509-8857-e34bf92b27f2",
        "scope": "cc98-api openid offline_access"
      },
    ).timeout(const Duration(seconds: 10),onTimeout: (){
      return http.Response('请求超时，请检查网络连接', 408);
    });
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final accessToken = jsonResponse['access_token'] as String?;
      final refreshToken = jsonResponse['refresh_token'] as String?;
      if (accessToken != null && refreshToken != null) {
        await Connector().saveToken("access", accessToken);
        await Connector().saveToken("refresh", refreshToken);
        dev.log("成功登录并保存凭据",name: "登录");
        //自动保存凭据
        return "1";
      } else {
        dev.log("登录失败:响应中缺少令牌",name: "登录");
        return '登录失败:响应中缺少令牌';
      }
    } else if (response.statusCode == 400) {
      final errorResponse = json.decode(response.body);
      return '登录失败: ${errorResponse['error_description']}';
    } else {
      return '登录失败: ${response.statusCode}';
    }
  }
}
class RequestSender{
  static Future<String> getNewTopic(int currentPage,int pageSize) async {
    final String url="https://api.cc98.org/topic/new?from=${currentPage * pageSize}&size=$pageSize";
    final response = await Connector().get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "404:请求失败";   
    }
  }
  Future<String> getHotTopic() async {
    const String url="https://api.cc98.org/config/index";
    final response = await Connector().get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "404:请求失败";   
    }
  }
  Future<String> getUserPortrait(List<int> userIds) async {
    final String ids = userIds.map((e) =>"id=$e" ).join('&');
    final String url="https://api.cc98.org/user/basic?$ids";
    final response = await Connector().get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "404:请求失败";   
    }
  }
  static Future<String> getUserInfo(List<dynamic> userIds) async {
    final String ids = userIds.map((e) =>"id=$e" ).join('&');
    final String url="https://api.cc98.org/user?$ids";
    final response = await Connector().get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "404:请求失败";   
    }
  }
  static Future<bool> likeReply(int replyId,String mode)async
  {
    String url="https://api.cc98.org/post/$replyId/like";
    //此处使用了utf编码，否则发送的是"1".
    final res=await Connector().put(url,body:utf8.encode(mode),headers: {"Content-Type": "application/json;charset=utf-8"});
    if(res.statusCode==200)
    {
      return true;
    }
    return false;
  }
  static Future<Map<String,int>> getLikeStatus(int replyId)async
  {
    String url="https://api.cc98.org/post/$replyId/like";
    final res=await Connector().get(url);
    if(res.statusCode==200)
    {
      final jsonResponse = json.decode(res.body);
      return {
        "likeCount":jsonResponse['likeCount'] as int,
        "dislikeCount":jsonResponse['dislikeCount'] as int,
        "likeState":jsonResponse['likeState'] as int,
        "success":1,
      };
    }
    return {
      "likeCount":0,
      "dislikeCount":0,
      "likeState":0,
      "success":0,
    };
  }
  static Future<String> simpleRequest(String url) async{
    final response = await Connector().get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "404:请求失败";   
    }
  }
  static Future<String> sendReplyToTopic(int topicId, String content, bool isAnonymous, bool notifyReplier, int contentType,bool canBeTraced,int parentId)//canbe_traced表明使用了引用回复，可以被追踪
       async {
            String url = "https://api.cc98.org/topic/$topicId/post";
            Map<String, Object> reply;
            if (canBeTraced)
            {
                reply = 
              {
                "clientType":1 ,
                "content":content ,
                "contentType":contentType ,
                "isAnonymous":false ,
                "notifyAllReplier":false ,
                "title":"" ,
                "parentId":parentId 
              };
            }
            else
            {
                reply = 
              {
                "clientType":1 ,
                "content":content ,
                "contentType":contentType ,
                "isAnonymous":false ,
                "notifyAllReplier":false ,
                "title":"" ,
              };
            }
            //此处注意如何发送StringContent,需要jsonEncode,否则会不报错静默失效
            final res=await Connector().post(url, body:jsonEncode(reply), headers: {"Content-Type": "application/json"});
            if(res.statusCode==200)
            {
                return "1";
            }
            else if(res.statusCode==400)
            {
                final errorResponse = json.decode(res.body);
                return '0: ${errorResponse['error_description']}';
            }
            else
            {
                return '0: ${res.statusCode}';
            }
            
        }
}
class Deserializer{
  static List<SimpleUserInfo> parseUserPortrait(String res){
    final list = json.decode(res) as List;
    final data=list.map((e)=>SimpleUserInfo.fromJson(e as Map<String,dynamic>)).toList();
    return data;
  }
 
}