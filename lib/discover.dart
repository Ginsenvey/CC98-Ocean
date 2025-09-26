import 'dart:io';

import 'package:cc98_ocean/controls/clickarea.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/kernel.dart';
import 'package:cc98_ocean/topic.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';


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
  RequestSender r=RequestSender();
  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  // 模拟从API获取帖子数据
  Future<void> _fetchPosts() async {
    setState(() {
      posts.clear();
      isLoading = true;
      hasError = false;
    });

    try {
      String response=await r.getNewTopic(currentPage, pageSize);
      if(!response.startsWith("404:")){
        final List<dynamic> _data = json.decode(response);
        final List<String> userIds = _data.map((e) => e['userId'].toString()).toSet().toList();
        final portraitMap=Deserializer.parseUserPortrait(await RequestSender().getUserPortrait(userIds));
        final data=_data.map((e){
          e['portraitUrl'] = portraitMap[e['userId'].toString()]??"";
          return e;
        });
      setState(() {
        posts.addAll(data);
        isLoading = false;
      });
      }
      

      
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = '加载失败: ${e.toString()}';
      });
    }
  }
  Future<void> _loadPrePage() async {
    if (isLoading) return;
    
    setState(() {
      if (currentPage <= 0){
        //提醒用户页码不能小于0
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已加载最新主题'),
            duration: Duration(seconds: 2),
          ),
        );
        currentPage = 0;
        return;
      } // 防止页码小于0
      currentPage--;
      posts.clear(); // 清空当前列表
      isLoading = true;
    });
    
    await _fetchPosts();
  }
  Future<void> _loadNextPage() async {
    if (isLoading) return;
    
    setState(() {
      currentPage++;
      isLoading = true;
    });
    
    await _fetchPosts();
  }

  // 处理收藏操作
  void _toggleFavorite(int postId) {
    setState(() {
      final postIndex = posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        posts[postIndex].isFavorited = !posts[postIndex].isFavorited;
      }
    });
    
    // 这里可以添加实际的API调用
    // _apiClient.post('/posts/$postId/favorite', body: {'favorite': posts[postIndex].isFavorited});
  }

  // 构建帖子列表项
Widget _buildPostItem(dynamic post) {
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
                Row(
                  spacing: 4,
                  children: [
                    FluentIconbutton(icon: FluentIcons.chat_16_regular,iconColor: colorScheme.primary),
                    Text(post["replyCount"].toString(),style: TextStyle(color: ColorTokens.softPurple),)
                  ],
                ),
                Row(
                  children: [
                    FluentIconbutton(icon: FluentIcons.chevron_up_16_regular,iconColor: colorScheme.primary),
                    Text(post["likeCount"].toString(),style: TextStyle(color: ColorTokens.softPurple),)
                  ],
                )           
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildTipIndicator() {
    return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('小水怡情,注意休息哦~', style: TextStyle(color: Colors.grey)),
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
        actionsPadding: EdgeInsets.only(right: 13),
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
          child: FluentIconbutton(icon: FluentIcons.chevron_left_16_regular,iconColor: ColorTokens.softPurple,onPressed: () =>_loadPrePage() ,),
        ),
        centerTitle: true,
        actions: [
          FluentIconbutton(icon: FluentIcons.chevron_right_16_regular,iconColor: ColorTokens.softPurple,onPressed: ()=>_loadNextPage(),),
        ],
        title: const Text("发现",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: ColorTokens.primaryLight),)

      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
              onPressed: _fetchPosts,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: posts.length + 1,
            separatorBuilder: (_, __) {
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
            },
            itemBuilder: (context, index) {
              if (index == posts.length) {
                return _buildTipIndicator();
              }
              return _buildPostItem(posts[index]);
            },
          ),
        ),
      ],
    );

    
  }
}