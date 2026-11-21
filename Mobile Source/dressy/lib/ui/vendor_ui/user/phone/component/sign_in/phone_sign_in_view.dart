import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../config/ps_config.dart';
import '../../../../../../config/route/route_paths.dart';

import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../../core/vendor/repository/user_repository.dart';
import '../../../../../../core/vendor/utils/ps_animation.dart';
import '../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../custom_ui/user/phone/component/sign_in/widgets/back_to_login_widget.dart';
import '../../../../../custom_ui/user/phone/component/sign_in/widgets/phone_num_text_box.dart';
import '../../../../../custom_ui/user/phone/component/sign_in/widgets/phone_sign_in_button.dart';
import '../../../../../custom_ui/user/phone/component/sign_in/widgets/phone_sign_user_name_text_box.dart';
import '../../../../common/ps_header_icon_and_dynamic_text_widget.dart';

class PhoneSignInView extends StatefulWidget {
  const PhoneSignInView(
      {Key? key,
      this.animationController,
      this.goToLoginSelected,
      this.phoneSignInSelected,
      this.isSignUp = false,
      this.initialPhone})
      : super(key: key);
  final AnimationController? animationController;
  final Function? goToLoginSelected;
  final Function? phoneSignInSelected;
  final bool isSignUp;
  final String? initialPhone;
  @override
  _PhoneSignInViewState createState() => _PhoneSignInViewState();
}

class _PhoneSignInViewState extends State<PhoneSignInView>
    with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  UserRepository? repo1;
  PsValueHolder? psValueHolder;
  late AnimationController animationController;
  @override
  void initState() {
    animationController =
        AnimationController(duration: PsConfig.animation_duration, vsync: this);
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      phoneController.text = widget.initialPhone!;
    }
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = curveAnimation(animationController);

    animationController.forward();
    repo1 = Provider.of<UserRepository>(context);
    psValueHolder = Provider.of<PsValueHolder>(context);

    return SliverToBoxAdapter(
      child: ChangeNotifierProvider<UserProvider>(
        lazy: false,
        create: (BuildContext context) {
          final UserProvider provider =
              UserProvider(repo: repo1, psValueHolder: psValueHolder);
          return provider;
        },
        child: Consumer<UserProvider>(builder:
            (BuildContext context, UserProvider provider, Widget? child) {
          return Stack(
            children: <Widget>[
              SingleChildScrollView(
                  child: AnimatedBuilder(
                      animation: animationController,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            PsHeaderIconAndDynamicTextWidget(
                                text: widget.isSignUp
                                    ? 'phone_signup__title'.tr
                                    : 'login__phone_signin'.tr),
                            if (widget.isSignUp) ...<Widget>[
                              CustomPhoneSignUserNameTextBox(
                                  nameController: nameController),
                              const SizedBox(
                                height: PsDimens.space16,
                              ),
                            ],
                            CustomPhoneNumTextBox(
                                phoneController: phoneController),
                            const SizedBox(
                              height: PsDimens.space16,
                            ),
                            CustomPhoneSignInButton(
                              nameController: nameController,
                              phoneController: phoneController,
                              phoneSignInSelected: widget.phoneSignInSelected,
                              isSignUp: widget.isSignUp,
                            ),
                            const SizedBox(height: PsDimens.space16),
                            GestureDetector(
                              onTap: () {
                                if (widget.isSignUp) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    RoutePaths.user_phone_signin_container,
                                    arguments: phoneController.text.trim(),
                                  );
                                } else {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    RoutePaths.user_phone_signup_container,
                                    arguments: phoneController.text.trim(),
                                  );
                                }
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  widget.isSignUp
                                      ? 'phone_signup__already_have_account'.tr
                                      : 'phone_signin__dont_have_account'.tr,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                            CustomBackToLoginWidget(
                                goToLoginSelected: widget.goToLoginSelected),
                          ],
                        ),
                      ),
                      builder: (BuildContext context, Widget? child) {
                        return FadeTransition(
                          opacity: animation,
                          child: Transform(
                              transform: Matrix4.translationValues(
                                  0.0, 100 * (1.0 - animation.value), 0.0),
                              child: child),
                        );
                      }))
            ],
          );
        }),
      ),
    );
  }
}
