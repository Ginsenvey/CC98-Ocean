
import 'dart:convert';

import 'package:cc98_ocean/controls/info_indicator.dart';
import 'package:cc98_ocean/core/kernel.dart';
import 'package:cc98_ocean/pages/boards.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/hyperlink_button.dart';
import 'package:cc98_ocean/controls/pager.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/core/helper.dart';
import 'package:cc98_ocean/pages/topic.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart';
import 'package:http/http.dart';

class StandardPost {
  final int id;
  final String title;
  final String userName;
  final int replyCount;
  final int hitCount;

  StandardPost({
    required this.id,
    required this.title,
    required this.userName,
    required this.replyCount,
    required this.hitCount
  });

  factory StandardPost.fromJson(Map<String, dynamic> json) {
    return StandardPost(
      id: json['id'] as int,
      title: json['title'] as String,
      userName: json["userName"] as String? ??"匿名",
      replyCount: json["replyCount"] as int,
      hitCount: json["hitCount"] as int
    );
  }
}


class Board extends StatefulWidget {
  final int boardId;
  const Board({super.key,required this.boardId});

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> with TickerProviderStateMixin
{
  late final AnimationController _controller;
  late final Animation<double> _sizeFactor; 
  late final Animation<Offset> _slide;
  bool _showBigPaper=false;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage="";
  late BoardInfo data;
  List<StandardPost> posts=[];
  int currentPage=0;
  int pageSize=20;
  

  @override
  void initState() {
    super.initState();
    getMetaData();
     _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,                          // ← 合法
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  _sizeFactor = Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  Future<void> getMetaData()async{
    setState(() {
      isLoading = true;
      hasError = false;
    });

  String url="https://api.cc98.org/board/${widget.boardId}";
  try{
    String res=await RequestSender.simpleRequest(url);
    getTopic();
    if(!res.startsWith("404:")){
      final _data=json.decode(res) as Map<String,dynamic>;
      setState(() {
        data=BoardInfo.fromJson(_data);
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
  
  Future<void> getTopic()async{
    
    String url="https://api.cc98.org/board/${widget.boardId}/topic?from=${currentPage*pageSize}&size=$pageSize";
    try{
      final res=await RequestSender.simpleRequest(url);
    if(!res.startsWith("404:")){
      final data=json.decode(res) as List<dynamic>;
      setState(() {
        posts.clear();//在状态管理中处理UI数据源更新，而不是在外部
        final newPosts=data.map((e)=>StandardPost.fromJson((e as Map<String,dynamic>))).toList();
        posts.addAll(newPosts);
        isLoading=false;
      });
    }
    }
    catch(e)
    {
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
            icon: FluentIcons.pin_16_regular,
            iconColor: ColorTokens.softPurple,
            onPressed: () {
              
            },
            ),
          SizedBox(width: 6),
          FluentIconbutton(
            icon: FluentIcons.slide_text_16_regular,
            iconColor: ColorTokens.softPurple,
            onPressed: () {
              setState(() => _showBigPaper = !_showBigPaper);
              _showBigPaper? _controller.forward(): _controller.reverse();
            },
            ),
        ],
        title: Text(isLoading?"加载中···":data.name,style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),)
        //对于late变量，我们确保已经初始化再调用
      ),
      body:buildLayout(),
      bottomNavigationBar: SafeArea( 
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child:isLoading?null:PageBar(currentPage: currentPage+1,totalPages:data.topicCount~/20,onJump:(p) {
                setState(() {
                  currentPage=p-1;
                  getTopic();
                });
              }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildLayout(){
    if(isLoading)return Center(child: CircularProgressIndicator());
    if(!isLoading&&posts.isEmpty)return ErrorIndicator(icon: FluentIcons.music_note_1_20_regular, info: "暂无帖子，点击刷新",onTapped: getTopic);
    if(hasError)return ErrorIndicator(icon: FluentIcons.music_note_2_16_regular, info: errorMessage,onTapped: getTopic);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child:Column(
        children: [
          if (_showBigPaper || _controller.value > 0)
          SizeTransition(                 // ← 高度 0↔1
      sizeFactor: _sizeFactor,
      axisAlignment: -1,            // 从顶部开始展开
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: SlideTransition(       // ← 滑动 -1↔0
          position: _slide,
          child: buildBigPaper(),     // 真正内容
        ),
      ),
    ),

          buildTopicList(posts),
          
        ],
      ),
    );
  }
  
  Widget buildBigPaper(){
    final bigPaper=isLoading?"":data.bigPaper;
    return Card(
      elevation: 0,
      color: ColorTokens.dividerBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
        child: BBCodeText(data:BBCodeConverter.convertBBCode(bigPaper),stylesheet: defaultBBStylesheet(textStyle: TextStyle(fontSize: 12,color: Colors.black)),),
      ));
  }
  Widget buildTopicList(List<StandardPost> posts){
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FluentIcons.music_note_1_24_regular, size: 64, color: ColorTokens.primaryLight),
            const SizedBox(height: 16),
            Text(errorMessage),
            const SizedBox(height: 16),
            HyperlinkButton(onPressed: () => getTopic(),text: "刷新",icon:FluentIcons.arrow_sync_16_regular ,)
          ],
        ),
      );
    }
    //占位组件
    
    return Expanded(
      child: ListView.builder(
        itemCount: posts.length,
        shrinkWrap: true,
        itemBuilder:(context,index){
          return buildTopicCard(posts[index]);
        } ),
    );
  }

  Widget buildTopicCard(StandardPost post){
    return Card(
    key: ValueKey(post.id),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(FluentIcons.notepad_16_regular,size: 16,color: ColorTokens.softPurple,),
            SizedBox(width: 6,),
            Expanded(
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
            SizedBox(width: 6),
            Text(post.userName,style:TextStyle(fontSize: 12) ,)      
          ],
        ),
      ),
    ),
  );
  }
}