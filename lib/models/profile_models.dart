import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

enum AccountCategory {
  individual,
  business,
  medical,
  educational,
  charity,
  government,
}

enum AccountSubType {
  none,
  // Business
  company,
  cafe,
  restaurant,
  shop,
  supermarket,
  hotel,
  salon,
  // Medical
  hospital,
  clinic,
  pharmacy,
  healthCenter,
  lab,
  // Educational
  school,
  university,
  trainingCenter,
  // Charity & Gov
  charityOrganization,
  governmentEntity,
  freelancer,
}

extension AccountCategoryExtension on AccountCategory {
  String get label {
    switch (this) {
      case AccountCategory.individual:
        return 'حساب أفراد';
      case AccountCategory.business:
        return 'أعمال تجارية';
      case AccountCategory.medical:
        return 'رعاية صحية';
      case AccountCategory.educational:
        return 'مؤسسات تعليمية';
      case AccountCategory.charity:
        return 'جهات غير ربحية';
      case AccountCategory.government:
        return 'أخرى / حكومية';
    }
  }

  String get description {
    switch (this) {
      case AccountCategory.individual:
        return 'حساب شخصي للأفراد العاديين';
      case AccountCategory.business:
        return 'شركات، كافيهات، مطاعم، متاجر';
      case AccountCategory.medical:
        return 'مستشفيات، صيدليات، مراكز وعيادات';
      case AccountCategory.educational:
        return 'مدارس، جامعات، مراكز تدريب';
      case AccountCategory.charity:
        return 'جمعيات خيرية ومنظمات مجتمع';
      case AccountCategory.government:
        return 'جهات حكومية أو أعمال حرة';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountCategory.individual:
        return SolarIconsOutline.user;
      case AccountCategory.business:
        return SolarIconsOutline.shop;
      case AccountCategory.medical:
        return SolarIconsOutline.heartPulse;
      case AccountCategory.educational:
        return SolarIconsOutline.diploma;
      case AccountCategory.charity:
        return SolarIconsOutline.handHeart;
      case AccountCategory.government:
        return SolarIconsOutline.global;
    }
  }
}

extension AccountSubTypeExtension on AccountSubType {
  String get label {
    switch (this) {
      case AccountSubType.none:
        return 'بدون تحديد';
      case AccountSubType.company:
        return 'شركة';
      case AccountSubType.cafe:
        return 'كافية';
      case AccountSubType.restaurant:
        return 'مطعم';
      case AccountSubType.shop:
        return 'متجر / محل';
      case AccountSubType.supermarket:
        return 'سوبر ماركت';
      case AccountSubType.hotel:
        return 'فندق';
      case AccountSubType.salon:
        return 'صالون';
      case AccountSubType.hospital:
        return 'مستشفى';
      case AccountSubType.clinic:
        return 'عيادة طبية';
      case AccountSubType.pharmacy:
        return 'صيدلية';
      case AccountSubType.healthCenter:
        return 'مركز صحي';
      case AccountSubType.lab:
        return 'مختبر طبي';
      case AccountSubType.school:
        return 'مدرسة';
      case AccountSubType.university:
        return 'جامعة';
      case AccountSubType.trainingCenter:
        return 'مركز تدريب';
      case AccountSubType.charityOrganization:
        return 'جمعية خيرية';
      case AccountSubType.governmentEntity:
        return 'جهة حكومية';
      case AccountSubType.freelancer:
        return 'عمل حر (مستقل)';
    }
  }
}

// Temporary Models for UI State (No DB mapping yet)
class RegisterFormData {
  AccountCategory category = AccountCategory.individual;
  AccountSubType subType = AccountSubType.none;
  
  // Common
  String phone = '';
  String email = '';
  String password = '';

  // Individual
  String fullName = '';

  // Entity
  String entityName = '';
  String commercialRegister = '';
  String address = '';
  String managerName = '';

  // Files (Store paths)
  String? logoPath;
  String? documentPath;
}
