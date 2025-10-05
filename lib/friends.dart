import 'dart:convert';
import 'dart:io';

import 'package:cc98_ocean/controls/clickarea.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/segmented.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/kernel.dart';
import 'package:cc98_ocean/main.dart';
import 'package:cc98_ocean/profile.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserInfo{
  final int id;
  final String name;
  final String portraitUrl;
  final int postCount;
  final int fanCount;
  final String introduction;
  UserInfo({
    required this.id,
    required this.name,
    required this.portraitUrl,
    required this.fanCount,
    required this.postCount,
    required this.introduction
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserInfo && runtimeType == other.runtimeType && id == other.id&&name==other.name;

  @override
  int get hashCode => id.hashCode;

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id:json["id"] as int,
      name: json["name"] as String? ??"匿名",
      portraitUrl: json["portraitUrl"]as String? ??"",
      fanCount: json["fanCount"] as int? ??0,
      postCount: json["postCount"] as int? ??0,
      introduction: json["introduction"] as String? ??""
    );
  }
}

class Friends extends StatefulWidget {
  const Friends({super.key});

  @override
  State<Friends> createState() => _FriendsState();
}
class _FriendsState extends State<Friends>{
  int _selected=0;
  int currentPage=0;
  int pageSize=10;
  bool isLoading=false;
  bool hasError=false;
  bool hasMore=true;
  String errorMessage="";
  List<UserInfo> friends=[];
  final ScrollController controller = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.addListener(onScroll);
    getFriends();
  }

  Future<void> getFriends()async{
    setState(() {
      isLoading = true;
      hasError = false;
    });
    String mode=_selected==0? "follower":"followee";
    String url="https://api.cc98.org/me/$mode?from=${currentPage*pageSize}&size=$pageSize";

    try{
      String res=await RequestSender.simpleRequest(url);
    //获取id列表
    if(!res.startsWith("404:")){
      final list=json.decode(res) as List;
      //从dynamic装箱,这是一个强制类型转换
      final userIds=list.cast<int>();
      String userInfoJson=await RequestSender.getUserInfo(userIds);
      final userInfoList=json.decode(userInfoJson) as List;
      final data=userInfoList.map((e)=>UserInfo.fromJson(e as Map<String,dynamic>)).toList();
      setState(() {
        friends.addAll(data);
        if(data.length<pageSize){
          hasMore=false;
        }
        else{
          hasMore=true;
        }
        isLoading=false;
        hasError=false;
      });
    }
    }
    catch(e){
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = '加载失败: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            icon: FluentIcons.chevron_left_16_regular,
            onPressed: () {
              Navigator.maybePop(context);
            },
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
        
        title: Text("好友",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),), 
      ),
      body: buildLayout(),
      );
  }

  Widget buildLayout(){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 4),
          child: SegmentedControl(
              items: const ['粉丝', '关注'],
              initialIndex: _selected,
              onSelected: (i) {
                setState((){
                  _selected=i;
                  currentPage=0;
                  hasMore=true;
                  friends.clear();//涉及UI更新，必须setState
              });
                getFriends();
            }),
        ),
        Text(errorMessage),
        Expanded(child: 
          ListView.separated(
            controller: controller,
            itemCount: friends.length,
            separatorBuilder: (context, index) => Divider(height: 1, thickness: 1,color: ColorTokens.dividerBlue),
            itemBuilder: (_,i)=>buildFriend(friends[i])
            )
        )
      ],
    ) ;
  }
  Widget buildFriend(UserInfo info){
    return Card(
      elevation: 0, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(0)
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            SizedBox(
              height: 36,
              width: 36,
              child: ClickArea(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context)=>Profile(userId: info.id, canEscape: true))),
                child: ClipOval(
                  child: Image.network(info.portraitUrl,height: 36,width: 36,errorBuilder: (context, error, stackTrace) => Text("")), 
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.name,style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: ColorTokens.primaryLight, 
                            ),),
                  SizedBox(height: 2),
                  Text(info.introduction,style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),)
                      
                ],
              ),
            ),
            FluentIconbutton(icon: FluentIcons.heart_16_regular),
            SizedBox(width: 20,)
          ],
        ),
      ),
    );
  }

  void onScroll() {
    if (controller.position.pixels >=controller.position.maxScrollExtent - 100 &&!isLoading &&!hasError && hasMore) {
        currentPage++;
        getFriends();  
    }
  }

  @override
  void dispose() {
  controller.dispose();
  super.dispose();
}
}