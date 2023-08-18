import 'package:equatable/equatable.dart';

/// Class used to get partial Billing Information
class PartialBillingInformation extends Equatable {
  /// Billing address: First line address
  final String? address1;
  /// Billing address: Second line address
  final String? address2;
  /// Billing card type
  final String? cardType;
  /// Billing address: city
  final String? city;
  /// Billing address: country
  final String? country;
  /// Credit card: First name
  final String? firstName;
  /// Credit card: Last four digits
  final String? lastFour;
  /// Credit card: Last name
  final String? lastName;
  /// Billing address: state
  final String? state;
  /// Billing address: zip or postal code
  final String? zip;
  /// Credit card: expiration month
  final int? month;
  /// Credit card: expiration year
  final int? year;

  PartialBillingInformation.fromJson(Map<String, dynamic> json)
      : address1 = json['address1'],
        address2 = json['address2'],
        cardType = json['cardType'],
        city = json['city'],
        country = json['country'],
        firstName = json['firstName'],
        lastFour = json['lastFour'],
        lastName = json['lastName'],
        state = json['state'],
        zip = json['zip'],
        month = json['month'],
        year = json['year'];

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        address1,
        address2,
        city,
        country,
        state,
        zip,
        cardType,
        lastFour,
        month,
        year,
      ];

  @override
  bool get stringify => true;
}
