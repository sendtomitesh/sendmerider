import 'package:flutter/material.dart';

/// Change this single line to switch between rider app brands
AppConfig activeApp = sendmeRider;
// AppConfig activeApp = eatozRider;
// AppConfig activeApp = sendme6Rider;
// AppConfig activeApp = hopshopRider;
// AppConfig activeApp = tyebRider;
// AppConfig activeApp = sendmeLebanonRider;
// AppConfig activeApp = sendmeTalabetakRider;
// AppConfig activeApp = sendmeShrirampurRider;

/// ########################################################################

/// SENDME RIDER APP
const AppConfig sendmeRider = AppConfig(
  id: 'sendme_rider',
  name: 'SendMe Rider',
  color: Color(0xff29458E),
  packageName: 'today.sendme',
  packagePassword: 'SMWL2022',
  domainName: 'cp-rider.sendme.today',
  termsAndConditionsLink:
      'https://s3.ap-south-1.amazonaws.com/web.sendme.today.in/terms.html',
  privacyPolicyLink:
      'https://s3.ap-south-1.amazonaws.com/web.sendme.today.in/privacypolicy.html',
  whatsappLink: 'https://wa.me/message/TGZLSZYVYVSVC1',
  appType: 2,
  androidAppLink:
      'https://play.google.com/store/apps/details?id=today.sendme.rider',
  iosAppLink: 'https://apps.apple.com/us/app/id1279244554',
  deepLink: 'https://deeplink.sendme.today',
  email: 'rider@sendme.today',
  androidBundle: 'today.sendme.rider',
  iosBundle: 'com.vs2.sendmerider',
  iosAppStoreId: '1279244554',
  urlLink: 'https://sendme.today?',
);

/// EATOZ RIDER APP
const AppConfig eatozRider = AppConfig(
  id: 'eatoz_rider',
  name: 'Eatoz Rider',
  color: Color(0xff1982C4),
  packageName: 'today.eatoz',
  packagePassword: 'SMWL2023@eatoz',
  domainName: 'cp-eatoz.sendme.today',
  termsAndConditionsLink:
      'https://s3.ap-south-1.amazonaws.com/web.sendme.today.in/terms.html',
  privacyPolicyLink:
      'https://s3.ap-south-1.amazonaws.com/web.sendme.today.in/privacypolicy.html',
  whatsappLink: '',
  appType: 2,
  androidAppLink: '',
  iosAppLink: '',
  deepLink: 'https://eatozfood.page.link',
  email: '',
  androidBundle: 'today.eatoz.rider',
  iosBundle: 'today.eatoz.rider',
  iosAppStoreId: '',
  urlLink: 'https://eatoz.in?',
);

/// SENDME6 RIDER APP
const AppConfig sendme6Rider = AppConfig(
  id: 'sendme6_rider',
  name: 'SendMe6 Rider',
  color: Color(0xff1982C4),
  packageName: 'today.sendme6',
  packagePassword: 'SMWL2023@SendMe6',
  domainName: 'cp-sendme6.sendme.today',
  termsAndConditionsLink:
      'https://s3.ap-south-1.amazonaws.com/web.sendme.today.in/terms.html',
  privacyPolicyLink:
      'https://s3.ap-south-1.amazonaws.com/web.sendme.today.in/privacypolicy.html',
  whatsappLink: '',
  appType: 2,
  androidAppLink: '',
  iosAppLink: '',
  deepLink: '',
  email: '',
  androidBundle: 'today.sendme6.rider',
  iosBundle: 'today.sendme6.rider',
  iosAppStoreId: '',
  urlLink: '',
);

/// HOPSHOP RIDER APP
const AppConfig hopshopRider = AppConfig(
  id: 'hopshop_rider',
  name: 'Hopshop Rider',
  color: Color(0xffF97C38),
  packageName: 'today.hopshop',
  packagePassword: 'SMWL2023@Hopshop',
  domainName: 'cp.hopshop.app',
  termsAndConditionsLink:
      'https://sendme-images.s3.ap-south-1.amazonaws.com/WhiteLabel/hopshop87383/terms.html',
  privacyPolicyLink:
      'https://sendme-images.s3.ap-south-1.amazonaws.com/WhiteLabel/hopshop87383/privacy.html',
  whatsappLink: 'https://wa.me/96171487383',
  appType: 2,
  androidAppLink:
      'https://play.google.com/store/apps/details?id=today.hopshop.rider',
  iosAppLink: 'https://apps.apple.com/us/app/id6448111466',
  deepLink: 'https://hopshop.page.link',
  email: 'info@mediavision.mobi',
  androidBundle: 'today.hopshop.rider',
  iosBundle: 'today.hopshop.rider',
  iosAppStoreId: '6448111466',
  urlLink: 'https://hopshop.app?',
);

/// TYEB RIDER APP
const AppConfig tyebRider = AppConfig(
  id: 'tyeb_rider',
  name: 'Tyeb Rider',
  color: Color(0xff000000),
  packageName: 'today.tyeb',
  packagePassword: 'SMWL2023@Tyeb',
  domainName: 'cp-tyeb.sendme.today',
  termsAndConditionsLink:
      'https://sendme-images.s3.ap-south-1.amazonaws.com/WhiteLabel/tyeb/index.html?myParam=tc',
  privacyPolicyLink:
      'https://sendme-images.s3.ap-south-1.amazonaws.com/WhiteLabel/tyeb/index.html?myParam=privacy',
  whatsappLink: 'link',
  appType: 2,
  androidAppLink:
      'https://play.google.com/store/apps/details?id=today.tyeb.rider',
  iosAppLink: 'https://apps.apple.com/us/app/',
  deepLink: '',
  email: 'sendmeapplicationlb@gmail.com',
  androidBundle: 'today.tyeb.rider',
  iosBundle: 'today.tyeb.rider',
  iosAppStoreId: '',
  urlLink: '',
);

/// SENDME LEBANON RIDER APP
const AppConfig sendmeLebanonRider = AppConfig(
  id: 'sendme_lebanon_rider',
  name: 'SendMe Lebanon Rider',
  color: Color(0xff1982C4),
  packageName: 'today.sendmelebanondev',
  packagePassword: 'SMWL2023@SendMeLebanonDev',
  domainName: 'cp-lebanondev.sendme.today',
  termsAndConditionsLink:
      'https://s3.ap-south-1.amazonaws.com/web.sendme.today.in/terms.html',
  privacyPolicyLink:
      'https://s3.ap-south-1.amazonaws.com/web.sendme.today.in/privacypolicy.html',
  whatsappLink: '',
  appType: 2,
  androidAppLink: '',
  iosAppLink: 'https://apps.apple.com/us/app/id6670752907',
  deepLink: '',
  email: '',
  androidBundle: 'today.sendmelebanon.rider',
  iosBundle: 'today.sendmelebanon.rider',
  iosAppStoreId: '6670752907',
  urlLink: '',
);

/// SENDME TALABETAK RIDER APP
const AppConfig sendmeTalabetakRider = AppConfig(
  id: 'sendme_talabetak_rider',
  name: 'SendMe Talabetak Rider',
  color: Color(0xfff74747),
  packageName: 'today.talabetak',
  packagePassword: 'SMWL2023@Talabetak',
  domainName: 'talabetak.sendme.today',
  termsAndConditionsLink:
      'https://s3.ap-south-1.amazonaws.com/web.sendme.today.in/terms.html',
  privacyPolicyLink:
      'https://s3.ap-south-1.amazonaws.com/web.sendme.today.in/privacypolicy.html',
  whatsappLink: '',
  appType: 2,
  androidAppLink: '',
  iosAppLink: '',
  deepLink: '',
  email: '',
  androidBundle: 'today.talabetak.rider',
  iosBundle: 'today.talabetak.rider',
  iosAppStoreId: '',
  urlLink: '',
);

/// SENDME SHRIRAMPUR RIDER APP
const AppConfig sendmeShrirampurRider = AppConfig(
  id: 'sendme_shrirampur_rider',
  name: 'SendMe Shrirampur Rider',
  color: Color(0xff29458E),
  packageName: 'today.sendmeshrirampur',
  packagePassword: 'SMWL2023@SendMeShrirampur',
  domainName: 'cp-sendmeshrirampur.sendme.today',
  termsAndConditionsLink:
      'https://sendme-images.s3.ap-south-1.amazonaws.com/WhiteLabel/shrirampur/terms.html',
  privacyPolicyLink:
      'https://sendme-images.s3.ap-south-1.amazonaws.com/WhiteLabel/shrirampur/privacy.html',
  whatsappLink: 'https://wa.me/919011794508',
  appType: 2,
  androidAppLink:
      'https://play.google.com/store/apps/details?id=today.sendmeshrirampur.rider',
  iosAppLink: 'https://apps.apple.com/us/app/id6447060680',
  deepLink: 'https://sendmeshrirampur.page.link',
  email: 'sendme.shrirampur@gmail.com',
  androidBundle: 'today.sendmeshrirampur.rider',
  iosBundle: 'today.sendmeshrirampur.rider',
  iosAppStoreId: '6447060680',
  urlLink: 'https://sendme.today?',
);

/// ########################################################################

/// List of all brand instances for iteration in tests
const List<AppConfig> allBrandInstances = [
  sendmeRider,
  eatozRider,
  sendme6Rider,
  hopshopRider,
  tyebRider,
  sendmeLebanonRider,
  sendmeTalabetakRider,
  sendmeShrirampurRider,
];

/// ########################################################################

class AppConfig {
  final String id;
  final String name;
  final Color color;
  final String packageName;
  final String packagePassword;
  final String domainName;
  final String termsAndConditionsLink;
  final String privacyPolicyLink;
  final String whatsappLink;
  final int appType;
  final String androidAppLink;
  final String iosAppLink;
  final String deepLink;
  final String email;
  final String androidBundle;
  final String iosBundle;
  final String iosAppStoreId;
  final String urlLink;

  const AppConfig({
    required this.id,
    required this.name,
    required this.color,
    required this.packageName,
    required this.packagePassword,
    required this.domainName,
    required this.termsAndConditionsLink,
    required this.privacyPolicyLink,
    required this.whatsappLink,
    required this.appType,
    required this.androidAppLink,
    required this.iosAppLink,
    required this.deepLink,
    required this.email,
    required this.androidBundle,
    required this.iosBundle,
    required this.iosAppStoreId,
    required this.urlLink,
  });
}
