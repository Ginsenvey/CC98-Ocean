import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:xml/xml.dart' as xml;
import 'package:pointycastle/export.dart';

class VpnService {
  static const String _authUrl =
      'https://webvpn.zju.edu.cn/por/login_auth.csp?apiversion=1';
  static const String _pswUrl =
      'https://webvpn.zju.edu.cn/por/login_psw.csp?anti_replay=1&encrypt=1&apiversion=1';

  final http.Client client;
  final _jar = <String, String>{};

  bool isVpnEnabled = false;
  bool logined = false;
  bool autoDirect = true;

  Cookie? get twfIdCookie =>
      _jar.entries
          .where((e) => e.key.contains('TWFID'))
          .map((e) => Cookie.fromSetCookieValue(e.value))
          .firstOrNull;

  VpnService() : client = http.Client();

  

  /// 登录主流程，返回 "1" 表示成功，其余为错误信息
  Future<String> login(String username, String password) async {
    // 1. 拿授权参数
    final authResp = await client.get(Uri.parse(_authUrl));
    if (authResp.statusCode != HttpStatus.ok) {
      throw Exception('auth request failed: ${authResp.statusCode}');
    }
    final authXml = authResp.body;
    final auth = _parseAuthXml(authXml);

    // 2. 加密密码
    final plain = '${password}_${auth.csrf}';
    final encrypted = _rsaEncrypt(plain, auth.key, auth.exp);

    // 3. 提交登录
    final form = {
      'mitm_result': '',
      'svpn_req_randcode': auth.csrf,
      'svpn_name': username,
      'svpn_password': encrypted,
      'svpn_rand_code': '',
    };
    final loginResp = await client.post(
      Uri.parse(_pswUrl),
      body: form,
      headers: {'content-type': 'application/x-www-form-urlencoded'},
    );
    final loginXml = loginResp.body;

    // 4. 解析结果
    final result = _verifyLoginResult(loginXml);
    if (result == '1') logined = true;
    return result;
  }

  ({String csrf, String key, String exp}) _parseAuthXml(String xmlStr) {
    final doc = xml.XmlDocument.parse(xmlStr);
    String xpath(String tag) => doc.findAllElements(tag).first.innerText;
    return (
      csrf: xpath('CSRF_RAND_CODE'),
      key: xpath('RSA_ENCRYPT_KEY'),
      exp: xpath('RSA_ENCRYPT_EXP'),
    );
  }

  /// RSA/ECB/PKCS1 加密，返回小写十六进制
  String _rsaEncrypt(String plain, String modulusHex, String exponentDec) {

    final engine = RSAEngine()
      ..init(
        true,
        PublicKeyParameter<RSAPublicKey>(
          RSAPublicKey(
            BigInt.parse(modulusHex, radix: 16),
            BigInt.parse(exponentDec, radix: 10),
          ),
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

/* ---------- 小工具 ---------- */
Uint8List _hexToBytes(String hex) =>
    Uint8List.fromList(List.generate(hex.length ~/ 2,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)));

Uint8List _decToBytes(String dec) {
  final big = BigInt.parse(dec, radix: 10);
  return big.toRadixString(16).padLeft(2, '0').toUpperCase().hexToBytes();
}

String _bytesToHex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

extension _Hex on String {
  Uint8List hexToBytes() => _hexToBytes(this);
}

extension _Xml on xml.XmlDocument {
  Iterable<xml.XmlElement> findAllElements(String name) =>
      this.findAllElements(name);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}