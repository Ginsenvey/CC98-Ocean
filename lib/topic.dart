
import 'package:cc98_ocean/controls/extended_tags.dart';
import 'package:cc98_ocean/controls/fluent_dialog.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/pager.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/helper.dart';
import 'package:cc98_ocean/kernel.dart';
import 'package:cc98_ocean/profile.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart';
import 'package:markdown_widget/widget/all.dart';
// 帖子详情页
class Topic extends StatefulWidget {
  final int topicId;

  const Topic({super.key, required this.topicId});

  @override
  State<Topic> createState() => _TopicState();
}

class _TopicState extends State<Topic> {
  final extendStyle=defaultBBStylesheet(textStyle: TextStyle(
    wordSpacing: 1.2,
    fontSize: 15,
    color: Colors.black,
    height: 1.5,
    )).addTag(AudioTag()).addTag(VideoTag()).addTag(StrikeTag());
  // 帖子详情
  Map<String, dynamic>? topicDetail;
  // 回复列表
  List<dynamic> replies = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  int currentPage = 0;
  int totalPages=1;
  final int pageSize = 10;
  bool hasMore = true;
  Client client = Client();
  @override
  void initState() {
    super.initState();
    _fetchTopicData();
  }

  // 获取帖子详情
  Future<void> _fetchTopicData() async {
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
      await _fetchReplies();
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = '加载失败: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // 获取回复列表
  Future<void> _fetchReplies() async {
    try {
      final response = await client.get(
        'https://api.cc98.org/Topic/${widget.topicId}/post?from=${currentPage * pageSize}&size=$pageSize'
      );

      if (response.statusCode == 200) {
        final List<dynamic> newReplies0 = json.decode(response.body);
        //考虑e["userId"]可能为null的情况
        final List<String> userIds = newReplies0.map((e) => e['userId'].toString()).toSet().toList();
        final portraitMap=Deserializer.parseUserPortrait(await RequestSender().getUserPortrait(userIds));
        final List<dynamic> newReplies = newReplies0.map((e) {
          e['portraitUrl'] = portraitMap[e['userId'].toString()] ?? '';
          return e;
        }).toList();
        setState(() {
          replies.addAll(newReplies);
          isLoading = false;
          hasMore = newReplies.length == pageSize;
        });
      } else {
        throw Exception('获取回复失败: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = '加载回复失败: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // 加载更多回复
  Future<void> _loadMoreReplies() async {
    if (!hasMore || isLoading) return;
    
    setState(() {
      currentPage++;
      isLoading = true;
    });
    
    await _fetchReplies();
  }

  // 构建顶部标题横幅
  Widget _buildTitleBanner() {
    
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
                  DateTime.parse(topicDetail!['time'] ?? DateTime.now().toString()),
                ),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建回复项
  Widget _buildReplyItem(dynamic reply) {
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
                reply['portraitUrl'] != null && reply['portraitUrl'] != ''
                    ? GestureDetector(
                      onTap: () {
                        if(reply['userId']==null) return;
                        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Profile(userId: reply['userId'] as int,canEscape: true,),
            ),
          );
                      },
                      child: ClipOval(
                          child: Image.network(
                            reply['portraitUrl'],
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                (reply['userName'] != null && reply['userName'] != '')
                                    ? reply['userName'][0]
                                    : '匿',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: ColorTokens.softPink,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                    )
                    : Text(
                        (reply['userName'] != null && reply['userName'] != '')
                            ? reply['userName'][0]
                            : '匿',
                        style: const TextStyle(
                          fontSize: 18,
                          color: ColorTokens.softPink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply['userName'] ?? '匿名用户',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: ColorTokens.softPink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MM-dd HH:mm').format(
                          DateTime.parse(reply['time'] ?? DateTime.now().toString()),
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // 楼层
                Text("${reply["floor"]}L",style: TextStyle(fontSize: 14,color: ColorTokens.softPurple),)
              ],
            ),
            const SizedBox(height: 16),
            reply["contentType"]==0?BBCodeText(data: BBCodeConverter.convertBBCode(reply['content'] ?? ''),stylesheet: extendStyle,errorBuilder: (context,obj,trace){return Text(reply["content"]??"UBB解析错误");} )
            :MarkdownBlock(data: MdConverter.convertHtml(reply['content'] ?? '')),
            const SizedBox(height: 16),
            // 点赞和点踩数据
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // 点赞数
                    _buildReactionChip(
                      icon: reply["likeState"] as int==1?FluentIcons.chevron_up_12_filled:FluentIcons.chevron_up_12_regular,
                      count: reply['likeCount'] ?? 0,
                      onPressed: () => _handleLike(reply['id']),
                    ),
                    const SizedBox(width: 12),
                    // 点踩数
                    _buildReactionChip(
                      icon: reply["likeState"] as int==2?FluentIcons.chevron_down_12_regular:FluentIcons.chevron_down_12_regular,
                      count: reply['dislikeCount'] ?? 0,
                      onPressed: () => _handleDislike(reply['id']),
                    ),
                  ],
                ),
    TextButton(
      onPressed: () => _handleReplyAction("reply", reply),
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: ColorTokens.softBlue),
        ),
        padding: const EdgeInsets.all(6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(0, 0),
      ),
      child: Icon(FluentIcons.more_horizontal_16_regular, size: 16),
    )
      
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
         side: BorderSide(color: ColorTokens.softBlue),
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

  // 处理回复操作
  void _handleReplyAction(String action, dynamic reply) {
    switch (action) {
      case 'like':
        _handleLike(reply['id']);
        break;
      case 'dislike':
        _handleDislike(reply['id']);
        break;
      case 'reply':
        _showReplyDialog(reply['id'],reply['userName']??'匿名用户');
        break;
      
    }
  }

  // 处理点赞
  void _handleLike(int replyId)async {
    bool success=await RequestSender.likeReply(replyId,"1");    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success?'已点赞回复 #$replyId':'点赞失败')),
    );
    
    final newLikeStatus=await RequestSender.getLikeStatus(replyId);
    if(newLikeStatus["success"]==0){
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('获取最新点赞状态失败')),
    );
      return;
    }
    setState(() {
    final target = replies.firstWhere((e) => e['id'] == replyId);
    if(newLikeStatus["success"]==1){
      target["likeCount"]=newLikeStatus["likeCount"];
      target["dislikeCount"]=newLikeStatus["dislikeCount"];
      target["likeState"]=newLikeStatus["likeState"];
    }
});
  }

  // 处理点踩
  void _handleDislike(int replyId) async{
    bool success=await RequestSender.likeReply(replyId,"2");    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success?'已点踩回复 #$replyId':'点踩失败')),
    );
    
    final newLikeStatus=await RequestSender.getLikeStatus(replyId);
    setState(() {
    final target = replies.firstWhere((e) => e['id'] == replyId);
    if(newLikeStatus["success"]==1){
      target["likeCount"]=newLikeStatus["likeCount"];
      target["dislikeCount"]=newLikeStatus["dislikeCount"];
      target["likeState"]=newLikeStatus["likeState"];
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
              String content="$originalContent\n[align=right][size=3][color=gray]——来自「[b][color=purple]CC98 For Android[/color][/b]」[/color][/size][/align]";
              if(content.isEmpty)
              {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('回复内容不能为空')),
                );
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
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('回复已提交')),
              );
              }else{
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('回复失败:$res')),
              );
              }
              }
              Navigator.pop(context);
            }, 
          ),
    );
  }

  // 显示举报对话框
  

  // 构建加载更多指示器
  Widget _buildLoadMoreIndicator() {
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('没有更多回复了', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: _loadMoreReplies,
                child: const Text('加载更多回复'),
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
        title: const Text("帖子详情",style: TextStyle(fontSize: 16,color: ColorTokens.primaryLight),)

      ),
      body: SafeArea(child: _buildContent()),
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
                      _fetchReplies();
                    });
          } ),
        ),
      )),
    );
  }

  Widget _buildContent() {
    if (isLoading && replies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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
              onPressed: _fetchTopicData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 标题横幅
        _buildTitleBanner(),
        const SizedBox(height: 8),
        // 回复列表
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchTopicData,
            child: ListView.separated(
              separatorBuilder:(_, __)=>Divider(height: 1, thickness: 1,color: ColorTokens.dividerBlue) ,
              itemCount:totalPages>3?replies.length :replies.length+1,
              itemBuilder: (context, index) {
                if (index == replies.length&&totalPages<4) {
                  return _buildLoadMoreIndicator();
                }
                return _buildReplyItem(replies[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// 在列表页添加跳转逻辑
