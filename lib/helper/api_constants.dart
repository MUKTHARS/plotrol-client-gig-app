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
  static String createRequester = '/egov-hrms/employees/_create';
  static String createCitizen = '/user/citizen/_create';

  static String individualSearch = '/individual/v1/_search';
  static String memberSearch = '/household/member/v1/_search';

  static String createAccount = '${host}/api/v1/tenants/createtenantuser';

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

  // Local Go backend
  // Android emulator → 10.0.2.2 maps to your PC's localhost
  // Real device on same Wi-Fi → replace with your PC's local IP, e.g. http://192.168.1.x:8080
  static String host = 'http://localhost:8080';
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