import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/helpers.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.image, required this.title, required this.subTitle, required this.onPressed});

  final String image, title, subTitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
              top: SSizes.appBarHeight*2,
              left: SSizes.defaultSpace*2,
              bottom: SSizes.defaultSpace*2,
              right: SSizes.defaultSpace*2
          ),
          child: Column(
            children: [
              Image(image: AssetImage(image), width: SHelperFunctions.screenWidth()*0.6,),
              SizedBox(height: SSizes.spaceBtwSections,),

              Text(title, style: Theme.of(context).textTheme.headlineMedium,textAlign: TextAlign.center,),
              SizedBox(height: SSizes.spaceBtwItems,),
              Text(subTitle, style: Theme.of(context).textTheme.labelMedium,textAlign: TextAlign.center,),
              SizedBox(height: SSizes.spaceBtwSections,),

              SizedBox(width: double.infinity,  child: ElevatedButton(onPressed: onPressed, child: Text(STexts.TContinue)),),
            ],
          ),
        ),
      ),
    );
  }
}
