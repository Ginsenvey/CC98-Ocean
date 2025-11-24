import 'dart:convert';

import 'package:cc98_ocean/controls/info_indicator.dart';
import 'package:cc98_ocean/controls/portrait_oval.dart';
import 'package:cc98_ocean/core/kernel.dart';
import 'package:cc98_ocean/pages/chat.dart';
import 'package:cc98_ocean/controls/clickarea.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/segmented.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/pages/focus.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    time: json["time"] as String? ??"null");
  }
}
class Mailbox extends StatefulWidget {
  const Mailbox({super.key});

  @override
  State<Mailbox> createState() => _MailboxState();
}

class _MailboxState extends State<Mailbox> {
  final List<Contact> contacts=[];
  bool isLoading=false;
  bool hasError=false;
  String errorMessage="";
  @override
  void initState() {
    super.initState();
    getRecentContact();
  }
  Future<void> getRecentContact()async{
    String url="https://api.cc98.org/message/recent-contact-users?from=0&size=10";
    try{
      setState(() {
        isLoading=true;
        hasError=false;
      });
      final res=await RequestSender.simpleRequest(url);
    if(!res.startsWith("404:")){
      contacts.clear();
      final list=json.decode(res) as List;
      List<Contact> data=list.map((e)=>Contact.fromJson(e as Map<String,dynamic>)).toList();
      final userIds=data.map((e)=>e.id).toList();
      final userInfoList=Deserializer.parseUserPortrait(await RequestSender().getUserPortrait(userIds));
      for (var e in data) {
        var user=userInfoList.firstWhere((u)=>u.userId==e.id);
        e.name=user.userName;
        e.portraitUrl=user.portraitUrl;  
      }
      setState(() {
        contacts.addAll(data);
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
        
        title: const Text("消息",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: ColorTokens.primaryLight),)

      ),
      body:buildLayout() 
    );
  }
  Widget buildLayout(){
    if(isLoading)return Center(child: CircularProgressIndicator());
    if(!isLoading&&contacts.isEmpty)return ErrorIndicator(icon: FluentIcons.music_note_1_20_regular, info: "暂无帖子，点击刷新",onTapped: getRecentContact);
    if(hasError)return ErrorIndicator(icon: FluentIcons.music_note_2_16_regular, info: errorMessage,onTapped: getRecentContact);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
          child: SegmentedControl(items: ["私信","系统消息","@我的"], onSelected:(i)=>{}),
        ),

        Expanded(child: buildMailList())
      ],
    );
  }
  Widget buildMailList(){
    return ListView.separated(itemBuilder: (_,i)=>buildMailCard(contacts[i]), separatorBuilder: (_,i)=>Divider(thickness: 1,indent: 60,endIndent: 0,color: ColorTokens.dividerBlue,), itemCount:contacts.length);
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
                                  color: Colors.black, 
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