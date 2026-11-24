import 'dart:async';
import 'package:flutter/material.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

import '/config/ps_colors.dart';
import '../../vendor/provider/language/app_localization_provider.dart';
import '../../vendor/utils/utils.dart';

class PsProgressDialog {
  PsProgressDialog._();

  static ProgressDialog? _progressDialog;
  static Timer? _autoDismissTimer;
  // static ProgressDialog _progressDownloadDialog;

  static Future<bool> showDialog(BuildContext context,
      {String? message}) async {
    _autoDismissTimer?.cancel();
    // Safety auto-dismiss after 15 seconds so UI is never permanently blocked
    _autoDismissTimer = Timer(const Duration(seconds: 15), () {
      dismissDialog();
    });

    try {
      if (_progressDialog == null) {
        _progressDialog = ProgressDialog(context,
            type: ProgressDialogType.normal,
            isDismissible: true,
            showLogs: false);

        _progressDialog!.style(
            message: message ?? 'loading_dialog__loading'.tr,
            borderRadius: 5.0,
            backgroundColor: Utils.isLightMode(context)
                ? PsColors.achromatic50
                : PsColors.achromatic900,
            progressWidget: Container(
                padding: const EdgeInsets.all(10.0),
                child: const CircularProgressIndicator()),
            elevation: 10.0,
            insetAnimCurve: Curves.easeInOut,
            progress: 0.0,
            maxProgress: 100.0,
            progressTextStyle: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: Theme.of(context).primaryColor),
            messageTextStyle: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: Theme.of(context).primaryColor));
      }

      if (message != null) {
        _progressDialog!.update(message: message);
      }

      await _progressDialog!.show();
      return true;
    } catch (e) {
      print('PsProgressDialog show error: $e');
      _progressDialog = null;
      return false;
    }
  }

  static Future<void> dismissDialog() async {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    if (_progressDialog != null) {
      try {
        if (_progressDialog!.isShowing()) {
          await _progressDialog!.hide();
        }
      } catch (e) {
        print('PsProgressDialog dismiss error: $e');
      } finally {
        _progressDialog = null;
      }
    }
  }

  static bool isShowing() {
    if (_progressDialog != null) {
      return _progressDialog!.isShowing();
    } else {
      return false;
    }
  }

  static void showDownloadDialog(BuildContext context, double progress,
      {String? message}) {
    if (_progressDialog == null) {
      _progressDialog = ProgressDialog(context,
          type: ProgressDialogType.download,
          isDismissible: false,
          showLogs: true);

      _progressDialog!.style(
          message: message ?? 'loading_dialog__loading'.tr,
          borderRadius: 5.0,
          backgroundColor: PsColors.achromatic50,
          progressWidget: Container(
              padding: const EdgeInsets.all(10.0),
              child: const CircularProgressIndicator()),
          elevation: 10.0,
          insetAnimCurve: Curves.easeInOut,
          progress: progress,
          maxProgress: 100.0,
          progressTextStyle: Theme.of(context).textTheme.bodyLarge,
          messageTextStyle: Theme.of(context).textTheme.bodyLarge);
    }

    _progressDialog!.update(
        message: message ?? 'loading_dialog__loading'.tr, progress: progress);

    if (!_progressDialog!.isShowing()) {
      _progressDialog!.show();
    }
  }

  static void dismissDownloadDialog() {
    if (_progressDialog != null) {
      _progressDialog!.hide();
      _progressDialog = null;
    }
  }
}
