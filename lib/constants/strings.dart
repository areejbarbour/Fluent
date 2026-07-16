// const String baseUrl = 'http://10.0.0.2:8000';
const String baseUrl = 'http://172.20.10.2:8000';

// ✅ Routes
const String onboardingRoute = '/';
const String loginRoute = '/login';
const String registerRoute = '/register';
const String otpRoute = '/otp';
const String forgotPasswordRoute = '/forgot-password';
const String resetPasswordRoute = '/reset-password';
const String setNewPasswordRoute = '/set-new-password';
const String homeRoute = '/home';
const String streakRoute = '/streak';
const String placementTestDialogRoute = '/placement-test-dialog';
const String placementTestRoute = '/placement-test';
const String studentHomeRoute = '/student/home';
//const String teacherHomeRoute = '/teacher/home';
const String levelCoursesRoute = '/level-courses';
const String profileRoute = '/profile';
const String wordBankRoute = '/word_bank';
const String podcastsRoute = '/podcasts';          
const String aiConversationRoute = '/ai-conversation'; 



// ✅ Teacher Question routes
const String questionsListRoute = '/teacher/questions';
const String questionDetailRoute = '/teacher/questions/detail';
const String questionCreateRoute = '/teacher/questions/create';
const String questionEditRoute = '/teacher/questions/edit';
const String questionStatusRoute = '/teacher/questions/status';
const String blockingTestsRoute = '/teacher/questions/blocking-tests';

// Add this
// ✅ API Endpoints
const String apiRegister = '/api/register';
const String apiLogin = '/api/login';
const String apiLogout = '/api/logout';
const String apiCurrentUser = '/api/user';

// ✅ Question API Endpoints
const String apiQuestions = '/api/questions';
const String apiDeprecatedQuestions = '/api/questions/deprecated';
String apiQuestionDetail(int id) => '/api/questions/$id';
String apiQuestionCheckStatus(int id) => '/api/questions/$id/checkStatus';
String apiQuestionDelete(int id) => '/api/questions/$id/delete';
String apiQuestionBlockingTests(int id) => '/api/questions/$id/blocking-tests';

// ✅ OTP Endpoints - Dynamic with type parameter
String apiVerifyOtp(String type) => '/api/verifyOtp/$type';
String apiResendOtp(String type) => '/api/resendOtp/$type';

// ✅ Forgot/Reset Password Endpoints
const String apiForgotPassword = '/api/forgotPassword';
const String apiResetPassword = '/api/resetPassword';

// ✅ OTP Types
class OtpType {
  static const String register = 'register';
  static const String forgotPassword = 'forgot_password';
}
