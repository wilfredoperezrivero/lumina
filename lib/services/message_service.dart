import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

class MessageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all messages for a specific capsule
  static Future<List<Message>> getMessagesForCapsule(String capsuleId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('capsule_id', capsuleId)
          .eq('hidden', false)
          .order('submitted_at', ascending: false);

      return response.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get messages: ${e.toString()}');
    }
  }

  /// Create a new message
  static Future<Message> createMessage({
    required String capsuleId,
    String? contentText,
    String? contentAudioUrl,
    String? contentVideoUrl,
    String? contentImageUrl,
    String? contributorName,
    String? contributorEmail,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .insert({
            'capsule_id': capsuleId,
            'content_text': contentText,
            'content_audio_url': contentAudioUrl,
            'content_video_url': contentVideoUrl,
            'content_image_url': contentImageUrl,
            'contributor_name': contributorName,
            'contributor_email': contributorEmail,
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Message.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create message: ${e.toString()}');
    }
  }

  /// Update a message
  static Future<Message> updateMessage({
    required String messageId,
    String? contentText,
    String? contentAudioUrl,
    String? contentVideoUrl,
    bool? hidden,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (contentText != null) updateData['content_text'] = contentText;
      if (contentAudioUrl != null)
        updateData['content_audio_url'] = contentAudioUrl;
      if (contentVideoUrl != null)
        updateData['content_video_url'] = contentVideoUrl;
      if (hidden != null) updateData['hidden'] = hidden;

      final response = await _supabase
          .from('messages')
          .update(updateData)
          .eq('id', messageId)
          .select()
          .single();

      return Message.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update message: ${e.toString()}');
    }
  }

  /// Delete a message
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('messages').delete().eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  /// Hide a message (soft delete)
  static Future<void> hideMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'hidden': true}).eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to hide message: ${e.toString()}');
    }
  }
}
