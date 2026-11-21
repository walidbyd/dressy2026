import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../config/ps_colors.dart';
import '../../../../../../config/ps_config.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../../core/vendor/repository/user_repository.dart';
import '../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../core/vendor/viewobject/user.dart';
import '../../../../../config/route/route_paths.dart';
import '../../../../custom_ui/user/login/component/widgets/login_with_google_widget.dart';
import '../../../../custom_ui/user/register/component/widgets/go_to_login_text_widget.dart';

class RegisterView extends StatefulWidget {
  const RegisterView(
      {Key? key,
      this.animationController,
      this.onRegisterSelected,
      this.goToLoginSelected})
      : super(key: key);
  final AnimationController? animationController;
  final Function? onRegisterSelected, goToLoginSelected;
  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  UserRepository? repo1;
  PsValueHolder? psValueHolder;

  @override
  void initState() {
    animationController =
        AnimationController(duration: PsConfig.animation_duration, vsync: this);

    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Widget _spacingWidget = SizedBox(
      height: PsDimens.space32,
    );
    final Animation<double> animation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
            parent: animationController,
            curve: const Interval(0.5 * 1, 1.0, curve: Curves.fastOutSlowIn)));

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
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          const SizedBox(height: PsDimens.space32),
                          // Centered Dressy wordmark + tagline
                          const Text(
                            'Dressy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: Color(0xFFED7768),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'La mode seconde main en Algérie',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Utils.isLightMode(context)
                                  ? PsColors.text600
                                  : PsColors.text400,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: PsDimens.space32),

                          // Primary CTA: Phone registration button
                          Container(
                            height: 52,
                            margin: const EdgeInsets.only(
                                left: PsDimens.space16,
                                right: PsDimens.space16),
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14.0),
                                color: const Color(0xFFED7768),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: const Color(0xFFED7768).withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14.0),
                                  onTap: () async {
                                    Navigator.pushNamed(
                                      context,
                                      RoutePaths.user_phone_signup_container,
                                    );
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(Icons.phone_iphone_rounded,
                                          color: Colors.white, size: 20),
                                      SizedBox(width: PsDimens.space12),
                                      Text(
                                        "S'inscrire avec le téléphone",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: PsDimens.space12),

                          // Secondary CTA: Google Sign-In button
                          CustomLoginWithGoogleWidget(
                            onGoogleSignInSelected: widget.onRegisterSelected,
                            callBackAfterLoginSuccess:
                                callBackAfterLoginSuccess,
                          ),
                          const SizedBox(height: PsDimens.space24),

                          // Already have an account? Sign in
                          CustomGoToLoginTextWidget(
                            onSignInSelected: widget.goToLoginSelected,
                          ),
                          _spacingWidget,
                          _spacingWidget,
                        ],
                      ),
                      builder: (BuildContext context, Widget? child) {
                        return FadeTransition(
                            opacity: animation,
                            child: Transform(
                                transform: Matrix4.translationValues(
                                    0.0, 100 * (1.0 - animation.value), 0.0),
                                child: child));
                      }))
            ],
          );
        }),
      ),
    );
  }

  Future<void> callBackAfterLoginSuccess(User user) async {
    await Utils.completeAuthAndGoHome(context, user);
  }
}
