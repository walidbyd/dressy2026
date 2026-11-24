import 'package:flutter/material.dart';

import '../../../../../../../core/vendor/viewobject/sub_category.dart';
import '../../../../../../vendor_ui/item/entry/component/entry_data/widgets/choose_subcategory_widget.dart';

class CustomChooseSubCategoryDropDownWidget extends StatelessWidget {
  const CustomChooseSubCategoryDropDownWidget(
      {required this.subCategoryController,
      required this.isMandatory,
      this.onSubCategoryChanged});
  final TextEditingController subCategoryController;
  final bool isMandatory;
  final ValueChanged<SubCategory>? onSubCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return ChooseSubCategoryDropDownWidget(
        subCategoryController: subCategoryController,
        isMandatory: isMandatory,
        onSubCategoryChanged: onSubCategoryChanged);
  }
}
