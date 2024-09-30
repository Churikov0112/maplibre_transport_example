part of 'models.dart';

enum MobilityType {
  walk,
  bus,
  tram,
  trolley,
  subway,
  suburbanTrain,
  gondola,
  ferry,
  funicular,
  cableCar,
  bikeScooter,
  carpool,
}

extension _MobitityTypeMappers on MobilityType {
  static MobilityType? fromString(String? source) {
    switch (source) {
      case 'BUS':
        return MobilityType.bus;
      case 'TRAM':
        return MobilityType.tram;
      case 'TROLLEY':
        return MobilityType.trolley;
      default:
        return MobilityType.bus;
    }
  }
}
