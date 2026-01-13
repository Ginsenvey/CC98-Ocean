import 'dart:convert';

import 'package:cc98_ocean/controls/adaptive_divider.dart';
import 'package:cc98_ocean/controls/info_indicator.dart';
import 'package:cc98_ocean/controls/portrait_oval.dart';
import 'package:cc98_ocean/controls/status_title.dart';
import 'package:cc98_ocean/core/helper.dart';
import 'package:cc98_ocean/core/kernel.dart';
import 'package:cc98_ocean/pages/chat.dart';
import 'package:cc98_ocean/controls/clickarea.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/segmented.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum MailType {
  message,     //私信
  comments,   // 回复
  systemNotification,  //系统通知
}
class Contact{
  final String lastContent;
  final int id;
  final String time;
  String name="未知用户";
  String portraitUrl="";
  Contact({required this.lastContent,
  required this.id,
  required this.time
  });
  factory Contact.fromJson(Map<String,dynamic> json){
    return Contact(lastContent: json["lastContent"] as String? ?? "", 
    id: json["userId"] as int? ?? 0, 
    time: json["time"] as String? ??"");
  }
}
class NotificationItem {
  final int id;
  final int type;
  final int topicId;
  final int postId;
  final int boardId;
  final String time;
  final bool isRead;
  final PostBasicInfo postBasicInfo;

  NotificationItem({
    required this.id,
    required this.type,
    required this.topicId,
    required this.postId,
    required this.boardId,
    required this.time,
    required this.isRead,
    required this.postBasicInfo,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      type: json['type'] as int,
      topicId: json['topicId'] as int,
      postId: json['postId'] as int,
      boardId: json['boardId'] as int,
      time: json["time"] as String? ??"",
      isRead: json['isRead'] as bool,
      postBasicInfo: PostBasicInfo.fromJson(json['postBasicInfo'] as Map<String, dynamic>),
    );
  }
}
class PostBasicInfo {
  final int id;
  final int floor;
  final int userId;
  final String userName;
  final bool isDeleted;
  final int boardId;

  PostBasicInfo({
    required this.id,
    required this.floor,
    required this.userId,
    required this.userName,
    required this.isDeleted,
    required this.boardId,
  });
  factory PostBasicInfo.fromJson(Map<String, dynamic> json) {
    return PostBasicInfo(
      id: json['id'] as int,
      floor: json['floor'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      isDeleted: json['isDeleted'] as bool,
      boardId: json['boardId'] as int,
    );
  }
}
class Mailbox extends StatefulWidget {
  const Mailbox({super.key});

  @override
  State<Mailbox> createState() => _MailboxState();
}

class _MailboxState extends State<Mailbox> {
  
  Map<MailType,List<dynamic>> dataMap={
    MailType.message:<Contact>[],
    MailType.comments:<NotificationItem>[],
    MailType.systemNotification:<NotificationItem>[]
  };
  bool isLoading=false;
  bool hasError=false;
  MailType currentMailType=MailType.message;
  String errorMessage="";
  @override
  void initState() {
    super.initState();
    getRecentContact();
  }
  String targetDomain(MailType type)=>switch(type){
    MailType.comments=>"https://api.cc98.org/notification/reply?",
    MailType.message=>"https://api.cc98.org/message/recent-contact-users?",
    MailType.systemNotification=>"",
  };
  Future<void> getRecentContact()async{
    final String domain=targetDomain(currentMailType);
    String url="${domain}from=0&size=10";
    try{
      setState(() {
        isLoading=true;
        hasError=false;
      });
      final res=await RequestSender.simpleRequest(url);
    if(!res.startsWith("404:")){
      final list=json.decode(res) as List;
      final data=await parseMail(currentMailType, list);
      setState(() {
        dataMap[currentMailType]?.addAll(data);
      });
    }
    }catch(e){
      setState(() {
        hasError=true;
        errorMessage=e.toString();
      });
    }finally{
      setState(() {
        isLoading=false;
      });
    }
  }
  Future<List<dynamic>> parseMail(MailType type,List<dynamic> list)async {
    switch (type) {
      case MailType.message:
        final data=list.map((e)=>Contact.fromJson(e as Map<String,dynamic>)).toList();
        final userIds=data.map((e)=>e.id).toList();
        final userInfoList=Deserializer.parseUserPortrait(await RequestSender().getUserPortrait(userIds));
        for (var e in data) {
          var user=userInfoList.firstWhere((u)=>u.userId==e.id);
          e.name=user.userName;
          e.portraitUrl=user.portraitUrl;  
        }
        return data;
      case MailType.comments:
        final data=list.map((e)=>NotificationItem.fromJson(e as Map<String,dynamic>)).toList();
        return data;
      case MailType.systemNotification:
        return [];
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
            icon:FluentIcons.chevron_left_16_regular,
            onPressed: () =>Navigator.maybePop(context)
          ),
        ),
        
        title: StatusTitle(title: "消息",isLoading: isLoading,onTap:getRecentContact)

      ),
      body:buildLayout() 
    );
  }
  Widget buildLayout(){
    if(!isLoading&&dataMap[currentMailType]!.isEmpty)return ErrorIndicator(icon: FluentIcons.music_note_1_20_regular, info: "暂无帖子，点击刷新",onTapped: getRecentContact);
    if(hasError)return ErrorIndicator(icon: FluentIcons.music_note_2_16_regular, info: errorMessage,onTapped: getRecentContact);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
          child: SegmentedControl(items: ["私信","系统消息","@我的"], onSelected:(i){
            setState(() {
              currentMailType=MailType.values[i];
            });
            getRecentContact();
          }),
        ),

        Expanded(child: buildMailList())
      ],
    );
  }
  Widget buildMailList(){
    switch(currentMailType){
      case MailType.message:
        return ListView.separated(itemBuilder: (_,i)=>buildMailCard((dataMap[currentMailType] as List<Contact>)[i]), 
        separatorBuilder: (_,i)=>Divider(indent: 60,height: 6,thickness: 1,color: Theme.of(context).dividerColor), 
        itemCount:dataMap[currentMailType]!.length);
      case MailType.comments:
        return ListView.separated(itemBuilder: (_,i)=>buildNotificationCard((dataMap[currentMailType] as List<NotificationItem>)[i]), 
        separatorBuilder:(_,i)=> AdaptiveDivider(), 
        itemCount: dataMap[currentMailType]!.length);
      case MailType.systemNotification:
        return ListView.separated(itemBuilder: (_,i)=>buildMailCard((dataMap[currentMailType] as List<Contact>)[i]), 
        separatorBuilder: (_,i)=>Divider(indent: 60,height: 6,thickness: 1,color: Theme.of(context).dividerColor), 
        itemCount:dataMap[currentMailType]!.length);
    }
    
  }
  Widget buildMailCard(Contact contact){
    return ClickArea(
      onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>Chat(senderId: contact.id,senderName: contact.name,))),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            SizedBox(
              height: 36,
              width: 36,
              child: PortraitOval(url:contact.portraitUrl),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(contact.name,style: const TextStyle(
                                  fontSize: 14,
                                ),),
                      Text(DateFormat('yyyy-MM-dd').format(
                        DateTime.parse(contact.time).add(const Duration(hours: 8)),),
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),)
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(contact.lastContent,style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                    maxLines: 1, )
                ],
              ),
            ),
            
          ],
        ),
      ),
    );
  }
  Widget buildNotificationCard(NotificationItem item){
    return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            SizedBox(
              height: 36,
              width: 36,
              child: PortraitOval(url:""),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.postBasicInfo.userName,style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold
                                )),
                      Text(item.time.toUtc8,
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),)
                    ],
                  ),
                  SizedBox(height: 4),
                  Text("在CC${item.topicId}中回复了你。",style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                    maxLines: 1, )
                ],
              ),
            ),
            
          ],
        ),
      );
  }
  Widget buildDefaultAvatar(String url){
    if(url.contains("boy")){
      return Image.asset("assets/images/default_avatar_boy.png");
    }
    else if(url.contains("girl")){
      return Image.asset("assets/images/default_avatar_girl.png");
    }
    else{
      return Image.asset("assets/images/unknown.gif");
    }
  }
}