import 'dart:convert';
import 'package:html2md/html2md.dart' as html2md;
class BBCodeConverter {
  static final RegExp emojiRegex = RegExp(r'\[([a-zA-Z]+)(\d+)\]');
  
  // 基础图片URL
  static const String baseImageUrl = 'https://www.cc98.org/static/images/';
  static String convertUnusedTags(String input) {
    //去掉font标签
    input = input.replaceAll(RegExp(r'\[font=[^\]]+\]'), '');
    input = input.replaceAll(RegExp(r'\[/font\]'), '');
    //去掉size标签
    input = input.replaceAll(RegExp(r'\[size=[^\]]+\]'), '');
    input = input.replaceAll(RegExp(r'\[/size\]'), '');
    return input;
  }
  /// 转换字符串中的表情标签为图片标签
  static String convertEmojiTags(String input) {
    return input.replaceAllMapped(emojiRegex, (match) {
      final prefix = match.group(1)!; // 获取前缀部分（如 "tb"）
      final number = match.group(2)!; // 获取数字部分（如 "02"）
      if(prefix=="ac"){
        return '[img]$baseImageUrl$prefix/$number.png[/img]';
      }
      else if(prefix=="tb"||prefix=="em"||prefix=="ms"){
        return '[img]$baseImageUrl$prefix/$prefix$number.png[/img]';
      }
      else if(prefix=="cc"){
        return '[img]https://www.cc98.org/static/images/CC98/CC$number.png[/img]';
      }
      return '$baseImageUrl$prefix/$prefix$number.png';
    });
  }
  
  /// 转换整个BBCode字符串，处理表情标签
  static String convertBBCode(String input) {
    input= convertEmojiTags(input);
    input=convertColorTags(input);
    input=convertAlignTags(input);
    input=convertUnusedTags(input);
    return input;
  }
  static String convertAlignTags(String input) {
  // 使用正则表达式匹配 [align=value]...[/align] 结构
  final regex = RegExp(r'\[align=([a-zA-Z]+)\](.*?)\[/align\]', dotAll: true);
  
  return input.replaceAllMapped(regex, (match) {
    final alignment = match.group(1)!.toLowerCase(); // 获取对齐值并转为小写
    final content = match.group(2)!; // 获取标签内容
    
    // 只处理允许的对齐值
    if (alignment == 'left' || alignment == 'center' || alignment == 'right') {
      return '[$alignment]$content[/$alignment]';
    } else {
      // 非法的对齐值保持原样
      return match.group(0)!;
    }
  });
}
  static String convertColorTags(String input) {
  // 常见颜色名称到十六进制值的映射表
  final colorMap = {
    'red': 'ff0000',
    'green': '008000',
    'blue': '0000ff',
    'yellow': 'ffff00',
    'purple': '800080',
    'orange': 'ffa500',
    'pink': 'ffc0cb',
    'brown': 'a52a2a',
    'black': '000000',
    'white': 'ffffff',
    'gray': '808080',
    'cyan': '00ffff',
    'magenta': 'ff00ff',
    'lime': '00ff00',
    'maroon': '800000',
    'olive': '808000',
    'teal': '008080',
    'navy': '000080',
    'silver': 'c0c0c0',
    'gold': 'ffd700',
    'violet': 'ee82ee',
    'indigo': '4b0082',
    'coral': 'ff7f50',
    'turquoise': '40e0d0',
    'salmon': 'fa8072',
    'aqua': '00ffff',
    'azure': 'f0ffff',
    'beige': 'f5f5dc',
    'crimson': 'dc143c',
    'darkblue': '00008b',
    'darkred': '8b0000',
    'khaki': 'f0e68c',
    'lavender': 'e6e6fa',
    'plum': 'dda0dd',
  };

  // 正则表达式匹配 [color=任意字母]
  final colorRegex = RegExp(r'\[color=([a-zA-Z]+)\]');
  
  return input.replaceAllMapped(colorRegex, (match) {
    final colorName = match.group(1)!.toLowerCase(); // 获取颜色名并转为小写
    final hexCode = colorMap[colorName]; // 查找映射表

    if (hexCode != null) {
      return '[color=#$hexCode]'; // 找到对应颜色值
    } else {
      // 未找到颜色名称时，将名称转换为十六进制（示例逻辑）
      final fallbackHex = _nameToHexFallback(colorName);
      return '[color=#$fallbackHex]'; // 使用备用转换方案
    }
    
  });
  
}

  /// 将颜色名称转换为十六进制值的备用方案
  static String _nameToHexFallback(String name) {
  if (name.isEmpty) return "000000";
  
  // 取前6个字符（不足则重复填充），每个字符转换为其ASCII值的十六进制
  final bytes = utf8.encode(name.padRight(6, name).substring(0, 6));
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
}
  
  
}
class MdConverter{
  static String convertHtml(String input){
    final paraReg = RegExp(
  r'<p(\s[^>]*)?>(.*?)</p>',
  caseSensitive: false,
  dotAll: true, // 允许内容换行
);
    return input.replaceAllMapped(paraReg, (m) {
    final fullHtml = m.group(0)!; // 整个 <p>...</p>
    final markdown = html2md.convert(fullHtml); // 转成 md
    return markdown.trimRight(); // 去掉 html2md 可能多出的尾换行
  });
  }
}
