import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/pkcs1.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:xml/xml.dart' as xml;


class VpnService {
  static const String _authUrl =
      'https://webvpn.zju.edu.cn/por/login_auth.csp?apiversion=1';
  static const String _pswUrl =
      'https://webvpn.zju.edu.cn/por/login_psw.csp?anti_replay=1&encrypt=1&apiversion=1';

  final client;
  final jar = <String, String>{};
  bool logined = false;
  static const baseHeaders = {
  HttpHeaders.refererHeader: 'https://webvpn.zju.edu.cn/portal/',
  HttpHeaders.connectionHeader: 'keep-alive',
  HttpHeaders.userAgentHeader:
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0',
};

  ///当完成登录后，将从xml中读取TWFID值并保存到Jar.这个值可能是null.
  Cookie? get twfId =>
      jar.entries
          .where((e) => e.key.contains('TWFID'))
          .map((e) => Cookie.fromSetCookieValue(e.value))
          .firstOrNull;
  VpnService():client=http.Client();

  ///标准转写函数
  static String convertUrl(String origin){
    Uri uri=Uri.parse(origin);
    String host=uri.host.replaceAll(".", "-");
    int port=uri.port;
    String pathAndQuery=uri.hasQuery?"${uri.path}?${uri.query}":uri.path;
    if(uri.scheme.toLowerCase()=="https")host+="-s";
    if(port>0&&!(port==80&&uri.scheme=="http")&&!(port==443&&uri.scheme=="https"))host+="-$port-p";
    return "http://$host.webvpn.zju.edu.cn:8001$pathAndQuery";
  }

  ///检测是否处于内网,返回1时为内网，返回0为外网，其余返回均认为无网络
  static Future<String> checkNetwork() async {
    try {
      final response = await http.get(Uri.parse('https://mirrors.zju.edu.cn/api/is_campus_network')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = response.body;
        if (data=="1"||data=='2') 
        {
          return '1';
        } 
        else if(data=="0")
        {
          return '0';
        }
        else
        {
          return '2:非法返回';
        }
      } 
      else 
      {
        return '3:无互联网连接';
      }
    } 
    catch (e) 
    {
      return '4: $e';
    }
  }

  /// 登录主流程，返回 "1" 表示成功，其余为错误信息
  Future<String> login(String username, String password) async {
   
    final authResp = await client.get(Uri.parse(_authUrl),headers: baseHeaders);
    if (authResp.statusCode != HttpStatus.ok) {
      throw Exception('auth request failed: ${authResp.statusCode}');
    }
    final authXml = authResp.body;
    final auth = parseAuthXml(authXml);

    //获取Set-Cookie
    final setCookie = authResp.headers['set-cookie'];
    String? cookieHeader;
    if (setCookie != null) {
      cookieHeader = setCookie.split(';').first;
    }

    // 2. 加密密码
    final plain = '${password}_${auth.csrf}';
    final encrypted = encrypt(plain, auth.key, auth.exp);

    // 3. 提交登录
    final form = {
      'mitm_result': '',
      'svpn_req_randcode': auth.csrf,
      'svpn_name': username,
      'svpn_password': encrypted,
      'svpn_rand_code': '',
    };
    print(form);
    final loginResp = await client.post(
      Uri.parse(_pswUrl),
      body: form,
      headers:{
        ...baseHeaders,
        if (cookieHeader != null) HttpHeaders.cookieHeader: cookieHeader,
        HttpHeaders.contentTypeHeader:'application/x-www-form-urlencoded',
      }
    );
    final loginXml = loginResp.body;
    print(loginXml);
    // 4. 解析结果
    final result = _verifyLoginResult(loginXml);
    if (result == '1') logined = true;
    return result;
  }

  ({String csrf, String key, String exp}) parseAuthXml(String xmlStr) {
    final doc = xml.XmlDocument.parse(xmlStr);
    String xpath(String tag) => doc.findAllElements(tag).first.innerText;
    return (
      csrf: xpath('CSRF_RAND_CODE'),
      key: xpath('RSA_ENCRYPT_KEY'),
      exp: xpath('RSA_ENCRYPT_EXP'),
    );
  }

  /// RSA/ECB/PKCS1 加密，返回小写十六进制
  String encrypt(String plain, String modulusHex, String exponentDec) {
    final mod = BigInt.parse(modulusHex, radix: 16);
    final exp = BigInt.parse(exponentDec,radix: 10);
    final engine = PKCS1Encoding(RSAEngine())
      ..init(
        true,
        PublicKeyParameter<RSAPublicKey>(
          RSAPublicKey(mod,exp),
        ),
      );

    final input = Uint8List.fromList(utf8.encode(plain));
    final output = engine.process(input);
    return _bytesToHex(output);
  }

  String _verifyLoginResult(String xmlStr) {
    final doc = xml.XmlDocument.parse(xmlStr);
    final result = doc.findAllElements('Result').first.innerText;
    final msg = doc.findAllElements('Message').firstOrNull?.innerText ?? 'Unknown error';
    if (result == '1') {
      logined = true;
      return '1';
    } else {
      logined = false;
      return '400:$msg';
    }
  }

  void close() => client.close();
}




String _bytesToHex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();


extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

