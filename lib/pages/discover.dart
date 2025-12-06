import 'package:cc98_ocean/controls/clickarea.dart';
import 'package:cc98_ocean/controls/adaptive_divider.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/info_flower.dart';
import 'package:cc98_ocean/controls/info_indicator.dart';
import 'package:cc98_ocean/controls/portrait_oval.dart';
import 'package:cc98_ocean/controls/smart_image.dart';
import 'package:cc98_ocean/controls/status_title.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/core/helper.dart';
import 'package:cc98_ocean/core/kernel.dart';
import 'package:cc98_ocean/pages/focus.dart';
import 'package:cc98_ocean/pages/topic.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class Post{
  final int id;
  final int userId;
  int likeCount;
  int dislikeCount;
  int replyCount;
  int hitCount;
  final String userName;
  final String title;
  final String time;
  final bool isMe;
  String portraitUrl=""; 
  final Map<String,dynamic> mediaContent;
  Post({
    required this.id,
    required this.isMe,
    required this.userId,
    required this.dislikeCount,
    required this.hitCount,
    required this.likeCount,
    required this.replyCount,
    required this.time,
    required this.title,
    required this.userName,
    required this.mediaContent
  });
  factory Post.fromJson(Map<String,dynamic> json){
    return Post(
      id:json["id"] as int? ??0,
      isMe: json["isMe"] as bool? ??false,
      userId: json["userId"] as int? ??0,
      dislikeCount: json["dislikeCount"] as int? ??0,
      hitCount: json["hitCount"] as int? ??0,
      likeCount: json["likeCount"] as int? ??0, 
      replyCount: json["replyCount"] as int? ??0,
      time: json["time"] as String? ??"", 
      title: json["title"] as String? ??"未知内容",
      userName: json["userName"] as String? ??"匿名用户",
      mediaContent: json["mediaContent"] as Map<String,dynamic>? ?? {}
      );
  }
}

class Discover extends StatefulWidget {
  const Discover({super.key});

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  List<dynamic> posts = [];
  bool isLoading = true;
  bool hasError = false;
  int currentPage = 0;
  int pageSize = 20;
  String errorMessage = '';
  final ScrollController controller = ScrollController();
  @override
  void initState() {
    super.initState();
    controller.addListener(onScroll);
    getPosts();
  }

  // 模拟从API获取帖子数据
  Future<void> getPosts() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      String response=await RequestSender.getNewTopic(currentPage, pageSize);
      if(!response.startsWith("404:")){
        List list = json.decode(response) as List;
        final data=list.map((e)=>Post.fromJson(e as Map<String,dynamic>)).toList();
        final List<int> userIds = data.map((e) => e.userId).toSet().toList();
        final portraitMap=Deserializer.parseUserPortrait(await RequestSender().getUserPortrait(userIds));
        for (var e in data) {
          SimpleUserInfo? user;
          try {
            user = portraitMap.firstWhere((u) => u.userId == e.userId);
          } catch (_) {
            user = null;
          }
          if (user != null) {
            e.portraitUrl = user.portraitUrl;
          }
        }
      setState(() {
        posts.addAll(data);
      });
      }
 
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = '加载失败: ${e.toString()}';
      });
    }finally{
      setState(() {
        isLoading=false;
      });
    }
  }
  Future<void> _loadPrePage(BuildContext context) async {
    if (isLoading) return;
    if (currentPage <= 0){
        //提醒用户页码不能小于0
        InfoFlower.showContent(context,child: Text("已加载最新页面",style: TextStyle(color: ColorTokens.primaryLight),));
        currentPage = 0;
        return;
      } // 防止页码小于0
    currentPage--;
    setState(() {
      posts.clear(); // 清空当前列表
    });
    await getPosts();
  }
  Future<void> _loadNextPage() async {
    if (isLoading) return;
      currentPage++;
      await getPosts();
  }

  
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        automaticallyImplyLeading: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),       
        actionsPadding: EdgeInsets.only(right: 13),
        centerTitle: true,
        title: StatusTitle(title: "发现",isLoading: isLoading,onTap: ()async{
          setState(() {
            posts.clear();
          });
          currentPage=0;
          await getPosts();
        },)
      ),
      body: buildLayout(),
    );
  }
  
  Widget buildLayout() {
    if(!isLoading&&posts.isEmpty)return ErrorIndicator(icon: FluentIcons.music_note_1_20_regular, info: "暂无帖子，点击刷新",onTapped: getPosts);
    if(hasError)return ErrorIndicator(icon: FluentIcons.music_note_2_16_regular, info: errorMessage,onTapped: getPosts);
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: controller,
            itemCount: posts.length,
            separatorBuilder: (_, __) {
              return AdaptiveDivider();
            },
            itemBuilder: (context, index) {
              return buildPostItem(posts[index]);
            },
          ),
        ),
      ],
    );

    
  }
  
  // 构建帖子列表项
  Widget buildPostItem(Post post) {
  final mediaMap=post.mediaContent;//取出第一层
  final thumbNails=(mediaMap["thumbnail"] as List<dynamic>?)?.cast<String>()??<String>[];
  return Card( 
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0),
    ),
    child: ClickArea(
      onTap: ()=>{Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Topic(topicId: post.id),
            ),
          )},
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 作者头像
                PortraitOval(url: post.portraitUrl),
                const SizedBox(width: 12),
                // 作者名和发布时间
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: ColorTokens.primaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.time.toUtc8,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // 收藏按钮
                FluentIconbutton(icon: FluentIcons.more_vertical_16_regular)
              ],
            ),
            const SizedBox(height: 12),
            // 帖子标题
            Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
      
            const SizedBox(height: 12),
            if (thumbNails.isNotEmpty)
              Wrap(
                runSpacing: 8,
                spacing: 12,
                children: thumbNails
                    .map((url) => Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(side: BorderSide(color: ColorTokens.softPurple),borderRadius:BorderRadiusGeometry.circular(6)),
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(6),
                        child: Image(
                              image:SmartNetworkImage(url),
                              width: 150,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text("图片加载失败:$url"),
                                  ),
                            ),
                      ),
                    ))
                    .toList(),
              ),
            // 回复数和浏览量
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6,vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildStatItem(FluentIcons.fire_16_regular, post.hitCount),
                  buildStatItem(FluentIcons.chat_16_regular, post.replyCount),
                  buildStatItem(FluentIcons.chevron_up_16_regular, post.likeCount)     
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget buildStatItem(IconData icon,int count){
    return Row(
      spacing: 4,
      children: [
      Icon(icon,color: ColorTokens.softPurple,size: 12),
      Text(count.toString(),style: TextStyle(color: ColorTokens.softPurple))
    ]);
  }
  Widget buildTipIndicator() {
    return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('小水怡情,注意休息哦~', style: TextStyle(color: Colors.grey)),
        ),
      );
  }


  void onScroll()async{
    if (controller.position.pixels >=controller.position.maxScrollExtent - 100 &&!isLoading &&!hasError) {
        currentPage++;
        await getPosts();  
    }
  }
  @override
  void dispose() {
  controller.dispose();
  super.dispose();
}
}