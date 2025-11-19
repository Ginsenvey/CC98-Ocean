import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart' as pc;

/// VPN服务类，用于连接浙江大学WebVPN
class VpnService {
  final http.Client client;
  VpnService() : client = http.Client();
  static const String loginAuthUrl = "https://webvpn.zju.edu.cn/login";
  static const String loginPswUrl = "https://webvpn.zju.edu.cn/do-login";
  final Map<String, String> _cookies = {};
  bool logined = false;
  bool isVpnEnabled = false;
  bool autoDirect = true;
  bool _disposed = false;

  String? get ticket => _cookies['wengine_vpn_ticketwebvpn_zju_edu_cn'];
  String? get route => _cookies['route'];

  void dispose() {
    if (!_disposed) {
      client.close();
      _disposed = true;
    }
  }

  /// 合并默认请求头与自定义请求头
  Map<String, String> _mergeHeaders(Map<String, String>? additional) {
    final headers = <String, String>{
      'Referer': 'https://webvpn.zju.edu.cn/',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0',
    };
    if (additional != null) {
      headers.addAll(additional);
    }
    return headers;
  }

  /// 从响应头更新Cookie
  void _updateCookies(http.Response response) {
    final setCookieHeader = response.headers['set-cookie'];
    if (setCookieHeader != null) {
      // 处理多个Set-Cookie头
      final cookies = setCookieHeader.split(',');
      for (var cookieStr in cookies) {
        final parts = cookieStr.split(';');
        for (var part in parts) {
          final equalsIndex = part.indexOf('=');
          if (equalsIndex > 0) {
            final name = part.substring(0, equalsIndex).trim();
            final value = part.substring(equalsIndex + 1).trim();
            _cookies[name] = value;
            break;
          }
        }
      }
    }
  }

  /// 获取当前Cookie字符串
  String _getCookieHeader() {
    if (_cookies.isEmpty) return '';
    return _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// 登录到WebVPN
  Future<String> loginAsync(String username, String password, {CancellationToken? cts}) async {
    try {
      cts?.throwIfCancelled();
      
      final response = await client.get(
        Uri.parse(loginAuthUrl),
        headers: _mergeHeaders({}),
      );
      
      if (response.statusCode == 200) {
        _updateCookies(response);
        
        final html = response.body;
        final param = getRandCode(html);
        final encryptedPassword = buildPassword("wrdvpnisawesome!", password);
        final formData = {
          '_csrf': param.csrf,
          'auth_type': param.authType,
          'sms_code': '',
          'captcha': '',
          'needCaptcha': 'false',
          'captcha_id': param.captcha,
          'username': username,
          'password': encryptedPassword,
        };
        
        cts?.throwIfCancelled();
        
        final loginResponse = await client.post(
          Uri.parse(loginPswUrl),
          headers: _mergeHeaders({
            'Content-Type': 'application/x-www-form-urlencoded',
            'Cookie': _getCookieHeader(),
          }),
          body: formData,
        );
        
        if (loginResponse.statusCode != 200) {
          return "404:登录请求失败";
        }
        
        _updateCookies(loginResponse);
        
        final text = loginResponse.body;
        if (parseLoginResult(text)) {
          logined = true;
          return "1";
        } else {
          return "0";
        }
      } else {
        return "404:获取CSRF失败";
      }
    } catch (e) {
      if (e is CancelledException) {
        rethrow;
      }
      return "404:${e.toString()}";
    }
  }

  /// 转换普通URL为VPN URL
  static String convertUrl(String origin) {
  final uri = Uri.parse(origin);
  final scheme = uri.scheme;
  final port = uri.port;
  final host = uri.host;

  final isSpecialPort = port > 0 &&
      !(scheme == 'http' && port == 80) &&
      !(scheme == 'https' && port == 443);
  final property = isSpecialPort ? '$scheme-$port' : scheme;

  // 1. 正确的路径+查询串
  final pathAndQuery = uri.path + (uri.hasQuery ? '?${uri.query}' : '');

  // 3. 拼 VPN 前缀
  final vpnPrefix = Uri(
    scheme: 'https',
    host: 'webvpn.zju.edu.cn',
    pathSegments: [
      Uri.encodeComponent(property),
      Uri.encodeComponent(buildPassword('wrdvpnisthebest!', host)),
    ],
  ).toString();

  // 4. 最后拼上原始路径和查询
  return vpnPrefix + (pathAndQuery.startsWith('/') ? pathAndQuery : '/$pathAndQuery');
}

  /// 检查网络状态
  

  /// 解析登录结果
  static bool parseLoginResult(String json) {
    if (json.isEmpty) return false;
    try {
      final dic = jsonDecode(json);
      if (dic is Map<String, dynamic>) {
        final success = dic['success'];
        if (success is bool) {
          return success;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 从HTML中提取随机码
  static ({String csrf, String captcha, String authType}) getRandCode(String html) {
    final doc = html_parser.parse(html);
    final csrfNode = doc.querySelector("input[type='hidden'][name='_csrf']");
    final captchaNode = doc.querySelector("input[type='hidden'][name='captcha_id']");
    final authTypeNode = doc.querySelector("input[type='hidden'][name='auth_type']");
    
    final csrf = csrfNode?.attributes['value'] ?? '';
    final captcha = captchaNode?.attributes['value'] ?? '';
    final authType = authTypeNode?.attributes['value'] ?? '';
    
    return (csrf: csrf, captcha: captcha, authType: authType);
  }

  /// 构建加密密码
  static String buildPassword(String prefix, String plainText) {
    final sliceLength = 2 * plainText.length;
    final prefixHex = stringToAscll(prefix);
    final fullCore = encryptStringToHex(plainText, prefix, prefix);
    final core = fullCore.length > sliceLength ? fullCore.substring(0, sliceLength) : fullCore;
    return "$prefixHex$core";
  }

  /// AES CFB加密
  static String encryptStringToHex(String plainText, String key, String iv) {
    final ivBytes = Uint8List.fromList(iv.padRight(16, ' ').substring(0, 16).codeUnits);
    final keyBytes = Uint8List.fromList(key.padRight(16, ' ').substring(0, 16).codeUnits);
    
    final paddedPlainText = padWithZeros(plainText);
    
    // 使用AES CFB模式加密
    final cipher = pc.BlockCipher("AES/CFB-128");
    final params = pc.ParametersWithIV(pc.KeyParameter(keyBytes), ivBytes);
    cipher.init(true, params);
    
    final encrypted = cipher.process(paddedPlainText);
    return hex.encode(encrypted).toLowerCase();
  }

  /// 用0填充到16字节倍数
  static Uint8List padWithZeros(String plainText) {
    final raw = Uint8List.fromList(utf8.encode(plainText));
    final len = raw.length;
    var pad = 16 - (len % 16);
    if (pad == 16) pad = 0;
    
    final padded = Uint8List(len + pad);
    padded.setAll(0, raw);
    // 剩余部分默认为0
    return padded;
  }

  /// 字符串转ASCII Hex
  static String stringToAscll(String origin) {
    final asciiBytes = ascii.encode(origin);
    final sb = StringBuffer();
    for (final b in asciiBytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}

/// 取消令牌类
class CancellationToken {
  final Completer<void> _completer = Completer<void>();
  
  bool get isCancelled => _completer.isCompleted;
  
  void cancel() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
  
  Future<void> get whenCancelled => _completer.future;
  
  void throwIfCancelled() {
    if (isCancelled) {
      throw CancelledException();
    }
  }
}

/// 取消异常
class CancelledException implements Exception {
  @override
  String toString() => "Operation was cancelled";
}

