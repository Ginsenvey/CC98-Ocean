
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
    return(ElementType.outlink,"");
  }
  
}