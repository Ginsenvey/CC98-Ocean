import 'package:http/http.dart' as http;

class Network {
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
          return '非法返回';
        }
      } 
      else 
      {
        return '无互联网连接';
      }
    } 
    catch (e) 
    {
      return '连接出错: $e';
    }
  }
}