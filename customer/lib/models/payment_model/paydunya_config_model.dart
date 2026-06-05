class PaydunyaConfigModel {
  bool isEnabled;
  String mode;

  PaydunyaConfigModel({this.isEnabled = false, this.mode = 'sandbox'});

  factory PaydunyaConfigModel.fromJson(Map<String, dynamic> json) {
    final raw = json['isEnabled'] ?? json['isEnable'] ?? json['is_enabled'] ?? json['enabled'] ?? false;
    final isEnabled = raw == true || raw == 1 || raw == '1' || raw == 'true';
    final mode = json['mode']?.toString() ?? (json['sandbox'] == true ? 'sandbox' : 'live');
    return PaydunyaConfigModel(
      isEnabled: false, // temporairement désactivé — remplacer par isEnabled pour réactiver
      mode: mode,
    );
  }
}
