import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/controls/smart_image.dart';
import 'package:cc98_ocean/controls/status_title.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
class ImagePreview extends StatelessWidget {
  final String imageUrl;

  const ImagePreview({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: buildAppBar(context),
      body: buildLayout()
    );
  }
  PreferredSizeWidget buildAppBar(BuildContext context){
    return AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 48,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),       
        actionsPadding: EdgeInsets.only(right: 13),
        titleSpacing: 8,
        leading:Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
          child: FluentIconbutton(
            icon:FluentIcons.chevron_left_16_regular,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        actions: [
          FluentIconbutton(icon: FluentIcons.arrow_download_16_regular),
          FluentIconbutton(icon: FluentIcons.share_16_regular)
        ],
        title: StatusTitle(title: "图片预览")
      );
  }
  Widget buildLayout(){
    return Center(
        child: PhotoView(
          imageProvider: SmartNetworkImage(imageUrl), 
          minScale: PhotoViewComputedScale.contained * 0.2,
          maxScale: PhotoViewComputedScale.covered * 4,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => Center(
            child: CircularProgressIndicator(),
          ),
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text("图片已被小猫吃掉···"),
          ),
        ),
      );
  }
}