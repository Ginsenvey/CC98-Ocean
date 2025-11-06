import 'package:cc98_ocean/controls/clickarea.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/segmented.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class Mailbox extends StatefulWidget {
  const Mailbox({super.key});

  @override
  State<Mailbox> createState() => _MailboxState();
}

class _MailboxState extends State<Mailbox> {
  final List<String> names=["ts","ns","wu"];
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
            onPressed: () => {}
          ),
        ),
        
        title: const Text("消息",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: ColorTokens.primaryLight),)

      ),
      body:buildLayout() 
    );
  }
  Widget buildLayout(){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 4),
          child: SegmentedControl(items: ["回复","系统消息","@我的"], onSelected:(i)=>{}),
        ),
        Expanded(child: buildMailList())
      ],
    );
  }
  Widget buildMailList(){
    return ListView.separated(itemBuilder: (_,i)=>buildMailCard(names[i]), separatorBuilder: (_,i)=>Divider(thickness: 1,indent: 60,endIndent: 0,color: ColorTokens.dividerBlue,), itemCount: names.length);
  }
  Widget buildMailCard(String name){
    return ClickArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            SizedBox(
              height: 36,
              width: 36,
              child: ClipOval(
                child: Image.network("test",height: 36,width: 36,errorBuilder: (context, error, stackTrace) => Text("测试")), 
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: ColorTokens.primaryLight, 
                            ),),
                  SizedBox(height: 2),
                  Text("自动回复",style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),)
                      
                ],
              ),
            ),
            FluentIconbutton(icon: FluentIcons.heart_16_regular),
            SizedBox(width: 20,)
          ],
        ),
      ),
    );
  }
}