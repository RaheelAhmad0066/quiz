import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import '../models/category_model.dart';
import '../models/topic_model.dart';
import '../models/test_model.dart';
import '../models/question_model.dart';
import '../app_widgets/app_toast.dart';
import 'leaderboard_controller.dart';

class QuizController extends GetxController {
  DatabaseReference? _databaseRef;
  
  DatabaseReference? get databaseRef {
    if (_databaseRef == null) {
      try {
        if (Firebase.apps.isNotEmpty) {
          _databaseRef = FirebaseDatabase.instance.ref();
        } else {
          print('Firebase apps is empty');
          return null;
        }
      } catch (e) {
        print('Firebase Database not initialized: $e');
        return null;
      }
    }
    return _databaseRef;
  }
  
  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty && _databaseRef != null;
    } catch (e) {
      return false;
    }
  }

  // Observable Lists
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<TopicModel> topics = <TopicModel>[].obs;
  final RxList<TestModel> tests = <TestModel>[].obs;
  final RxList<QuestionModel> questions = <QuestionModel>[].obs;

  // Selected Values
  final RxString selectedCategory = ''.obs;
  final RxString selectedTopicId = ''.obs;
  final RxString selectedTestId = ''.obs;
  final RxInt currentQuestionIndex = 0.obs;
  final RxMap<int, int?> selectedAnswers = <int, int?>{}.obs; // questionIndex -> selectedOptionIndex
  final RxMap<int, bool> answeredQuestions = <int, bool>{}.obs; // questionIndex -> isAnswered

  // Loading States
  final RxBool isLoadingCategories = false.obs;
  final RxBool isLoadingTopics = false.obs;
  final RxBool isLoadingTests = false.obs;
  final RxBool isLoadingQuestions = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    // Initialize Firebase Database reference
    if (Firebase.apps.isNotEmpty) {
      try {
        _databaseRef = FirebaseDatabase.instance.ref();
        loadCategories();
      } catch (e) {
        print('Error initializing Firebase Database: $e');
      }
    } else {
      print('Firebase not initialized yet');
    }
  }

  // Load Categories
  Future<void> loadCategories() async {
    if (!isFirebaseAvailable) {
      print('Firebase not available');
      return;
    }
    
    try {
      isLoadingCategories.value = true;
      
      print('Loading categories from Firebase...');
      
      // Load from categories node (categories are stored as key-value pairs where value is category name)
      final dbRef = databaseRef;
      if (dbRef == null) {
        print('Database reference is null');
        categories.clear();
        return;
      }
      final categoriesSnapshot = await dbRef.child('categories').get();
      
      if (categoriesSnapshot.exists) {
        final snapshotValue = categoriesSnapshot.value;
        print('Categories snapshot value type: ${snapshotValue.runtimeType}');
        
        if (snapshotValue is Map<dynamic, dynamic>) {
          final data = snapshotValue;
          print('Found ${data.length} categories in Firebase');
          
          categories.value = data.entries.map((entry) {
            // In Firebase, categories are stored as: key (Firebase ID) -> value (category name string)
            final categoryName = entry.value?.toString() ?? '';
            
            return CategoryModel(
              id: entry.key.toString(),
              name: categoryName.isNotEmpty ? categoryName : entry.key.toString(),
            );
          }).toList();
          
          // Sort categories alphabetically
          categories.sort((a, b) => a.name.compareTo(b.name));
          
          print('Successfully loaded ${categories.length} categories');
        } else {
          print('Categories snapshot value is not a Map');
          categories.clear();
        }
      } else {
        print('Categories node does not exist in Firebase');
        categories.clear();
        AppToast.showCustomToast(
          'No Categories',
          'No categories found. Please create categories in admin panel.',
          type: ToastType.info,
        );
      }
    } catch (e, stackTrace) {
      print('Error loading categories: $e');
      print('Stack trace: $stackTrace');
      AppToast.showCustomToast(
        'Error',
        'Failed to load categories: ${e.toString()}',
        type: ToastType.error,
      );
      categories.clear();
    } finally {
      isLoadingCategories.value = false;
    }
  }

  // Load Topics by Category
  Future<void> loadTopicsByCategory(String category) async {
    if (!isFirebaseAvailable) {
      print('Firebase not available for loading topics');
      AppToast.showCustomToast(
        'Error',
        'Firebase is not available',
        type: ToastType.error,
      );
      return;
    }
    
    try {
      isLoadingTopics.value = true;
      selectedCategory.value = category;

      print('Loading topics for category: $category');

      final dbRef = databaseRef;
      if (dbRef == null) {
        print('Database reference is null');
        topics.clear();
        return;
      }
      final snapshot = await dbRef
          .child('topics')
          .orderByChild('category')
          .equalTo(category)
          .get();

      print('Snapshot exists: ${snapshot.exists}');

      if (snapshot.exists) {
        final snapshotValue = snapshot.value;
        print('Snapshot value type: ${snapshotValue.runtimeType}');
        
        if (snapshotValue is Map<dynamic, dynamic>) {
          final data = snapshotValue;
          print('Found ${data.length} topics in Firebase');
          
          final loadedTopics = data.entries.map((entry) {
            if (entry.value is Map<dynamic, dynamic>) {
              try {
                return TopicModel.fromJson(
                  Map<String, dynamic>.from(entry.value),
                  entry.key.toString(),
                );
              } catch (e) {
                print('Error parsing topic ${entry.key}: $e');
                return null;
              }
            }
            return null;
          }).whereType<TopicModel>().toList();
          
          print('Successfully loaded ${loadedTopics.length} topics');
          topics.value = loadedTopics;
          
          if (loadedTopics.isEmpty) {
            AppToast.showCustomToast(
              'No Topics',
              'No topics found for this category',
              type: ToastType.info,
            );
          }
        } else {
          print('Snapshot value is not a Map, it is: ${snapshotValue.runtimeType}');
          topics.clear();
        }
      } else {
        print('No topics found in Firebase for category: $category');
        topics.clear();
        AppToast.showCustomToast(
          'No Topics',
          'No topics found for this category. Please create topics in admin panel.',
          type: ToastType.info,
        );
      }
    } catch (e, stackTrace) {
      print('Error loading topics: $e');
      print('Stack trace: $stackTrace');
      AppToast.showCustomToast(
        'Error',
        'Failed to load topics: ${e.toString()}',
        type: ToastType.error,
      );
      topics.clear();
    } finally {
      isLoadingTopics.value = false;
    }
  }

  // Load Tests by Category (all topics in category)
  Future<void> loadTestsByCategory(String category) async {
    if (!isFirebaseAvailable) {
      print('Firebase not available');
      return;
    }
    
    try {
      isLoadingTests.value = true;
      selectedCategory.value = category;

      // First load all topics for this category
      await loadTopicsByCategory(category);

      print('Loaded ${topics.length} topics for category: $category');

      // Then load all tests for all topics in this category
      final allTests = <TestModel>[];
      final dbRef = databaseRef;
      if (dbRef == null) {
        print('Database reference is null');
        tests.clear();
        return;
      }
      
      for (var topic in topics) {
        print('Loading tests for topic: ${topic.name} (${topic.id})');
        final snapshot = await dbRef
            .child('tests')
            .orderByChild('topicId')
            .equalTo(topic.id)
            .get();

        if (snapshot.exists) {
          final snapshotValue = snapshot.value;
          if (snapshotValue is Map<dynamic, dynamic>) {
            final data = snapshotValue;
            final topicTests = data.entries.map((entry) {
              if (entry.value is Map<dynamic, dynamic>) {
                return TestModel.fromJson(
                  Map<String, dynamic>.from(entry.value),
                  entry.key.toString(),
                );
              }
              return null;
            }).whereType<TestModel>().toList();
            print('Found ${topicTests.length} tests for topic: ${topic.name}');
            allTests.addAll(topicTests);
          }
        } else {
          print('No tests found for topic: ${topic.name}');
        }
      }

      print('Total tests loaded: ${allTests.length}');
      tests.value = allTests;
      
      if (allTests.isEmpty) {
        AppToast.showCustomToast(
          'No Tests',
          'No tests available for this category. Please create tests in admin panel.',
          type: ToastType.info,
        );
      }
    } catch (e, stackTrace) {
      print('Error loading tests: $e');
      print('Stack trace: $stackTrace');
      AppToast.showCustomToast(
        'Error',
        'Failed to load tests: ${e.toString()}',
        type: ToastType.error,
      );
    } finally {
      isLoadingTests.value = false;
    }
  }

  // Load Tests by Topic
  Future<void> loadTestsByTopic(String topicId) async {
    if (!isFirebaseAvailable) return;
    
    try {
      isLoadingTests.value = true;
      selectedTopicId.value = topicId;

      final dbRef = databaseRef;
      if (dbRef == null) {
        print('Database reference is null');
        tests.clear();
        return;
      }
      
      final snapshot = await dbRef
          .child('tests')
          .orderByChild('topicId')
          .equalTo(topicId)
          .get();

      if (snapshot.exists) {
        final snapshotValue = snapshot.value;
        if (snapshotValue is Map<dynamic, dynamic>) {
          final data = snapshotValue;
          tests.value = data.entries.map((entry) {
            if (entry.value is Map<dynamic, dynamic>) {
              return TestModel.fromJson(
                Map<String, dynamic>.from(entry.value),
                entry.key.toString(),
              );
            }
            return null;
          }).whereType<TestModel>().toList();
        } else {
          tests.clear();
        }
      } else {
        tests.clear();
      }
    } catch (e) {
      print('Error loading tests: $e');
    } finally {
      isLoadingTests.value = false;
    }
  }

  // Load Questions by Test
  Future<void> loadQuestionsByTest(String testId) async {
    if (!isFirebaseAvailable) return;
    
    try {
      isLoadingQuestions.value = true;
      selectedTestId.value = testId;
      currentQuestionIndex.value = 0;
      selectedAnswers.clear();
      answeredQuestions.clear();

      final dbRef = databaseRef;
      if (dbRef == null) {
        print('Database reference is null');
        questions.clear();
        return;
      }
      
      final snapshot = await dbRef
          .child('questions')
          .orderByChild('testId')
          .equalTo(testId)
          .get();

      if (snapshot.exists) {
        final snapshotValue = snapshot.value;
        if (snapshotValue is Map<dynamic, dynamic>) {
          final data = snapshotValue;
          questions.value = data.entries.map((entry) {
            if (entry.value is Map<dynamic, dynamic>) {
              return QuestionModel.fromJson(
                Map<String, dynamic>.from(entry.value),
                entry.key.toString(),
              );
            }
            return null;
          }).whereType<QuestionModel>().toList();
        } else {
          questions.clear();
        }
      } else {
        questions.clear();
      }
    } catch (e) {
      print('Error loading questions: $e');
    } finally {
      isLoadingQuestions.value = false;
    }
  }

  // Select Answer
  void selectAnswer(int questionIndex, int optionIndex) {
    selectedAnswers[questionIndex] = optionIndex;
    answeredQuestions[questionIndex] = true;
  }

  // Check if answer is correct
  bool isAnswerCorrect(int questionIndex) {
    if (questions.isEmpty || questionIndex >= questions.length) return false;
    final question = questions[questionIndex];
    final selectedAnswer = selectedAnswers[questionIndex];
    return selectedAnswer == question.correctAnswerIndex;
  }

  // Get selected answer index
  int? getSelectedAnswer(int questionIndex) {
    return selectedAnswers[questionIndex];
  }

  // Check if question is answered
  bool isQuestionAnswered(int questionIndex) {
    return answeredQuestions[questionIndex] ?? false;
  }

  // Navigate to next question
  void nextQuestion() {
    if (currentQuestionIndex.value < questions.length - 1) {
      currentQuestionIndex.value++;
    }
  }

  // Navigate to previous question
  void previousQuestion() {
    if (currentQuestionIndex.value > 0) {
      currentQuestionIndex.value--;
    }
  }

  // Navigate to specific question
  void goToQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      currentQuestionIndex.value = index;
    }
  }

  // Get current question
  QuestionModel? getCurrentQuestion() {
    if (questions.isEmpty || currentQuestionIndex.value >= questions.length) {
      return null;
    }
    return questions[currentQuestionIndex.value];
  }

  // Get total questions count
  int getTotalQuestions() {
    return questions.length;
  }

  // Get answered questions count
  int getAnsweredCount() {
    return answeredQuestions.length;
  }

  // Calculate quiz score and update leaderboard
  Future<Map<String, dynamic>> submitQuizResults() async {
    if (questions.isEmpty) {
      return {
        'correctAnswers': 0,
        'totalQuestions': 0,
        'totalPoints': 0,
        'testPassed': false,
      };
    }

    int correctAnswers = 0;
    int totalQuestions = questions.length;

    // Count correct answers
    for (int i = 0; i < totalQuestions; i++) {
      if (isAnswerCorrect(i)) {
        correctAnswers++;
      }
    }

    // Calculate score (points per correct answer)
    int pointsPerQuestion = 10;
    int totalPoints = correctAnswers * pointsPerQuestion;

    // Check if test passed (at least 60% correct)
    double passPercentage = 0.6;
    bool testPassed = (correctAnswers / totalQuestions) >= passPercentage;

    // Update leaderboard
    try {
      final leaderboardController = Get.isRegistered<LeaderboardController>()
          ? Get.find<LeaderboardController>()
          : Get.put(LeaderboardController());

      await leaderboardController.updateUserScore(
        points: totalPoints,
        testPassed: testPassed,
      );
    } catch (e) {
      print('Error updating leaderboard: $e');
    }

    return {
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'totalPoints': totalPoints,
      'testPassed': testPassed,
    };
  }

  // Get test count for a topic
  Future<int> getTestCountForTopic(String topicId) async {
    if (!isFirebaseAvailable) return 0;
    
    try {
      final dbRef = databaseRef;
      if (dbRef == null) return 0;
      
      final snapshot = await dbRef
          .child('tests')
          .orderByChild('topicId')
          .equalTo(topicId)
          .get();

      if (snapshot.exists) {
        final snapshotValue = snapshot.value;
        if (snapshotValue is Map<dynamic, dynamic>) {
          return snapshotValue.length;
        }
      }
      return 0;
    } catch (e) {
      print('Error getting test count: $e');
      return 0;
    }
  }

  // Get selected topic name
  String getSelectedTopicName() {
    if (selectedTopicId.value.isEmpty) return '';
    try {
      final topic = topics.firstWhere((t) => t.id == selectedTopicId.value);
      return topic.name;
    } catch (e) {
      return '';
    }
  }

  // Check if topic has questions (through its tests)
  Future<bool> topicHasQuestions(String topicId) async {
    if (!isFirebaseAvailable) return false;
    
    try {
      final dbRef = databaseRef;
      if (dbRef == null) return false;
      
      // First get all tests for this topic
      final testsSnapshot = await dbRef
          .child('tests')
          .orderByChild('topicId')
          .equalTo(topicId)
          .get();

      if (!testsSnapshot.exists) return false;

      final testsValue = testsSnapshot.value;
      if (testsValue is! Map<dynamic, dynamic>) return false;

      // Check if any test has questions
      for (var testEntry in testsValue.entries) {
        final testId = testEntry.key.toString();
        
        // Check if this test has questions
        final questionsSnapshot = await dbRef
            .child('questions')
            .orderByChild('testId')
            .equalTo(testId)
            .get();

        if (questionsSnapshot.exists) {
          final questionsValue = questionsSnapshot.value;
          if (questionsValue is Map<dynamic, dynamic> && questionsValue.isNotEmpty) {
            return true; // Found at least one question
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking if topic has questions: $e');
      return false;
    }
  }
}

