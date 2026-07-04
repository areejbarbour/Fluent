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
const String placementTestRoute = '/placement-test';
const String studentHomeRoute = '/student/home';
const String teacherHomeRoute = '/teacher/home';
const String levelCoursesRoute = '/level-courses';
// Add this
// ✅ API Endpoints
const String apiRegister = '/api/register';
const String apiLogin = '/api/login';
const String apiLogout = '/api/logout';
const String apiCurrentUser = '/api/user';

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
