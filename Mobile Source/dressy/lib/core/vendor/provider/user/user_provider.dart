import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../config/route/route_paths.dart';
import '../../../../core/vendor/provider/common/ps_init_provider.dart';
import '../../../../ui/vendor_ui/common/dialog/email_sent_warning_dialog.dart';
import '../../../../ui/vendor_ui/common/dialog/error_dialog.dart';
import '../../../../ui/vendor_ui/common/dialog/warning_dialog_view.dart';
import '../../../vendor/provider/language/app_localization_provider.dart';
import '../../api/common/ps_resource.dart';
import '../../api/common/ps_status.dart';
import '../../constant/ps_constants.dart';
import '../../repository/user_repository.dart';
import '../../utils/ps_progress_dialog.dart';
import '../../utils/utils.dart';
import '../../viewobject/api_status.dart';
import '../../viewobject/common/ps_value_holder.dart';
import '../../viewobject/edit_profile_user_relation.dart';
import '../../viewobject/holder/apple_login_parameter_holder.dart';
import '../../viewobject/holder/facebook_login_user_holder.dart';
import '../../viewobject/holder/fb_login_parameter_holder.dart';
import '../../viewobject/holder/google_login_parameter_holder.dart';
import '../../viewobject/holder/resend_code_again_parameter_holder.dart';
import '../../viewobject/holder/user_login_parameter_holder.dart';
import '../../viewobject/holder/user_name_status_parameter_holder.dart';
import '../../viewobject/holder/user_parameter_holder.dart';
import '../../viewobject/holder/user_register_parameter_holder.dart';
import '../../viewobject/shipping_city.dart';
import '../../viewobject/shipping_country.dart';
import '../../viewobject/user.dart';
import '../../viewobject/user_name_status.dart';
import '../common/ps_provider.dart';

class UserProvider extends PsProvider<User> {
  UserProvider({
    required UserRepository? repo,
    required PsValueHolder? psValueHolder,
    int limit = 0,
  }) : super(repo, limit,
            subscriptionType: PsConst.SINGLE_OBJECT_SUBSCRIPTION) {
    _repo = repo;
    super.psValueHolder = psValueHolder;
  }

  UserRepository? _repo;
  User? holderUser;
  ShippingCountry? selectedCountry;
  ShippingCity? selectedCity;
  bool isCheckBoxSelect = true;
  bool isRememberMeChecked = false;
  String selectedCountryCode = '';
  String selectedCountryName = '';
  UserParameterHolder userParameterHolder =
      UserParameterHolder().getOtherUserData();

  PsResource<User> get user => super.data;

  PsResource<ApiStatus> _apiStatus =
      PsResource<ApiStatus>(PsStatus.NOACTION, '', null);
  PsResource<ApiStatus> get apiStatus => _apiStatus;
  List<EditProfileUserRelation> userRelationList = <EditProfileUserRelation>[];
  StreamController<PsResource<User>>? userListStream;
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  
  static Future<void>? _googleInitFuture;
  static Future<void> ensureGoogleSignInInitialized() {
    return _googleInitFuture ??=
        GoogleSignIn.instance.initialize().catchError((Object e) {
      _googleInitFuture = null;
      throw e;
    });
  }

  // Register
  Future<dynamic> postUserRegister(
      Map<dynamic, dynamic> jsonMap, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    return await _repo!.postUserRegister(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, psValueHolder!.headerToken!, languageCode);
  }

  // Login
  Future<dynamic> postUserLogin(
      Map<dynamic, dynamic> jsonMap, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    return await _repo!.postUserLogin(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, psValueHolder!.headerToken!, languageCode);
  }

  // Check User Name Exists
  Future<dynamic> checkUserNameExists(Map<dynamic, dynamic> jsonMap) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    return await _repo!
        .checkUserNameExists(jsonMap, psValueHolder!.headerToken!);
  }

  // Set UserName and Password
  Future<dynamic> setUserNameAndPassword(
      Map<dynamic, dynamic> jsonMap, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    return await _repo!.setUserNameAndPassword(jsonMap, languageCode);
  }

  // Facebook Login
  Future<dynamic> postFBLogin(
      Map<dynamic, dynamic> jsonMap, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    return await _repo!.postFBLogin(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, psValueHolder!.headerToken!, languageCode);
  }

  // Apple Login
  Future<dynamic> postAppleLogin(
      Map<dynamic, dynamic> jsonMap, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    return await _repo!.postAppleLogin(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, psValueHolder!.headerToken!, languageCode);
  }

  // Google Login
  Future<dynamic> postGoogleLogin(
      Map<dynamic, dynamic> jsonMap, String languageCode) async {
        
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    return await _repo!.postGoogleLogin(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, psValueHolder!.headerToken!, languageCode);
  }

  // Phone Login
  Future<dynamic> postPhoneLogin(
    Map<dynamic, dynamic> jsonMap,
    String languageCode,
  ) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    return await _repo!.postPhoneLogin(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, psValueHolder!.headerToken!, languageCode);
  }

  // Log Out
  Future<dynamic> userLogout(
      Map<dynamic, dynamic> jsonMap, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    _apiStatus = await _repo!.userLogout(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, psValueHolder!.headerToken!, languageCode);

    return _apiStatus;
  }

  Future<dynamic> postUserEmailVerify(
      Map<dynamic, dynamic> jsonMap, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    return await _repo!.postUserEmailVerify(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, languageCode);
  }

  Future<dynamic> postForgotPasswordVerify(
      Map<dynamic, dynamic> jsonMap, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    return await _repo!.postForgotPasswordVerify(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, languageCode);
  }

  Future<dynamic> postImageUpload(String userId, String platformName,
      File? imageFile, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    final dynamic resource = await _repo!.postUserImageUpload(
        userId,
        psValueHolder!.headerToken!,
        platformName,
        imageFile!,
        isConnectedToInternet,
        PsStatus.PROGRESS_LOADING,
        languageCode);

    isLoading = false;
    if (resource is PsResource<User> && resource.status == PsStatus.SUCCESS && resource.data != null) {
      user.data = resource.data;
      super.data = resource;
      dataStreamController?.add(resource);
      notifyListeners();
    }

    return resource;
  }

  Future<dynamic> postForgotPassword(
      Map<dynamic, dynamic> jsonMap, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    _apiStatus = await _repo!.postForgotPassword(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, languageCode);

    return _apiStatus;
  }

  Future<dynamic> postChangePassword(Map<dynamic, dynamic> jsonMap,
      String loginUserId, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    _apiStatus = await _repo!.postChangePassword(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, loginUserId, languageCode);

    return _apiStatus;
  }

  Future<dynamic> postUpdateForgotPassword(Map<dynamic, dynamic> jsonMap,
      String loginUserId, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    _apiStatus = await _repo!.postUpdateForgotPassword(
        jsonMap,
        isConnectedToInternet,
        PsStatus.PROGRESS_LOADING,
        loginUserId,
        languageCode);

    return _apiStatus;
  }

  Future<dynamic> postProfileUpdate(Map<dynamic, dynamic> jsonMap,
      String loginUserId, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    final PsResource<User> resource = await _repo!.postProfileUpdate(
        jsonMap,
        loginUserId,
        psValueHolder!.headerToken!,
        isConnectedToInternet,
        PsStatus.SUCCESS,
        languageCode);

    if (resource.status == PsStatus.SUCCESS && resource.data != null) {
      super.data = resource;
      dataStreamController?.add(resource);
      if (resource.data!.userName != null && resource.data!.userName!.isNotEmpty) {
        await replaceLoginUserName(resource.data!.userName!);
        if (psValueHolder != null) {
          psValueHolder!.loginUserName = resource.data!.userName;
        }
      }
      notifyListeners();
    }

    return resource;
  }

  Future<dynamic> postUserFollow(
    Map<dynamic, dynamic> jsonMap,
    String loginUserId,
    String languageCode,
  ) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    return await _repo!.postUserFollow(
        jsonMap,
        isConnectedToInternet,
        PsStatus.PROGRESS_LOADING,
        loginUserId,
        psValueHolder!.headerToken!,
        languageCode);
  }

  Future<dynamic> postResendCode(
      Map<dynamic, dynamic> jsonMap, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    _apiStatus = await _repo!.postResendCode(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, languageCode);

    return _apiStatus;
  }

  Future<dynamic> getUser(String? loginUserId, String languageCode) async {
    if (loginUserId == null || loginUserId.isEmpty || loginUserId == 'nologinuser') {
      return;
    }
    isLoading = true;
    isConnectedToInternet = await Utils.checkInternetConnectivity();

    await _repo!.getUser(super.dataStreamController, loginUserId,
        isConnectedToInternet, PsStatus.PROGRESS_LOADING, languageCode);
  }

  Future<dynamic> checkUserExistsById(
      String? loginUserId, String? languageCode) async {
    return _repo!.checkUserExistsById(loginUserId, languageCode);
  }

  Future<dynamic> getUserFromDB(String loginUserId) async {
    isLoading = true;

    await _repo!.getUserFromDB(
        loginUserId, super.dataStreamController!, PsStatus.PROGRESS_LOADING);
  }

  Future<dynamic> getOtherUserData(Map<dynamic, dynamic> jsonMap,
      String? otherUserId, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    await _repo!.getOtherUserData(
        super.dataStreamController,
        jsonMap,
        otherUserId,
        psValueHolder!.headerToken!,
        limit,
        offset!,
        isConnectedToInternet,
        PsStatus.PROGRESS_LOADING,
        languageCode);
  }

  Future<dynamic> userReportItem(
      Map<dynamic, dynamic> jsonMap, String loginUserId) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    _apiStatus = await _repo!.userReportItem(jsonMap, isConnectedToInternet,
        PsStatus.PROGRESS_LOADING, loginUserId, psValueHolder!.headerToken!);

    return _apiStatus;
  }

  Future<dynamic> blockUser(Map<dynamic, dynamic> jsonMap, String loginUserId,
      String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    _apiStatus = await _repo!.blockUser(
        jsonMap,
        isConnectedToInternet,
        PsStatus.PROGRESS_LOADING,
        loginUserId,
        psValueHolder!.headerToken!,
        languageCode);

    return _apiStatus;
  }

  Future<dynamic> postUnBlockUser(Map<dynamic, dynamic> jsonMap,
      String loginUserId, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    _apiStatus = await _repo!.postUnBlockUser(
        jsonMap,
        isConnectedToInternet,
        PsStatus.PROGRESS_LOADING,
        loginUserId,
        psValueHolder!.headerToken!,
        languageCode);

    return _apiStatus;
  }

  // Delete User
  Future<dynamic> postDeleteUser(
      Map<dynamic, dynamic> jsonMap, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    _apiStatus = await _repo!.postDeleteUser(
        jsonMap,
        psValueHolder!.loginUserId!,
        isConnectedToInternet,
        PsStatus.PROGRESS_LOADING,
        psValueHolder!.headerToken!,
        languageCode);

    return _apiStatus;
  }

  ///
  /// Firebase Auth
  ///
  Future<fb_auth.User?> getCurrentFirebaseUser() async {
    final fb_auth.FirebaseAuth auth = fb_auth.FirebaseAuth.instance;
    final fb_auth.User? currentUser = auth.currentUser;
    return currentUser;
  }

  Future<void> handleFirebaseAuthError(BuildContext context, String email,
      {bool ignoreEmail = false}) async {
    if (email.isEmpty) {
      return;
    }

    // final List<String> providers =
    //     // ignore: deprecated_member_use
    //     await _firebaseAuth.fetchSignInMethodsForEmail(email);
    // if(providers.isEmpty) {
    //   return;
    // }
    // final String provider = providers.single;
    // print('provider : $provider');
    // // Registered With Email
    // if (provider.contains(PsConst.emailAuthProvider) && !ignoreEmail) {
    //   showDialog<dynamic>(
    //       context: context,
    //       builder: (BuildContext context) {
    //         return WarningDialog(
    //           message: '[ $email ]\n' + 'auth__email_provider'.tr,
    //           onPressed: () {},
    //         );
    //       });
    // }
    // // Registered With Google
    // else if (provider.contains(PsConst.googleAuthProvider)) {
    //   showDialog<dynamic>(
    //       context: context,
    //       builder: (BuildContext context) {
    //         return WarningDialog(
    //           message: '[ $email ]\n' + 'auth__google_provider'.tr,
    //           onPressed: () {},
    //         );
    //       });
    // }
    // // Registered With Facebook
    // else if (provider.contains(PsConst.facebookAuthProvider)) {
    //   showDialog<dynamic>(
    //       context: context,
    //       builder: (BuildContext context) {
    //         return WarningDialog(
    //           message: '[ $email ]\n' + 'auth__facebook_provider'.tr,
    //           onPressed: () {},
    //         );
    //       });
    // }
    // // Registered With Apple
    // else if (provider.contains(PsConst.appleAuthProvider)) {
    //   showDialog<dynamic>(
    //       context: context,
    //       builder: (BuildContext context) {
    //         return WarningDialog(
    //           message: '[ $email ]\n' + 'auth__apple_provider'.tr,
    //           onPressed: () {},
    //         );
    //       });
    // }

    final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;

  try {
    // --- Attempt a sign-in with email and a dummy password ---
    // This is a common workaround to trigger the 'user-not-found' or 'wrong-password' errors
    // without actually signing in the user.
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: 'dummy_password_for_check', // Use a dummy password
    );

    // If we reach here, it means signInWithEmailAndPassword succeeded,
    // which implies the email is registered with email/password.
    // This scenario is less likely if you are just checking,
    // as you'd usually have specific sign-in flows.
    // However, if it *does* succeed, it means the dummy password was correct,
    // which is a security risk. This method is usually for "email already exists"
    // checks during *registration*.

  } on FirebaseAuthException catch (e) {
    print('Firebase Auth Exception Code: ${e.code}');
    print('Firebase Auth Exception Message: ${e.message}');

    String? providerId;

    switch (e.code) {
      case 'user-not-found':
        // Email is not registered at all.
        // You can return or proceed with registration flow.
        return;

      case 'wrong-password':
      case 'invalid-credential': // Modern error for wrong password or other credential issues
        // Email is registered with email/password, but the password was wrong.
        // This is the most common way to detect 'email/password' provider.
        providerId = PsConst.emailAuthProvider;
        break;

      case 'email-already-in-use':
        // This error typically occurs during user *creation* (createUserWithEmailAndPassword)
        // and indicates the email is already registered, potentially with *any* provider.
        // To find *which* provider, you'd then use `fetchSignInMethodsForEmail` if it were still allowed,
        // or rely on the user's `providerData` after they successfully sign in with *some* method.
        // For now, we'll assume this means it's already registered, and you'd guide the user to log in.
        // If you need to differentiate, you might need to prompt the user to try social logins.

        // Since fetchSignInMethodsForEmail is deprecated for security,
        // Firebase encourages you to *not* reveal which provider it is.
        // Instead, the recommended UX is:
        // "This email is already registered. Please sign in."
        // Or, "If you registered with Google/Facebook/Apple, try those options."

        // If you *must* know the provider, the user needs to sign in first.
        // After they sign in, you can check `FirebaseAuth.instance.currentUser?.providerData`.
        // For pre-login check, the security changes make this harder.
        // However, if you are *creating* a user, and get 'email-already-in-use',
        // you can then prompt them to sign in via any method.
        providerId = 'unknown_existing_provider'; // Or a more generic message
        break;

      case 'account-exists-with-different-credential':
        // This error occurs when you try to link a new credential (e.g., Google)
        // to an account, but that credential's email is already used by a *different*
        // Firebase account.
        // In this scenario, `e.credential` might contain information about the provider
        // you were *trying* to link.
        // You'd typically prompt the user to sign in with the *existing* account first,
        // then link the new credential.
        // To get the *original* provider, you might need to prompt the user to sign in
        // with the method they used initially.
        providerId = e.credential?.providerId ?? 'different_credential';
        break;

      // Add other relevant FirebaseAuthException codes if necessary
      default:
        // Handle other errors
        print('Unhandled Firebase Auth error: ${e.code} - ${e.message}');
        return;
    }

    // Display the warning dialog based on the detected providerId
    // ignore: unnecessary_null_comparison
    if (providerId != null) {
      String messageKey = '';
      if (providerId == PsConst.emailAuthProvider && !ignoreEmail) {
        messageKey = 'auth__email_provider';
      } else if (providerId.contains(PsConst.googleAuthProvider)) {
        messageKey = 'auth__google_provider';
      } else if (providerId.contains(PsConst.facebookAuthProvider)) {
        messageKey = 'auth__facebook_provider';
      } else if (providerId.contains(PsConst.appleAuthProvider)) {
        messageKey = 'auth__apple_provider';
      } else if (providerId == 'unknown_existing_provider') {
        // Generic message for 'email-already-in-use' during sign-up
        messageKey = 'auth__email_already_registered_generic'; // Create this new translation key
      } else if (providerId == 'different_credential') {
        // Message for account-exists-with-different-credential
        messageKey = 'auth__account_exists_different_credential'; // Create this new translation key
      }

      if (messageKey.isNotEmpty) {
        showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return WarningDialog(
              message: '[ $email ]\n' + messageKey,
              onPressed: () {
                // You might add navigation to login page or clear form here
                Navigator.of(context).pop();
              },
            );
          },
        );
      }
    }
  } catch (e) {
    // Catch any other unexpected errors
    print('An unexpected error occurred: $e');
    showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return WarningDialog(
          message: 'auth__unexpected_error', // Generic error message
          onPressed: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
  }

  ///
  /// Apple Login Related
  ///
  Future<void> loginWithAppleId(
      BuildContext context,
      Function? onAppleIdSignInSelected,
      Function? callBackAfterLoginSuccess,
      String languageCode) async {
    ///
    /// Check User is Accept Terms and Conditions
    ///
    if (isCheckBoxSelect) {
      ///
      /// Check Connection
      ///
      if (await Utils.checkInternetConnectivity()) {
        ///
        /// Get Firebase User with Apple Id Login
        ///
        final fb_auth.User? firebaseUser =
            await _getFirebaseUserWithAppleId(context);

        if (firebaseUser != null) {
          ///
          /// Got Firebase User
          ///
          Utils.psPrint('User id : ${firebaseUser.uid}');

          ///
          /// Show Progress Dialog
          ///
          await PsProgressDialog.showDialog(context);

          ///
          /// Submit to backend
          ///
          final PsResource<User>? resourceUser =
              await _submitLoginWithAppleId(firebaseUser, languageCode);

          ///
          /// Close Progress Dialog
          ///
          await PsProgressDialog.dismissDialog();

          if (resourceUser != null && resourceUser.data != null) {
            final User user = resourceUser.data!;

            try {
              final PsValueHolder liveHolder =
                  Provider.of<PsValueHolder>(context, listen: false);
              liveHolder.loginUserId = user.userId;
              if (user.userName != null && user.userName!.isNotEmpty) {
                liveHolder.loginUserName = user.userName;
              }
              liveHolder.isToShowIntroSlider = false;
              liveHolder.showOnboardLanguage = false;
            } catch (_) {}

            ///
            /// Success
            ///
            if (onAppleIdSignInSelected != null) {
              await onAppleIdSignInSelected(user.userId);
            }
            if (callBackAfterLoginSuccess != null) {
              await callBackAfterLoginSuccess(user);
            }
            await Utils.completeAuthAndGoHome(context, user);
          } else {
            ///
            /// Error from server
            ///
            showDialog<dynamic>(
                context: context,
                builder: (BuildContext context) {
                  if (resourceUser != null) {
                    return ErrorDialog(
                      message: resourceUser.message,
                    );
                  } else {
                    return ErrorDialog(
                      message: 'login__error_signin'.tr,
                    );
                  }
                });
          }
        }
      } else {
        ///
        /// No Internet Connection
        ///
        showDialog<dynamic>(
            context: context,
            builder: (BuildContext context) {
              return ErrorDialog(
                message: 'error_dialog__no_internet'.tr,
              );
            });
      }
    } else {
      ///
      /// Not yet agree on Privacy Policy
      ///
      showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return WarningDialog(
              message: 'login__warning_agree_privacy'.tr,
              onPressed: () {},
            );
          });
    }
  }

  Future<PsResource<User>?> _submitLoginWithAppleId(
      fb_auth.User user, String languageCode) async {
    // ignore: unnecessary_null_comparison
    if (user != null) {
      String? email = user.email;
      if (email == null || email == '') {
        // if (user.providerData.isNotEmpty) {
        //   email = user.providerData[0].email;
        // }
        // Apple and Facebook
        if (user.providerData.isNotEmpty) {
          for (int i = 0; i < user.providerData.length; i++) {
            if (user.providerData[i].email != null &&
                user.providerData[i].email!.trim() != '') {
              email = user.providerData[i].email;
            }
          }

          // Email Checking
          email ??= '';
        }
      }
      final AppleLoginParameterHolder appleLoginParameterHolder =
          AppleLoginParameterHolder(
              appleId: user.uid,
              name: user.displayName,
              email: email,
              profilePhotoUrl: user.photoURL,
              deviceToken: psValueHolder!.deviceToken,
              platformName: PsConst.PLATFORM,
              deviceInfo: psValueHolder!.deviceModelName,
              deviceId: psValueHolder!.deviceUniqueId);

      final PsResource<User> _apiStatus =
          await postAppleLogin(appleLoginParameterHolder.toMap(), languageCode);

      if (_apiStatus.data != null) {
        final User user = _apiStatus.data!;
        await checkForUserNameNeeded(
            PsConst.APPLE_LOGIN, user.userEmail ?? '', user.userId ?? '');
        await replaceAppleLoginUser(true);
        await replaceVerifyUserData('', '', '', '');
        await replaceLoginUserId(user.userId ?? '');
        if (user.userName != null && user.userName!.isNotEmpty) {
          await replaceLoginUserName(user.userName!);
        }
        await replaceIsToShowIntroSlider(false);
        await replaceShowOnboardLanguage(false);
        await replaceCurrentLoginMethod(PsConst.APPLE_LOGIN);

        if (psValueHolder != null) {
          psValueHolder!.loginUserId = user.userId;
          if (user.userName != null && user.userName!.isNotEmpty) {
            psValueHolder!.loginUserName = user.userName;
          }
          psValueHolder!.isToShowIntroSlider = false;
          psValueHolder!.showOnboardLanguage = false;
        }
      }
      return _apiStatus;
    } else {
      return null;
    }
  }

  Future<fb_auth.User?> _getFirebaseUserWithAppleId(
      BuildContext context) async {
    try {
      // 1. Perform the sign-in request
      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // 2. Create an OAuth credential using the ID token and authorization code
      final fb_auth.OAuthProvider oAuthProvider =
          fb_auth.OAuthProvider('apple.com');
      final fb_auth.OAuthCredential credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // 3. Sign in to Firebase with the Apple credential
      final fb_auth.UserCredential authResult =
          await _firebaseAuth.signInWithCredential(credential);

      final fb_auth.User? firebaseUser = authResult.user;

      // 4. Update the Firebase user profile with the full name if available
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        final String displayName =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
        if (displayName.isNotEmpty) {
          await firebaseUser!.updateDisplayName(displayName);
        }
      }

      return firebaseUser;
    } on SignInWithAppleAuthorizationException catch (e) {
      print(e);

      if (e.code == AuthorizationErrorCode.canceled) {
        throw PlatformException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      } else {
        throw PlatformException(
          code: 'ERROR_AUTHORIZATION_DENIED',
          message: e.message,
        );
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  ///
  /// Google Login Related
  ///
  Future<void> loginWithGoogleId(
      BuildContext context,
      Function? onGoogleIdSignInSelected,
      Function? callBackAfterLoginSuccess,
      String languageCode) async {
    if (!isCheckBoxSelect) {
      if (context.mounted) {
        showDialog<dynamic>(
            context: context,
            builder: (BuildContext context) {
              return WarningDialog(
                message: 'login__warning_agree_privacy'.tr,
                onPressed: () {},
              );
            });
      }
      return;
    }

    if (!await Utils.checkInternetConnectivity()) {
      if (context.mounted) {
        showDialog<dynamic>(
            context: context,
            builder: (BuildContext context) {
              return ErrorDialog(
                message: 'error_dialog__no_internet'.tr,
              );
            });
      }
      return;
    }

    try {
      final fb_auth.User? firebaseUser = await _getFirebaseUserWithGoogleId();
      if (firebaseUser == null) {
        if (context.mounted) {
          showDialog<dynamic>(
              context: context,
              builder: (BuildContext context) {
                return ErrorDialog(
                  message: 'login__error_signin'.tr,
                );
              });
        }
        return;
      }

      Utils.psPrint('User id : ${firebaseUser.uid}');
      if (context.mounted) {
        await PsProgressDialog.showDialog(context);
      }

      final PsResource<User>? resourceUser =
          await _submitLoginWithGoogleId(firebaseUser, languageCode);

      await PsProgressDialog.dismissDialog();

      if (resourceUser != null && resourceUser.data != null) {
        final User user = resourceUser.data!;

        try {
          final PsValueHolder liveHolder =
              Provider.of<PsValueHolder>(context, listen: false);
          liveHolder.loginUserId = user.userId;
          if (user.userName != null && user.userName!.isNotEmpty) {
            liveHolder.loginUserName = user.userName;
          }
          liveHolder.isToShowIntroSlider = false;
          liveHolder.showOnboardLanguage = false;
        } catch (_) {}

        if (onGoogleIdSignInSelected != null) {
          await onGoogleIdSignInSelected(user.userId);
        }
        if (callBackAfterLoginSuccess != null) {
          await callBackAfterLoginSuccess(user);
        } else if (context.mounted) {
          await Utils.completeAuthAndGoHome(context, user);
        }
      } else {
        if (context.mounted) {
          showDialog<dynamic>(
              context: context,
              builder: (BuildContext context) {
                return ErrorDialog(
                  message: (resourceUser != null && resourceUser.message.isNotEmpty)
                      ? resourceUser.message
                      : 'login__error_signin'.tr,
                );
              });
        }
      }
    } on GoogleSignInException catch (e) {
      await PsProgressDialog.dismissDialog();
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return;
      }
      if (context.mounted) {
        showDialog<dynamic>(
            context: context,
            builder: (BuildContext context) {
              return ErrorDialog(
                message: 'Google Sign-In failed: ${e.description ?? e.code.name}',
              );
            });
      }
    } catch (e) {
      await PsProgressDialog.dismissDialog();
      if (context.mounted) {
        showDialog<dynamic>(
            context: context,
            builder: (BuildContext context) {
              return ErrorDialog(
                message: 'Google Sign-In error: $e',
              );
            });
      }
    }
  }

  Future<fb_auth.User?> _getFirebaseUserWithGoogleId() async {
    await ensureGoogleSignInInitialized();

    final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication auth = account.authentication;
    final String? idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google authentication did not return an ID token.');
    }

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    final fb_auth.UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    final fb_auth.User? user = userCredential.user;
    if (user != null) {
      print('signed in ${user.displayName ?? user.email ?? user.uid}');
    }
    return user;
  }

  Future<PsResource<User>?> _submitLoginWithGoogleId(
      fb_auth.User user, String languageCode) async {
    // ignore: unnecessary_null_comparison
    if (user != null) {
      String? email = user.email;
      if (email == null || email == '') {
        // if (user.providerData.isNotEmpty) {
        //   email = user.providerData[0].email;
        // }
        if (user.providerData.isNotEmpty) {
          for (int i = 0; i < user.providerData.length; i++) {
            if (user.providerData[i].email != null &&
                user.providerData[i].email!.trim() != '') {
              email = user.providerData[i].email;
              break;
            }
          }
        } else {
          return null;
        }
      }
      final GoogleLoginParameterHolder googleLoginParameterHolder =
          GoogleLoginParameterHolder(
        googleId: user.uid,
        userName: user.displayName,
        userEmail: email,
        profilePhotoUrl: user.photoURL,
        deviceToken: psValueHolder?.deviceToken ?? '',
        platformName: PsConst.PLATFORM,
        deviceInfo: (psValueHolder?.deviceModelName?.isNotEmpty == true)
            ? psValueHolder!.deviceModelName!
            : (Platform.isIOS ? 'iOS Device' : 'Android Device'),
        deviceId: (psValueHolder?.deviceUniqueId?.isNotEmpty == true)
            ? psValueHolder!.deviceUniqueId!
            : 'device_${DateTime.now().millisecondsSinceEpoch}',
      );

      final PsResource<User> _apiStatus = await postGoogleLogin(
          googleLoginParameterHolder.toMap(), languageCode);

      if (_apiStatus.data != null) {
        final User user = _apiStatus.data!;
        await checkForUserNameNeeded(
            PsConst.GOOGLE_LOGIN, user.userEmail ?? '', '');
        await replaceVerifyUserData('', '', '', '');
        await replaceLoginUserId(user.userId ?? '');
        if (user.userName != null && user.userName!.isNotEmpty) {
          await replaceLoginUserName(user.userName!);
        }
        await replaceIsToShowIntroSlider(false);
        await replaceShowOnboardLanguage(false);
        await replaceCurrentLoginMethod(PsConst.GOOGLE_LOGIN);

        if (psValueHolder != null) {
          psValueHolder!.loginUserId = user.userId;
          if (user.userName != null && user.userName!.isNotEmpty) {
            psValueHolder!.loginUserName = user.userName;
          }
          psValueHolder!.isToShowIntroSlider = false;
          psValueHolder!.showOnboardLanguage = false;
        }
      }

      return _apiStatus;
    } else {
      return null;
    }
  }

  ///
  /// Facebook Login Related
  ///
  Future<void> loginWithFacebookId(
      BuildContext context,
      Function? onFacebookIdSignInSelected,
      Function? callBackAfterLoginSuccess,
      String languageCode) async {
    ///
    /// Check User is Accept Terms and Conditions
    ///
    if (isCheckBoxSelect) {
      ///
      /// Check Connection
      ///
      if (await Utils.checkInternetConnectivity()) {
        ///
        /// Get Firebase User with Facebook Id Login
        ///
        final FacebookLoginUserHolder? facebookLoginUserHolder =
            await _getFirebaseUserWithFacebookId(context);

        if (facebookLoginUserHolder != null) {
          ///
          /// Got Firebase User
          ///
          Utils.psPrint(
              'User id : ${facebookLoginUserHolder.firebaseUser.uid}');

          ///
          /// Show Progress Dialog
          ///
          await PsProgressDialog.showDialog(context);

          ///
          /// Submit to backend
          ///
          final PsResource<User>? resourceUser =
              await _submitLoginWithFacebookId(
                  facebookLoginUserHolder, languageCode);

          ///
          /// Close Progress Dialog
          ///
          await PsProgressDialog.dismissDialog();

          if (resourceUser != null && resourceUser.data != null) {
            final User user = resourceUser.data!;
            try {
              final PsValueHolder liveHolder =
                  Provider.of<PsValueHolder>(context, listen: false);
              liveHolder.loginUserId = user.userId;
              if (user.userName != null && user.userName!.isNotEmpty) {
                liveHolder.loginUserName = user.userName;
              }
              liveHolder.isToShowIntroSlider = false;
              liveHolder.showOnboardLanguage = false;
            } catch (_) {}

            ///
            /// Success
            ///
            if (onFacebookIdSignInSelected != null) {
              await onFacebookIdSignInSelected(user.userId);
            }
            if (callBackAfterLoginSuccess != null) {
              await callBackAfterLoginSuccess(user);
            }
            await Utils.completeAuthAndGoHome(context, user);
          } else {
            ///
            /// Error from server
            ///
            showDialog<dynamic>(
                context: context,
                builder: (BuildContext context) {
                  if (resourceUser != null) {
                    return ErrorDialog(
                      message: resourceUser.message,
                    );
                  } else {
                    return ErrorDialog(
                      message: 'login__error_signin'.tr,
                    );
                  }
                });
          }
        }
      } else {
        ///
        /// No Internet Connection
        ///
        showDialog<dynamic>(
            context: context,
            builder: (BuildContext context) {
              return ErrorDialog(
                message: 'error_dialog__no_internet'.tr,
              );
            });
      }
    } else {
      ///
      /// Not yet agree on Privacy Policy
      ///
      showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return WarningDialog(
              message: 'login__warning_agree_privacy'.tr,
              onPressed: () {},
            );
          });
    }
  }

  Future<FacebookLoginUserHolder?> _getFirebaseUserWithFacebookId(
      BuildContext context) async {
    final LoginResult result = await FacebookAuth.instance.login();
    final String token = result.accessToken!.tokenString;
    // final String token = result.accessToken!.tokenString;
    // Get User Info Based on the Access Token
    final dynamic graphResponse = await http.get(Uri.parse(
        'https://graph.facebook.com/v2.12/me?fields=name,picture.width(800).height(800),first_name,last_name,email&access_token=$token'));
    final dynamic profile = json.decode(graphResponse.body);

    // Firebase Base Login
    // ignore: unnecessary_null_comparison
    if (result != null) {
      final FacebookAuthCredential facebookAuthCredential = FacebookAuthProvider
              .credential(result.accessToken!.tokenString)
          // FacebookAuthProvider.credential(result.accessToken!.tokenString)
          as FacebookAuthCredential;
      try {
        final fb_auth.User? user =
            (await _firebaseAuth.signInWithCredential(facebookAuthCredential))
                .user;
        print('signed in' + user!.displayName!);

        return FacebookLoginUserHolder(user, profile);
        // return user;
      } on PlatformException catch (e) {
        print(e);

        handleFirebaseAuthError(context, profile['email']);

        return null;
      }
    } else {
      return null;
    }
  }

  Future<PsResource<User>?> _submitLoginWithFacebookId(
      FacebookLoginUserHolder facebookLoginUserHolder,
      String languageCode) async {
    final fb_auth.User user = facebookLoginUserHolder.firebaseUser;
    final dynamic facebookUser = facebookLoginUserHolder.facebookUser;
    // ignore: unnecessary_null_comparison
    if (user != null) {
      String? email = user.email;
      if (email == null || email == '') {
        // if (user.providerData.isNotEmpty) {
        //   email = user.providerData[0].email;
        // }
        if (user.providerData.isNotEmpty) {
          for (int i = 0; i < user.providerData.length; i++) {
            if (user.providerData[i].email != null &&
                user.providerData[i].email!.trim() != '') {
              email = user.providerData[i].email;
            }
          }

          // Email Checking
          email ??= '';
        }
      }
      final FBLoginParameterHolder fbLoginParameterHolder =
          FBLoginParameterHolder(
              facebookId: user.uid,
              name: user.displayName,
              email: email,
              profileImgId: facebookUser['id'],
              deviceToken: psValueHolder!.deviceToken ?? '',
              platformName: PsConst.PLATFORM,
              deviceInfo: psValueHolder!.deviceModelName,
              deviceId: psValueHolder!.deviceUniqueId);

      final PsResource<User> _apiStatus =
          await postFBLogin(fbLoginParameterHolder.toMap(), languageCode);

      if (_apiStatus.data != null) {
        final User user = _apiStatus.data!;
        await checkForUserNameNeeded(
            PsConst.FACEBOOK_LOGIN, user.userEmail ?? '', '');
        await replaceVerifyUserData('', '', '', '');
        await replaceLoginUserId(user.userId ?? '');
        if (user.userName != null && user.userName!.isNotEmpty) {
          await replaceLoginUserName(user.userName!);
        }
        await replaceIsToShowIntroSlider(false);
        await replaceShowOnboardLanguage(false);
        await replaceCurrentLoginMethod(PsConst.FACEBOOK_LOGIN);

        if (psValueHolder != null) {
          psValueHolder!.loginUserId = user.userId;
          if (user.userName != null && user.userName!.isNotEmpty) {
            psValueHolder!.loginUserName = user.userName;
          }
          psValueHolder!.isToShowIntroSlider = false;
          psValueHolder!.showOnboardLanguage = false;
        }
      }

      return _apiStatus;
    } else {
      return null;
    }
  }

  ///
  /// Email Login Related
  ///
  Future<void> loginWithEmailId(
      BuildContext context,
      String email,
      String password,
      Function? onProfileSelected,
      Function? callBackAfterLoginSuccess,
      String languageCode) async {
    ///
    /// Check Connection
    ///
    if (await Utils.checkInternetConnectivity()) {

      ///
      /// Check User Email Format
      /// 
      final bool isEmailFormatCorrect = Utils.checkEmailFormat(email)!;
      if (!isEmailFormatCorrect) {        
        showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {              
            return ErrorDialog(
              message: 'login__email_required_error'.tr,
            );              
        });
        return;
      }

      ///
      /// Show Progress Dialog
      ///
      await PsProgressDialog.showDialog(context);

      // Firebase sign-in for RTDB chat is best-effort; never block Laravel backend login
      try {
        await signInWithEmailAndPasswordNext(context, email, email);
      } catch (_) {}

      try {
        final PsResource<User> resourceUser =
            await _submitLoginWithEmailId(email, password, languageCode, context);

        await PsProgressDialog.dismissDialog();

        // ignore: unnecessary_null_comparison
        if (resourceUser != null && resourceUser.data != null) {
          if (resourceUser.data!.code == PsConst.ONE) {
            psValueHolder?.userEmailToVerify = resourceUser.data!.userEmail;
            final ResendCodeAgainParameterHolder resendCodeParameterHolder =
                ResendCodeAgainParameterHolder(
                    userEmail: resourceUser.data!.userEmail);

            postResendCode(resendCodeParameterHolder.toMap(), languageCode);
            if (context.mounted) {
              await Navigator.pushNamed(
                  context, RoutePaths.user_verify_email_container,
                  arguments: resourceUser.data!.userId);
            }
          } else if (resourceUser.data!.code == PsConst.ZERO &&
              resourceUser.data!.status == PsConst.ZERO) {
            if (context.mounted) {
              showDialog<dynamic>(
                  context: context,
                  builder: (BuildContext context) {
                    return ErrorDialog(
                      message: 'user_status__unpublished'.tr,
                    );
                  });
            }
          } else {
            String? loginName = email;
            if (resourceUser.data?.userEmail != null &&
                resourceUser.data?.userEmail != '') {
              loginName = resourceUser.data?.userEmail!;
            } else if (resourceUser.data?.userPhone != null &&
                resourceUser.data?.userPhone != '') {
              loginName = resourceUser.data?.userPhone!;
            }
            final User user = resourceUser.data!;
            await checkForUserNameNeeded(PsConst.NORMAL_LOGIN, loginName, '');
            await replaceVerifyUserData('', '', '', '');
            await replaceLoginUserId(user.userId ?? '');
            if (user.userName != null && user.userName!.isNotEmpty) {
              await replaceLoginUserName(user.userName!);
            }
            await replaceIsToShowIntroSlider(false);
            await replaceShowOnboardLanguage(false);
            await replaceCurrentLoginMethod(PsConst.NORMAL_LOGIN);

            try {
              final PsValueHolder liveHolder =
                  Provider.of<PsValueHolder>(context, listen: false);
              liveHolder.loginUserId = user.userId;
              if (user.userName != null && user.userName!.isNotEmpty) {
                liveHolder.loginUserName = user.userName;
              }
              liveHolder.isToShowIntroSlider = false;
              liveHolder.showOnboardLanguage = false;
            } catch (_) {}
            if (onProfileSelected != null) {
              await onProfileSelected(user.userId);
            }
            if (callBackAfterLoginSuccess != null) {
              await callBackAfterLoginSuccess(user);
            } else if (context.mounted) {
              await Utils.completeAuthAndGoHome(context, user);
            }
          }
        } else {
          if (context.mounted) {
            showDialog<dynamic>(
                context: context,
                builder: (BuildContext context) {
                  return ErrorDialog(
                    message: (resourceUser.message.isNotEmpty)
                        ? resourceUser.message
                        : 'login__error_signin'.tr,
                  );
                });
          }
        }
      } catch (e) {
        await PsProgressDialog.dismissDialog();
        if (context.mounted) {
          showDialog<dynamic>(
              context: context,
              builder: (BuildContext context) {
                return ErrorDialog(
                  message: 'Login error: $e',
                );
              });
        }
      }
    } else {
      ///
      /// No Internet Connection
      ///
      showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(
              message: 'error_dialog__no_internet'.tr,
            );
          });
    }
  }

  /// @deprecated
  /// This method is deprecated and will be removed in future versions.
  Future<fb_auth.User?> signInWithEmailAndPassword(
      BuildContext context, String email, String password) async {
    fb_auth.UserCredential result;
    fb_auth.User? user;
    try {
      final bool isEmailFormatCorrect = Utils.checkEmailFormat(email)!;
      if (isEmailFormatCorrect) {
        result = await _firebaseAuth.signInWithEmailAndPassword(
            email: email, password: password);
      } else {
        //sign in with default credentials
        result = await _firebaseAuth.signInWithEmailAndPassword(
            email: PsConst.defaultEmail, password: PsConst.defaultPassword);
      }
      user = result.user;
    } on fb_auth.FirebaseException {
      await PsProgressDialog.dismissDialog();
      
      final fb_auth.User? _user = await createUserWithEmailAndPassword(
          context, email, password,
          ignoreHandleFirebaseAuthError: true);

      //sing in with default credentials
      if (_user == null) {
        try {
          result = await _firebaseAuth.signInWithEmailAndPassword(
              email: PsConst.defaultEmail, password: PsConst.defaultPassword);
          user = result.user;
        } on PlatformException catch (e) {
          print(e);
          final fb_auth.User? _user2 = await createUserWithEmailAndPassword(
              context, PsConst.defaultEmail, PsConst.defaultPassword,
              ignoreHandleFirebaseAuthError: true);

          if (_user2 != null) {
            user = _user2;
          }
        }
      } else {
        user = _user;
      }
    }

    print('signInEmail succeeded: $user');

    return user;
  }

  
  Future<fb_auth.User?> signInWithEmailAndPasswordNext(
      BuildContext context, String email, String password) async {
    fb_auth.UserCredential result;
    fb_auth.User? user;
    try {      
      result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);    
      user = result.user;
    } on Exception catch (_) {
      
      // Handle Firebase authentication error
      // Login as Anonymous
      print('Sign In User with email failed. Trying anonymous login');
      try {
        result = await _firebaseAuth.signInAnonymously();
        user = result.user;        

      } on Exception catch (_) {
        print('Anonymous login failed');
        user = null;
      }
      
    }

    print('signInEmail succeeded: $user');
    
    return user;
  }

  // Future<PsResource<User>> _submitLoginWithEmailId(
  //     String email, String password, String languageCode) async {
  //   final UserLoginParameterHolder userLoginParameterHolder =
  //       UserLoginParameterHolder(
  //     userEmail: email,
  //     userPassword: password,
  //     deviceToken: psValueHolder!.deviceToken,
  //     platformName: PsConst.PLATFORM,
  //     deviceInfo: psValueHolder!.deviceModelName,
  //     deviceId: psValueHolder!.deviceUniqueId,
  //   );

  //   final PsResource<User> _apiStatus =
  //       await postUserLogin(userLoginParameterHolder.toMap(), languageCode);

  //   if (_apiStatus.data != null) {
  //     await checkForUserNameNeeded(
  //         PsConst.NORMAL_LOGIN, email);
  //     await replaceVerifyUserData('', '', '', '');
  //     await replaceLoginUserId(_apiStatus.data!.userId!);
  //     await replaceCurrentLoginMethod(PsConst.NORMAL_LOGIN);
  //   }
  //   return _apiStatus;
  // }

  Future<PsResource<User>> _submitLoginWithEmailId(String email,
      String password, String languageCode, BuildContext context) async {
    final UserLoginParameterHolder userLoginParameterHolder =
        UserLoginParameterHolder(
      userEmail: email,
      userPassword: password,
      deviceToken: psValueHolder?.deviceToken ?? '',
      platformName: PsConst.PLATFORM,
      deviceInfo: (psValueHolder?.deviceModelName?.isNotEmpty == true)
          ? psValueHolder!.deviceModelName!
          : (Platform.isIOS ? 'iOS Device' : 'Android Device'),
      deviceId: (psValueHolder?.deviceUniqueId?.isNotEmpty == true)
          ? psValueHolder!.deviceUniqueId!
          : 'device_${DateTime.now().millisecondsSinceEpoch}',
    );

    final PsResource<User> _apiStatus =
        await postUserLogin(userLoginParameterHolder.toMap(), languageCode);

    if (_apiStatus.data?.code == PsConst.ZERO &&
        _apiStatus.data?.status != PsConst.ZERO) {
      String? loginName = email; // input from textbox
      if (_apiStatus.data?.userEmail != null &&
          _apiStatus.data?.userEmail != '') {
        loginName = _apiStatus.data?.userEmail!;
      } else if (_apiStatus.data?.userPhone != null &&
          _apiStatus.data?.userPhone != '') {
        loginName = _apiStatus.data?.userPhone!;
      }
      if (_apiStatus.data != null) {
        final User user = _apiStatus.data!;
        await checkForUserNameNeeded(PsConst.NORMAL_LOGIN, loginName, '');
        await replaceVerifyUserData('', '', '', '');
        await replaceLoginUserId(user.userId!);
        if (user.userName != null && user.userName!.isNotEmpty) {
          await replaceLoginUserName(user.userName!);
        }
        await replaceIsToShowIntroSlider(false);
        await replaceShowOnboardLanguage(false);
        await replaceCurrentLoginMethod(PsConst.NORMAL_LOGIN);

        if (psValueHolder != null) {
          psValueHolder!.loginUserId = user.userId;
          if (user.userName != null && user.userName!.isNotEmpty) {
            psValueHolder!.loginUserName = user.userName;
          }
          psValueHolder!.isToShowIntroSlider = false;
          psValueHolder!.showOnboardLanguage = false;
        }
      }
    }
    return _apiStatus;
  }

  ///
  /// Email Register Related
  ///
  Future<void> signUpWithEmailId(
      BuildContext context,
      Function? onRegisterSelected,
      String name,
      String userName,
      String email,
      String password,
      Function? callBackAfterLoginSuccess,
      String languageCode) async {
    ///
    /// Check User is Accept Terms and Conditions
    ///
    if (isCheckBoxSelect) {
      ///
      /// Check Connection
      ///
      if (await Utils.checkInternetConnectivity()) {

        ///
        /// Show Progress Dialog
        ///
        await PsProgressDialog.showDialog(context);

        // Firebase user creation for RTDB chat is best-effort; never block Laravel registration
        try {
          await createUserWithEmailAndPasswordNext(context, email, email);
        } catch (_) {}

        try {
          final PsResource<User> resourceUser = await _submitSignUpWithEmailId(
              context,
              onRegisterSelected,
              name,
              userName,
              email,
              password,
              languageCode);

          await PsProgressDialog.dismissDialog();

          if (resourceUser.data != null) {
            final User user = resourceUser.data!;
            if (user.needVerify != PsConst.ONE) {
              await replaceVerifyUserData('', '', '', '');
              await replaceLoginUserId(user.userId ?? '');
              if (user.userName != null && user.userName!.isNotEmpty) {
                await replaceLoginUserName(user.userName!);
              }
              await replaceIsToShowIntroSlider(false);
              await replaceShowOnboardLanguage(false);

              if (psValueHolder != null) {
                psValueHolder!.loginUserId = user.userId;
                if (user.userName != null && user.userName!.isNotEmpty) {
                  psValueHolder!.loginUserName = user.userName;
                }
                psValueHolder!.isToShowIntroSlider = false;
                psValueHolder!.showOnboardLanguage = false;
              }

              try {
                final PsValueHolder liveHolder =
                    Provider.of<PsValueHolder>(context, listen: false);
                liveHolder.loginUserId = user.userId;
                if (user.userName != null && user.userName!.isNotEmpty) {
                  liveHolder.loginUserName = user.userName;
                }
                liveHolder.isToShowIntroSlider = false;
                liveHolder.showOnboardLanguage = false;
              } catch (_) {}

              if (onRegisterSelected != null) {
                await onRegisterSelected(user);
              }
              if (callBackAfterLoginSuccess != null) {
                await callBackAfterLoginSuccess(user);
              } else if (context.mounted) {
                await Utils.completeAuthAndGoHome(context, user);
              }
            } else {
            // Approval On
            showDialog<dynamic>(
                barrierDismissible: false,
                context: context,
                builder: (BuildContext context) {
                  return EmailSentWarningDialog(
                    message: 'register_email_sent'.tr,
                    onPressed: () async {
                      Navigator.pop(context);
                      if (onRegisterSelected != null) {
                        onRegisterSelected(resourceUser.data);
                      } else {
                        await replaceVerifyUserData(
                            resourceUser.data!.userId!,
                            resourceUser.data!.name!,
                            resourceUser.data!.userEmail!,
                            password);

                        psValueHolder!.userIdToVerify = user.userId;
                        psValueHolder!.userNameToVerify = user.name;
                        psValueHolder!.userEmailToVerify = user.userEmail;

                        final dynamic returnData = await Navigator.pushNamed(
                            context, RoutePaths.user_verify_email_container,
                            arguments: resourceUser.data!.userId);

                        if (returnData != null && returnData is User) {
                          final User user = returnData;
                          psValueHolder = Provider.of<PsValueHolder>(context,
                              listen: false);
                          psValueHolder!.loginUserId = user.userId;
                          psValueHolder!.userIdToVerify = '';
                          psValueHolder!.userNameToVerify = '';
                          psValueHolder!.userEmailToVerify = '';
                          psValueHolder!.userPasswordToVerify = '';
                          print(user.userId);

                          Navigator.pop(context, resourceUser.data);
                        }
                      }
                    },
                  );
                });
          }
          //delete code from here
        } else {
          ///
          /// Error from server
          ///
          showDialog<dynamic>(
              context: context,
              builder: (BuildContext context) {
                // ignore: unnecessary_null_comparison
                if (resourceUser != null) {
                  return ErrorDialog(
                    message: resourceUser.message,
                  );
                } else {
                  return ErrorDialog(
                    message: 'login__error_signin'.tr,
                  );
                }
              });
        }
        } catch (e) {
          await PsProgressDialog.dismissDialog();
          if (context.mounted) {
            showDialog<dynamic>(
                context: context,
                builder: (BuildContext context) {
                  return ErrorDialog(
                    message: 'Register error: $e',
                  );
                });
          }
        }
        
      } else {
        ///
        /// No Internet Connection
        ///
        showDialog<dynamic>(
            context: context,
            builder: (BuildContext context) {
              return ErrorDialog(
                message: 'error_dialog__no_internet'.tr,
              );
            });
      }
    } else {
      ///
      /// Not yet agree on Privacy Policy
      ///
      showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return WarningDialog(
              message: 'login__warning_agree_privacy'.tr,
              onPressed: () {},
            );
          });
    }
  }

  /// @deprecated
  /// This method is deprecated and will be removed in future versions.
  Future<fb_auth.User?> createUserWithEmailAndPassword(
      BuildContext context, String email, String password,
      {bool ignoreHandleFirebaseAuthError = false}) async {
    fb_auth.UserCredential result;
    try {
      result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on Exception catch (e) {
      print(e);

      try {
        result = await _firebaseAuth.signInAnonymously();          
        final fb_auth.User? user = result.user;
        return user;
      } on Exception catch (e) {
        print('Anonymous login failed: $e');
        return null;
      }

      // final List<String> providers =
      //     // ignore: deprecated_member_use
      //     await _firebaseAuth.fetchSignInMethodsForEmail(email);

      // if(providers.isEmpty) {          
        
      // }

      // final String provider = providers.single;
      // print('provider : $provider');
      // // Registered With Email
      // if (provider.contains(PsConst.emailAuthProvider)) {
      //   final fb_auth.User? user =
      //       await signInWithEmailAndPassword(context, email, email);

      //   if (user == null) {
      //     if (!ignoreHandleFirebaseAuthError) {
      //       handleFirebaseAuthError(context, email, ignoreEmail: true);
      //     }

      //     // Fail to Login to Firebase, must return null;
      //     return null;
      //   } else {
      //     return user;
      //   }
      // } else {
      //   if (!ignoreHandleFirebaseAuthError) {
      //     handleFirebaseAuthError(context, email, ignoreEmail: true);
      //   }
      //   return null;
      // }
    }

    final fb_auth.User? user = result.user;

    return user;
  }

  Future<fb_auth.User?> createUserWithEmailAndPasswordNext(
      BuildContext context, String email, String password,
      {bool ignoreHandleFirebaseAuthError = false}) async {
    fb_auth.UserCredential result;
    fb_auth.User? user;
    try {
      result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      user = result.user;
    } on Exception catch (_) {
      // Handle Firebase authentication error
      // Login as Anonymous
      print('Creating User with email failed. Trying anonymous login');
      try {
        result = await _firebaseAuth.signInAnonymously();
        user = result.user;        

      } on Exception catch (_) {
        print('Anonymous login failed');
        user = null;
      }
      
    }
    
    return user;
  }

  Future<PsResource<User>> _submitSignUpWithEmailId(
      BuildContext context,
      Function? onRegisterSelected,
      String name,
      String userName,
      String email,
      String password,
      String languageCode) async {
    final UserRegisterParameterHolder userRegisterParameterHolder =
        UserRegisterParameterHolder(
      name: name,
      userName: userName,
      userEmail: email,
      userPassword: password,
      userPhone: '',
      deviceToken: psValueHolder?.deviceToken ?? '',
      platformName: PsConst.PLATFORM,
      deviceInfo: (psValueHolder?.deviceModelName?.isNotEmpty == true)
          ? psValueHolder!.deviceModelName!
          : (Platform.isIOS ? 'iOS Device' : 'Android Device'),
      deviceId: (psValueHolder?.deviceUniqueId?.isNotEmpty == true)
          ? psValueHolder!.deviceUniqueId!
          : 'device_${DateTime.now().millisecondsSinceEpoch}',
    );

    final PsResource<User> _apiStatus = await postUserRegister(
        userRegisterParameterHolder.toMap(), languageCode);

    if (_apiStatus.data != null) {
      final User user = _apiStatus.data!;

      //for change email
      await replaceVerifyUserData(_apiStatus.data!.userId!,
          _apiStatus.data!.name!, _apiStatus.data!.userEmail!, password);

      psValueHolder!.userIdToVerify = user.userId;
      psValueHolder!.userNameToVerify = user.name;
      psValueHolder!.userEmailToVerify = user.userEmail;
    }

    return _apiStatus;
  }

  Future<dynamic> postApplyBlueMark(Map<dynamic, dynamic> jsonMap,
      String loginUserId, String languageCode) async {
    isLoading = true;

    isConnectedToInternet = await Utils.checkInternetConnectivity();

    _apiStatus = await _repo!.postApplyBlueMark(
        jsonMap,
        loginUserId,
        psValueHolder!.headerToken!,
        isConnectedToInternet,
        PsStatus.PROGRESS_LOADING,
        languageCode);

    return _apiStatus;
  }

  Future<void> checkForUserNameNeeded(
      String loginMethod, String? email, String? appleId) async {
    late UserNameStatusParameterHolder holder;
    if (loginMethod == PsConst.PHONE_LOGIN) {
      holder = UserNameStatusParameterHolder(
          loginMethod: loginMethod, userPhone: email);
    } else if (loginMethod == PsConst.APPLE_LOGIN) {
      holder = UserNameStatusParameterHolder(
          loginMethod: loginMethod, email: email, appleId: appleId);
    } else {
      holder =
          UserNameStatusParameterHolder(loginMethod: loginMethod, email: email);
    }
    print(holder.appleId);
    final PsResource<UserNameStatus> status =
        await checkUserNameExists(holder.toMap());
    print(status.data?.message?.isUserNameExisted);
    print(status.data?.message?.hasPassword);
    print('############');

    if (status.data != null) {
      print('this method is called');
      await replaceIsUserNameAndPwdNeeded(
          status.data?.message?.isUserNameExisted != PsConst.ONE,
          status.data?.message?.hasPassword != 'true');
    }
  }
}

SingleChildWidget initUserProvider(
  BuildContext context, {
  String? userId,
  Widget? widget,
}) {
  final UserRepository repo = Provider.of<UserRepository>(context);
  final PsValueHolder valueHolder = Provider.of<PsValueHolder>(context);
  return psInitProvider<UserProvider>(
      initProvider: () => UserProvider(repo: repo, psValueHolder: valueHolder),
      onProviderReady: (UserProvider provider) {
        if (provider.psValueHolder!.loginUserId == null ||
            provider.psValueHolder!.loginUserId == '') {
          provider.userParameterHolder.id = userId;
          provider.getUser(userId, valueHolder.languageCode!);
        } else {
          provider.userParameterHolder.id = provider.psValueHolder!.loginUserId;
          provider.getUser(
              provider.psValueHolder!.loginUserId, valueHolder.languageCode!);
        }
        print('..................USER_ID...................');
        print(provider.userParameterHolder.id);
        return provider;
      });
}
