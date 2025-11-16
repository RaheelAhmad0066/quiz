import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/question_model.dart';

/// Gemini Service - Generates random MCQs using Google Gemini AI
class GeminiService {
  // Gemini API key
  static const String _apiKey = 'AIzaSyAwUG6ZECAiS6Xm7MD_7DsCdA6XIpJsVds';
  
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-flash-latest', // Using gemini-flash-latest
      apiKey: _apiKey,
    );
  }

  /// Generate random MCQs based on topic/category
  Future<List<QuestionModel>> generateMCQs({
    required String topic,
    int count = 10,
    String? category,
  }) async {
    // Try with retry mechanism
    int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        final prompt = _buildPrompt(topic, count, category);
        
        // Add timeout to prevent hanging
        final response = await _model.generateContent([Content.text(prompt)])
            .timeout(
              Duration(seconds: 30),
              onTimeout: () {
                throw Exception('Request timeout - No internet connection');
              },
            );
        
        final text = response.text ?? '';
        
        if (text.isEmpty) {
          throw Exception('Empty response from Gemini API');
        }
        
        // Parse the response to extract questions
        final questions = _parseQuestions(text, topic, count);
        
        if (questions.isNotEmpty && questions.length >= count) {
          return questions;
        }
        
        // If we got some questions but not enough, use fallback for the rest
        if (questions.isNotEmpty) {
          final remaining = count - questions.length;
          questions.addAll(_generateFallbackQuestions(topic, remaining));
          return questions;
        }
        
        // If parsing failed, throw to trigger retry or fallback
        throw Exception('Failed to parse questions from response');
        
      } catch (e) {
        retryCount++;
        final errorMessage = e.toString().toLowerCase();
        
        // Check if it's a network error
        if (errorMessage.contains('socketexception') || 
            errorMessage.contains('failed host lookup') ||
            errorMessage.contains('network') ||
            errorMessage.contains('timeout') ||
            errorMessage.contains('connection')) {
          print('⚠️ Network error generating MCQs (attempt $retryCount/$maxRetries): $e');
          
          // If it's the last retry, use fallback
          if (retryCount >= maxRetries) {
            print('⚠️ Using fallback questions due to network error');
            return _generateFallbackQuestions(topic, count);
          }
          
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }
        
        // For other errors, log and use fallback
        print('❌ Error generating MCQs: $e');
        if (retryCount >= maxRetries) {
          print('⚠️ Using fallback questions due to error');
          return _generateFallbackQuestions(topic, count);
        }
        
        // Wait before retrying
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
    
    // If all retries failed, return fallback questions
    print('⚠️ All retries failed, using fallback questions');
    return _generateFallbackQuestions(topic, count);
  }

  String _buildPrompt(String topic, int count, String? category) {
    return '''
Generate $count multiple choice questions (MCQs) about "$topic"${category != null ? ' in the category "$category"' : ''}.

Requirements:
- Each question should have exactly 4 options (A, B, C, D)
- One option must be correct
- Questions should be technical and educational
- Format each question as JSON with this structure:
{
  "question": "Question text here?",
  "options": ["Option A", "Option B", "Option C", "Option D"],
  "correctAnswerIndex": 0,
  "explanation": "Brief explanation of the correct answer"
}

Return ONLY a JSON array of questions, no additional text. Example format:
[
  {
    "question": "What is...?",
    "options": ["A", "B", "C", "D"],
    "correctAnswerIndex": 0,
    "explanation": "Explanation"
  }
]
''';
  }

  List<QuestionModel> _parseQuestions(String response, String topic, int count) {
    try {
      // Try to extract JSON from response
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        // If JSON not found, generate fallback questions
        return _generateFallbackQuestions(topic, count);
      }
      
      final jsonString = response.substring(jsonStart, jsonEnd);
      
      // Parse JSON and create QuestionModel objects
      // Note: jsonDecode is from dart:convert which is always available
      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      final questions = <QuestionModel>[];
      
      for (int i = 0; i < jsonList.length && i < count; i++) {
        final item = jsonList[i] as Map<String, dynamic>;
        questions.add(QuestionModel(
          id: 'gemini_${topic}_${DateTime.now().millisecondsSinceEpoch}_$i',
          testId: 'gemini_test',
          question: item['question'] as String? ?? 'Question ${i + 1}',
          options: List<String>.from(item['options'] as List? ?? []),
          correctAnswerIndex: item['correctAnswerIndex'] as int? ?? 0,
          explanation: item['explanation'] as String?,
        ));
      }
      
      // If we got less than required, fill with fallback
      if (questions.length < count) {
        questions.addAll(_generateFallbackQuestions(topic, count - questions.length));
      }
      
      return questions;
    } catch (e) {
      print('Error parsing questions: $e');
      return _generateFallbackQuestions(topic, count);
    }
  }

  /// Generate fallback questions if Gemini API fails
  List<QuestionModel> _generateFallbackQuestions(String topic, int count) {
    final questions = <QuestionModel>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Generate more realistic fallback questions based on topic
    final topicQuestions = _getTopicBasedQuestions(topic);
    
    for (int i = 0; i < count; i++) {
      final questionIndex = i % topicQuestions.length;
      final baseQuestion = topicQuestions[questionIndex];
      
      questions.add(QuestionModel(
        id: 'fallback_${topic}_${timestamp}_$i',
        testId: 'fallback_test',
        question: (baseQuestion['question'] as String).replaceAll('{topic}', topic),
        options: baseQuestion['options'] as List<String>,
        correctAnswerIndex: baseQuestion['correctIndex'] as int,
        explanation: (baseQuestion['explanation'] as String).replaceAll('{topic}', topic),
      ));
    }
    
    return questions;
  }
  
  /// Get topic-based question templates for fallback
  List<Map<String, dynamic>> _getTopicBasedQuestions(String topic) {
    return [
      {
        'question': 'What is the main concept of {topic}?',
        'options': [
          'The fundamental principle of {topic}',
          'A basic understanding of {topic}',
          'An advanced technique in {topic}',
          'A related topic to {topic}',
        ],
        'correctIndex': 0,
        'explanation': 'The main concept refers to the fundamental principle of {topic}.',
      },
      {
        'question': 'Which of the following is most important in {topic}?',
        'options': [
          'Understanding core concepts',
          'Memorizing facts',
          'Following procedures',
          'Using tools',
        ],
        'correctIndex': 0,
        'explanation': 'Understanding core concepts is most important in {topic}.',
      },
      {
        'question': 'What is a key feature of {topic}?',
        'options': [
          'Its practical applications',
          'Its historical background',
          'Its theoretical framework',
          'All of the above',
        ],
        'correctIndex': 3,
        'explanation': 'All options are key features of {topic}.',
      },
      {
        'question': 'How does {topic} relate to real-world scenarios?',
        'options': [
          'Through practical examples',
          'Through theoretical models',
          'Through case studies',
          'All of the above',
        ],
        'correctIndex': 3,
        'explanation': '{topic} relates to real-world scenarios through multiple approaches.',
      },
      {
        'question': 'What is the primary purpose of studying {topic}?',
        'options': [
          'To gain knowledge and skills',
          'To pass exams',
          'To complete assignments',
          'To get grades',
        ],
        'correctIndex': 0,
        'explanation': 'The primary purpose of studying {topic} is to gain knowledge and skills.',
      },
      {
        'question': 'Which method is commonly used in {topic}?',
        'options': [
          'Systematic approach',
          'Random selection',
          'Trial and error',
          'Guessing',
        ],
        'correctIndex': 0,
        'explanation': 'A systematic approach is commonly used in {topic}.',
      },
      {
        'question': 'What makes {topic} effective?',
        'options': [
          'Proper understanding and application',
          'Quick memorization',
          'Avoiding practice',
          'Ignoring details',
        ],
        'correctIndex': 0,
        'explanation': 'Proper understanding and application makes {topic} effective.',
      },
      {
        'question': 'What is essential for mastering {topic}?',
        'options': [
          'Consistent practice and study',
          'Occasional review',
          'Last-minute preparation',
          'Avoiding practice',
        ],
        'correctIndex': 0,
        'explanation': 'Consistent practice and study is essential for mastering {topic}.',
      },
      {
        'question': 'Which factor contributes most to success in {topic}?',
        'options': [
          'Dedication and effort',
          'Natural talent alone',
          'Avoiding challenges',
          'Minimal involvement',
        ],
        'correctIndex': 0,
        'explanation': 'Dedication and effort contributes most to success in {topic}.',
      },
      {
        'question': 'What should be prioritized when learning {topic}?',
        'options': [
          'Building strong foundations',
          'Skipping basics',
          'Focusing only on advanced topics',
          'Avoiding fundamentals',
        ],
        'correctIndex': 0,
        'explanation': 'Building strong foundations should be prioritized when learning {topic}.',
      },
    ];
  }
}

