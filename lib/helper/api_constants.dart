import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {

  static String mainDev = 'dev';

  static String mainLive = 'live';

  ///authentication
  static const double API_VERSION = 1;
  static const String API_MODULE_NAME = 'hcm';
  static const String API_MESSAGE_ID = '';
  static const double API_DID = 1;
  static const String API_KEY = '';
  static const String API_TS = '';

  static String login = '${host}/user/oauth/token';

  static String sendOtp = '/user-otp/v1/_send';
  static String forgotPassword = '${host}/user/password/forgot';
  static String resetPassword = '${host}/user/password/reset';
  static String createRequester = '/egov-hrms/employees/_create';
  static String createCitizen = '/user/citizen/_create';
  static String createHelpdeskUser = '/admin/helpdesk-users/_create';

  static String individualSearch = '/individual/v1/_search';
  static String memberSearch = '/household/member/v1/_search';

  static String createAccount = '';

  static String bookService = '/pgr-services/v2/request/_create';
  static String updateService = '/pgr-services/v2/request/_update';

  static String getCategories = '';

  static String addProperties = '/household/v1/_create';
  static String addHouseholdMember = '/household/member/v1/_create';
  static String addIndividual = '/individual/v1/_create';

  static String getProperties = '';

  static String tenantId = 'mz';

  static String getOrders = '/pgr-services/v2/request/_search';

  static String employeeSearch = '/egov-hrms/employees/_search';

  static String editProfile  = '';

  static String getTenant = '';

  // Host is loaded from .env (API_HOST key)
  // Android emulator  → http://10.0.2.2:8080
  // Real device (WiFi) → http://<your-PC-LAN-IP>:8080
  static String get host => dotenv.env['API_HOST'] ?? 'http://10.0.2.2:8080';
  static String get w3wApiKey => dotenv.env['W3W_API_KEY'] ?? '';
  /// authentication

  static String fileUpload = '/filestore/v1/files';
  static String  fileFetch = '/filestore/v1/files/url';
  static String loginDev = '${host}/user/oauth/token';

  static String loginLive = '${host}/user/oauth/token';

  static String createAccountLive = '${host}/api/v1/tenants/createtenantuser';

  static String createAccountDev = '${host}/api/v1/tenants/createtenantuser';

  static String bookServicesLive = '/pgr-services/v2/request/_create';

  static String bookYourServiceDev = '/pgr-services/v2/request/_create';

  static String getCategoriesLive = '${host}/api/v1/utils/getservicecategory';

  static String addPropertiesLive = '/household/v1/_create';

  static String addPropertiesDev = '/household/v1/_create';

  static String getPropertiesLive = '/household/v1/_search';

  static String getPropertiesDev = '/household/v1/_search';

  static String getOrderLive = '/pgr-services/v2/request/_search';

  static String getOrderDev = '/pgr-services/v2/request/_search';

  static String editProfileDev = '${host}/api/v1/tenants/update';

  static String editProfileLive = '${host}/api/v1/tenants/update';

  static String getTenantDev =  '/user/_search';

  static String getTenantLive =  '/user/_search';
}