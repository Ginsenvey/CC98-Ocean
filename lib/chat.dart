import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
class ChatMessage {
  final String text;
  final bool isMe;

  ChatMessage({required this.text, required this.isMe});
}
class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(text: "你好！", isMe: false),
    ChatMessage(text: "你好，有什么可以帮助你的吗？", isMe: true),
  ];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(text: text, isMe: true));
        _controller.clear();
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
          FluentIconbutton(icon: FluentIcons.arrow_sync_16_regular,iconColor: ColorTokens.softPurple,onPressed: ()=>{}),
        ],
        title: const Text("xxx",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: ColorTokens.primaryLight),)

      ),
      body: buildLayout()
    );
  }

  Widget buildLayout(){
    return Column(
        children: [
          Expanded(
            child: buildChatList()
          ),
          
          buildInputField(),
        ],
      );
  }

  Widget buildChatList(){
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10,vertical: 12),
      color: ColorTokens.chatBackground,
      child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return buildChatBox(msg);
                },
              ),
    );
  }
  Widget buildChatBox(ChatMessage msg){
    return Align(
                  alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isMe ? ColorTokens.softPurple : Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12),topRight: Radius.zero,bottomLeft:Radius.circular(12) ,bottomRight: Radius.circular(12)),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isMe ? Colors.white : Colors.black87,
                      ),
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