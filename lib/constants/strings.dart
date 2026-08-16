// const String baseUrl = 'http://172.20.10.2:8000';

const String baseUrl = 'https://fluent.moayadismail.com';
//
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
const String studentTestRoute = '/student-test';
const String studentHomeRoute = '/student/home';
const String teacherHomeRoute = '/teacher/home';
const String teacherStatsRoute = '/teacher/stats';
const String levelCoursesRoute = '/level-courses';
const String courseLessonsRoute = '/course-lessons';
const String profileRoute = '/profile';
const String wordBankRoute = '/word_bank';
const String podcastsRoute = '/podcasts';
const String aiConversationRoute = '/ai-conversation';
const String levelExceptionsRoute = '/level-exceptions';
const String notificationsRoute = '/notifications';
const String certificatesRoute = '/certificates';
const String contactUsRoute = '/contact-us';

const String questionsListRoute = '/teacher/questions';
const String questionDetailRoute = '/teacher/questions/detail';
const String questionCreateRoute = '/teacher/questions/create';
const String questionEditRoute = '/teacher/questions/edit';
const String questionStatusRoute = '/teacher/questions/status';
const String blockingTestsRoute = '/teacher/questions/blocking-tests';

const String teacherStatusBoardRoute = '/teacher/lessons/statuses';

const String teacherCoursesRoute = '/teacher/courses';

const String teacherCourseDetailRoute = '/teacher/courses/detail';

const String courseTestsRoute = '/teacher/courses/tests';

const String lessonFormRoute = '/teacher/lessons/form';

const String lessonDetailRoute = '/teacher/lessons/detail';

const String apiQuestionsFilter = '/api/questions/filter';

const String apiRegister = '/api/register';
const String apiLogin = '/api/login';
const String apiLogout = '/api/logout';
const String apiCurrentUser = '/api/user';

const String apiGetStudentLevels = '/api/getStudentLevels';

const String testFormRoute = '/teacher/tests/form';

const String testDetailViewRoute = '/teacher/tests/detail-view';
const String lessonStudentDetailRoute = '/lesson-student-detail';

const String apiLevelExceptionsPending = '/api/levelexceptions/pending';
const String apiLevelExceptionsInReview = '/api/levelexceptions/in_review';
const String apiLevelExceptionsRejected = '/api/levelexceptions/rejected';
const String apiLevelExceptionsApproved = '/api/levelexceptions/approved';
const String levelExceptionDetailsRoute = '/level-exception-details';

String apiLevelExceptionDetails(int id) => '/api/levelexceptions/$id/details';

String apiUpdateLevelException(int id) => '/api/levelexceptions/$id/update';

String apiCreateLevelException(int levelId) =>
    '/api/levelexceptions/$levelId/create';

String apiDeleteLevelException(int id) => '/api/levelexceptions/$id/delete';

String apiDeleteLevelExceptionAttachment(int exceptionId, int mediaId) =>
    '/api/level-exceptions/$exceptionId/attachments/$mediaId';

const String apiWordsBankLearning = '/api/words_bank/learning';
const String apiWordsBankKnow = '/api/words_bank/know';

String apiLessonWords(int lessonId) => '/api/words/$lessonId/lesson';

String apiWordToLearning(int wordId) => '/api/words/$wordId/learning';
String apiWordToKnow(int wordId) => '/api/words/$wordId/know';

const String apiWordsQuiz = '/api/words/quiz';
String apiWordQuizCheck(int wordId) => '/api/words/$wordId/quiz_check';

String apiRateCourse(int courseId) => '/api/rate/$courseId';
String apiDeleteRate(int rateId) => '/api/rate/$rateId/delete';

const String apiStudentProfile = '/api/student/profile';
const String apiStudentWeeklyActivity = '/api/student/weeklyActivity';
const String apiTeacherProfile = '/api/teacher/profile';

const String apiPlacementTestStatus = '/api/placement-test/status';

const String apiStartPlacementTest = '/api/startPlacementTest';
String apiTestStart(int testId) => '/api/tests/$testId/start';

String apiAttemptSubmitAnswer(int attemptId, int questionId) =>
    '/api/attempts/$attemptId/questions/$questionId/submit-answer';

String apiAttemptFinish(int attemptId) => '/api/attempts/$attemptId/finish';

String apiAttemptLeave(int attemptId) => '/api/attempts/$attemptId/leave';

String apiAttemptReview(int attemptId) => '/api/attempts/$attemptId/review';

String apiGetStudentCourses(int levelId) => '/api/getStudentcourses/$levelId';

String apiGetStudentLessons(int courseId) => '/api/lessons/$courseId';

String apiLessonDetail(int lessonId) => '/api/lessons/$lessonId/detail';

String apiCreateComment(int lessonId) => '/api/comments/$lessonId';

String apiUpdateComment(int commentId) => '/api/comments/$commentId/update';

String apiDeleteComment(int commentId) => '/api/comments/$commentId/delete';

const String apiPodcastTopics = '/api/podcasts/topics';
String apiTopicPodcasts(int topicId) => '/api/podcasts/$topicId';

const String topicPodcastsRoute = '/topic-podcasts';

String apiOpenPodcast(int podcastId) => '/api/podcasts/$podcastId/open';

String apiPodcastDetails(int podcastId) => '/api/podcasts/$podcastId/details';
const String podcastDetailRoute = '/podcast-detail';

String apiCreatePaymentIntent(int id) => '/api/payments/$id/create-intent';
String apiPaymentStatus(String paymentIntentId) =>
    '/api/payments/$paymentIntentId/status';

const String stripePublishableKey =
    'pk_test_51U0JM13hGKhXKNjRobR8Fgo98Nh3dDcFFG103DNbmOnT4NiJturB1HWRINQKQFZEWN85CMH3uf1h5Q1LK3ojrx5x00N4JQ5PR8';

const String apiQuestions = '/api/questions';
const String apiDeprecatedQuestions = '/api/questions/deprecated';
String apiQuestionDetail(int id) => '/api/questions/$id';
String apiQuestionCheckStatus(int id) => '/api/questions/$id/checkStatus';
String apiQuestionDelete(int id) => '/api/questions/$id/delete';
String apiQuestionBlockingTests(int id) => '/api/questions/$id/blocking-tests';

const String apiGetTeacherCourses = '/api/getTeacherCourses';
String apiLessonUpdate(int lessonId) => '/api/lessons/$lessonId/update';

String apiVerifyOtp(String type) => '/api/verifyOtp/$type';
String apiResendOtp(String type) => '/api/resendOtp/$type';

String apiTeacherLessons(int courseId) => '/api/lessons/$courseId/teacher';

String apiLessonDetails(int lessonId) => '/api/lessons/$lessonId/details';

String apiTestDetail(int id) => '/api/tests/$id';

String apiCreateLesson(int courseId) => '/api/lessons/$courseId';

const String apiTests = '/api/tests';

const String apiForgotPassword = '/api/forgotPassword';
const String apiResetPassword = '/api/resetPassword';

String apiCreateWord(int lessonId) => '/api/words/$lessonId/create';
String apiUpdateWord(int wordId) => '/api/words/$wordId/update';
String apiDeleteWord(int wordId) => '/api/words/$wordId/delete';

String apiSubmitLesson(int lessonId) => '/api/lessons/$lessonId/submit';
String apiResubmitLesson(int lessonId) => '/api/lessons/$lessonId/resubmit';
String apiSubmitTest(int testId) => '/api/tests/$testId/submit';
String apiResubmitTest(int testId) => '/api/tests/$testId/resubmit';
String apiLessonReviewHistory(int lessonId) => '/api/lessons/$lessonId/history';
String apiTestReviewHistory(int testId) => '/api/tests/$testId/history';

String apiCourseStats(int courseId) => '/api/courses/$courseId/stats';
String apiTestStats(int testId) => '/api/tests/$testId/stats';

const String apiFirebaseToken = '/api/firebase/token';
const String apiNotifications = '/api/notifications';
const String apiNotificationsUnread = '/api/notifications/unread';
const String apiNotificationsUnreadCount = '/api/notifications/unreadcount';
String apiNotificationMarkAsRead(String notificationId) =>
    '/api/notifications/$notificationId/markAsRead';
const String apiNotificationsMarkAllAsRead = '/api/notifications/markAllAsRead';
String apiNotificationDelete(String notificationId) =>
    '/api/notifications/$notificationId/delete';

const String apiChatActiveSession = '/api/chat/sessions/active';
const String apiChatSessions = '/api/chat/sessions';
const String apiChatHistory = '/api/chat/sessions/history';
const String apiChatTopics = '/api/chat/topics';

String apiChatSendMessage(int sessionId) =>
    '/api/chat/sessions/$sessionId/messages';

String apiChatEndSession(int sessionId) => '/api/chat/sessions/$sessionId/end';

String apiChatSessionDetails(int sessionId) => '/api/chat/sessions/$sessionId';

String apiCourseProgress(int courseId) => '/api/courses/$courseId/progress';

String apiLevelProgress(int levelId) => '/api/levels/$levelId/progress';

const String apiCertificates = '/api/certificates';

String apiUserLevelCertificate(int userLevelId) =>
    '/api/user-levels/$userLevelId/certificate';

const String apiContactUs = '/api/contact-us';

class OtpType {
  static const String register = 'register';
  static const String forgotPassword = 'forgot_password';
}
