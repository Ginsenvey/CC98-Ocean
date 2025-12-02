import 'dart:convert';

import 'package:cc98_ocean/controls/adaptive_divider.dart';
import 'package:cc98_ocean/controls/info_indicator.dart';
import 'package:cc98_ocean/controls/status_title.dart';
import 'package:cc98_ocean/core/kernel.dart';
import 'package:cc98_ocean/pages/board.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

///
class BoardInfo {
  final int id;
  final String name;
  final String description;
  final String bigPaper;
  final List<String> boardMasters;
  final int topicCount;
  final int todayCount;

  BoardInfo({
    required this.id,
    required this.name,
    required this.description,
    this.bigPaper="",
    required this.boardMasters,
    required this.todayCount,
    required this.topicCount,
  });

  factory BoardInfo.fromJson(Map<String, dynamic> json) {
    return BoardInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json["description"] as String? ?? "暂无描述",
      bigPaper: json["bigPaper"] as String? ?? "这是一个版面~",
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
    getSections();
  }

  Future<void> getSections()async{
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
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        actions: [
          FluentIconbutton(icon: FluentIcons.arrow_sync_16_regular,iconColor: ColorTokens.softPurple,),
        ],
        title: StatusTitle(title: "全部版面",isLoading: isLoading,onTap: getSections)
      ),
      body: buildLayout(),
    );
  }
  
  Widget buildLayout(){
    if (hasError)return ErrorIndicator(icon: FluentIcons.music_note_2_16_regular, info: errorMessage,onTapped: getSections);
    return Column(
      children: [
        // 回复列表
        Expanded(
          child: ListView.builder(
            itemCount: sections.length,
            
            itemBuilder: (context, index) {
              return buildSection(sections[index]);
  
            },
          ),
        ),
      ],
    );

    
  }
  Widget buildSection(Section section){
    return Card(
      elevation: 0,
      surfaceTintColor: ColorTokens.softPurple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
        ),
        AdaptiveDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 8),
          child: Wrap(
            runAlignment: WrapAlignment.start,
            alignment: WrapAlignment.start,
            runSpacing: 8,
            spacing: 6,
            children: section.boards.map((e)=>buildBoardCard(e)).toList(),
          ),
        )
        ],
      ),
    );
  }
  Widget buildBoardCard(BoardInfo info){
    return TextButton(onPressed: ()=>{
      Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Board(boardId: info.id),
            ),
      )
    }, 
    style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: ColorTokens.dividerBlue)
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
    
    child: Text(info.name));
  }
}