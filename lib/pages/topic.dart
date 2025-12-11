import 'package:cc98_ocean/controls/clickarea.dart';
import 'package:cc98_ocean/controls/extended_tags.dart';
import 'package:cc98_ocean/controls/fluent_dialog.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/image_viewer.dart';
import 'package:cc98_ocean/controls/info_flower.dart';
import 'package:cc98_ocean/controls/info_indicator.dart';
import 'package:cc98_ocean/controls/pager.dart';
import 'package:cc98_ocean/controls/portrait_oval.dart';
import 'package:cc98_ocean/controls/status_title.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/core/kernel.dart';
import 'package:cc98_ocean/core/themes/setting_controller.dart';
import 'package:cc98_ocean/pages/focus.dart';
import 'package:cc98_ocean/core/helper.dart';
import 'package:cc98_ocean/pages/profile.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:provider/provider.dart';

class Reply{
  final int id;
  final int userId;
  int likeCount;
  int dislikeCount;
  int likeState;
  final int floor;
  final int contentType;
  final String userName;
  final String title;
  final String time;
  final bool isMe;
  String portraitUrl=""; 
  final String content;
  Reply({
    required this.id,
    required this.isMe,
    required this.userId,
    required this.dislikeCount,
    required this.contentType,
    required this.likeCount,
    required this.floor,
    required this.time,
    required this.title,
    required this.userName,
    required this.content,
    required this.likeState
  });
  factory Reply.fromJson(Map<String,dynamic> json){
    return Reply(
      id:json["id"] as int? ??0,
      isMe: json["isMe"] as bool? ??false,
      userId: json["userId"] as int? ??0,
      floor: json["floor"] as int? ??0,
      dislikeCount: json["dislikeCount"] as int? ??0,
      contentType: json["contentType"] as int? ??0,
      likeCount: json["likeCount"] as int? ??0, 
      likeState: json["likeState"] as int? ??0,
      time: json["time"] as String? ??"", 
      title: json["title"] as String? ??"未知内容",
      userName: json["userName"] as String? ??"匿名用户",
      content: json["content"] as String? ??""
      );
  }
}

class Topic extends StatefulWidget {
  final int topicId;

  const Topic({super.key, required this.topicId});

  @override
  State<Topic> createState() => _TopicState();
}

class _TopicState extends State<Topic> with SingleTickerProviderStateMixin {
  late BBStylesheet extendStyle;
  bool useTail=true;
  Map<String, dynamic>? topicDetail;
  List<Reply> replies = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  int currentPage = 0;
  int totalPages=1;
  final int pageSize = 10;
  bool hasMore = true;
  Connector client = Connector();
  final ScrollController controller = ScrollController();
  @override
  void initState() {
    super.initState();
    // 不在这里初始化样式
    controller.addListener(onScroll);
    getTopicData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 根据当前 Theme 重新生成 stylesheet，保证随主题实时更新
    initializeStyleSheet();
  }

  void initializeStyleSheet(){
    // 从当前主题取基础文字样式，保证颜色随主题变化
    final baseTextStyle = (Theme.of(context).textTheme.bodyMedium ??
            const TextStyle()).copyWith(
      wordSpacing: 1.2,
      fontSize: 15,
      height: 1.5,
    );

    extendStyle = defaultBBStylesheet(textStyle: baseTextStyle)
        .addTag(AudioTag())
        .addTag(VideoTag())
        .addTag(StrikeTag())
        .replaceTag(SmartImgTag(context: context));
  }
  // 获取帖子详情
  Future<void> getTopicData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // 获取帖子标题
      final topicResponse = await client.get(
        'https://api.cc98.org/topic/${widget.topicId}'
      );

      if (topicResponse.statusCode == 200) {
        final topicData = json.decode(topicResponse.body);
        setState(() {
          topicDetail = topicData;
          totalPages=(topicDetail!["replyCount"] as int? ??0)~/10+1;
        });
      } else {
        throw Exception('获取帖子详情失败: ${topicResponse.statusCode}');
      }

      // 获取回复列表
      currentPage = 0;
      replies.clear();
      await getReply();
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = '加载失败: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // 获取回复列表
  Future<void> getReply() async {
    try {
      final response = await client.get(
        'https://api.cc98.org/Topic/${widget.topicId}/post?from=${currentPage * pageSize}&size=$pageSize'
      );

      if (response.statusCode == 200) {
        List list = json.decode(response.body);
        final data=list.map((e)=>Reply.fromJson(e as Map<String,dynamic>)).toList();
        //考虑e["userId"]可能为null的情况
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
          replies.addAll(data);
          hasMore = data.length == pageSize;
        });
      } else {
        setState(() {
          errorMessage='获取回复失败: ${response.statusCode}';
          hasError=true;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = '加载回复失败: ${e.toString()}';
      });
    }finally{
      setState(() {
        isLoading=false;
      });
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading) return;
    currentPage++;
    setState(() {
      isLoading = true;
    });
    await getReply();
  }
  @override
  Widget build(BuildContext context) {
    useTail=Provider.of<AppState>(context).useTail;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),       
        actionsPadding: EdgeInsets.only(right: 8),
        titleSpacing: 8,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
          child: FluentIconbutton(icon: FluentIcons.chevron_left_16_regular,onPressed:()=>{Navigator.maybePop(context)},),
        ),
        actions: [FluentIconbutton(icon: FluentIcons.share_16_regular,iconColor: ColorTokens.softPurple,),
          SizedBox(width: 6,),
          FluentIconbutton(icon: FluentIcons.more_horizontal_16_regular,iconColor: ColorTokens.softPurple,),
        ],
        title: StatusTitle(title: "帖子详情",isLoading: isLoading,onTap:getTopicData)

      ),
      body: SafeArea(child: buildLayout()),
      floatingActionButton: FloatingActionButton(
        elevation: 3,
        mini: true,
        shape: const CircleBorder(),
        onPressed: () => _showReplyDialog(0,widget.topicId.toString()),//0表示回复楼主
        child: const Icon(FluentIcons.add_12_regular),
      ),
      bottomNavigationBar: isLoading?null:(totalPages<4?null:SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: PageBar(currentPage: currentPage+1, totalPages: totalPages, onJump:(p){
            setState(() {
                      currentPage=p-1;
                      replies.clear();
                      getReply();
                    });
          } ),
        ),
      )),
    );
  }

  Widget buildLayout() {
    if(hasError)return ErrorIndicator(icon: FluentIcons.music_note_2_16_regular, info: errorMessage,onTapped: getReply);
    return Column(
      children: [
        buildTitleBanner(),
        const SizedBox(height: 8),
        buildReplyList()
      ],
    );
  }

  Widget buildTitleBanner() {
    
    if (topicDetail == null) return Container();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            softWrap: true,
            topicDetail!['title'] ?? '无标题',
            style: const TextStyle(
              
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(FluentIcons.person_16_filled, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                topicDetail!['userName'] ?? '匿名',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(FluentIcons.history_16_regular, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                DateFormat('yyyy-MM-dd HH:mm').format(
                  DateTime.parse(topicDetail!['time'] ?? DateTime.now().toString()).add(const Duration(hours: 8)),
                ),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget buildReplyList(){
    return Expanded(
          child: RefreshIndicator(
            onRefresh: getTopicData,
            child: ListView.separated(
              separatorBuilder:(_, __)=>Divider(height: 1,thickness: 1,color: Theme.of(context).dividerColor), 
              controller: controller,
              itemCount:totalPages>3?replies.length :replies.length+1,
              itemBuilder: (context, index) {
                if (index == replies.length&&totalPages<4) {
                  return _buildLoadMoreIndicator();
                }
                return buildReplyItem(replies[index]);
              },
            ),
          ),
        );
  }
  // 构建回复项
  Widget buildReplyItem(Reply reply) {
    return Card(
      margin: EdgeInsets.all(0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 回复者信息
            Row(
              children: [
                ClickArea(onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>Profile(userId: reply.userId, canEscape: true))),
                  child: PortraitOval(url: reply.portraitUrl)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: ColorTokens.softPink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reply.time.toUtc8,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // 楼层
                Text("${reply.floor}L",style: TextStyle(fontSize: 14,color: ColorTokens.softPurple),)
              ],
            ),
            const SizedBox(height: 16),
            reply.contentType==0?BBCodeText(data: BBCodeConverter.convertBBCode(reply.content),stylesheet: extendStyle,errorBuilder: (context,obj,trace){return Text(">>UBB解析错误,请报告开发者<<");} )
            :MarkdownBlock(data: MdConverter.convertHtml(reply.content).trim()),
            const SizedBox(height: 16),
            // 点赞和点踩数据
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildReactionChip(
                  icon: reply.likeState ==1?FluentIcons.thumb_like_16_filled:FluentIcons.thumb_like_16_regular,
                  count: reply.likeCount,
                  onPressed: () => _handleLike(reply.id,true),
                ),
                const SizedBox(width: 6),
                // 点踩数
                _buildReactionChip(
                  icon: reply.likeState==2?FluentIcons.thumb_dislike_16_filled:FluentIcons.thumb_dislike_16_regular,
                  count: reply.dislikeCount,
                  onPressed: () => _handleLike(reply.id,false),
                ),
                  ],
                ),
                // 点赞数
                
                TextButton(
                  onPressed: () => _showReplyDialog(0, reply.userName),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 0),
                  ),
                  child: Icon(FluentIcons.comment_16_regular, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建反应芯片
  Widget _buildReactionChip({
    required IconData icon,
    required int count,
    required VoidCallback onPressed,
  }) {
    return TextButton(onPressed: onPressed,
     style: TextButton.styleFrom(
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(4),
      
       ),
       padding: const EdgeInsets.all(6),
       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
       minimumSize: const Size(0, 0),
     ),
     child:
     Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(count.toString(), style: TextStyle(color: Colors.grey.shade800,fontSize: 12)),
      ],
     ) );
  }

  // 小尾巴参数
  String get platform => switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS     => 'IOS',
      TargetPlatform.windows => 'Windows x64',
      TargetPlatform.macOS  => 'macOS',
      TargetPlatform.linux   => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };

  // 处理点赞
  void _handleLike(int replyId,bool mode)async {
    bool success=await RequestSender.likeReply(replyId,mode?"1":"2");  
    if(mode){
      InfoFlower.showContent(context, child: Text(success?"已点赞回复$replyId":"点赞失败"));
    }else{
      InfoFlower.showContent(context, child: Text(success?"已点踩回复$replyId":"点踩失败"));
    }
    final newLikeStatus=await RequestSender.getLikeStatus(replyId);
    if(newLikeStatus["success"]==0){
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('获取最新点赞状态失败')),
    );
      return;
    }
    setState(() {
    final target = replies.firstWhere((e) => e.id == replyId);
    if(newLikeStatus["success"]==1){
      target.likeCount=newLikeStatus["likeCount"] as int;
      target.dislikeCount=newLikeStatus["dislikeCount"] as int;
      target.likeState=newLikeStatus["likeState"] as int;
    }
});
}


  // 显示回复对话框
  void _showReplyDialog(int replyId,String receiverName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => FluentDialog(
        title: '回复:$receiverName',
        content: TextField(
          controller: controller,
          maxLines: 5,
          
          decoration: const InputDecoration(
            hintText: '输入您的回复内容...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {},
        ),
        cancelText: "取消",
        confirmText: "发送",
        onConfirm: ()async {
              String originalContent=controller.text.trim();
              String content=useTail?originalContent:"$originalContent\n[align=right][size=3][color=gray]——来自「[b][color=purple]CC98 For $platform[/color][/b]」[/color][/size][/align]";
              if(originalContent.isEmpty)
              {
                InfoFlower.showContent(context, child: Text("回复内容不能为空",style: TextStyle(color: ColorTokens.primaryLight)));
                return;
              }
              else{
                String res;
                if(replyId==0)//回复楼主
                {
                  res=await RequestSender.sendReplyToTopic(widget.topicId,content,false,false,0,false,0);
                }
                else
                {
                  res=await RequestSender.sendReplyToTopic(widget.topicId,content,false,false,0,true,replyId);
                } 
                if(res=="1"){
                InfoFlower.showContent(context,child: Text("回复已提交",style: TextStyle(color: ColorTokens.primaryLight))
              );
              }else{
                InfoFlower.showContent(context,child: Text("回复已提交",style: TextStyle(color: ColorTokens.primaryLight))
              );
              }
              }
              Navigator.pop(context);

            }, 
          ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(hasMore?"下拉加载更多":'没有更多回复了', style: TextStyle(color: Colors.grey)),
    ),
  );
  }

  void onScroll() async{
    if (controller.position.pixels >=controller.position.maxScrollExtent - 100 &&!isLoading &&!hasError&&totalPages<4) {
        currentPage++;
        await loadMore();
    }
  }
  @override
  void dispose() {
  controller.dispose();
  super.dispose();
}
}


