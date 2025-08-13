// lib/services/chat/whatsapp_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../core/config/environment.dart';
import '../../core/utils/logger.dart';
import '../../core/errors/exceptions.dart';
import '../../data/models/user/user_model.dart';

/// WhatsApp Business API service for bot functionality
class WhatsAppService {
  final String _phoneNumberId;
  final String _accessToken;
  final String _webhookVerifyToken;
  final http.Client _httpClient;
  final Logger _logger;
  
  static const String _baseUrl = 'https://graph.facebook.com/v18.0';
  
  WhatsAppService({
    required String phoneNumberId,
    required String accessToken,
    required String webhookVerifyToken,
    required http.Client httpClient,
    required Logger logger,
  }) : _phoneNumberId = phoneNumberId,
       _accessToken = accessToken,
       _webhookVerifyToken = webhookVerifyToken,
       _httpClient = httpClient,
       _logger = logger;

  /// Verify webhook for initial setup
  bool verifyWebhook({
    required String mode,
    required String token,
    required String challenge,
  }) {
    if (mode == 'subscribe' && token == _webhookVerifyToken) {
      _logger.info('WhatsApp webhook verified successfully');
      return true;
    }
    
    _logger.warning('WhatsApp webhook verification failed');
    return false;
  }

  /// Send text message
  Future<WhatsAppMessageResponse> sendTextMessage({
    required String to,
    required String message,
    String? replyToMessageId,
  }) async {
    try {
      _logger.info('Sending WhatsApp text message to: $to');
      
      final messageData = {
        'messaging_product': 'whatsapp',
        'recipient_type': 'individual',
        'to': to,
        'type': 'text',
        'text': {
          'body': message,
        },
      };
      
      if (replyToMessageId != null) {
        messageData['context'] = {
          'message_id': replyToMessageId,
        };
      }

      final response = await _makeWhatsAppRequest(
        'POST',
        '/$_phoneNumberId/messages',
        body: messageData,
      );

      return WhatsAppMessageResponse.fromJson(response);
      
    } catch (e) {
      _logger.error('Failed to send WhatsApp text message: $e');
      throw WhatsAppException('Failed to send message');
    }
  }

  /// Send template message
  Future<WhatsAppMessageResponse> sendTemplateMessage({
    required String to,
    required String templateName,
    required String languageCode,
    List<TemplateComponent>? components,
  }) async {
    try {
      _logger.info('Sending WhatsApp template message: $templateName to $to');
      
      final messageData = {
        'messaging_product': 'whatsapp',
        'recipient_type': 'individual',
        'to': to,
        'type': 'template',
        'template': {
          'name': templateName,
          'language': {
            'code': languageCode,
          },
          if (components != null && components.isNotEmpty)
            'components': components.map((c) => c.toJson()).toList(),
        },
      };

      final response = await _makeWhatsAppRequest(
        'POST',
        '/$_phoneNumberId/messages',
        body: messageData,
      );

      return WhatsAppMessageResponse.fromJson(response);
      
    } catch (e) {
  _logger.error('Failed to send WhatsApp template message: $e');
      throw WhatsAppException('Failed to send template message');
    }
  }

  /// Send image message
  Future<WhatsAppMessageResponse> sendImageMessage({
    required String to,
    required String imageUrl,
    String? caption,
    String? replyToMessageId,
  }) async {
    try {
      _logger.info('Sending WhatsApp image message to: $to');
      
      final messageData = {
        'messaging_product': 'whatsapp',
        'recipient_type': 'individual',
        'to': to,
        'type': 'image',
        'image': {
          'link': imageUrl,
          if (caption != null) 'caption': caption,
        },
      };
      
      if (replyToMessageId != null) {
        messageData['context'] = {
          'message_id': replyToMessageId,
        };
      }

      final response = await _makeWhatsAppRequest(
        'POST',
        '/$_phoneNumberId/messages',
        body: messageData,
      );

      return WhatsAppMessageResponse.fromJson(response);
      
    } catch (e) {
      _logger.error('Failed to send WhatsApp image message: $e');
      throw WhatsAppException('Failed to send image');
    }
  }

  /// Send document message
  Future<WhatsAppMessageResponse> sendDocumentMessage({
    required String to,
    required String documentUrl,
    required String filename,
    String? caption,
    String? replyToMessageId,
  }) async {
    try {
      _logger.info('Sending WhatsApp document message to: $to');
      
      final messageData = {
        'messaging_product': 'whatsapp',
        'recipient_type': 'individual',
        'to': to,
        'type': 'document',
        'document': {
          'link': documentUrl,
          'filename': filename,
          if (caption != null) 'caption': caption,
        },
      };
      
      if (replyToMessageId != null) {
        messageData['context'] = {
          'message_id': replyToMessageId,
        };
      }

      final response = await _makeWhatsAppRequest(
        'POST',
        '/$_phoneNumberId/messages',
        body: messageData,
      );

      return WhatsAppMessageResponse.fromJson(response);
      
    } catch (e) {
      _logger.error('Failed to send WhatsApp document message: $e');
      throw WhatsAppException('Failed to send document');
    }
  }

  /// Send interactive message with buttons
  Future<WhatsAppMessageResponse> sendInteractiveMessage({
    required String to,
    required String bodyText,
    String? headerText,
    String? footerText,
    required List<InteractiveButton> buttons,
    String? replyToMessageId,
  }) async {
    try {
      _logger.info('Sending WhatsApp interactive message to: $to');
      
      final messageData = {
        'messaging_product': 'whatsapp',
        'recipient_type': 'individual',
        'to': to,
        'type': 'interactive',
        'interactive': {
          'type': 'button',
          'body': {
            'text': bodyText,
          },
          if (headerText != null)
            'header': {
              'type': 'text',
              'text': headerText,
            },
          if (footerText != null)
            'footer': {
              'text': footerText,
            },
          'action': {
            'buttons': buttons.map((b) => b.toJson()).toList(),
          },
        },
      };
      
      if (replyToMessageId != null) {
        messageData['context'] = {
          'message_id': replyToMessageId,
        };
      }

      final response = await _makeWhatsAppRequest(
        'POST',
        '/$_phoneNumberId/messages',
        body: messageData,
      );

      return WhatsAppMessageResponse.fromJson(response);
      
    } catch (e) {
      _logger.error('Failed to send WhatsApp interactive message: $e');
      throw WhatsAppException('Failed to send interactive message');
    }
  }

  /// Send list message
  Future<WhatsAppMessageResponse> sendListMessage({
    required String to,
    required String bodyText,
    required String buttonText,
    String? headerText,
    String? footerText,
    required List<ListSection> sections,
    String? replyToMessageId,
  }) async {
    try {
      _logger.info('Sending WhatsApp list message to: $to');
      
      final messageData = {
        'messaging_product': 'whatsapp',
        'recipient_type': 'individual',
        'to': to,
        'type': 'interactive',
        'interactive': {
          'type': 'list',
          'body': {
            'text': bodyText,
          },
          if (headerText != null)
            'header': {
              'type': 'text',
              'text': headerText,
            },
          if (footerText != null)
            'footer': {
              'text': footerText,
            },
          'action': {
            'button': buttonText,
            'sections': sections.map((s) => s.toJson()).toList(),
          },
        },
      };
      
      if (replyToMessageId != null) {
        messageData['context'] = {
          'message_id': replyToMessageId,
        };
      }

      final response = await _makeWhatsAppRequest(
        'POST',
        '/$_phoneNumberId/messages',
        body: messageData,
      );

      return WhatsAppMessageResponse.fromJson(response);
      
    } catch (e) {
      _logger.error('Failed to send WhatsApp list message: $e');
      throw WhatsAppException('Failed to send list message');
    }
  }

  /// Upload media and get media ID
  Future<String> uploadMedia({
    required File mediaFile,
    required String mediaType,
  }) async {
    try {
      _logger.info('Uploading media to WhatsApp: ${mediaFile.path}');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/$_phoneNumberId/media'),
      );
      
      request.headers['Authorization'] = 'Bearer $_accessToken';
      
      request.fields['messaging_product'] = 'whatsapp';
      request.fields['type'] = mediaType;
      
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        mediaFile.path,
        filename: path.basename(mediaFile.path),
      );
      
      request.files.add(multipartFile);
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode != 200) {
        throw WhatsAppException('Failed to upload media: $responseBody');
      }
      
      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
      final mediaId = responseData['id'] as String;
      
      _logger.info('Media uploaded successfully: $mediaId');
      return mediaId;
      
    } catch (e) {
      _logger.error('Failed to upload media to WhatsApp: $e');
      throw WhatsAppException('Failed to upload media');
    }
  }

  /// Send media message using media ID
  Future<WhatsAppMessageResponse> sendMediaMessage({
    required String to,
    required String mediaId,
    required String mediaType,
    String? caption,
    String? replyToMessageId,
  }) async {
    try {
      _logger.info('Sending WhatsApp media message to: $to');
      
      final messageData = {
        'messaging_product': 'whatsapp',
        'recipient_type': 'individual',
        'to': to,
        'type': mediaType,
        mediaType: {
          'id': mediaId,
          if (caption != null) 'caption': caption,
        },
      };
      
      if (replyToMessageId != null) {
        messageData['context'] = {
          'message_id': replyToMessageId,
        };
      }

      final response = await _makeWhatsAppRequest(
        'POST',
        '/$_phoneNumberId/messages',
        body: messageData,
      );

      return WhatsAppMessageResponse.fromJson(response);
      
    } catch (e) {
      _logger.error('Failed to send WhatsApp media message: $e');
      throw WhatsAppException('Failed to send media message');
    }
  }

  /// Download media from WhatsApp
  Future<Uint8List> downloadMedia(String mediaId) async {
    try {
      _logger.info('Downloading media from WhatsApp: $mediaId');
      
      // First, get media URL
      final mediaInfo = await _makeWhatsAppRequest('GET', '/$mediaId');
      final mediaUrl = mediaInfo['url'] as String;
      
      // Download media
      final response = await _httpClient.get(
        Uri.parse(mediaUrl),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
      
      if (response.statusCode != 200) {
        throw WhatsAppException('Failed to download media');
      }
      
      return response.bodyBytes;
      
    } catch (e) {
      _logger.error('Failed to download media from WhatsApp: $e');
      throw WhatsAppException('Failed to download media');
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _makeWhatsAppRequest(
        'POST',
        '/$_phoneNumberId/messages',
        body: {
          'messaging_product': 'whatsapp',
          'status': 'read',
          'message_id': messageId,
        },
      );
      
    } catch (e) {
      _logger.error('Failed to mark WhatsApp message as read: $e');
      // Don't throw - this is not critical
    }
  }

  /// Process incoming webhook message
  Future<WhatsAppWebhookResponse> processWebhookMessage(
    Map<String, dynamic> webhookData,
  ) async {
    try {
      _logger.info('Processing WhatsApp webhook message');
      
      final entry = webhookData['entry'] as List?;
      if (entry == null || entry.isEmpty) {
        return WhatsAppWebhookResponse(success: false, error: 'No entry data');
      }
      
      final changes = entry.first['changes'] as List?;
      if (changes == null || changes.isEmpty) {
        return WhatsAppWebhookResponse(success: false, error: 'No changes data');
      }
      
      final change = changes.first;
      final value = change['value'] as Map<String, dynamic>?;
      
      if (value == null) {
        return WhatsAppWebhookResponse(success: false, error: 'No value data');
      }
      
      // Handle different webhook types
      if (value.containsKey('messages')) {
        return await _handleIncomingMessage(value);
      } else if (value.containsKey('statuses')) {
        return await _handleMessageStatus(value);
      } else {
        return WhatsAppWebhookResponse(success: true, message: 'Webhook processed');
      }
      
    } catch (e) {
      _logger.error('Failed to process WhatsApp webhook: $e');
      return WhatsAppWebhookResponse(success: false, error: e.toString());
    }
  }

  /// Handle incoming message
  Future<WhatsAppWebhookResponse> _handleIncomingMessage(
    Map<String, dynamic> value,
  ) async {
    try {
      final messages = value['messages'] as List;
      final contacts = value['contacts'] as List?;
      
      for (final messageData in messages) {
        final message = WhatsAppIncomingMessage.fromJson(messageData);
        
        // Get contact info
        String? contactName;
        if (contacts != null) {
          final contact = contacts.firstWhere(
            (c) => c['wa_id'] == message.from,
            orElse: () => null,
          );
          if (contact != null) {
            contactName = contact['profile']?['name'];
          }
        }
        
        // Mark as read
        await markMessageAsRead(message.id);
        
        // Process based on message type
        await _processIncomingMessage(message, contactName);
      }
      
      return WhatsAppWebhookResponse(success: true, message: 'Messages processed');
      
    } catch (e) {
      _logger.error('Failed to handle incoming WhatsApp message: $e');
      return WhatsAppWebhookResponse(success: false, error: e.toString());
    }
  }

  /// Handle message status updates
  Future<WhatsAppWebhookResponse> _handleMessageStatus(
    Map<String, dynamic> value,
  ) async {
    try {
      final statuses = value['statuses'] as List;
      
      for (final statusData in statuses) {
        final status = WhatsAppMessageStatus.fromJson(statusData);
        _logger.info('Message ${status.id} status: ${status.status}');
        
        // Update message status in your database
        await _updateMessageStatus(status);
      }
      
      return WhatsAppWebhookResponse(success: true, message: 'Statuses processed');
      
    } catch (e) {
      _logger.error('Failed to handle WhatsApp message status: $e');
      return WhatsAppWebhookResponse(success: false, error: e.toString());
    }
  }

  /// Process incoming message based on type
  Future<void> _processIncomingMessage(
    WhatsAppIncomingMessage message,
    String? contactName,
  ) async {
    try {
      switch (message.type) {
        case 'text':
          await _handleTextMessage(message, contactName);
          break;
          
        case 'image':
          await _handleImageMessage(message, contactName);
          break;
          
        case 'document':
          await _handleDocumentMessage(message, contactName);
          break;
          
        case 'interactive':
          await _handleInteractiveMessage(message, contactName);
          break;
          
        case 'button':
          await _handleButtonMessage(message, contactName);
          break;
          
        case 'list':
          await _handleListMessage(message, contactName);
          break;
          
        default:
          _logger.warning('Unhandled WhatsApp message type: ${message.type}');
          await sendTextMessage(
            to: message.from,
            message: 'Sorry, I cannot process this type of message. Please send text or images.',
          );
      }
    } catch (e) {
      _logger.error('Failed to process incoming message: $e');
      
      // Send error message to user
      await sendTextMessage(
        to: message.from,
        message: 'Sorry, something went wrong. Please try again later.',
      );
    }
  }

  /// Handle text message
  Future<void> _handleTextMessage(
    WhatsAppIncomingMessage message,
    String? contactName,
  ) async {
    final text = message.text?.body?.toLowerCase().trim() ?? '';
    
    // Handle common commands
    if (text == 'help' || text == '/help') {
      await _sendHelpMessage(message.from);
    } else if (text == 'start' || text == '/start') {
      await _sendWelcomeMessage(message.from, contactName);
    } else if (text == 'status' || text == '/status') {
      await _sendStatusMessage(message.from);
    } else {
      // Default response for unrecognized text
      await sendTextMessage(
        to: message.from,
        message: 'I received your message: "$text"\n\nPlease send a photo of your receipt or type "help" for available commands.',
        replyToMessageId: message.id,
      );
    }
  }

  /// Handle image message (receipt processing)
  Future<void> _handleImageMessage(
    WhatsAppIncomingMessage message,
    String? contactName,
  ) async {
    try {
      // Download image
      final imageData = await downloadMedia(message.image!.id);
      
      // Send processing message
      await sendTextMessage(
        to: message.from,
        message: '🔄 Processing your receipt...',
      );
      
      // Process receipt (you'll need to implement this)
      // final receiptData = await _processReceiptImage(imageData, message.from);
      
      // Send confirmation message
      await sendInteractiveMessage(
        to: message.from,
        bodyText: '✅ Receipt processed successfully!\n\nVendor: Sample Store\nAmount: \$25.99\nDate: Today\n\nWhat would you like to do?',
        buttons: [
          InteractiveButton(
            type: 'reply',
            id: 'edit_receipt',
            title: 'Edit Details',
          ),
          InteractiveButton(
            type: 'reply',
            id: 'confirm_receipt',
            title: 'Confirm',
          ),
          InteractiveButton(
            type: 'reply',
            id: 'delete_receipt',
            title: 'Delete',
          ),
        ],
      );
      
    } catch (e) {
      _logger.error('Failed to handle image message: $e');
      await sendTextMessage(
        to: message.from,
        message: '❌ Failed to process receipt. Please try again or check image quality.',
      );
    }
  }

  /// Handle document message
  Future<void> _handleDocumentMessage(
    WhatsAppIncomingMessage message,
    String? contactName,
  ) async {
    await sendTextMessage(
      to: message.from,
      message: 'I received your document. For receipt processing, please send images (JPG/PNG) instead.',
    );
  }

  /// Handle interactive message response
  Future<void> _handleInteractiveMessage(
    WhatsAppIncomingMessage message,
    String? contactName,
  ) async {
    final buttonId = message.interactive?.buttonReply?.id;
    
    if (buttonId != null) {
      await _handleButtonResponse(message.from, buttonId);
    }
  }

  /// Handle button message
  Future<void> _handleButtonMessage(
    WhatsAppIncomingMessage message,
    String? contactName,
  ) async {
    // Handle button responses
    final buttonText = message.button?.text;
    if (buttonText != null) {
      await _handleButtonResponse(message.from, buttonText);
    }
  }

  /// Handle list message
  Future<void> _handleListMessage(
    WhatsAppIncomingMessage message,
    String? contactName,
  ) async {
    final listId = message.interactive?.listReply?.id;
    
    if (listId != null) {
      await _handleListResponse(message.from, listId);
    }
  }

  /// Handle button/interactive responses
  Future<void> _handleButtonResponse(String from, String buttonId) async {
    switch (buttonId) {
      case 'edit_receipt':
        await sendTextMessage(
          to: from,
          message: 'To edit your receipt, reply with:\n• "vendor [name]" - Update vendor\n• "amount [value]" - Update amount\n• "category [name]" - Update category',
        );
        break;
        
      case 'confirm_receipt':
        await sendTextMessage(
          to: from,
          message: '✅ Receipt confirmed and saved to your account!',
        );
        break;
        
      case 'delete_receipt':
        await sendTextMessage(
          to: from,
          message: '🗑️ Receipt deleted successfully.',
        );
        break;
        
      default:
        await sendTextMessage(
          to: from,
          message: 'Unknown action. Type "help" for available commands.',
        );
    }
  }

  /// Handle list responses
  Future<void> _handleListResponse(String from, String listId) async {
    // Handle list item selections
    await sendTextMessage(
      to: from,
      message: 'You selected: $listId',
    );
  }

  /// Send welcome message
  Future<void> _sendWelcomeMessage(String to, String? contactName) async {
    final name = contactName ?? 'there';
    
    await sendTextMessage(
      to: to,
      message: '👋 Welcome to Receiptsly, $name!\n\nI can help you track expenses by processing receipt photos.\n\n📷 Just send me a photo of your receipt\n📊 Type "status" to see your summary\n❓ Type "help" for all commands\n\nLet\'s get started! Send me your first receipt.',
    );
  }

  /// Send help message
  Future<void> _sendHelpMessage(String to) async {
    await sendTextMessage(
      to: to,
      message: '📚 **Receiptsly Commands:**\n\n📷 Send a photo - Upload a receipt\n📊 "status" - View your monthly summary\n❓ "help" - Show this message\n\nAfter uploading a receipt, you can:\n• Reply "vendor [name]" to update vendor\n• Reply "amount [value]" to update amount\n• Reply "category [name]" to change category',
    );
  }

  /// Send status message
  Future<void> _sendStatusMessage(String to) async {
    // You'll need to implement this based on your user data
    await sendTextMessage(
      to: to,
      message: '📊 **Monthly Summary**\n\nTotal Expenses: \$150.00\nReceipt Count: 8\n\n**By Category:**\n• Food & Dining: \$75.00\n• Transportation: \$45.00\n• Office Supplies: \$30.00',
    );
  }

  /// Update message status in your database
  Future<void> _updateMessageStatus(WhatsAppMessageStatus status) async {
    // Implement database update logic
    _logger.info('Updating message ${status.id} status to ${status.status}');
  }

  /// Make authenticated request to WhatsApp API
  Future<Map<String, dynamic>> _makeWhatsAppRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    
    final uri = Uri.parse('$_baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );
    
    final headers = {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
    };

    http.Response response;
    
    switch (method.toUpperCase()) {
      case 'GET':
        response = await _httpClient.get(uri, headers: headers);
        break;
        
      case 'POST':
        final jsonBody = body != null ? jsonEncode(body) : '';
        response = await _httpClient.post(uri, headers: headers, body: jsonBody);
        break;
        
      default:
        throw WhatsAppException('Unsupported HTTP method: $method');
    }
    
    if (response.statusCode >= 400) {
      final errorData = response.body.isNotEmpty 
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
          
      throw WhatsAppApiException(
        message: errorData['error']?['message'] ?? 'WhatsApp API error',
        code: errorData['error']?['code']?.toString(),
        statusCode: response.statusCode,
      );
    }
    
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// WhatsApp models and data classes
class WhatsAppMessageResponse {
  final String? messagingProduct;
  final List<WhatsAppContact>? contacts;
  final List<WhatsAppMessage>? messages;

  WhatsAppMessageResponse({
    this.messagingProduct,
    this.contacts,
    this.messages,
  });

  factory WhatsAppMessageResponse.fromJson(Map<String, dynamic> json) {
    return WhatsAppMessageResponse(
      messagingProduct: json['messaging_product'],
      contacts: (json['contacts'] as List?)
          ?.map((c) => WhatsAppContact.fromJson(c))
          .toList(),
      messages: (json['messages'] as List?)
          ?.map((m) => WhatsAppMessage.fromJson(m))
          .toList(),
    );
  }
}

class WhatsAppContact {
  final String waId;
  final String input;

  WhatsAppContact({
    required this.waId,
    required this.input,
  });

  factory WhatsAppContact.fromJson(Map<String, dynamic> json) {
    return WhatsAppContact(
      waId: json['wa_id'],
      input: json['input'],
    );
  }
}

class WhatsAppMessage {
  final String id;

  WhatsAppMessage({required this.id});

  factory WhatsAppMessage.fromJson(Map<String, dynamic> json) {
    return WhatsAppMessage(id: json['id']);
  }
}

class WhatsAppIncomingMessage {
  final String id;
  final String from;
  final int timestamp;
  final String type;
  final WhatsAppText? text;
  final WhatsAppImage? image;
  final WhatsAppDocument? document;
  final WhatsAppInteractive? interactive;
  final WhatsAppButton? button;
  final WhatsAppContext? context;

  WhatsAppIncomingMessage({
    required this.id,
    required this.from,
    required this.timestamp,
    required this.type,
    this.text,
    this.image,
    this.document,
    this.interactive,
    this.button,
    this.context,
  });

  factory WhatsAppIncomingMessage.fromJson(Map<String, dynamic> json) {
    return WhatsAppIncomingMessage(
      id: json['id'],
      from: json['from'],
      timestamp: json['timestamp'],
      type: json['type'],
      text: json['text'] != null ? WhatsAppText.fromJson(json['text']) : null,
      image: json['image'] != null ? WhatsAppImage.fromJson(json['image']) : null,
      document: json['document'] != null ? WhatsAppDocument.fromJson(json['document']) : null,
      interactive: json['interactive'] != null ? WhatsAppInteractive.fromJson(json['interactive']) : null,
      button: json['button'] != null ? WhatsAppButton.fromJson(json['button']) : null,
      context: json['context'] != null ? WhatsAppContext.fromJson(json['context']) : null,
    );
  }
}

class WhatsAppText {
  final String? body;

  WhatsAppText({this.body});

  factory WhatsAppText.fromJson(Map<String, dynamic> json) {
    return WhatsAppText(body: json['body']);
  }
}

class WhatsAppImage {
  final String id;
  final String? mimeType;
  final String? sha256;
  final String? caption;

  WhatsAppImage({
    required this.id,
    this.mimeType,
    this.sha256,
    this.caption,
  });

  factory WhatsAppImage.fromJson(Map<String, dynamic> json) {
    return WhatsAppImage(
      id: json['id'],
      mimeType: json['mime_type'],
      sha256: json['sha256'],
      caption: json['caption'],
    );
  }
}

class WhatsAppDocument {
  final String id;
  final String? mimeType;
  final String? sha256;
  final String? caption;
  final String? filename;

  WhatsAppDocument({
    required this.id,
    this.mimeType,
    this.sha256,
    this.caption,
    this.filename,
  });

  factory WhatsAppDocument.fromJson(Map<String, dynamic> json) {
    return WhatsAppDocument(
      id: json['id'],
      mimeType: json['mime_type'],
      sha256: json['sha256'],
      caption: json['caption'],
      filename: json['filename'],
    );
  }
}

class WhatsAppInteractive {
  final String? type;
  final WhatsAppButtonReply? buttonReply;
  final WhatsAppListReply? listReply;

  WhatsAppInteractive({
    this.type,
    this.buttonReply,
    this.listReply,
  });

  factory WhatsAppInteractive.fromJson(Map<String, dynamic> json) {
    return WhatsAppInteractive(
      type: json['type'],
      buttonReply: json['button_reply'] != null 
          ? WhatsAppButtonReply.fromJson(json['button_reply'])
          : null,
      listReply: json['list_reply'] != null 
          ? WhatsAppListReply.fromJson(json['list_reply'])
          : null,
    );
  }
}

class WhatsAppButtonReply {
  final String id;
  final String title;

  WhatsAppButtonReply({
    required this.id,
    required this.title,
  });

  factory WhatsAppButtonReply.fromJson(Map<String, dynamic> json) {
    return WhatsAppButtonReply(
      id: json['id'],
      title: json['title'],
    );
  }
}

class WhatsAppListReply {
  final String id;
  final String title;
  final String? description;

  WhatsAppListReply({
    required this.id,
    required this.title,
    this.description,
  });

  factory WhatsAppListReply.fromJson(Map<String, dynamic> json) {
    return WhatsAppListReply(
      id: json['id'],
      title: json['title'],
      description: json['description'],
    );
  }
}

class WhatsAppButton {
  final String? text;
  final String? payload;

  WhatsAppButton({this.text, this.payload});

  factory WhatsAppButton.fromJson(Map<String, dynamic> json) {
    return WhatsAppButton(
      text: json['text'],
      payload: json['payload'],
    );
  }
}

class WhatsAppContext {
  final String? from;
  final String? id;
  final bool? forwarded;
  final bool? frequentlyForwarded;

  WhatsAppContext({
    this.from,
    this.id,
    this.forwarded,
    this.frequentlyForwarded,
  });

  factory WhatsAppContext.fromJson(Map<String, dynamic> json) {
    return WhatsAppContext(
      from: json['from'],
      id: json['id'],
      forwarded: json['forwarded'],
      frequentlyForwarded: json['frequently_forwarded'],
    );
  }
}

class WhatsAppMessageStatus {
  final String id;
  final String status;
  final int timestamp;
  final String recipientId;

  WhatsAppMessageStatus({
    required this.id,
    required this.status,
    required this.timestamp,
    required this.recipientId,
  });

  factory WhatsAppMessageStatus.fromJson(Map<String, dynamic> json) {
    return WhatsAppMessageStatus(
      id: json['id'],
      status: json['status'],
      // lib/services/chat/whatsapp_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../core/config/environment.dart';
import '../../core/utils/logger.dart';
import '../../core/errors/exceptions.dart';
import '../../data/models/user/user_model.dart';

/// WhatsApp Business API service for bot functionality
class WhatsAppService {
  final String _phoneNumberId;
  final String _accessToken;
  final String _webhookVerifyToken;
  final http.Client _httpClient;
  final Logger _logger;
  
  static const String _baseUrl = 'https://graph.facebook.com/v18.0';
  
  WhatsAppService({
    required String phoneNumberId,
    required String accessToken,
    required String webhookVerifyToken,
    required http.Client httpClient,
    required Logger logger,
  }) : _phoneNumberId = phoneNumberId,
       _accessToken = accessToken,
       _webhookVerifyToken = webhookVerifyToken,
       _httpClient = httpClient,
       _logger = logger;

  /// Verify webhook for initial setup
  bool verifyWebhook({
    required String mode,
    required String token,
    required String challenge,
  }) {
    if (mode == 'subscribe' && token == _webhookVerifyToken) {
      _logger.info('WhatsApp webhook verified successfully');
      return true;
    }
    
    _logger.warning('WhatsApp webhook verification failed');
    return false;
  }

  /// Send text message
  Future<WhatsAppMessageResponse> sendTextMessage({
    required String to,
    required String message,
    String? replyToMessageId,
  }) async {
    try {
      _logger.info('Sending WhatsApp text message to: $to');
      
      final messageData = {
        'messaging_product': 'whatsapp',
        'recipient_type': 'individual',
        'to': to,
        'type': 'text',
        'text': {
          'body': message,
        },
      };
      
      if (replyToMessageId != null) {
        messageData['context'] = {
          'message_id': replyToMessageId,
        };
      }

      final response = await _makeWhatsAppRequest(
        'POST',
        '/$_phoneNumberId/messages',
        body: messageData,
      );

      return WhatsAppMessageResponse.fromJson(response);
      
    } catch (e) {
      _logger.error('Failed to send WhatsApp text message: $e');
      throw WhatsAppException('Failed to send message');
    }
  }

  /// Send template message
  Future<WhatsAppMessageResponse> sendTemplateMessage({
    required String to,
    required String templateName,
    required String languageCode,
    List<TemplateComponent>? components,
  }) async {
    try {
      _logger.info('Sending WhatsApp template message: $templateName to $to');
      
      final messageData = {
        'messaging_product': 'whatsapp',
        'recipient_type': 'individual',
        'to': to,
        'type': 'template',
        'template': {
          'name': templateName,
          'language': {
            'code': languageCode,
          },
          if (components != null && components.isNotEmpty)
            'components': components.map((c) => c.toJson()).toList(),
        },
      };

      final response = await _makeWhatsAppRequest(
        'POST',
        '/$_phoneNumberId/messages',
        body: messageData,
      );

      return WhatsAppMessageResponse.fromJson(response);
      
    } catch (e) {
      _logger.error('Failed to send WhatsApp template message: $e');