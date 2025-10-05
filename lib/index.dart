import 'dart:io';

import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/kernel.dart';
import 'package:cc98_ocean/main.dart';
import 'package:cc98_ocean/topic.dart';
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
    _fetchPosts();
    AuthService().init();
    setUp();
  }
  Future<void> setUp() async {
    isLoggedIn = await service.getLoginStatus();
    setState(() {});
  }
  Future<void> _fetchPosts() async {
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

  // 处理收藏操作
  

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

 
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),       
        actionsPadding: EdgeInsets.only(right: 13),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
          child: FluentIconbutton(
            icon: FluentIcons.panel_left_expand_16_regular,
           
          ),
        ),
        actions: [
          FluentIconbutton(icon: FluentIcons.more_horizontal_16_regular,iconColor: ColorTokens.softPurple,),
        ],
        title: const Text("今日话题",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: ColorTokens.primaryLight),)

      ),
      body:LayoutBuilder(
        builder: (_,box){
          final width=box.maxWidth;
          final crossCount = width < 600 ? 1 : width ~/ 300;
          return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child:isLoading?
          const Center(child: CircularProgressIndicator(),
        ):
        MasonryGridView.count(
          crossAxisCount: crossCount,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          itemCount: sections.length,
          itemBuilder: (context, index) {
            return _buildSection(sections[index]);
          },
        )
        );
        }
        
      )
    );
    
  }
  Widget _buildSection(Section section ) {
    ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: ColorTokens.softOrange);
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        // 标题栏
        ListTile(
          title: Text(section.description,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          tileColor: colorScheme.primaryContainer ,
        ),
        // 帖子列表
        _buildContent(section.posts),
      ],
    ),
  );
}
  Widget _buildContent(List<Post> posts) {
    //加载中组件
    
    //错误组件
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPosts,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    //占位组件
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('暂无帖子'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetchPosts,
              child: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), 
      itemCount: posts.length,
      itemBuilder: (context, index) => _buildPostItem(posts[index],key: ValueKey(posts[index].id)),
    );
  }
}