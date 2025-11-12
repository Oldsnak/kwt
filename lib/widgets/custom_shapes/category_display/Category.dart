import 'package:flutter/material.dart';
import 'package:kwt/widgets/custom_shapes/category_display/widget/decoration_circle.dart';
import '../../../app/theme/colors.dart';

class CategoryName extends StatelessWidget {
  const CategoryName({super.key,
    required this.name
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DecorationCircle(height: 2, width: 50,),
        SizedBox(width: 5,),
        DecorationCircle(height: 5, width: 5,),
        SizedBox(width: 5,),
        DecorationCircle(height: 8, width: 8,),
        SizedBox(width: 5,),
        DecorationCircle(mainBox: true,),


        Container(
          height: 40, width: 150,
          decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: SColors.primary)
          ),
          child: Center(
            child: Text(name, style: Theme.of(context).textTheme.headlineSmall!.apply(color: SColors.primary),),
          ),
        ),

        DecorationCircle(mainBox: true, reverse: true,),
        SizedBox(width: 5,),
        DecorationCircle(width: 8,height: 8,),
        SizedBox(width: 5,),
        DecorationCircle(height: 5, width: 5,),
        SizedBox(width: 5,),
        DecorationCircle(height: 2, width: 50,)
      ],
    );
  }
}
