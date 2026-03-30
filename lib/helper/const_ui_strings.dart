class ConstUiStrings {

  static const String welcomeBack = 'Welcome Back';

  static const String plotRol = 'PLOTROL';

  static const String signInToContinue = 'Sign in to Continue';
  static const String logInToContinue = 'Log in to Continue';

  static const String passwordInfo = 'Note:';
  static const String passwordDescription = 'Password should contain';

  static const String newUserChooseAction = 'Welcome! Let’s Get You Signed In';

  static const String termsAndPrivacy = 'I agree to the Terms of Service & ';

  static const String privacyPolicy = 'Privacy Policy';

  static const String enterPhoneNumber = 'Enter Phone Number';

  static const String enterName = 'Enter your name';

  static const String enterUserNameForYourAccount = 'Enter username for your account';

  static const String enterUserName = 'Enter Username / Mobile Number';
  static const String enterPassword = 'Enter Password';
  static const String confirmPassword = 'Confirm Password';

  static const String continueText = 'Continue';
  static const String loginAsRequester = 'Sign In as a Requester';
  static const String newUserSignUp = 'New User ?   Sign Up  →';
  static const String login = 'Existing user ?  Login  →';
  static const String loginAsEmployee = 'Sign In as an Employee';

  static const String didNtReceiveCode = "Didn't receive the code? ";

  static const String resendAgain = 'Resend Again';

  static const String verify = 'Verify';

  static const String verification = 'Verification';

  static const String otpVerificationText = 'Please enter your 6 digit One-Time-Password';

  static const List<String> getIntroScreenText = [
    // "Precise Property Measuring",
    // "Landscaping and Outdoor Care",
    "Inspection and Reporting",
  ];

  static const List<String> getIntroScreenDescription = [
    "Accurate measurements for renovation projects, interior design, and more.",
    "Tailored solutions for garden and outdoor space maintenance to enhance your property's exterior appeal.",
    "Detailed inspections and reports to help you stay informed about the condition of your property.",
  ];

  static const List<dynamic> getComplaintTypes = [
    {
      "name": "Other",
      "order": 1,
      "active": true,
      "keywords": "other",
      "menuPath": "Sync",
      "slaHours": 336,
      "department": "OTHER",
      "serviceCode": "Other"
    },
    {
      "name": "Performance Issue",
      "order": 1,
      "active": true,
      "keywords": "performance",
      "menuPath": "Sync",
      "slaHours": 336,
      "department": "eGov",
      "serviceCode": "PerformanceIssue"
    },
    {
      "name": "Security Issues",
      "order": 1,
      "active": true,
      "keywords": "security",
      "menuPath": "Sync",
      "slaHours": 336,
      "department": "eGov",
      "serviceCode": "SecurityIssues"
    },
    {
      "name": "Data Issues",
      "order": 1,
      "active": true,
      "keywords": "data",
      "menuPath": "Sync",
      "slaHours": 336,
      "department": "eGov",
      "serviceCode": "DataIssues"
    },
    {
      "name": "User Account Issues",
      "order": 1,
      "active": true,
      "keywords": "user, account",
      "menuPath": "Sync",
      "slaHours": 336,
      "department": "eGov",
      "serviceCode": "UserAccountIssues"
    },
    {
      "name": "Technical Issues",
      "order": 1,
      "active": true,
      "keywords": "technical, tech",
      "menuPath": "Sync",
      "slaHours": 336,
      "department": "eGov",
      "serviceCode": "TechnicalIssues"
    }
  ];
}