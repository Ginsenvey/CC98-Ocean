import 'dart:convert';
import 'dart:io';

import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:cc98_ocean/kernel.dart';
import 'package:cc98_ocean/main.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

///
class BoardInfo {
  final int id;
  final String name;
  final String description;
  final List<String> boardMasters;
  final int topicCount;
  final int todayCount;

  BoardInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.boardMasters,
    required this.todayCount,
    required this.topicCount,
  });

  factory BoardInfo.fromJson(Map<String, dynamic> json) {
    return BoardInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json["description"] as String? ?? "暂无描述",
      todayCount: json["todayCount"] as int,
      topicCount: json["topicCount"] as int,
      boardMasters: (json["boardMasters"] as List<dynamic>).map((e)=>e as String).toList()
    );
  }
}

class Section{
  final String name;
  final int id;
  final List<BoardInfo> boards;
  Section({
    required this.boards,
    required this.id,
    required this.name,
  });

  factory Section.fromJson(Map<String,dynamic> json){
    return Section(boards: (json["boards"] as List<dynamic>).map((e)=>BoardInfo.fromJson(e as Map<String,dynamic>)).toList(), 
    id: json["id"] as int, 
    name: json["name"] as String);
  }
}

class Boards extends StatefulWidget {
  const Boards({super.key});

  @override
  State<Boards> createState() => _BoardsState();
}

class _BoardsState extends State<Boards> 
{
  bool isLoading = true;
  bool hasError = false;
  String errorMessage="";
  List<dynamic> sections=[];

  @override
  void initState() {
    super.initState();
    _fetchSecttions();
  }

  Future<void> _fetchSecttions()async{
    setState(() {
      sections.clear();
      isLoading = true;
      hasError = false;
    });

  const String url="https://api.cc98.org/Board/all";
  try{
    String res=await RequestSender.simpleRequest(url);
  if(!res.startsWith("404:")){
    final List<dynamic> data=json.decode(res);
    final List<Section> newSections=data.map((e)=>Section.fromJson(e as Map<String,dynamic>)).toList();
    setState(() {
        sections.addAll(newSections);
        isLoading = false;
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
            icon: FluentIcons.panel_left_expand_16_regular,
            onPressed: () {
              if (!kIsWeb) {
                if (Platform.isAndroid || Platform.isIOS) {
                   context.read<MyAppState>().drawerKey.currentState?.openDrawer();
                }
              }
            },
          ),
        ),
        titleSpacing: 8,
        actions: [
          FluentIconbutton(icon: FluentIcons.arrow_sync_16_regular,iconColor: ColorTokens.softPurple,),
        ],
        title: const Text("全部版面",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),)

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
              onPressed: _fetchSecttions,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 回复列表
        Expanded(
          child: ListView.builder(
            itemCount: sections.length,
            
            itemBuilder: (context, index) {
              return _buildSection(sections[index]);
  
            },
          ),
        ),
      ],
    );

    
  }
  Widget _buildSection(Section section){
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12,vertical: 8),
      elevation: 3,
      surfaceTintColor: ColorTokens.softPurple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8)),
      child: Column(
        children: [
          ListTile(
          title: Text(section.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          tileColor: ColorTokens.softBlue,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Wrap(
            alignment: WrapAlignment.start,
            runSpacing: 8,
            spacing: 6,
            children: section.boards.map((e)=>_buildBoardCard(e)).toList(),
          ),
        )
        ],
      ),
    );
  }
  Widget _buildBoardCard(BoardInfo info){
    return TextButton(onPressed: ()=>{}, 
    style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),

    child: Text(info.name));
  }
}