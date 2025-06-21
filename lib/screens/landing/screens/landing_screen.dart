import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/common/widgets/round_button.dart';
import '../../../utils/constants/assets_constants.dart';
import '../../../utils/common/widgets/helper_widgets.dart';
import '../../../utils/constants/colors_constants.dart';
import '../../../utils/constants/routes_constants.dart';
import '../../../screens/auth/repositories/auth_repository.dart'; // <-- Buraya dikkat

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              addVerticalSpace(size.height * 0.05),
              _buildTitle(context, size),
              _buildSubTitle(context, size),
              const Expanded(child: SizedBox()),
              _buildHeroImage(size),
              const Expanded(child: SizedBox()),
              _buildGoogleButton(context, ref, size),
              addVerticalSpace(size.height * 0.02),
              RoundButton(
                text: 'Continue with Phone',
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.phoneLoginScreen,
                  );
                },
              ),
              addVerticalSpace(size.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(Size size) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
      child: Image.asset(
        ImagesConsts.icLanding2,
        width: size.width * 0.9,
        height: size.width * 0.9,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildTitle(BuildContext context, Size size) {
    return Text(
      'Welcome To LetsChat',
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
        fontSize: size.width * 0.08,
      ),
    );
  }

  Widget _buildSubTitle(BuildContext context, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        'Easy and free you can get all features here.',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: size.width * 0.04,
          color: AppColors.grey,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context, WidgetRef ref, Size size) {
    return InkWell(
      onTap: () async {
        final authRepo = ref.read(authRepositoryProvider);
        try {
          final userCredential = await authRepo.signInWithGoogle();
          if (userCredential != null) {
            // Giriş başarılıysa yönlendir
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.userInformationScreen,
                  (route) => false,
            );
          } else {
            showSnackBar(context, content: 'Giriş iptal edildi');
          }
        } catch (e) {
          showSnackBar(context, content: 'Google ile giriş başarısız: $e');
        }
      },
      child: Container(
        width: size.width * 0.8,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Sign in with Google',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: size.width * 0.045,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
