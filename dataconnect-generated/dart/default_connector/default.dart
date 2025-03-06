// library default_connector;
// import 'package:firebase_data_connect/firebase_data_connect.dart';
// import 'dart:convert';
//
// class DefaultConnector {
//
//
//   static ConnectorConfig connectorConfig = ConnectorConfig(
//     'us-central1',
//     'default',
//     'shivayscreation',
//   );
//
//   DefaultConnector({required this.dataConnect});
//   static DefaultConnector get instance {
//     return DefaultConnector(
//         dataConnect: FirebaseDataConnect.instanceFor(
//             connectorConfig: connectorConfig,
//             sdkType: CallerSDKType.generated));
//   }
//
//   FirebaseDataConnect dataConnect;
// }
//

library;

import 'package:firebase_data_connect/firebase_data_connect.dart';

class DefaultConnector {
  static final ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'default',
    'shivayscreation',
  );

  final FirebaseDataConnect dataConnect;

  // Private Constructor
  DefaultConnector._internal({required this.dataConnect});

  // Singleton Instance
  static final DefaultConnector _instance = DefaultConnector._internal(
    dataConnect: FirebaseDataConnect.instanceFor(
      connectorConfig: connectorConfig,
      sdkType: CallerSDKType.generated,
    ),
  );

  // Getter for Singleton
  static DefaultConnector get instance => _instance;
}
