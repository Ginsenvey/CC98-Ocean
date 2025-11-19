import 'dart:convert';

import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/info_flower.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/kernel.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class ChatMessage {
  final String content;
  final int id;
  final int senderId;
  final String time;
  ChatMessage({
    required this.content, 
    required this.id,
    required this.senderId,
    required this.time
  });
  factory ChatMessage.fromJson(Map<String,dynamic> json){
    return ChatMessage(
      content: json["content"] as String? ??"", 
      id: json["id"] as int? ??0, 
      senderId: json["senderId"] as int? ??0,
      time: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(json['time'] ?? DateTime.now().toString()).add(const Duration(hours: 8)))
      );
  }
}
class Chat extends StatefulWidget {
  final int senderId;
  final String senderName;
  const Chat({super.key,required this.senderId,required this.senderName});
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> messages = [];
  int currentPage=0;
  int pageSize=10;
  bool hasMore=true;
  bool isLoading=false;
  bool hasError=false;
  void _sendMessage() {
}
  @override
  void initState(){
    super.initState();
    getChatHistory();
  }
  Future<void> getChatHistory()async{
    setState(() {
      hasError=false;
      isLoading=true;
    });
    String url="https://api.cc98.org/message/user/${widget.senderId}?from=${currentPage*pageSize}&size=$pageSize";
    try
    {
      final res=await RequestSender.simpleRequest(url);
      if(!res.startsWith("404:")){
        var list=json.decode(res) as List;
        final data=list.map((e)=>ChatMessage.fromJson(e as Map<String,dynamic>)).toList();
        setState(() {
          hasMore=data.length==pageSize;
          for (var e in data) {
          messages.insert(0, e);
        }});
      }
    }
    catch(e){
      setState(() {
        hasError=true;
      });
    }
    finally{
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
            onPressed: () => Navigator.maybePop(context)
          ),
        ),
        actions: [
          FluentIconbutton(icon: FluentIcons.arrow_sync_16_regular,iconColor: ColorTokens.softPurple,onPressed: (){
            currentPage=0;
            messages.clear();
            getChatHistory();
          }),
        ],
        title: Text(widget.senderName,style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: ColorTokens.primaryLight),)

      ),
      body: buildLayout()
    );
  }

  Widget buildLayout(){
    return Column(
        children: [
          isLoading?CircularProgressIndicator():Expanded(
            child: buildChatList()
          ),
          buildInputField(),
        ],
      );
  }

  Widget buildChatList(){
    return RefreshIndicator(
      onRefresh: ()async{
        if(hasMore){
          currentPage++;
          getChatHistory();
        }
        else{
          InfoFlower.showContent(context, child:Text("已加载全部对话"));
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10,vertical: 12),
        color: ColorTokens.chatBackground,
        child: ListView.builder(
                  itemCount: messages.length+1,
                  itemBuilder: (context, index) {
                    if(index==0){
                      return Center(child: Padding(padding: EdgeInsetsGeometry.all(12),child: Text(hasMore?"下拉加载更多":"没有更多回复了",style: TextStyle(color: Colors.grey,fontSize: 12),),));
                    }
                    else{
                      final msg = messages[index-1];
                      return buildChatBox(msg); 
                    }
                    
                  },
                ),
      ),
    );
  }
  Widget buildChatBox(ChatMessage msg){
    bool isMe=msg.senderId!=widget.senderId;
    return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? ColorTokens.softPurple.withAlpha(100) : Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12),topRight: Radius.zero,bottomLeft:Radius.circular(12) ,bottomRight: Radius.circular(12)),
                    ),
                    child: Column(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg.content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          msg.time,
                          style: TextStyle(
                            color:isMe?Colors.white:ColorTokens.softGrey,
                            fontSize: 10
                          ),
                        ),
                      ],
                    ),
                  ),
                );
  }
  Widget buildInputField(){
    return Container(
            padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "输入消息...",
                    enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: ColorTokens.softPurple),
                    ),
                    focusedBorder: UnderlineInputBorder(

                    borderSide: BorderSide(color: ColorTokens.primaryLight),
                    ),
                    hintStyle: TextStyle(color: ColorTokens.softPurple),
                    prefixIconColor: ColorTokens.softPurple,
                    suffixIconColor: ColorTokens.softPurple)
                     ),
                  ),
                
                FluentIconbutton(icon: FluentIcons.send_16_regular,onPressed: () => _sendMessage(),)
              ],
            ),
          );
  }
}