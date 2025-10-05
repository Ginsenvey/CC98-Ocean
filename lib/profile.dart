import 'dart:io';

import 'package:cc98_ocean/Friends.dart';
import 'package:cc98_ocean/board.dart';
import 'package:cc98_ocean/controls/clickarea.dart';
import 'package:cc98_ocean/controls/expand_button.dart';
import 'package:cc98_ocean/controls/extended_tags.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/helper.dart';
import 'package:cc98_ocean/kernel.dart';
import 'package:cc98_ocean/settings.dart';
import 'package:cc98_ocean/topic.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart';
import 'dart:convert';

class Profile extends StatefulWidget {
  final int userId;
  final bool canEscape;
  const Profile({super.key, required this.userId,required this.canEscape});
  
  @override
  State<Profile> createState() => _ProfileState();
}
class _ProfileState extends State<Profile> {
  bool get wantKeepAlive => true;
  final ScrollController controller = ScrollController();
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
    ColorTag(),],
    defaultText: TextStyle(
    wordSpacing: 1.2,
    fontSize: 14,
    color: Colors.black,
    height: 1.2,
    )
    );
    
  Map<String, dynamic>? userProfile;
  // 历史发帖列表
  List<StandardPost> recentTopics = [];
  bool isLoading = true;
  bool hasError = false;
  bool isExpanded=true;
  bool hasMore = true; // 是否还有更多数据
  String errorMessage = '';
  Client client = Client();
  int currentPage = 0;
  final int pageSize = 10;
  
  @override
  void initState() {
    super.initState();
    fetchUserData();
  }
  
  // 获取用户数据
  Future<void> fetchUserData() async {

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
 
      getTopics();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }
  Future<void> getTopics() async {
    String targetUrl =widget.userId==0?'https://api.cc98.org/me/recent-topic?from=${currentPage * pageSize}&size=$pageSize':'https://api.cc98.org/user/${widget.userId}/recent-topic?from=${currentPage * pageSize}&size=$pageSize';
    // 获取历史发帖
      final topicsResponse = await client.get(targetUrl);

      if (topicsResponse.statusCode == 200) {
        final List<dynamic> newTopics = json.decode(topicsResponse.body);
        final List<StandardPost> data=newTopics.map((e)=>StandardPost.fromJson(e as Map<String,dynamic>)).toList();
        if(data.length==11){
          data.removeLast();
          // 如果有11条数据，移除最后一条
        }
        setState(() {
          recentTopics.addAll(data);
          isLoading = false;
          hasMore = newTopics.length == pageSize;
        });
        // 如果返回的数量等于pageSize，说明还有更多数据 
      } else {
        throw Exception('获取历史发帖失败: ${topicsResponse.statusCode}');
      } 
  }
  

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
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        actions: [
          FluentIconbutton(icon: FluentIcons.settings_16_regular,iconColor: ColorTokens.softPurple,onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context)=>Settings()));
          },),
        ],
        centerTitle: true,
        title: const Text("空间",style: TextStyle(fontSize: 16,color: ColorTokens.primaryLight,fontWeight: FontWeight.bold),)

      ),
      body: buildLayout(),
      
    );
  }

  Widget buildLayout() {
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
              onPressed: fetchUserData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
            buildProfile(),
            buildSignature(),
            buildHistory(),
          ],
      ),
    );
    
  }
  
  Widget buildProfile() {
    if (userProfile == null) return Container();
    var colorBase=ColorScheme.fromSeed(seedColor: ColorTokens.surfaceLight);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          // 头像和昵称
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                      spacing: 12,
                      children: [
                        Text(
                          userProfile!['name'] ?? '未知用户',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:ColorTokens.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          userProfile!['gender'] == 1 ? Icons.male : Icons.female,
                          color: userProfile!['gender'] == 1 ? Colors.blue.shade100 : Colors.pink.shade100,
                          size: 20,
                        ),
                      ],
                    ),
                    Text(userProfile!['levelTitle']??"98er",
                         style: TextStyle(
                          fontSize: 13,
                          color: ColorTokens.softPurple)
                        ),
                    // 用户ID
                    Text('ID: ${userProfile!['id']}',
                         style: TextStyle(
                          fontSize: 13,
                          color: ColorTokens.softPurple)
                        ),
                  ],
                ),
              ),
              ClickArea(
                child: Row(
                  spacing: 4,
                  children: [
                    Text("空间",style: TextStyle(fontSize: 12,color: ColorTokens.softGrey),),
                    Icon(FluentIcons.chevron_right_16_regular,size: 14,color: ColorTokens.softGrey,)
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          // 数据指标
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildStatItem('风评', userProfile!['popularity']?.toString() ?? '0'),
              SizedBox(height: 24,child: VerticalDivider(width: 16,thickness: 1,color: ColorTokens.dividerBlue,)),
              buildStatItem('动态', userProfile!['postCount']?.toString() ?? '0'),
              SizedBox(height: 24,child: VerticalDivider(width: 16,thickness: 1,color: ColorTokens.dividerBlue,)),
              ClickArea(child: buildStatItem('粉丝', userProfile!['fanCount']?.toString() ?? '0'),onTap: () {
                Navigator.push(context,MaterialPageRoute(builder: (context) => Friends()));}),
              SizedBox(height: 24,child: VerticalDivider(width: 16,thickness: 1,color: ColorTokens.dividerBlue,)),
              buildStatItem('财富', userProfile!['wealth']?.toString() ?? '0'),

            ],
          ),
        ],
      ),
    );
  }

  Widget buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: ColorTokens.primaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: ColorTokens.softGrey,
          ),
        ),
      ],
    );
  }

  Widget buildSignature() {
    if (userProfile == null) return Container();
    final signature = userProfile!['signatureCode'] ?? '';
    return Card(
      elevation: 0,
      color: ColorTokens.dividerBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8)),
      child:Padding(padding: EdgeInsetsGeometry.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExpandButton(initialExpanded: true,onExpansionChanged: (i)=>setState(() {
            isExpanded=i;
          })),
          SizedBox(width: 8),
          Expanded(
            child: isExpanded?(signature.isNotEmpty
                  ? BBCodeText(data: BBCodeConverter.convertBBCode(signature),stylesheet: extendedStyle,)
                  : const Text(
                      '该用户还没有设置签名档',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    )):const Text(
                      '签名档已折叠',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    )

          )
        ],
      ),
      )
       );
  }
  
  Widget buildHistory() {
    return Expanded(
      child: ListView.builder(
        controller: controller,
        itemCount: recentTopics.length,
        itemBuilder:(_,i)=>buildTopicCard(recentTopics[i])
         ),
    );
  }

  Widget buildTopicCard(StandardPost post){
    return Card(
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
          ],
        ),
      ),
    ),
  );
  }
  
  
}
