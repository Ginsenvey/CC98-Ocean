
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/info_indicator.dart';
import 'package:cc98_ocean/controls/pivot.dart';
import 'package:cc98_ocean/controls/portrait_oval.dart';
import 'package:cc98_ocean/controls/search_bar.dart';
import 'package:cc98_ocean/controls/status_title.dart';
import 'package:cc98_ocean/controls/tag_box.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/core/constants/section_info.dart';
import 'package:cc98_ocean/core/helper.dart';
import 'package:cc98_ocean/core/kernel.dart';
import 'package:cc98_ocean/pages/focus.dart';
import 'package:cc98_ocean/pages/mailbox.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class Section{
  final String name;//英文名
  final String description;//汉语名
  List<Post> posts;
  bool portraitLoaded=false;
  Section({
    required this.name,
    required this.description,
    required this.posts,
  });

  factory Section.fromJson(String key,List<Post> posts){ {
   Map<String,String> nameToDescription={
      "hotTopic":"十大话题",
      "schoolEvent":"校园活动",
      "academics":"学术通知",
      "emotion":"感性·情感",
      "partTimeJob":"实习兼职",
      "fullTimeJob":"求职广场",
      "fleaMarket":"跳蚤市场",
      "study":"学习天地",
   };
    return Section(
      name: key,
      description:nameToDescription[key]??"未知版块",
      posts: posts,
    );
  }
}
}
class Post{
  final int id;
  final int authorUserId;
  int replyCount;
  int hitCount;
  final String authorName;
  final String title;
  final String boardName;
  String portraitUrl=""; 
  Post({
    required this.id,
    required this.authorUserId,
    required this.hitCount,
    required this.replyCount,
    required this.title,
    required this.authorName,
    required this.boardName
  });
  factory Post.fromJson(Map<String,dynamic> json){
    int userId=json["authorUserId"] as int? ??0;
    String userName=json["authorName"] as String? ??"";
    if(userId==0)userId=json["userId"] as int? ??0;
    if(userName.isEmpty)userName=json["userName"] as String? ??"匿名用户";
    return Post(
      id:json["id"] as int? ??0,
      authorUserId: userId,
      hitCount: json["hitCount"] as int? ??0,
      replyCount: json["replyCount"] as int? ??0,
      title: json["title"] as String? ??"未知内容",
      authorName: json["authorName"] as String? ??"匿名用户",
      boardName: json["boardName"] as String? ?? ""
      );
  }
}



class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  List<Section> sections = [];
  int selectedSection=0;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  bool isLoggedIn=true;
  @override
  void initState() {
    super.initState();
    getPosts();
    AuthService().init();
  }

  Future<void> getPosts() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    
    String response=await RequestSender.getHotTopic();
      if(!response.startsWith("404:")){
        final Map<String, dynamic> index=json.decode(response);//首先解析出字典
      setState(()async{
        sections.clear();
        for(var sectionInfo in ConstantItems.sectionList){
          String key=sectionInfo.jsonPropertyName;
          final List<dynamic> sectionPosts = index[key] ?? [];
          final List<Map<String,dynamic>> data = List<Map<String, dynamic>>.from(sectionPosts);
          List<Post> posts = data.map((json) => Post.fromJson(json)).toList();
          sections.add(Section.fromJson(key,posts));
          isLoading=false;
        }
        await loadPortrait(0);
      });
      }
  }
  Future<void> loadPortrait(int index)async{
    if(sections.isEmpty)return;
    if(!sections[selectedSection].portraitLoaded){
      final List<int> userIds=sections[selectedSection].posts.map((e)=>e.authorUserId).toList();
      final portraitMap=Deserializer.parseUserPortrait(await RequestSender().getUserPortrait(userIds));
      setState(() {
        for (var e in sections[selectedSection].posts) {
          SimpleUserInfo? user;
          try {
            user = portraitMap.firstWhere((u) => u.userId == e.authorUserId);
          } catch (_) {
            user = null;
          }
          if (user != null) {
            e.portraitUrl = user.portraitUrl;
          }
        }
        sections[selectedSection].portraitLoaded=true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:buildLayout()
    ); 
  }
  
  Widget buildLayout(){
    //未在加载且总数是0，则未正常加载
    if(!isLoading&&(sections.isEmpty||sections.length<selectedSection+1))return ErrorIndicator(icon: FluentIcons.music_note_1_20_regular, info: "暂无帖子，点击刷新",onTapped: getPosts);
    if(hasError)return ErrorIndicator(icon: FluentIcons.music_note_2_16_regular, info: errorMessage,onTapped: getPosts);
    return Column(
      children: [
        builldAppBar(),
        buildPivot(),
        Divider(height: 0.2,thickness: 0.2,color: Theme.of(context).primaryColor),
        //正在加载时不显示内容，或者显示骨架屏
        if(!isLoading)buildSection(sections[selectedSection])
      ],
    );
  }
  Widget builldAppBar(){
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        spacing: 10,
        children: [
          FlutterLogo(),  
          Expanded(child: SimpleCapsuleSearchBar(hintText: "CC98,My home")),
          FluentIconbutton(icon: FluentIcons.gift_open_16_regular),
          FluentIconbutton(icon: FluentIcons.mail_16_regular,onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context)=>Mailbox()));
          },)
        ],
      ),
    );
  }
  Widget buildPivot(){
    return PivotTabBar(
            tabs: ConstantItems.sectionList.map((s)=>s.description).toList(),
            indicatorColor:ColorTokens.softPurple,
            selectedIndex: selectedSection,
            onTabSelected: (index) {
              setState(()async{
                selectedSection = index;
                await loadPortrait(index);
              });
            },
            indicatorHeight: 3.0,
            indicatorWidth: 50.0,
            tabWidth: 88,
            tabSpacing: 4.0,
            selectedTextStyle: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
            unselectedTextStyle: const TextStyle(
              fontSize: 16.0,
              color: Colors.grey,
            ),
          );
  }
  Widget buildSection(Section section) {
  return Expanded(
    child: ListView.separated(
      separatorBuilder: (context, index) => Divider(height: 6, thickness: 1,color: Theme.of(context).dividerColor),
      itemCount:section.posts.length,
      itemBuilder: (context, index) => buildPostItem(section.posts[index],key: ValueKey(section.posts[index].id)),
    ),
  );
}

    // 构建帖子列表项
Widget buildPostItem(Post post,{Key? key}) {
  return Card(
    key: key,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
    child:Padding(
      padding: EdgeInsetsGeometry.all(4),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  PortraitOval(url: post.portraitUrl),
                  Text(post.authorName,style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: ColorTokens.softPink,
                        ),)
                ],
              ),
              if(post.boardName.isNotEmpty)TextTagBox(text: post.boardName,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: 4,
              textColor: Theme.of(context).primaryColor,
              textStyle: TextStyle(fontSize: 12),
              )
            ],
          ),
          Text(post.title,maxLines: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${post.replyCount}回复·${post.hitCount}浏览",style: TextStyle(fontSize: 12,color: ColorTokens.softGrey),),
            ],
          ),
        ],
      ),
    )
  );
}
}