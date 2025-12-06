
import 'package:cc98_ocean/controls/image_viewer.dart';
import 'package:cc98_ocean/core/helper.dart';
import 'package:cc98_ocean/pages/topic.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum ElementType{topic,anchor,user,board,outlink,image,audio,post,file,video}
class LinkAnalyzer{
  static (ElementType type,String param) definite(String url){
    if(url.contains("topic")){
      final reg = RegExp(r'https://www\.cc98\.org/topic/(\d+)');
      final match = reg.firstMatch(url);
      if (match != null){
        return (ElementType.topic,match.group(1)??"");
      }
    }
    if(url.contains("user")){
      final reg=RegExp(r'https://www\.cc98\.org/user/id/(\d+)');
      final match = reg.firstMatch(url);
      if (match != null){
        return (ElementType.user,match.group(1)??"");
      }
    }
    if(url.contains("webp")){
      return (ElementType.image,url);
    }
    return(ElementType.outlink,"");
  }
  static void LinkClick(BuildContext context, String url){
    var r=LinkAnalyzer.definite(url);
    switch(r.$1){
      case ElementType.topic:
        Navigator.push(context, MaterialPageRoute(builder: (context)=>Topic(topicId: r.$2.safeToInt)));
        break;
      case ElementType.anchor:
        
        throw UnimplementedError();
      case ElementType.user:
        
        throw UnimplementedError();
      case ElementType.board:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ElementType.outlink:
        throw UnimplementedError();
      case ElementType.image:
        Navigator.push(context, MaterialPageRoute(builder: (context)=>ImagePreview(imageUrl: url)));
        break;
      case ElementType.audio:
        
        throw UnimplementedError();
      case ElementType.post:
        
        throw UnimplementedError();
      case ElementType.file:
        
        throw UnimplementedError();
      case ElementType.video:
        
        throw UnimplementedError();
    }
  }
  static Future<void> launch(String url)async{
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
}