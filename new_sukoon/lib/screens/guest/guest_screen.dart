import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login/flutter_login.dart';
import '../../cubits/guest/guest_cubit.dart';
import '../chat_list/chat_list_screen.dart';

class GuestScreen extends StatelessWidget {
  const GuestScreen({super.key});

  static const routeName = "guest";

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GuestCubit>();

return FlutterLogin(
  scrollable: true,
  hideForgotPasswordButton: true,
  title: 'Sukoon',
  theme: LoginTheme(
    titleStyle: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    pageColorDark: Color(0xFF292e91),  // Updated to #dfe0ef
    pageColorLight: Color(0xFFedf6fc),  // Updated to #e4f2fa
  ),



     
      logo: const AssetImage('assets/images/Sukoon_trans_logo.png'),
      onLogin: cubit.signIn,
      onSignup: cubit.signUp,
      userValidator: (value) {
        if (value == null || !value.contains('@')) {
          return 'Please enter a valid email address';
        }
        return null;
      },
      passwordValidator: (value) {
        if (value == null || value.length < 5) {
          return "Please must be at least 5 chars";
        }
        return null;
      },
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacementNamed(ChatListScreen.routeName);
      },
      onRecoverPassword: (_) async => null,
    );
  }
}