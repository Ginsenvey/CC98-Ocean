import 'dart:io';

import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/info_indicator.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/core/kernel.dart';
import 'package:cc98_ocean/pages/topic.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
class Section{
  final String name;//英文名
  final String description;//汉语名
  List<Post> posts;
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
class Post {
  final int id;
  final String title;

  Post({
    required this.id,
    required this.title,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
    );
  }
}

class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  final Map<String,String> nameToDescription={
      "hotTopic":"十大话题",
      "schoolEvent":"校园活动",
      "academics":"学术通知",
      "emotion":"感性·情感",
      "partTimeJob":"实习兼职",
      "fullTimeJob":"求职广场",
      "fleaMarket":"跳蚤市场",
      "study":"学习天地",
   };
  List<Section> sections = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  AuthService service=AuthService();
  bool isLoggedIn=true;
  RequestSender r=RequestSender();
  @override
  void initState() {
    super.initState();
    fetchPosts();
    AuthService().init();
    setUp();
  }
  Future<void> setUp() async {
    isLoggedIn = await service.getLoginStatus();
    setState(() {});
  }
  Future<void> fetchPosts() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    
    String response=await r.getHotTopic();
      if(!response.startsWith("404:")){
        final Map<String, dynamic> index=json.decode(response);//首先解析出字典
      setState(() {
        sections.clear();
        for(var key in nameToDescription.keys){
          final List<dynamic> sectionPosts = index[key] ?? [];
          final List<Map<String,dynamic>> data = List<Map<String, dynamic>>.from(sectionPosts);
          List<Post> posts = data.map((json) => Post.fromJson(json)).toList();
          sections.add(Section.fromJson(key,posts));
          isLoading=false;
        }
      });
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        automaticallyImplyLeading: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),       
        actionsPadding: EdgeInsets.only(right: 13),
        centerTitle: true,
        actions: [
          FluentIconbutton(icon: FluentIcons.more_horizontal_16_regular,iconColor: ColorTokens.softPurple,),
        ],
        title: const Text("今日话题",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: ColorTokens.primaryLight),)
      ),
      body:buildLayout()
    );
    
  }
  Widget buildLayout(){
    if(isLoading)return Center(child: CircularProgressIndicator());
    if(!isLoading&&sections.isEmpty)return ErrorIndicator(icon: FluentIcons.music_note_1_20_regular, info: "暂无帖子，点击刷新",onTapped: fetchPosts);
    if(hasError)return ErrorIndicator(icon: FluentIcons.music_note_2_16_regular, info: errorMessage,onTapped: fetchPosts);
    return LayoutBuilder(
        builder: (_,box){
          final width=box.maxWidth;
          final crossCount = width < 600 ? 1 : width ~/ 300;
          return MasonryGridView.count(
          crossAxisCount: crossCount,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          itemCount: sections.length,
          itemBuilder: (context, index) {
            return buildSection(sections[index]);
          },
                  );
        }
        
      );
  }
  Widget buildSection(Section section ) {
  return Column(
    mainAxisSize: MainAxisSize.max,
    children: [
      // 标题栏
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 10),
          Text(section.description,
                style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      // 帖子列表
      Divider(thickness: 2,color: ColorTokens.primaryLight,indent: 6,endIndent: 6,),
      buildPostList(section.posts),
      const SizedBox(height: 6,)
    ],
  );
}
  Widget buildPostList(List<Post> posts) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), 
      itemCount: posts.length,
      itemBuilder: (context, index) => _buildPostItem(posts[index],key: ValueKey(posts[index].id)),
    );
  }
    // 构建帖子列表项
Widget _buildPostItem(Post post,{Key? key}) {
  return Card(
    key: key,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Topic(topicId: post.id),
            ),
          );
      },
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
            post.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
      ),
    ),
  );
}
}