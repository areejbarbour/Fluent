 //const String baseUrl = 'http://192.168.1.5:8000';
//const String baseUrl = 'http://192.168.10.224:8000';
//const String baseUrl = 'http://172.20.10.2:8000';
const String baseUrl = 'https://fluent.moayadismail.com';

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
const String levelExceptionsRoute = '/level-exceptions';

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

// ✅ Level Exception API
const String apiLevelExceptionsPending = '/api/levelexceptions/pending';
const String apiLevelExceptionsInReview = '/api/levelexceptions/in_review';
const String apiLevelExceptionsRejected = '/api/levelexceptions/rejected';
const String apiLevelExceptionsApproved = '/api/levelexceptions/approved';
const String levelExceptionDetailsRoute = '/level-exception-details';

String apiLevelExceptionDetails(int id) => '/api/levelexceptions/$id/details';

// update Exception
String apiUpdateLevelException(int id) => '/api/levelexceptions/$id/update';

// create Exception
String apiCreateLevelException(int levelId) =>
    '/api/levelexceptions/$levelId/create';

// delete Exception
String apiDeleteLevelException(int id) => '/api/levelexceptions/$id/delete';

String apiDeleteLevelExceptionAttachment(int exceptionId, int mediaId) =>
    '/api/level-exceptions/$exceptionId/attachments/$mediaId';

// ✅ Student Word Bank API
const String apiWordsBankLearning = '/api/words_bank/learning';
const String apiWordsBankKnow = '/api/words_bank/know';

// ✅ Lesson Words API
String apiLessonWords(int lessonId) => '/api/words/$lessonId/lesson';

// ✅ Update word status (student)
String apiWordToLearning(int wordId) => '/api/words/$wordId/learning';
String apiWordToKnow(int wordId) => '/api/words/$wordId/know';

// ✅ Student Word Quiz API
const String apiWordsQuiz = '/api/words/quiz';
String apiWordQuizCheck(int wordId) => '/api/words/$wordId/quiz_check';

// ✅ Student Rate API (course must be completed — backend RateServiece)
String apiRateCourse(int courseId) => '/api/rate/$courseId';
String apiDeleteRate(int rateId) => '/api/rate/$rateId/delete';

// ✅ Course API
String apiGetStudentCourses(int levelId) => '/api/getStudentcourses/$levelId';

// ✅ Student Lessons API
String apiGetStudentLessons(int courseId) => '/api/lessons/$courseId';

// ✅ Lesson Detail API
String apiLessonDetail(int lessonId) => '/api/lessons/$lessonId/detail';

// ✅ Create Lesson Comment API
String apiCreateComment(int lessonId) => '/api/comments/$lessonId';

// ✅ Update Lesson Comment API
String apiUpdateComment(int commentId) => '/api/comments/$commentId/update';

// ✅ Delete Lesson Comment API
String apiDeleteComment(int commentId) => '/api/comments/$commentId/delete';

// ✅ Student Podcast API
const String apiPodcastTopics = '/api/podcasts/topics';
String apiTopicPodcasts(int topicId) => '/api/podcasts/$topicId';

// ✅ Podcast detail route
const String topicPodcastsRoute = '/topic-podcasts';

// ✅ Open (purchase) podcast with points
String apiOpenPodcast(int podcastId) => '/api/podcasts/$podcastId/open';

// ✅ Podcast detail
String apiPodcastDetails(int podcastId) => '/api/podcasts/$podcastId/details';
const String podcastDetailRoute = '/podcast-detail';

// ✅ Payment API
String apiCreatePaymentIntent(int id) => '/api/payments/$id/create-intent';
String apiPaymentStatus(String paymentIntentId) =>
    '/api/payments/$paymentIntentId/status';

// Stripe publishable key (test)
const String stripePublishableKey =
    'pk_test_51U0JM13hGKhXKNjRobR8Fgo98Nh3dDcFFG103DNbmOnT4NiJturB1HWRINQKQFZEWN85CMH3uf1h5Q1LK3ojrx5x00N4JQ5PR8';

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

// ✅ Teacher Word API Endpoints
String apiCreateWord(int lessonId) => '/api/words/$lessonId/create';
String apiUpdateWord(int wordId) => '/api/words/$wordId/update';
String apiDeleteWord(int wordId) => '/api/words/$wordId/delete';

// ✅ OTP Types
class OtpType {
  static const String register = 'register';
  static const String forgotPassword = 'forgot_password';
}
