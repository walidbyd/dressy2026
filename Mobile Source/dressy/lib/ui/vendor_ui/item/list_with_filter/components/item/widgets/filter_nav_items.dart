import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../config/ps_colors.dart';
import '../../../../../../../config/route/route_paths.dart';
import '../../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../core/vendor/provider/product/search_product_provider.dart';
import '../../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../../core/vendor/viewobject/entry_product_relation.dart';
import '../../../../../../../core/vendor/viewobject/holder/product_parameter_holder.dart';
import '../../../../../../custom_ui/item/list_with_filter/components/item/widgets/category_icon.dart';
import '../../../../../../custom_ui/item/list_with_filter/components/item/widgets/filter_icon.dart';
import '../../../../../../custom_ui/item/list_with_filter/components/item/widgets/filter_item_type.dart';
import '../../../../../../custom_ui/item/list_with_filter/components/item/widgets/map_icon.dart';

class FilterNavItems extends StatefulWidget {
  const FilterNavItems(
      {this.changeAppBarTitle, required this.onSubCategorySelected});

  final Function? changeAppBarTitle;
  final Function(String?)? onSubCategorySelected;

  @override
  State<FilterNavItems> createState() => _FilterNavItemsState();
}

class _FilterNavItemsState extends State<FilterNavItems> {
  String? _selectedCategoryName;
  String? _selectedSize;
  String? _selectedBrand;

  @override
  Widget build(BuildContext context) {
    final SearchProductProvider searchProductProvider =
        Provider.of<SearchProductProvider>(context);

    final bool hasCategoryFilter =
        searchProductProvider.productParameterHolder.catId != null &&
            searchProductProvider.productParameterHolder.catId != '';
    final bool hasSizeFilter = _selectedSize != null && _selectedSize!.isNotEmpty;
    final bool hasBrandFilter = _selectedBrand != null && _selectedBrand!.isNotEmpty;
    final bool hasPriceFilter =
        (searchProductProvider.productParameterHolder.minPrice != null &&
                searchProductProvider.productParameterHolder.minPrice != '') ||
            (searchProductProvider.productParameterHolder.maxPrice != null &&
                searchProductProvider.productParameterHolder.maxPrice != '') ||
            searchProductProvider.productParameterHolder.orderBy ==
                PsConst.FILTERING_PRICE;

    return Container(
      color: Utils.isLightMode(context)
          ? PsColors.backgroundColor
          : PsColors.achromatic900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Section Title: Bold "All Items"
          Padding(
            padding: const EdgeInsets.only(
              left: PsDimens.space16,
              right: PsDimens.space16,
              top: PsDimens.space12,
              bottom: PsDimens.space8,
            ),
            child: Text(
              'dashboard__all_items'.tr.isNotEmpty &&
                      'dashboard__all_items'.tr != 'dashboard__all_items'
                  ? 'dashboard__all_items'.tr
                  : 'Tous les articles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Utils.isLightMode(context)
                        ? PsColors.text900
                        : PsColors.text50,
                  ),
            ),
          ),
          // Horizontal Pill Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(
              left: PsDimens.space16,
              right: PsDimens.space16,
              bottom: PsDimens.space10,
            ),
            child: Row(
              children: <Widget>[
                // 1. Categories Pill
                _buildFilterPill(
                  context: context,
                  isActive: hasCategoryFilter,
                  icon: Icons.category_outlined,
                  label: hasCategoryFilter && _selectedCategoryName != null
                      ? _selectedCategoryName!
                      : ('search__category'.tr.isNotEmpty &&
                              'search__category'.tr != 'search__category'
                          ? 'search__category'.tr
                          : 'Catégories'),
                  onTap: () async {
                    final Map<String, String?> dataHolder =
                        <String, String?>{};
                    dataHolder[PsConst.CATEGORY_ID] =
                        searchProductProvider.productParameterHolder.catId;
                    dataHolder[PsConst.SUB_CATEGORY_ID] =
                        searchProductProvider.productParameterHolder.subCatId;
                    final dynamic result = await Navigator.pushNamed(
                        context, RoutePaths.categoryFilterList,
                        arguments: dataHolder);

                    if (result != null && result is Map<String, String?>) {
                      setState(() {
                        _selectedCategoryName = result[PsConst.CATEGORY_NAME];
                        _selectedSize = null;
                      });
                      searchProductProvider.productParameterHolder.catId =
                          result[PsConst.CATEGORY_ID];
                      searchProductProvider.productParameterHolder.subCatId =
                          result[PsConst.SUB_CATEGORY_ID];
                      if (widget.onSubCategorySelected != null) {
                        widget.onSubCategorySelected!(
                            result[PsConst.CATEGORY_NAME]);
                      }
                      searchProductProvider
                              .productParameterHolder.productRelation =
                          <EntryProductRelation>[];
                      searchProductProvider.loadDataList(reset: true);
                    }
                  },
                  onClear: hasCategoryFilter
                      ? () {
                          setState(() {
                            _selectedCategoryName = null;
                            _selectedSize = null;
                          });
                          searchProductProvider.productParameterHolder.catId =
                              '';
                          searchProductProvider
                              .productParameterHolder.subCatId = '';
                          searchProductProvider
                                  .productParameterHolder.productRelation =
                              <EntryProductRelation>[];
                          searchProductProvider.loadDataList(reset: true);
                        }
                      : null,
                ),
                const SizedBox(width: 8),

                // 2. Size / Pointure Pill
                _buildFilterPill(
                  context: context,
                  isActive: hasSizeFilter,
                  icon: Icons.straighten_outlined,
                  label: hasSizeFilter
                      ? _selectedSize!
                      : ('filter__size'.tr.isNotEmpty &&
                              'filter__size'.tr != 'filter__size'
                          ? 'filter__size'.tr
                          : 'Taille'),
                  onTap: () {
                    _showSizeBottomSheet(context, searchProductProvider);
                  },
                  onClear: hasSizeFilter
                      ? () {
                          setState(() {
                            _selectedSize = null;
                          });
                          _applyFilters(searchProductProvider);
                        }
                      : null,
                ),
                const SizedBox(width: 8),

                // 3. Brand Pill (Position 3, right after Size)
                _buildFilterPill(
                  context: context,
                  isActive: hasBrandFilter,
                  icon: Icons.sell_outlined,
                  label: hasBrandFilter
                      ? _selectedBrand!
                      : ('filter__brand'.tr.isNotEmpty &&
                              'filter__brand'.tr != 'filter__brand'
                          ? 'filter__brand'.tr
                          : 'Marque'),
                  onTap: () {
                    _showBrandBottomSheet(context, searchProductProvider);
                  },
                  onClear: hasBrandFilter
                      ? () {
                          setState(() {
                            _selectedBrand = null;
                          });
                          _applyFilters(searchProductProvider);
                        }
                      : null,
                ),
                const SizedBox(width: 8),

                // 4. Price Pill
                _buildFilterPill(
                  context: context,
                  isActive: hasPriceFilter,
                  icon: Icons.tune,
                  label: 'filter__price'.tr.isNotEmpty &&
                          'filter__price'.tr != 'filter__price'
                      ? 'filter__price'.tr
                      : 'Prix',
                  onTap: () {
                    _showPriceBottomSheet(context, searchProductProvider);
                  },
                  onClear: hasPriceFilter
                      ? () {
                          searchProductProvider
                              .productParameterHolder.minPrice = '';
                          searchProductProvider
                              .productParameterHolder.maxPrice = '';
                          searchProductProvider
                              .productParameterHolder.orderBy =
                              PsConst.FILTERING__ADDED_DATE;
                          searchProductProvider
                              .productParameterHolder.orderType =
                              PsConst.FILTERING__DESC;
                          searchProductProvider.loadDataList(reset: true);
                          setState(() {});
                        }
                      : null,
                ),
                const SizedBox(width: 8),

                // 4. All Filters Pill
                _buildFilterPill(
                  context: context,
                  isActive: false,
                  icon: Icons.filter_list_rounded,
                  label: 'search__filter'.tr.isNotEmpty &&
                          'search__filter'.tr != 'search__filter'
                      ? 'search__filter'.tr
                      : 'Filtres',
                  onTap: () async {
                    final dynamic result = await Navigator.pushNamed(
                        context, RoutePaths.itemSearch,
                        arguments:
                            searchProductProvider.productParameterHolder);
                    if (result != null && result is ProductParameterHolder) {
                      searchProductProvider.productParameterHolder = result;
                      searchProductProvider.loadDataList(reset: true);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
          // Hidden underlying widgets
          Visibility(
            visible: false,
            maintainState: true,
            child: Row(
              children: <Widget>[
                const CustomFilterProductItemTypeWidget(),
                CustomCategoryIconWidget(
                  onSubCategorySelected: widget.onSubCategorySelected,
                ),
                const CustomFilterIconWidget(),
                const CustomMapIconWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required BuildContext context,
    required bool isActive,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final bool isLight = Utils.isLightMode(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? (isLight
                  ? PsColors.burgundy.withValues(alpha: 0.1)
                  : PsColors.burgundy.withValues(alpha: 0.3))
              : (isLight ? Colors.white : PsColors.achromatic800),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? PsColors.burgundy
                : (isLight ? PsColors.cardBorderColor : PsColors.achromatic700),
            width: isActive ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 15,
              color: isActive
                  ? PsColors.burgundy
                  : (isLight ? PsColors.text700 : PsColors.text200),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? PsColors.burgundy
                    : (isLight ? PsColors.text800 : PsColors.text100),
              ),
            ),
            if (isActive && onClear != null) ...<Widget>[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: PsColors.burgundy,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSizeBottomSheet(
      BuildContext context, SearchProductProvider searchProductProvider) {
    final List<String> clothingSizes = <String>[
      'XS',
      'S',
      'M',
      'L',
      'XL',
      'XXL',
      'Standard'
    ];
    final List<String> shoeSizes = <String>[
      '35',
      '36',
      '37',
      '38',
      '39',
      '40',
      '41',
      '42',
      '43'
    ];
    final List<String> babySizes = <String>[
      '0-3M',
      '3-6M',
      '6-12M',
      '12-18M',
      '18-24M',
      '2-3Y',
      '3-4Y'
    ];
    final List<String> babyShoeSizes = <String>[
      '16',
      '17',
      '18',
      '19',
      '20',
      '21',
      '22',
      '23',
      '24'
    ];

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'filter__size'.tr.isNotEmpty &&
                              'filter__size'.tr != 'filter__size'
                          ? 'filter__size'.tr
                          : 'Choisir une taille',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedSize != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedSize = null;
                          });
                          searchProductProvider
                                  .productParameterHolder.productRelation =
                              <EntryProductRelation>[];
                          searchProductProvider.loadDataList(reset: true);
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'dialog__clear'.tr.isNotEmpty &&
                                  'dialog__clear'.tr != 'dialog__clear'
                              ? 'dialog__clear'.tr
                              : 'Effacer',
                          style: const TextStyle(color: PsColors.burgundy),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Vêtements Femme',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: clothingSizes.map((String size) {
                    final bool isSel = _selectedSize == size;
                    return _buildChip(size, isSel, () {
                      _selectSize(size, searchProductProvider, ctx);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chaussures Femme',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: shoeSizes.map((String size) {
                    final bool isSel = _selectedSize == size;
                    return _buildChip(size, isSel, () {
                      _selectSize(size, searchProductProvider, ctx);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bébé & Enfant',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <String>[...babySizes, ...babyShoeSizes].map((String size) {
                    final bool isSel = _selectedSize == size;
                    return _buildChip(size, isSel, () {
                      _selectSize(size, searchProductProvider, ctx);
                    });
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? PsColors.burgundy : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? PsColors.burgundy : const Color(0xFFD1D5DB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  void _applyFilters(SearchProductProvider searchProductProvider) {
    final List<EntryProductRelation> relations = <EntryProductRelation>[];
    if (_selectedSize != null && _selectedSize!.isNotEmpty) {
      relations.add(EntryProductRelation(coreKeyId: 'itm00037', value: _selectedSize!));
    }
    if (_selectedBrand != null && _selectedBrand!.isNotEmpty) {
      relations.add(EntryProductRelation(coreKeyId: 'ps-itm00001', value: _selectedBrand!));
    }
    searchProductProvider.productParameterHolder.productRelation = relations;
    searchProductProvider.loadDataList(reset: true);
  }

  void _selectSize(String size, SearchProductProvider searchProductProvider,
      BuildContext ctx) {
    setState(() {
      _selectedSize = size;
    });
    _applyFilters(searchProductProvider);
    Navigator.pop(ctx);
  }

  void _selectBrand(String brand, SearchProductProvider searchProductProvider,
      BuildContext ctx) {
    setState(() {
      _selectedBrand = brand;
    });
    _applyFilters(searchProductProvider);
    Navigator.pop(ctx);
  }

  void _showBrandBottomSheet(
      BuildContext context, SearchProductProvider searchProductProvider) {
    final List<String> popularBrands = <String>[
      'Zara',
      'Mango',
      'Bershka',
      'Stradivarius',
      'Pull&Bear',
      'H&M',
      'Shein',
      'Nike',
      'Adidas',
      'Puma',
      'Massimo Dutti',
      'Jennyfer',
      'Pimkie',
      'Lefties',
      'Celio',
      'Ralph Lauren',
      'Tommy Hilfiger',
      'Guess',
      'Lacoste',
      'Levi\'s',
      'Calvin Klein',
      'Koton',
      'Parfois',
      'Oysho',
      'Converse',
      'New Balance',
      'Vans',
    ];

    final TextEditingController searchController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext sheetContext, StateSetter setSheetState) {
            final String query = searchController.text.trim().toLowerCase();
            final List<String> filteredBrands = popularBrands
                .where((String b) => b.toLowerCase().contains(query))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.75,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'filter__brand'.tr.isNotEmpty &&
                                  'filter__brand'.tr != 'filter__brand'
                              ? 'filter__brand'.tr
                              : 'Choisir une marque',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedBrand != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedBrand = null;
                              });
                              _applyFilters(searchProductProvider);
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              'dialog__clear'.tr.isNotEmpty &&
                                      'dialog__clear'.tr != 'dialog__clear'
                                  ? 'dialog__clear'.tr
                                  : 'Effacer',
                              style: const TextStyle(color: PsColors.burgundy),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'brand_search_hint'.tr.isNotEmpty &&
                                'brand_search_hint'.tr != 'brand_search_hint'
                            ? 'brand_search_hint'.tr
                            : 'Rechercher ou entrer une marque...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  setSheetState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Utils.isLightMode(context)
                                ? const Color(0xFFE5E7EB)
                                : PsColors.achromatic700,
                          ),
                        ),
                        filled: true,
                        fillColor: Utils.isLightMode(context)
                            ? const Color(0xFFF9FAFB)
                            : PsColors.achromatic800,
                      ),
                      onChanged: (String val) {
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    if (searchController.text.trim().isNotEmpty &&
                        !popularBrands.any((String b) =>
                            b.toLowerCase() ==
                            searchController.text.trim().toLowerCase())) ...<Widget>[
                      InkWell(
                        onTap: () {
                          _selectBrand(searchController.text.trim(),
                              searchProductProvider, ctx);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFED7768).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFED7768)),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.add_circle_outline,
                                  color: Color(0xFFED7768), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Filtrer par : "${searchController.text.trim()}"',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFED7768),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: filteredBrands.map((String brand) {
                            final bool isSel = _selectedBrand == brand;
                            return _buildChip(brand, isSel, () {
                              _selectBrand(brand, searchProductProvider, ctx);
                            });
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPriceBottomSheet(
      BuildContext context, SearchProductProvider searchProductProvider) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Trier et Filtrer par Prix',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: PsColors.burgundy),
                title: const Text('Prix : Ordre croissant'),
                onTap: () {
                  searchProductProvider.productParameterHolder.orderBy =
                      PsConst.FILTERING_PRICE;
                  searchProductProvider.productParameterHolder.orderType =
                      PsConst.FILTERING__ASC;
                  searchProductProvider.loadDataList(reset: true);
                  setState(() {});
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.arrow_downward, color: PsColors.burgundy),
                title: const Text('Prix : Ordre décroissant'),
                onTap: () {
                  searchProductProvider.productParameterHolder.orderBy =
                      PsConst.FILTERING_PRICE;
                  searchProductProvider.productParameterHolder.orderType =
                      PsConst.FILTERING__DESC;
                  searchProductProvider.loadDataList(reset: true);
                  setState(() {});
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule, color: PsColors.burgundy),
                title: const Text('Les plus récents'),
                onTap: () {
                  searchProductProvider.productParameterHolder.orderBy =
                      PsConst.FILTERING__ADDED_DATE;
                  searchProductProvider.productParameterHolder.orderType =
                      PsConst.FILTERING__DESC;
                  searchProductProvider.loadDataList(reset: true);
                  setState(() {});
                  Navigator.pop(ctx);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.grey),
                title: const Text('Réinitialiser le prix'),
                onTap: () {
                  searchProductProvider.productParameterHolder.minPrice = '';
                  searchProductProvider.productParameterHolder.maxPrice = '';
                  searchProductProvider.productParameterHolder.orderBy =
                      PsConst.FILTERING__ADDED_DATE;
                  searchProductProvider.productParameterHolder.orderType =
                      PsConst.FILTERING__DESC;
                  searchProductProvider.loadDataList(reset: true);
                  setState(() {});
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
