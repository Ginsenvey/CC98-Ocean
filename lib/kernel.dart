import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Client {
  static final Client _instance = Client._internal();
  factory Client() => _instance;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static String? _accessToken;
  
  Client._internal() {
    _loadToken();
  }
   
  // 加载本地存储的 Token
  Future<void> _loadToken() async {
    _accessToken = await _storage.read(key: 'access');
  }
  
  // 保存 Token
  Future<void> saveToken(String name,String token) async {
    _accessToken = token;
    await _storage.write(key: name, value: token);
  }
  
  // 清除 Token
  Future<void> clearToken() async {
    _accessToken = null;
    await _storage.delete(key: 'access');
    await _storage.delete(key: 'refresh');
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
      final refreshToken = await _storage.read(key: 'refresh');
      
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }
      
      final response = await http.post(
        Uri.parse(refreshUrl),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
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
    String url, {
    Map<String, String>? headers,
    Object? body,
    int retryCount = 0,
  }) async {
    if (_accessToken == null) {
      await _loadToken();
    }
    
    // 获取 Content-Type
    final contentType = headers?['Content-Type'] ?? 'application/json';
    
    // 处理请求体
    Object? finalBody;
    if (contentType == 'application/x-www-form-urlencoded' && body is Map<String, String>) {
      finalBody = _encodeFormData(body);// 编码为表单数据
    } else if (body != null) {
      finalBody = body; // 其他类型直接使用
    }
    
    // 设置默认请求头
    final defaultHeaders = {
      if (contentType != 'multipart/form-data') 'Content-Type': contentType,// 避免 multipart/form-data 重复设置
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
    
    // 合并自定义请求头
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
  
  final FlutterSecureStorage vault=const FlutterSecureStorage() ;
  static SharedPreferences? set;
  AuthService._internal();
  
  // 初始化服务
  Future<void> init() async {
    set = await SharedPreferences.getInstance();
  }
  Future<bool> getLoginStatus() async {
    if(!await vault.containsKey(key:"access")){
      return false;
    }
    if(!await vault.containsKey(key:"refresh")){
      return false;
    }
    return set?.getBool('isActive') ?? false; 
  }
  Future<String?> getToken(String key) async {
    return await vault.read(key: key);
  }
  Future<bool> setLoginStatus(bool newValue) async {
    return await set?.setBool('isActive', newValue) ?? false;
  }
  static Future<String> loginAsync(String id,String password)async{
    const String loginUrl = "https://openid.cc98.org/connect/token";
    final response = await Client().post(
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
        await Client().saveToken("access", accessToken);
        await Client().saveToken("refresh", refreshToken);
        //自动保存凭据
        return "1";
      } else {
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
  Future<String> getNewTopic(int currentPage,int pageSize) async {
    final String url="https://api.cc98.org/topic/new?from=${currentPage * pageSize}&size=$pageSize";
    final response = await Client().get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "404:请求失败";   
    }
  }
  Future<String> getHotTopic() async {
    const String url="https://api.cc98.org/config/index";
    final response = await Client().get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "404:请求失败";   
    }
  }
  Future<String> getUserPortrait(List<dynamic> userIds) async {
    final String ids = userIds.map((e) =>"id=$e" ).join('&');
    final String url="https://api.cc98.org/user/basic?$ids";
    final response = await Client().get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "404:请求失败";   
    }
  }
  Future<bool> likeReply(int replyId,String mode)async
  {
    String url="https://api.cc98.org/post/$replyId/like";
    //此处使用了utf编码，否则发送的是"1".
    final res=await Client().put(url,body:utf8.encode(mode),headers: {"Content-Type": "application/json;charset=utf-8"});
    if(res.statusCode==200)
    {
      return true;
    }
    return false;
  }
  Future<Map<String,int>> getLikeStatus(int replyId)async
  {
    String url="https://api.cc98.org/post/$replyId/like";
    final res=await Client().get(url);
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
    final response = await Client().get(url);
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
            final res=await Client().post(url, body:jsonEncode(reply), headers: {"Content-Type": "application/json"});
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
  static Map<String,String> parseUserPortrait(String res){
    final List<Map<String, dynamic>> maps = jsArrayToList(res);
    final Map<String, String> result = {};
    //遍历maps,将id和portrait存入result
    for (var map in maps) {
      result[map['id'].toString()] = map['portraitUrl'] as String;
    }
    return result;
  }
  static List<Map<String, dynamic>> jsArrayToList(String jsArrayStr) {
  // 1. 去掉最外层引号（若存在）
  var s = jsArrayStr.trim();
  if ((s.startsWith('"') && s.endsWith('"')) ||
      (s.startsWith("'") && s.endsWith("'"))) {
    s = s.substring(1, s.length - 1);
  }
  // 2. 反转义
  s = s.replaceAll(r'\"', '"').replaceAll(r"\\'", "'");
  // 3. JSON 解码
  final list = jsonDecode(s) as List;
  return list.cast<Map<String, dynamic>>();
}
}