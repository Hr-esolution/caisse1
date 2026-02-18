class AppSettings {
  String currencyCode;
  String currencySymbol;
  String? appLogoPath;
  String? ticketLogoPath;

  AppSettings({
    this.currencyCode = 'MAD',
    this.currencySymbol = 'DH',
    this.appLogoPath,
    this.ticketLogoPath,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      currencyCode: (json['currency_code'] ?? 'MAD').toString(),
      currencySymbol: (json['currency_symbol'] ?? 'DH').toString(),
      appLogoPath: json['app_logo_path']?.toString(),
      ticketLogoPath: json['ticket_logo_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'currency_code': currencyCode,
    'currency_symbol': currencySymbol,
    'app_logo_path': appLogoPath,
    'ticket_logo_path': ticketLogoPath,
  };
}
