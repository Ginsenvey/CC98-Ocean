import 'dart:io';

import 'package:cc98_ocean/controls/extended_tags.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/helper.dart';
import 'package:cc98_ocean/kernel.dart';
import 'package:cc98_ocean/main.dart';
import 'package:cc98_ocean/topic.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart';
import 'dart:convert';

import 'package:provider/provider.dart';
class Profile extends StatefulWidget {
  final int userId;
  final bool canEscape;
  const Profile({super.key, required this.userId,required this.canEscape});
  
  @override
  State<Profile> createState() => _ProfileState();
}
class _ProfileState extends State<Profile> {
  bool get wantKeepAlive => true;
  double? _savedScrollPosition;
  final GlobalKey _scrollViewKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  //签名档特供样式
  var extendedStyle=BBStylesheet(tags: [
    HeightLimitedImgTag(),
    CenterAlignTag(),
    LeftAlignTag(),
    RightAlignTag(),
    UnderlineTag(),
    StrikeTag(),
    BoldTag(),
    ItalicTag(),
    UrlTag(),
    ColorTag(),
    ]);
    
  Map<String, dynamic>? userProfile;
  // 历史发帖列表
  List<dynamic> recentTopics = [];
  bool isLoading = true;
  bool hasError = false;
  bool hasMore = true; // 是否还有更多数据
  String errorMessage = '';
  Client client = Client();
  int currentPage = 0;
  final int pageSize = 10;
  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      _savedScrollPosition = _scrollController.position.pixels;
    }
  }
  @override
  void initState() {
    super.initState();

    _fetchUserData();
    _scrollController.addListener(_saveScrollPosition);
  }
  
  // 获取用户数据
  Future<void> _fetchUserData() async {
    _saveScrollPosition();
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // 获取用户信息
      String targetUrl =widget.userId==0?'https://api.cc98.org/me':'https://api.cc98.org/user/${widget.userId}';
      final profileResponse =await client.get(targetUrl);

      if (profileResponse.statusCode == 200) {
        userProfile = json.decode(profileResponse.body);
      } else {
        throw Exception('获取用户信息失败: ${profileResponse.statusCode}');
      }
 
      _fetchRecentTopic();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }
  Future<void> _fetchRecentTopic() async {
    String targetUrl =widget.userId==0?'https://api.cc98.org/me/recent-topic?from=${currentPage * pageSize}&size=$pageSize':'https://api.cc98.org/user/${widget.userId}/recent-topic?from=${currentPage * pageSize}&size=$pageSize';
    // 获取历史发帖
      final topicsResponse = await client.get(targetUrl);

      if (topicsResponse.statusCode == 200) {
        final List<dynamic> newTopics = json.decode(topicsResponse.body);
        if(newTopics.length==11){
          newTopics.removeLast();
          // 如果有11条数据，移除最后一条（"查看更多"）
        }
        setState(() {
          recentTopics.addAll(newTopics);
          isLoading = false;
          hasMore = newTopics.length == pageSize;
        });
        _saveScrollPosition();
        // 如果返回的数量等于pageSize，说明还有更多数据 
      } else {
        throw Exception('获取历史发帖失败: ${topicsResponse.statusCode}');
      }
      if (_savedScrollPosition != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_savedScrollPosition!);
          }
        });
      }
  }
  Future<void> _loadMoreTopics() async {
    if (!hasMore || isLoading) return;
    
    setState(() {
      currentPage++;
      isLoading = true;
    });
    
    await _fetchRecentTopic();
    _saveScrollPosition();
  }
  // 构建顶部横幅
  Widget _buildProfileBanner() {
    if (userProfile == null) return Container();
    var colorBase=ColorScheme.fromSeed(seedColor: ColorTokens.surfaceLight);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      child: Container(
        
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorTokens.softPurple),
        ),
        child: Column(
          children: [
            // 头像和昵称
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头像
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(
                    userProfile!['portraitUrl'] ?? '',
                  ),
                  backgroundColor: colorBase.surface,
                ),
                const SizedBox(width: 16),
                // 昵称和基本信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 昵称和性别
                      Row(
                        children: [
                          Text(
                            userProfile!['name'] ?? '未知用户',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:ColorTokens.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            userProfile!['gender'] == 1 ? Icons.male : Icons.female,
                            color: userProfile!['gender'] == 1 ? Colors.blue.shade100 : Colors.pink.shade100,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // 用户ID
                      Text(
                        'ID: ${userProfile!['id']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: ColorTokens.softPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 数据指标
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('风评', userProfile!['popularity']?.toString() ?? '0'),
                _buildStatItem('威望', userProfile!['prestige']?.toString() ?? '0'),
                _buildStatItem('发帖数', userProfile!['postCount']?.toString() ?? '0'),
                _buildStatItem('财富值', userProfile!['wealth']?.toString() ?? '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建数据指标项
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ColorTokens.primaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: ColorTokens.softPurple,
          ),
        ),
      ],
    );
  }

  // 构建签名档卡片
  Widget _buildSignatureCard() {
    if (userProfile == null) return Container();
    
    final signature = userProfile!['signatureCode'] ?? '';
    ColorScheme colorScheme=ColorScheme.fromSeed(seedColor: ColorTokens.softOrange,);
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title:const Text("签名档",
            style: TextStyle(fontWeight: FontWeight.bold)),
            shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        tileColor:colorScheme.primaryContainer, 
      ),
          const SizedBox(height: 12),
          signature.isNotEmpty
              ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: BBCodeText(data: BBCodeConverter.convertBBCode(signature),stylesheet: extendedStyle,),
              )
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Text(
                          '该用户还没有设置签名档',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  // 构建历史发帖项
  Widget _buildTopicItem(dynamic topic,{Key? key}) {
    return Card(
      key: ValueKey(key), 
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: 16,vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: InkWell(
        onTap: () {
          // 跳转到帖子详情
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Topic(topicId: topic['id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(0),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            topic['title'] ?? '无标题',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // 构建特殊处理的历史发帖列表
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //主区域
      appBar: AppBar(
        toolbarHeight: 48,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),       
        actionsPadding: EdgeInsets.only(right: 13),
        titleSpacing: 8,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
          child: FluentIconbutton(
            icon:widget.canEscape?FluentIcons.chevron_left_16_regular:FluentIcons.panel_left_expand_16_regular,
            onPressed: () {
              if(widget.canEscape){
                Navigator.maybePop(context);
              }else{
                if (!kIsWeb) {
                if (Platform.isAndroid || Platform.isIOS) {
                   context.read<MyAppState>().drawerKey.currentState?.openDrawer();
                }
              }
              }
              
            },
          ),
        ),
        actions: [
          FluentIconbutton(icon: FluentIcons.more_horizontal_16_regular,iconColor: ColorTokens.softPurple,),
        ],
        centerTitle: true,
        title: const Text("空间",style: TextStyle(fontSize: 16,color: ColorTokens.primaryLight,fontWeight: FontWeight.bold),)

      ),
      body: RefreshIndicator(child: _buildContent(),
      onRefresh: () async {
        currentPage = 0; // 重置页码
        recentTopics.clear(); // 清空历史发帖列表
        await _fetchUserData(); // 重新获取用户数据
      },),
      
    );
  }
  //构建信息卡片
  Widget _buildContent() {
    if (isLoading) {
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
              onPressed: _fetchUserData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    return CustomScrollView(
      key: _scrollViewKey,
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildProfileBanner()),
        SliverToBoxAdapter(child: _buildSignatureCard()),
        _buildHistorySliver()
        ]
    );
    
  }
  Widget _buildHistorySliver() {
    return SliverMainAxisGroup(slivers: [
      SliverPersistentHeader(
          pinned: true,
          delegate: _HistoryHeaderDelegate('历史发帖'),
        ),
      SliverList(delegate: SliverChildBuilderDelegate(
        (context,index)=>_buildTopicItem(recentTopics[index],key:ValueKey(recentTopics[index]['id'])),
        childCount:recentTopics.length,
      )),
      if (hasMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: _loadMoreTopics,
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('加载更多'),
              ),
            ),
          ),
        ),
    ]);
  }
  
}
class _HistoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  _HistoryHeaderDelegate(this.title);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical:0 ),
      child: ListTile(
              title: const Text(
                '历史发帖',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              tileColor: ColorTokens.softBlue,
            ),
    );
  }

  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}