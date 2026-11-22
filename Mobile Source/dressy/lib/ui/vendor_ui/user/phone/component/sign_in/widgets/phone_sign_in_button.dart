import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../config/route/route_paths.dart';
import '../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../../../core/vendor/utils/ps_progress_dialog.dart';
import '../../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../../core/vendor/viewobject/holder/intent_holder/verify_phone_internt_holder.dart';
import '../../../../../common/dialog/confirm_dialog_view.dart';
import '../../../../../common/dialog/error_dialog.dart';
import '../../../../../common/dialog/warning_dialog_view.dart';
import '../../../../../common/ps_button_widget.dart';

class PhoneSignInButton extends StatefulWidget {
  const PhoneSignInButton(
      {required this.nameController,
      required this.phoneController,
      required this.phoneSignInSelected,
      this.isSignUp = false});
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final Function? phoneSignInSelected;
  final bool isSignUp;

  @override
  __SendButtonWidgetState createState() => __SendButtonWidgetState();
}

class __SendButtonWidgetState extends State<PhoneSignInButton> {
  UserProvider? provider;
  PsValueHolder? psValueHolder;

  Future<String?> verifyPhone() async {
    String? verificationId;
    final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId)async {
      verificationId = verId;
     await PsProgressDialog.dismissDialog();
    };
    final PhoneCodeSent smsCodeSent = (String verId, [int? forceCodeResend]) async{
      verificationId = verId;
     await PsProgressDialog.dismissDialog();
      print('code has been send');

      final String userNameToPass =
          widget.isSignUp ? widget.nameController.text.trim() : '';
      String purePhone = widget.phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      if (purePhone.startsWith('0')) {
        purePhone = purePhone.substring(1);
      }

      if (widget.phoneSignInSelected != null) {
        widget.phoneSignInSelected!(
            userNameToPass,
            provider!.selectedCountryCode + '-' + purePhone,
            verificationId);
      } else {
        Navigator.pushReplacementNamed(
            context, RoutePaths.user_phone_verify_container,
            arguments: VerifyPhoneIntentHolder(
                userName: userNameToPass,
                phoneNumber: provider!.selectedCountryCode +
                    '-' +
                    purePhone,
                phoneId: verificationId));
      }
    };
    final PhoneVerificationCompleted verifySuccess = (AuthCredential user) async{
      print('verify');
     await PsProgressDialog.dismissDialog();
    };
    final PhoneVerificationFailed verifyFail =
        (FirebaseAuthException exception)async{
      print('${exception.message}');
     await PsProgressDialog.dismissDialog();
      showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(
              message: '${exception.message}',
            );
          });
    };
    String sendPhone = widget.phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (sendPhone.startsWith('0')) {
      sendPhone = sendPhone.substring(1);
    }
    await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+213' + sendPhone,
        codeAutoRetrievalTimeout: autoRetrieve,
        codeSent: smsCodeSent,
        timeout: const Duration(minutes: 2),
        verificationCompleted: verifySuccess,
        verificationFailed: verifyFail);
    print('phone no ::: ' +
        provider!.selectedCountryCode +
        widget.phoneController.text);
    return verificationId;
  }

  dynamic callWarningDialog(BuildContext context, String text) {
    showDialog<dynamic>(
        context: context,
        builder: (BuildContext context) {
          return WarningDialog(
            message: text.tr,
            onPressed: () {},
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<UserProvider>(context);
    psValueHolder = Provider.of<PsValueHolder>(context);

    return Container(
      height: 40,
      child: PSButtonWidget(
          colorData: Theme.of(context).primaryColor,
          hasShadow: false,
          width: double.infinity,
          titleText: widget.isSignUp
              ? 'phone_signup__submit'.tr
              : 'login__submit'.tr,
          onPressed: () {
            showDialog<dynamic>(
                context: context,
                builder: (BuildContext context) {
                  return ConfirmDialogView(
                      title: 'Confirmation'.tr,
                      description: 'phone_signin_confirmation'.tr,
                      leftButtonText: 'dialog__cancel'.tr,
                      rightButtonText: 'logout_dialog__confirm'.tr,
                      onAgreeTap: () async {
                        Navigator.pop(context);
                        final String purePhone =
                            widget.phoneController.text.trim();
                        final String trimmedName =
                            widget.nameController.text.trim();

                        if (widget.isSignUp && trimmedName.isEmpty) {
                          callWarningDialog(
                              context, 'warning_dialog__input_name'.tr);
                          return;
                        }

                        if (purePhone.isEmpty) {
                          callWarningDialog(
                              context, 'warning_dialog__input_phone'.tr);
                          return;
                        }

                        String digitsOnly =
                            purePhone.replaceAll(RegExp(r'\D'), '');
                        if (digitsOnly.startsWith('0')) {
                          digitsOnly = digitsOnly.substring(1);
                        }
                        if (digitsOnly.length != 9 || !RegExp(r'^[567]\d{8}$').hasMatch(digitsOnly)) {
                          callWarningDialog(
                              context, 'phone_number_algeria_invalid'.tr);
                          return;
                        }

                        await PsProgressDialog.showDialog(context);

                        final String fullFormattedPhone =
                            provider!.selectedCountryCode + '-' + digitsOnly;
                        final Map<String, dynamic> checkMap =
                            <String, dynamic>{
                          'loginMethod': 'phone',
                          'user_phone': fullFormattedPhone,
                        };
                        try {
                          final dynamic checkResult =
                              await provider!.checkUserNameExists(checkMap);
                          final String? isExisted =
                              checkResult?.data?.message?.isUserNameExisted;

                          if (widget.isSignUp) {
                            if (isExisted == '1') {
                              if (PsProgressDialog.isShowing()) {
                                await PsProgressDialog.dismissDialog();
                              }
                              showDialog<dynamic>(
                                context: context,
                                builder: (BuildContext dContext) {
                                  return WarningDialog(
                                    message:
                                        'phone_signup__already_registered'.tr,
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        RoutePaths.user_phone_signin_container,
                                      );
                                    },
                                  );
                                },
                              );
                              return;
                            }
                          } else {
                            if (isExisted != '1') {
                              if (PsProgressDialog.isShowing()) {
                                await PsProgressDialog.dismissDialog();
                              }
                              showDialog<dynamic>(
                                context: context,
                                builder: (BuildContext dContext) {
                                  return WarningDialog(
                                    message: 'phone_signin__not_found'.tr,
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        RoutePaths.user_phone_signup_container,
                                        arguments: purePhone,
                                      );
                                    },
                                  );
                                },
                              );
                              return;
                            }
                          }
                        } catch (_) {}

                        await verifyPhone();
                      });
                });
          }),
    );
  }
}
