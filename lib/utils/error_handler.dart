import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import '/generated/app_localizations.dart';

enum HandleTypes { auth, update, logout, other }

class ErrorHandler {
  BuildContext context;
  ErrorHandler(this.context);

  Logger logger = Logger();

  Future<void> handle(
    dynamic e, 
    HandleTypes type, 
    {
      void Function()? authFailedHandler, 
      void Function()? tokenExpiredFunction, 
      void Function()? onRetry
    }
  ) async {
    if(type == HandleTypes.logout){
      if(e.response != null){
        logger.e("logout error : ${e.response.data}");
      }else{
        logger.e("logout error: $e");
      }
      return;
    }
    if (e is TimeoutException) {
      return connectionErrorDialog(onRetry);
    }
    if (e is DioException) {
      return _handleDioError(e, type, authFailedHandler, tokenExpiredFunction);
    }
    if(e is PlayerException || e is PlayerInterruptedException){
      logger.e("Audio player error: $e");
      return;
    }
    // 兜底
    logger.e("Unexpected error: $e");
    return unknownErrorDialog();
  }

  Future<void> _handleDioError(
    DioException e, 
    HandleTypes type, 
    [
      void Function()? authFailedFunction, 
      void Function()? tokenExpiredFunction
    ]
  ) async {
    if(e is HandshakeException){
      logger.e("Handshake error: $e");
      return connectionErrorDialog();
    }
    if (e.response == null) {
      logger.e("No response: $e");
      return unknownErrorDialog();
    }
    
    final status = e.response?.statusCode;
    final message = e.response?.data?['message'];

    if(type == HandleTypes.auth){
      if (message == "Token expired") {
        tokenExpiredFunction??();
        return _tokenExpiredDialog();
      }
      if (status == 401) {
        if(authFailedFunction != null){
          return authFailedFunction();
        }else{
          return _authFailedDialog();
        }
      }
    }

    if (type == HandleTypes.update){
      // sth
      return connectionErrorDialog();
    }

    return unknownErrorDialog();
  }

  Future<void> handleGameError(dynamic e, void Function() navigateFunc, [void Function()? onRetry]) async {
    if(e is PlayerException || e is PlayerInterruptedException){
      //blahblah
      return;
    }
    if(e is TimeoutException){
      showDialog(
        context: context, 
        builder: (context){
          return AlertDialog(
            content: Text(AppLocalizations.of(context)!.connectError),
            actions: [
              TextButton(
                onPressed: navigateFunc,
                child: Text(AppLocalizations.of(context)!.back)
              ),
              if(onRetry != null)
                TextButton(
                  onPressed: (){
                    onRetry();
                  },
                  child: Text(AppLocalizations.of(context)!.retry)
                ),
            ],
          );
        }
      );
      return;
    }
    if(e is DioException){
      if(e.response != null){
        logger.e("Dio error: ${e.response?.data}");
        showDialog(
          context: context, 
          builder: (context){
            return AlertDialog(
              content: Text(AppLocalizations.of(context)!.connectError),
              actions: [
                TextButton(
                  onPressed: navigateFunc,
                  child: Text(AppLocalizations.of(context)!.back)
                ),
              ],
            );
          }
        );
      }
      return;
    }
    logger.e("Unexpected error: $e");
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(AppLocalizations.of(context)!.unknownError),
          actions: [
            TextButton(
              onPressed: navigateFunc,
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  void unknownErrorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(AppLocalizations.of(context)!.unknownError),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> connectionErrorDialog([void Function()? onRetry]) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(AppLocalizations.of(context)!.connectError),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.back),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  onRetry();
                },
                child: Text(AppLocalizations.of(context)!.retry),
              ),
          ],
        );
      },
    );
  }

  Future<void> _tokenExpiredDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Text("登录过期，请重新登录"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _authFailedDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Text("认证失败，请重新登录"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }
}
