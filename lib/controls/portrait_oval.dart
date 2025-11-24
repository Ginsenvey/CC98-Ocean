import 'package:cc98_ocean/controls/smart_image.dart';
import 'package:flutter/material.dart';

class PortraitOval extends StatelessWidget {
  final String url;
  const PortraitOval({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
              height: 36,
              width: 36,
              child: ClipOval(
                child: Image(image: SmartNetworkImage(url),height: 36,width: 36,errorBuilder: (context, error, stackTrace) => buildDefaultAvatar(url)), 
              ),
            );
  }
  Widget buildDefaultAvatar(String url){
    if(url.contains("boy")){
      return Image.asset("assets/images/default_avatar_boy.png");
    }
    else if(url.contains("girl")){
      return Image.asset("assets/images/default_avatar_girl.png");
    }
    else{
      return Image.asset("assets/images/unknown.gif");
    }
  }
}