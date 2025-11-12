import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../core/constants/app_images.dart';
import '../images/t_circular_image.dart';

class UserProfileTile extends StatelessWidget {
  const UserProfileTile({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircularImage(
        applyOverlayColor: false,
        image: SImages.user,
        width: 50,
        height: 50,
        padding: 0,
      ),
      title: Text("Mudassar Naeem", style: Theme.of(context).textTheme.headlineSmall!.apply(color: SColors.white),),
      subtitle: Text("bazurgIndustries@gmail.com", style: Theme.of(context).textTheme.bodyMedium!.apply(color: SColors.white),),
      trailing: IconButton(onPressed: onPressed, icon: Icon(Icons.edit, color: SColors.white,)),
    );
  }
}
