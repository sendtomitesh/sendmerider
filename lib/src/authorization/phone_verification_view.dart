import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:sendme_rider/src/resources/preferences_helper.dart';

class PhoneVerificationView extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const PhoneVerificationView({super.key, this.onLoginSuccess});

  @override
  State<PhoneVerificationView> createState() => _PhoneVerificationViewState();
}

class _PhoneVerificationViewState extends State<PhoneVerificationView> {
  final TextEditingController textController = TextEditingController();
  final TextEditingController otpTextController = TextEditingController();

  String? phoneNoWithCountryCode;
  String? phoneNoWithoutCountryCode;
  String? verificationId;
  String? errorMessage;
  String? countryCode;
  String phoneIsoCode = 'IN';

  bool sendOTPPressed = false;
  bool progress = false;
  bool _agreeChecked = false;
  int phoneNumberLength = 0;

  @override
  void dispose() {
    textController.dispose();
    otpTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry = countries.firstWhere((c) => c.code == phoneIsoCode);
    final loc = AppLocalizations.of(context);

    return SafeArea(
      child: !sendOTPPressed
          ? _buildPhoneEntryPhase(selectedCountry, loc)
          : _buildOtpEntryPhase(loc),
    );
  }

  // ===========================================================================
  // Phase 1: Phone Number Entry
  // ===========================================================================

  Widget _buildPhoneEntryPhase(Country selectedCountry, AppLocalizations? loc) {
    final bool isButtonEnabled =
        phoneNumberLength >= selectedCountry.minLength &&
        phoneNumberLength <= selectedCountry.maxLength &&
        _agreeChecked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc?.translate('Hello') ?? 'Hello'},',
              style: TextStyle(
                fontFamily: AssetsFont.textBold,
                color: AppColors.mainAppColor,
                fontSize: 24,
              ),
            ),
            Text(
              loc?.translate('EnterPhoneNumber') ?? 'Enter Phone Number',
              style: TextStyle(
                fontFamily: AssetsFont.textRegular,
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              child: IntlPhoneField(
                enabled: true,
                controller: textController,
                initialCountryCode: phoneIsoCode,
                dropdownIconPosition: IconPosition.leading,
                autovalidateMode: AutovalidateMode.disabled,
                disableLengthCheck: true,
                style: TextStyle(
                  color: AppColors.mainAppColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
                dropdownTextStyle: TextStyle(
                  color: AppColors.mainAppColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(top: 22, bottom: 20),
                  hintText: loc?.translate('PhoneNumber') ?? 'Phone Number',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 19,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    gapPadding: 5.0,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    gapPadding: 5.0,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.mainAppColor),
                    borderRadius: BorderRadius.circular(12),
                    gapPadding: 5.0,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (phone) {
                  setState(() {
                    phoneNoWithoutCountryCode = phone.number;
                    phoneNoWithCountryCode = phone.completeNumber;
                    phoneIsoCode = phone.countryISOCode;
                    countryCode = phone.countryCode;
                    phoneNumberLength = phone.number.length;
                  });
                },
              ),
            ),
          ],
        ),
        Column(
          children: [
            _buildTermsCheckbox(loc),
            const SizedBox(height: 8),
            SizedBox(
              height: MediaQuery.of(context).size.height / 15,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isButtonEnabled ? continueButtonOnClick : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonEnabled
                      ? AppColors.mainAppColor
                      : AppColors.mainAppColor.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: progress
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        loc?.translate('Next') ?? 'Next',
                        style: const TextStyle(
                          fontFamily: AssetsFont.textBold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox(AppLocalizations? loc) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: WidgetStateBorderSide.resolveWith(
              (states) => BorderSide(width: 1.0, color: AppColors.mainAppColor),
            ),
            value: _agreeChecked,
            checkColor: AppColors.mainAppColor,
            activeColor: Colors.white,
            onChanged: (bool? selected) {
              setState(() {
                _agreeChecked = selected ?? false;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: loc?.translate('Agree') ?? 'I agree to the ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontFamily: AssetsFont.textMedium,
                  ),
                ),
                TextSpan(
                  text:
                      loc?.translate('TermsAndConditions') ??
                      'Terms & Conditions',
                  style: TextStyle(
                    color: AppColors.mainAppColor,
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                    fontFamily: AssetsFont.textBold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      debugPrint(
                        'Open T&C: ${activeApp.termsAndConditionsLink}',
                      );
                    },
                ),
                TextSpan(
                  text: ' ${loc?.translate('And') ?? 'and'} ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontFamily: AssetsFont.textMedium,
                  ),
                ),
                TextSpan(
                  text: loc?.translate('PrivacyPolicy') ?? 'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.mainAppColor,
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                    fontFamily: AssetsFont.textBold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      debugPrint(
                        'Open Privacy: ${activeApp.privacyPolicyLink}',
                      );
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Phase 2: OTP Entry
  // ===========================================================================

  Widget _buildOtpEntryPhase(AppLocalizations? loc) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc?.translate('AlmostDone') ?? 'Almost Done'},',
              style: TextStyle(
                fontFamily: AssetsFont.textBold,
                color: AppColors.mainAppColor,
                fontSize: 24,
              ),
            ),
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    '${loc?.translate('OtpSentTo') ?? 'OTP sent to'} $phoneNoWithoutCountryCode',
                    style: TextStyle(
                      fontFamily: AssetsFont.textRegular,
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: changeNumberOnClick,
                  child: Container(
                    margin: const EdgeInsets.only(left: 5, top: 5.0),
                    child: Text(
                      loc?.translate('Change') ?? 'Change',
                      style: TextStyle(
                        fontFamily: AssetsFont.textRegular,
                        color: AppColors.mainAppColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            PinCodeTextField(
              autoDisposeControllers: false,
              controller: otpTextController,
              keyboardType: TextInputType.phone,
              length: 6,
              obscureText: false,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                borderWidth: 1,
                fieldHeight: 50,
                fieldWidth: 40,
                activeFillColor: Colors.white,
                inactiveColor: Colors.grey.shade200,
                activeColor: AppColors.mainAppColor,
                inactiveFillColor: Colors.white,
                selectedFillColor: Colors.white,
                selectedColor: AppColors.mainAppColor,
              ),
              animationDuration: const Duration(milliseconds: 300),
              enableActiveFill: true,
              onCompleted: (value) {
                setState(() {
                  otpTextController.text = value;
                });
                if (otpTextController.text.isNotEmpty) {
                  FocusScope.of(context).requestFocus(FocusNode());
                  setState(() {
                    progress = true;
                  });
                  if (errorMessage == null) {
                    signIn();
                  } else {
                    saveUserToDBAndNavigate();
                  }
                }
              },
              onChanged: (value) {
                setState(() {});
              },
              beforeTextPaste: (text) => true,
              appContext: context,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    loc?.translate('NotReceivedOtp') ?? 'Not received OTP?',
                    style: TextStyle(
                      fontFamily: AssetsFont.textBold,
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    ' - ',
                    style: TextStyle(
                      fontFamily: AssetsFont.textBold,
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (!progress) resendOTP();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 10.0),
                    child: progress
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.mainAppColor,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            loc?.translate('Resend') ?? 'Resend',
                            style: const TextStyle(
                              fontFamily: AssetsFont.textBold,
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Next button for manual OTP submit
        SizedBox(
          height: MediaQuery.of(context).size.height / 15,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (otpTextController.text.isNotEmpty) {
                FocusScope.of(context).requestFocus(FocusNode());
                setState(() {
                  progress = true;
                });
                if (errorMessage == null) {
                  signIn();
                } else {
                  saveUserToDBAndNavigate();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainAppColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: progress
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    loc?.translate('Next') ?? 'Next',
                    style: const TextStyle(
                      fontFamily: AssetsFont.textBold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Core Logic Methods
  // ===========================================================================

  void continueButtonOnClick() async {
    FocusScope.of(context).requestFocus(FocusNode());
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final phone = textController.text.replaceAll(RegExp(r'[^\d]'), '');

    if (phone.isEmpty) {
      _showSnackBar(
        AppLocalizations.of(context)?.translate('ValidContact') ??
            'Please enter a valid phone number',
      );
      return;
    }

    if (!_agreeChecked) {
      _showSnackBar(
        AppLocalizations.of(context)?.translate('AcceptCondition') ??
            'Please accept the Terms & Conditions',
      );
      return;
    }

    phoneNoWithoutCountryCode = phone;
    phoneNoWithCountryCode = '+$countryCode$phone';

    setState(() {
      progress = true;
    });

    if (errorMessage == null) {
      await verifyPhone();
    } else {
      resendOTP();
    }
  }

  Future<void> verifyPhone() async {
    void autoRetrieve(String verId) {
      verificationId = verId;
    }

    void smsCodeSent(String verId, [int? forceCodeResend]) {
      verificationId = verId;
      setState(() {
        progress = false;
        sendOTPPressed = true;
      });
    }

    void verifiedSuccess(AuthCredential credential) {
      saveUserToDBAndNavigate();
    }

    void verifiedFailed(FirebaseAuthException e) {
      debugPrint('verifyPhone failed: ${e.message}');
      resendOTP();
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNoWithCountryCode!,
      timeout: const Duration(seconds: 10),
      verificationCompleted: verifiedSuccess,
      verificationFailed: verifiedFailed,
      codeSent: smsCodeSent,
      codeAutoRetrievalTimeout: autoRetrieve,
    );
  }

  void signIn() {
    final AuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId!,
      smsCode: otpTextController.text,
    );

    FirebaseAuth.instance
        .signInWithCredential(credential)
        .then((user) async {
          saveUserToDBAndNavigate();
        })
        .catchError((onError) {
          debugPrint('signIn error: $onError');
          if (!mounted) return;
          setState(() {
            progress = false;
            errorMessage =
                AppLocalizations.of(context)?.translate('SmsVerification') ??
                'SMS verification failed';
            otpTextController.text = '';
          });
        });
  }

  Future<void> saveUserToDBAndNavigate() async {
    String url;
    http.Response response;
    Map<String, dynamic> data;

    try {
      if (errorMessage == null) {
        url =
            '${ApiPath.saveOTP}'
            'countryCode=$countryCode'
            '&mobileNumber=${Uri.encodeFull(phoneNoWithoutCountryCode!)}'
            '&deviceToken=${GlobalConstants.firebaseToken}'
            '&deviceId=${GlobalConstants.deviceId}'
            '&deviceType=${GlobalConstants.deviceType}'
            '&version=${GlobalConstants.appVersion}'
            '&packageName=${ThemeUI.appPackageName}'
            '&password=${ThemeUI.appPassword}';
      } else {
        url = Uri.encodeFull(
          '${ApiPath.verifyOTP}'
          'mobileNumber=$phoneNoWithoutCountryCode'
          '&accessToken=${otpTextController.text}'
          '&deviceToken=${GlobalConstants.firebaseToken}'
          '&deviceId=${GlobalConstants.deviceId}'
          '&deviceType=${GlobalConstants.deviceType}'
          '&version=${GlobalConstants.appVersion}'
          '&packageName=${ThemeUI.appPackageName}'
          '&password=${ThemeUI.appPassword}',
        );
      }

      debugPrint('Phone verification URL: $url');

      response = await http.Client()
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      debugPrint('saveUserToDBAndNavigate response: ${response.body}');
      data =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on TimeoutException catch (_) {
      debugPrint('saveUserToDBAndNavigate timeout');
      if (mounted) {
        setState(() {
          progress = false;
        });
        _showSnackBar(
          AppLocalizations.of(context)?.translate('Wrong') ??
              'Request timed out. Please try again.',
        );
      }
      return;
    } catch (e) {
      debugPrint('saveUserToDBAndNavigate exception: $e');
      if (mounted) {
        setState(() {
          progress = false;
          otpTextController.text = '';
        });
        _showSnackBar(
          AppLocalizations.of(context)?.translate('Wrong') ??
              'Something went wrong. Please try again.',
        );
      }
      return;
    }

    if (data['Status'] == 1 && data['Data'] != null) {
      await PreferencesHelper.saveStringPref(
        PreferencesHelper.prefRiderData,
        response.body,
      );
      widget.onLoginSuccess?.call();
    } else {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        setState(() {
          progress = false;
          otpTextController.text = '';
          errorMessage =
              loc?.translate('PasswordNotMatched') ?? 'Verification failed';
        });
        if (data['Status'] == 0) {
          _showSnackBar('${data['Message']}');
        }
      }
    }
  }

  void resendOTP() async {
    setState(() {
      progress = true;
    });

    try {
      final url = Uri.parse(
        '${ApiPath.sendOTP}'
        'mobileNumber=$phoneNoWithoutCountryCode'
        '&version=${GlobalConstants.appVersion}'
        '&isOld=1'
        '&platformId=${GlobalConstants.deviceType}'
        '&hashKey=kX9E8TUfIrN'
        '&countryCode=$countryCode'
        '&packageName=${ThemeUI.appPackageName}'
        '&password=${ThemeUI.appPassword}',
      );

      debugPrint('resendOTP URL: $url');
      final response = await http.Client().get(url);
      debugPrint('resendOTP response: ${response.body}');

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['Status'] == 0) {
        if (mounted) {
          setState(() {
            progress = false;
          });
          _showSnackBar('${data['Message']}');
        }
      } else {
        if (mounted) {
          setState(() {
            progress = false;
            sendOTPPressed = true;
            errorMessage ??= '';
          });
        }
      }
    } catch (e) {
      debugPrint('resendOTP exception: $e');
      if (mounted) {
        setState(() {
          progress = false;
        });
        _showSnackBar(
          AppLocalizations.of(context)?.translate('Wrong') ??
              'Something went wrong. Please try again.',
        );
      }
    }
  }

  void changeNumberOnClick() {
    setState(() {
      otpTextController.text = '';
      progress = false;
      errorMessage = null;
      sendOTPPressed = false;
    });
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
