//  const String baseUrl = 'http://192.168.1.7:8000';
const String baseUrl = 'http://192.168.10.224:8000';
// const String baseUrl = 'http://172.20.10.2:8000';

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
const String teacherHomeRoute = '/teacher/home';
const String levelCoursesRoute = '/level-courses';
const String courseLessonsRoute = '/course-lessons';
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

// ✅ Teacher Lesson routes
const String teacherStatusBoardRoute = '/teacher/lessons/statuses';

// ✅ Teacher Courses routes
const String teacherCoursesRoute = '/teacher/courses';

// ✅ Teacher Course Detail route
const String teacherCourseDetailRoute = '/teacher/courses/detail';

// ✅ Course Tests Screen Route
const String courseTestsRoute = '/teacher/courses/tests';

// ✅ Lesson Form Route
const String lessonFormRoute = '/teacher/lessons/form';

const String lessonDetailRoute = '/teacher/lessons/detail';

// ✅ Question Filter API Endpoint
const String apiQuestionsFilter = '/api/questions/filter';

// ✅ API Endpoints
const String apiRegister = '/api/register';
const String apiLogin = '/api/login';
const String apiLogout = '/api/logout';
const String apiCurrentUser = '/api/user';

// ✅ Level API
const String apiGetStudentLevels = '/api/getStudentLevels';

const String testFormRoute = '/teacher/tests/form';

const String testDetailViewRoute = '/teacher/tests/detail-view';
const String lessonStudentDetailRoute = '/lesson-student-detail';

// ✅ Course API
String apiGetStudentCourses(int levelId) => '/api/getStudentcourses/$levelId';

// ✅ Student Lessons API
String apiGetStudentLessons(int courseId) => '/api/lessons/$courseId';

// ✅ Lesson Detail API
String apiLessonDetail(int lessonId) => '/api/lessons/$lessonId/detail';

// ✅ Question API Endpoints
const String apiQuestions = '/api/questions';
const String apiDeprecatedQuestions = '/api/questions/deprecated';
String apiQuestionDetail(int id) => '/api/questions/$id';
String apiQuestionCheckStatus(int id) => '/api/questions/$id/checkStatus';
String apiQuestionDelete(int id) => '/api/questions/$id/delete';
String apiQuestionBlockingTests(int id) => '/api/questions/$id/blocking-tests';

// ✅ Teacher Lesson API Endpoints
const String apiGetTeacherCourses = '/api/getTeacherCourses';
//String apiTeacherLessons(int courseId) => '/api/lessons/$courseId';
String apiLessonUpdate(int lessonId) => '/api/lessons/$lessonId/update';

// ✅ OTP Endpoints - Dynamic with type parameter
String apiVerifyOtp(String type) => '/api/verifyOtp/$type';
String apiResendOtp(String type) => '/api/resendOtp/$type';

// دروس الكورس (جديد)
String apiTeacherLessons(int courseId) => '/api/lessons/$courseId/teacher';

// تفاصيل درس (جديد)
String apiLessonDetails(int lessonId) => '/api/lessons/$lessonId/details';

String apiTestDetail(int id) => '/api/tests/$id';

// إنشاء درس
String apiCreateLesson(int courseId) => '/api/lessons/$courseId';

// كل الاختبارات (جديد)
const String apiTests = '/api/tests';

// ✅ Forgot/Reset Password Endpoints
const String apiForgotPassword = '/api/forgotPassword';
const String apiResetPassword = '/api/resetPassword';

// ✅ OTP Types
class OtpType {
  static const String register = 'register';
  static const String forgotPassword = 'forgot_password';
}
