import 'dart:convert';
import 'dart:io';
import 'package:cc98_ocean/controls/clickarea.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/segmented.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/kernel.dart';
import 'package:cc98_ocean/main.dart';
import 'package:cc98_ocean/profile.dart';
import 'package:cc98_ocean/topic.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SimpleUserInfo{
  final int userId;
  final String userName;
  final String portraitUrl;
  SimpleUserInfo({
    required this.userId,
    required this.userName,
    required this.portraitUrl
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleUserInfo && runtimeType == other.runtimeType && userId == other.userId&&userName==other.userName;

  @override
  int get hashCode => userId.hashCode;

  factory SimpleUserInfo.fromJson(Map<String, dynamic> json) {
    return SimpleUserInfo(
      userId:json["userId"] as int,
      userName: json["userName"] as String? ??"匿名",
      portraitUrl: json["portraitUrl"]??""
    );
  }
}

class Moments extends StatefulWidget {
  const Moments({super.key});

  @override
  State<Moments> createState() => _MomentsState();
}
class _MomentsState extends State<Moments>{
  int _selected=0;
  List<SimpleUserInfo> users=[];
  int currentPage=0;
  int pageSize=20;
  bool isLoading=false;
  bool hasError=false;
  bool hasMore=true;
  String errorMessage="";
  List<dynamic> posts=[];
  final ScrollController controller=ScrollController();

  @override
  void initState() {
    super.initState();
    controller.addListener(onScroll);
    getMoments();
  }

  Future<void> getMoments()async{
    setState(() {
      isLoading=true;
      hasError=false;
    });
    
    String url=_selected==0? "https://api.cc98.org/me/followee/topic?from=${currentPage*pageSize}&size=$pageSize&order=$_selected":"https://api.cc98.org/topic/me/favorite?from=${currentPage*pageSize}&size=$pageSize&order=$_selected";
    try{
      String res=await RequestSender.simpleRequest(url);
    if(!res.startsWith("404:")){
      final List<dynamic> _data = json.decode(res);
      final List<String> userIds = _data.map((e) => e['userId'].toString()).toSet().toList();
      final portraitMap=Deserializer.parseUserPortrait(await RequestSender().getUserPortrait(userIds));
      final data=_data.map((e){
        e['portraitUrl'] = portraitMap[e['userId'].toString()]??"";
          return e;
      });
      final newUsers=data.map((e)=>SimpleUserInfo(userId: e["userId"] as int? ??0, userName: e["userName"] as String? ??"匿名", portraitUrl: e["portraitUrl"] as String? ??"")).where((e)=>e.portraitUrl!="").toSet().toList();
      setState(() {
        users.clear();
        users.addAll(newUsers);
        posts.addAll(data);
        isLoading = false;
      });
    }
    }catch(e){
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = '加载失败: ${e.toString()}';
      });
    }
    
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),       
        actionsPadding: EdgeInsets.only(right: 13),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
          child: FluentIconbutton(
            icon: FluentIcons.panel_left_expand_16_regular,
            
          ),
        ),
        titleSpacing: 8,
        actions: [
          FluentIconbutton(
            icon: FluentIcons.arrow_sync_16_regular,
            iconColor: ColorTokens.softPurple,
            onPressed: () {
              
            },
            ),
          SizedBox(width: 6),
          FluentIconbutton(
            icon: FluentIcons.edit_16_regular,
            iconColor: ColorTokens.softPurple,
            onPressed: () {
              
              
            },
            ),
        ],
        title: Text("动态",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: ColorTokens.softPurple),)
      ),
      body: buildLayout(),
    );
  }

  Widget buildLayout(){
    return CustomScrollView(
    controller: controller,
    slivers: [
      // ① SegmentedControl
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 4),
          child: SegmentedControl(
              items: const ['关注', '追更'],
              initialIndex: _selected,
              onSelected: (i) {
                setState((){
                  _selected=i;
                  currentPage=0;
                  hasMore=true;
                  posts.clear();
                } );
                getMoments();
              }),
        ),
      ),
      // ② SizedBox（占位或分隔）
      SliverToBoxAdapter(
        child: buildUserList(users),
      ),
      SliverToBoxAdapter(child: buildDivider()),
      // ③ 原 ListView 数据 → SliverList
      isLoading?SliverToBoxAdapter(child: const Center(child: CircularProgressIndicator(),),):
      SliverList.separated(
        
        itemCount:posts.length ,
        itemBuilder: (context, index) => buildPostItem(posts[index]),
        separatorBuilder:(_, __) =>buildDivider()
        
        ),
    ],
  );
  }

  Widget buildDivider(){
    if(!kIsWeb){
                if(Platform.isWindows||Platform.isLinux||Platform.isMacOS){
                  return Divider(height: 1,thickness: 1, color: ColorTokens.dividerBlue);
                }
                else{
                  return Divider(height: 1,thickness: 6, color: ColorTokens.dividerBlue);
                }
              }
              else{
                return Divider(height: 1, thickness: 1,color: ColorTokens.dividerBlue);
              }
  }

  Widget buildUserList(List<SimpleUserInfo> users){
    return SizedBox(
      height: 84,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12,vertical:8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: users.length,
          itemBuilder: (_,i)=>Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
            child:buildUserInfo(users[i]) ,
            )
          ),
      ),
    );
  }
  Widget buildUserInfo(SimpleUserInfo info){
    return ClickArea(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Profile(userId: info.userId,canEscape: true,),
            ),
          );
      },
      child: Column(
        spacing: 6,
        children: [
          ClipOval(child: Image.network(
                              info.portraitUrl,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Text(
                                    info.userName[0],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: ColorTokens.softPink,
                                      fontWeight: FontWeight.bold,
                                      
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
            
             Text(info.userName,style: TextStyle(color: ColorTokens.softPurple,fontSize: 10),)               
              
        ],
      ),
    );
  }

  Widget buildPostItem(dynamic post) {
  final ColorScheme colorScheme=ColorScheme.fromSeed(seedColor: ColorTokens.primaryLight);
  final mediaMap=post["mediaContent"] as Map<String,dynamic>? ??{};//取出第一层
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
              builder: (context) => Topic(topicId: post['id']),
            ),
          )},
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 作者信息和发布时间
            Row(
              children: [
                // 作者头像
                ClipOval(
                          child: post["userName"]==null?Text("匿",textAlign: TextAlign.center,style: const TextStyle(
                                  fontSize: 14,
                                  color: ColorTokens.softPink,
                                  fontWeight: FontWeight.bold,
                                ),):Image.network(
                            post['portraitUrl'],
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                (post['userName'] != null && post['userName'] != '')
                                    ? post['userName'][0]
                                    : '匿',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: ColorTokens.softPink,
                                  fontWeight: FontWeight.bold,
                                  
                                ),
                              );
                            },
                          ),
                        ),
                const SizedBox(width: 12),
                // 作者名和发布时间
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['userName'] ?? '@ 匿名',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: ColorTokens.primaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(post['time'] is DateTime
                            ? post['createdAt']
                            : DateTime.parse(post['time'])),
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
                post['title'],
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
                    .map((e) => Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(side: BorderSide(color: ColorTokens.softPurple),borderRadius:BorderRadiusGeometry.circular(6)),
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(6),
                        child: Image.network(
                              e,
                              width: 150,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text("图片加载失败:$e"),
                            ),
                      ),
                    ))
                    .toList(),
              ),
            // 回复数和浏览量
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FluentIconbutton(icon: FluentIcons.share_16_regular,iconColor: colorScheme.primary,),
                FluentIconbutton(icon: FluentIcons.chat_16_regular,iconColor: colorScheme.primary),
                FluentIconbutton(icon: FluentIcons.chevron_up_16_regular,iconColor: colorScheme.primary)           
              ],
            ),
          ],
        ),
      ),
    ),
  ); 
}
void onScroll() {
    if (controller.position.pixels >=controller.position.maxScrollExtent - 100 &&!isLoading &&!hasError && hasMore) {
        currentPage++;
        
  }
  }
  @override
  void dispose() {
  controller.dispose();
  super.dispose();
}
}