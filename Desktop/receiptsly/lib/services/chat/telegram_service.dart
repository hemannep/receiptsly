// lib/services/chat/telegram_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../core/config/environment.dart';
import '../../core/utils/logger.dart';
import '../../core/errors/exceptions.dart';

/// Telegram Bot API service for bot functionality
class TelegramService {
  final String _botToken;
  final String _webhookSecret;
  final http.Client _httpClient;
  final Logger _logger;

  late final String _baseUrl;

  TelegramService({
    required String botToken,
    required String webhookSecret,
    required http.Client httpClient,
    required Logger logger,
  }) : _botToken = botToken,
       _webhookSecret = webhookSecret,
       _httpClient = httpClient,
       _logger = logger {
    _baseUrl = 'https://api.telegram.org/bot$_botToken';
  }

  /// Set webhook URL for receiving updates
  Future<bool> setWebhook({
    required String url,
    List<String>? allowedUpdates,
    int? maxConnections,
    bool? dropPendingUpdates,
  }) async {
    try {
      _logger.info('Setting Telegram webhook: $url');

      final response = await _makeTelegramRequest(
        'POST',
        '/setWebhook',
        body: {
          'url': url,
          'secret_token': _webhookSecret,
          if (allowedUpdates != null) 'allowed_updates': allowedUpdates,
          if (maxConnections != null) 'max_connections': maxConnections,
          if (dropPendingUpdates != null)
            'drop_pending_updates': dropPendingUpdates,
        },
      );

      return response['ok'] as bool;
    } catch (e) {
      _logger.error('Failed to set Telegram webhook: $e');
      throw TelegramException('Failed to set webhook');
    }
  }

  /// Delete webhook
  Future<bool> deleteWebhook({bool? dropPendingUpdates}) async {
    try {
      final response = await _makeTelegramRequest(
        'POST',
        '/deleteWebhook',
        body: {
          if (dropPendingUpdates != null)
            'drop_pending_updates': dropPendingUpdates,
        },
      );

      return response['ok'] as bool;
    } catch (e) {
      _logger.error('Failed to delete Telegram webhook: $e');
      throw TelegramException('Failed to delete webhook');
    }
  }

  /// Get webhook info
  Future<WebhookInfo> getWebhookInfo() async {
    try {
      final response = await _makeTelegramRequest('GET', '/getWebhookInfo');
      return WebhookInfo.fromJson(response['result']);
    } catch (e) {
      _logger.error('Failed to get webhook info: $e');
      throw TelegramException('Failed to get webhook info');
    }
  }

  /// Send text message
  Future<TelegramMessage> sendMessage({
    required int chatId,
    required String text,
    String? parseMode,
    bool? disableWebPagePreview,
    bool? disableNotification,
    int? replyToMessageId,
    TelegramReplyMarkup? replyMarkup,
  }) async {
    try {
      _logger.info('Sending Telegram message to chat: $chatId');

      final response = await _makeTelegramRequest(
        'POST',
        '/sendMessage',
        body: {
          'chat_id': chatId,
          'text': text,
          if (parseMode != null) 'parse_mode': parseMode,
          if (disableWebPagePreview != null)
            'disable_web_page_preview': disableWebPagePreview,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        },
      );

      return TelegramMessage.fromJson(response['result']);
    } catch (e) {
      _logger.error('Failed to send Telegram message: $e');
      throw TelegramException('Failed to send message');
    }
  }

  /// Send photo
  Future<TelegramMessage> sendPhoto({
    required int chatId,
    required String photo, // File ID or URL
    String? caption,
    String? parseMode,
    bool? disableNotification,
    int? replyToMessageId,
    TelegramReplyMarkup? replyMarkup,
  }) async {
    try {
      _logger.info('Sending Telegram photo to chat: $chatId');

      final response = await _makeTelegramRequest(
        'POST',
        '/sendPhoto',
        body: {
          'chat_id': chatId,
          'photo': photo,
          if (caption != null) 'caption': caption,
          if (parseMode != null) 'parse_mode': parseMode,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        },
      );

      return TelegramMessage.fromJson(response['result']);
    } catch (e) {
      _logger.error('Failed to send Telegram photo: $e');
      throw TelegramException('Failed to send photo');
    }
  }

  /// Send document
  Future<TelegramMessage> sendDocument({
    required int chatId,
    required String document, // File ID or URL
    String? caption,
    String? parseMode,
    bool? disableNotification,
    int? replyToMessageId,
    TelegramReplyMarkup? replyMarkup,
  }) async {
    try {
      _logger.info('Sending Telegram document to chat: $chatId');

      final response = await _makeTelegramRequest(
        'POST',
        '/sendDocument',
        body: {
          'chat_id': chatId,
          'document': document,
          if (caption != null) 'caption': caption,
          if (parseMode != null) 'parse_mode': parseMode,
          if (disableNotification != null)
            'disable_notification': disableNotification,
          if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        },
      );

      return TelegramMessage.fromJson(response['result']);
    } catch (e) {
      _logger.error('Failed to send Telegram document: $e');
      throw TelegramException('Failed to send document');
    }
  }

  /// Upload file and send photo
  Future<TelegramMessage> sendPhotoFile({
    required int chatId,
    required File photoFile,
    String? caption,
    String? parseMode,
    bool? disableNotification,
    int? replyToMessageId,
    TelegramReplyMarkup? replyMarkup,
  }) async {
    try {
      _logger.info(
        'Uploading and sending Telegram photo file to chat: $chatId',
      );

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/sendPhoto'),
      );

      request.fields['chat_id'] = chatId.toString();
      if (caption != null) request.fields['caption'] = caption;
      if (parseMode != null) request.fields['parse_mode'] = parseMode;
      if (disableNotification != null)
        request.fields['disable_notification'] = disableNotification.toString();
      if (replyToMessageId != null)
        request.fields['reply_to_message_id'] = replyToMessageId.toString();
      if (replyMarkup != null)
        request.fields['reply_markup'] = jsonEncode(replyMarkup.toJson());

      final multipartFile = await http.MultipartFile.fromPath(
        'photo',
        photoFile.path,
        filename: path.basename(photoFile.path),
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw TelegramException('Failed to upload photo: $responseBody');
      }

      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      if (!(responseData['ok'] as bool)) {
        throw TelegramException(responseData['description'] ?? 'Unknown error');
      }

      return TelegramMessage.fromJson(responseData['result']);
    } catch (e) {
      _logger.error('Failed to send Telegram photo file: $e');
      throw TelegramException('Failed to send photo file');
    }
  }

  /// Edit message text
  Future<TelegramMessage> editMessageText({
    required int chatId,
    required int messageId,
    required String text,
    String? parseMode,
    bool? disableWebPagePreview,
    TelegramInlineKeyboardMarkup? replyMarkup,
  }) async {
    try {
      final response = await _makeTelegramRequest(
        'POST',
        '/editMessageText',
        body: {
          'chat_id': chatId,
          'message_id': messageId,
          'text': text,
          if (parseMode != null) 'parse_mode': parseMode,
          if (disableWebPagePreview != null)
            'disable_web_page_preview': disableWebPagePreview,
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        },
      );

      return TelegramMessage.fromJson(response['result']);
    } catch (e) {
      _logger.error('Failed to edit Telegram message: $e');
      throw TelegramException('Failed to edit message');
    }
  }

  /// Edit message reply markup
  Future<TelegramMessage> editMessageReplyMarkup({
    required int chatId,
    required int messageId,
    TelegramInlineKeyboardMarkup? replyMarkup,
  }) async {
    try {
      final response = await _makeTelegramRequest(
        'POST',
        '/editMessageReplyMarkup',
        body: {
          'chat_id': chatId,
          'message_id': messageId,
          if (replyMarkup != null) 'reply_markup': replyMarkup.toJson(),
        },
      );

      return TelegramMessage.fromJson(response['result']);
    } catch (e) {
      _logger.error('Failed to edit Telegram message markup: $e');
      throw TelegramException('Failed to edit message markup');
    }
  }

  /// Delete message
  Future<bool> deleteMessage({
    required int chatId,
    required int messageId,
  }) async {
    try {
      final response = await _makeTelegramRequest(
        'POST',
        '/deleteMessage',
        body: {'chat_id': chatId, 'message_id': messageId},
      );

      return response['ok'] as bool;
    } catch (e) {
      _logger.error('Failed to delete Telegram message: $e');
      throw TelegramException('Failed to delete message');
    }
  }

  /// Answer callback query
  Future<bool> answerCallbackQuery({
    required String callbackQueryId,
    String? text,
    bool? showAlert,
    String? url,
    int? cacheTime,
  }) async {
    try {
      final response = await _makeTelegramRequest(
        'POST',
        '/answerCallbackQuery',
        body: {
          'callback_query_id': callbackQueryId,
          if (text != null) 'text': text,
          if (showAlert != null) 'show_alert': showAlert,
          if (url != null) 'url': url,
          if (cacheTime != null) 'cache_time': cacheTime,
        },
      );

      return response['ok'] as bool;
    } catch (e) {
      _logger.error('Failed to answer callback query: $e');
      throw TelegramException('Failed to answer callback query');
    }
  }

  /// Get file info and download URL
  Future<TelegramFile> getFile(String fileId) async {
    try {
      final response = await _makeTelegramRequest(
        'GET',
        '/getFile',
        queryParams: {'file_id': fileId},
      );

      return TelegramFile.fromJson(response['result']);
    } catch (e) {
      _logger.error('Failed to get Telegram file: $e');
      throw TelegramException('Failed to get file');
    }
  }

  /// Download file
  Future<Uint8List> downloadFile(String filePath) async {
    try {
      _logger.info('Downloading Telegram file: $filePath');

      final fileUrl = 'https://api.telegram.org/file/bot$_botToken/$filePath';
      final response = await _httpClient.get(Uri.parse(fileUrl));

      if (response.statusCode != 200) {
        throw TelegramException('Failed to download file');
      }

      return response.bodyBytes;
    } catch (e) {
      _logger.error('Failed to download Telegram file: $e');
      throw TelegramException('Failed to download file');
    }
  }

  /// Get chat member
  Future<TelegramChatMember> getChatMember({
    required int chatId,
    required int userId,
  }) async {
    try {
      final response = await _makeTelegramRequest(
        'GET',
        '/getChatMember',
        queryParams: {
          'chat_id': chatId.toString(),
          'user_id': userId.toString(),
        },
      );

      return TelegramChatMember.fromJson(response['result']);
    } catch (e) {
      _logger.error('Failed to get chat member: $e');
      throw TelegramException('Failed to get chat member');
    }
  }

  /// Process webhook update
  Future<TelegramWebhookResponse> processWebhookUpdate(
    Map<String, dynamic> update,
    String? secretToken,
  ) async {
    try {
      // Verify secret token
      if (_webhookSecret.isNotEmpty && secretToken != _webhookSecret) {
        _logger.warning('Invalid Telegram webhook secret token');
        return TelegramWebhookResponse(
          success: false,
          error: 'Invalid secret token',
        );
      }

      _logger.info('Processing Telegram webhook update');

      final telegramUpdate = TelegramUpdate.fromJson(update);

      // Handle different update types
      if (telegramUpdate.message != null) {
        await _handleMessage(telegramUpdate.message!);
      } else if (telegramUpdate.callbackQuery != null) {
        await _handleCallbackQuery(telegramUpdate.callbackQuery!);
      } else if (telegramUpdate.editedMessage != null) {
        await _handleEditedMessage(telegramUpdate.editedMessage!);
      } else {
        _logger.info('Unhandled Telegram update type');
      }

      return TelegramWebhookResponse(
        success: true,
        message: 'Update processed',
      );
    } catch (e) {
      _logger.error('Failed to process Telegram webhook: $e');
      return TelegramWebhookResponse(success: false, error: e.toString());
    }
  }

  /// Handle incoming message
  Future<void> _handleMessage(TelegramMessage message) async {
    try {
      final chatId = message.chat.id;
      final userId = message.from?.id;

      if (userId == null) return;

      // Handle different message types
      if (message.text != null) {
        await _handleTextMessage(message);
      } else if (message.photo != null && message.photo!.isNotEmpty) {
        await _handlePhotoMessage(message);
      } else if (message.document != null) {
        await _handleDocumentMessage(message);
      } else {
        await sendMessage(
          chatId: chatId,
          text: 'Sorry, I can only process text messages and photos.',
        );
      }
    } catch (e) {
      _logger.error('Failed to handle Telegram message: $e');

      await sendMessage(
        chatId: message.chat.id,
        text: 'Sorry, something went wrong. Please try again.',
      );
    }
  }

  /// Handle text message
  Future<void> _handleTextMessage(TelegramMessage message) async {
    final text = message.text?.toLowerCase().trim() ?? '';
    final chatId = message.chat.id;

    // Handle commands
    if (text.startsWith('/')) {
      await _handleCommand(message, text);
    } else {
      // Handle regular text
      await sendMessage(
        chatId: chatId,
        text:
            'I received your message: "$text"\n\nPlease send a photo of your receipt or use /help for available commands.',
        replyToMessageId: message.messageId,
      );
    }
  }

  /// Handle commands
  Future<void> _handleCommand(TelegramMessage message, String command) async {
    final chatId = message.chat.id;
    final userName = message.from?.firstName ?? 'there';

    switch (command) {
      case '/start':
        await _sendWelcomeMessage(chatId, userName);
        break;

      case '/help':
        await _sendHelpMessage(chatId);
        break;

      case '/status':
        await _sendStatusMessage(chatId);
        break;

      case '/settings':
        await _sendSettingsMessage(chatId);
        break;

      default:
        await sendMessage(
          chatId: chatId,
          text: 'Unknown command. Use /help to see available commands.',
        );
    }
  }

  /// Handle photo message (receipt processing)
  Future<void> _handlePhotoMessage(TelegramMessage message) async {
    try {
      final chatId = message.chat.id;
      final photos = message.photo!;

      // Get the largest photo
      final photo = photos.last;

      // Send processing message
      final processingMessage = await sendMessage(
        chatId: chatId,
        text: '🔄 Processing your receipt...',
      );

      // Download photo
      final file = await getFile(photo.fileId);
      final imageData = await downloadFile(file.filePath!);

      // Process receipt (you'll need to implement this)
      // final receiptData = await _processReceiptImage(imageData, message.from?.id);

      // Delete processing message
      await deleteMessage(
        chatId: chatId,
        messageId: processingMessage.messageId,
      );

      // Send result with inline keyboard
      await sendMessage(
        chatId: chatId,
        text:
            '✅ *Receipt Processed Successfully!*\n\n'
            '📝 *Details:*\n'
            'Vendor: Sample Store\n'
            'Amount: \$25.99\n'
            'Date: Today\n'
            'Category: General\n\n'
            'Confidence: 85%',
        parseMode: 'Markdown',
        replyMarkup: TelegramInlineKeyboardMarkup(
          inlineKeyboard: [
            [
              TelegramInlineKeyboardButton(
                text: '✏️ Edit',
                callbackData: 'edit_receipt',
              ),
              TelegramInlineKeyboardButton(
                text: '✅ Confirm',
                callbackData: 'confirm_receipt',
              ),
            ],
            [
              TelegramInlineKeyboardButton(
                text: '🗑️ Delete',
                callbackData: 'delete_receipt',
              ),
              TelegramInlineKeyboardButton(
                text: '🔗 View in App',
                url: 'https://receiptsly.app/receipts/123',
              ),
            ],
          ],
        ),
      );
    } catch (e) {
      _logger.error('Failed to handle photo message: $e');
      await sendMessage(
        chatId: message.chat.id,
        text:
            '❌ Failed to process receipt. Please try again or check image quality.',
      );
    }
  }

  /// Handle document message
  Future<void> _handleDocumentMessage(TelegramMessage message) async {
    await sendMessage(
      chatId: message.chat.id,
      text:
          'I received your document. For receipt processing, please send images (JPG/PNG) instead.',
    );
  }

  /// Handle callback query (button presses)
  Future<void> _handleCallbackQuery(TelegramCallbackQuery callbackQuery) async {
    try {
      final chatId = callbackQuery.message?.chat.id;
      final data = callbackQuery.data;

      if (chatId == null || data == null) return;

      switch (data) {
        case 'confirm_receipt':
          await answerCallbackQuery(
            callbackQueryId: callbackQuery.id,
            text: '✅ Receipt confirmed!',
          );

          await editMessageReplyMarkup(
            chatId: chatId,
            messageId: callbackQuery.message!.messageId,
            replyMarkup: TelegramInlineKeyboardMarkup(inlineKeyboard: []),
          );
          break;

        case 'edit_receipt':
          await answerCallbackQuery(callbackQueryId: callbackQuery.id);

          await sendMessage(
            chatId: chatId,
            text:
                'To edit your receipt, reply with:\n'
                '• "vendor [name]" - Update vendor\n'
                '• "amount [value]" - Update amount\n'
                '• "category [name]" - Update category',
          );
          break;

        case 'delete_receipt':
          await answerCallbackQuery(
            callbackQueryId: callbackQuery.id,
            text: '🗑️ Receipt deleted',
          );

          await deleteMessage(
            chatId: chatId,
            messageId: callbackQuery.message!.messageId,
          );
          break;

        default:
          await answerCallbackQuery(
            callbackQueryId: callbackQuery.id,
            text: 'Unknown action',
          );
      }
    } catch (e) {
      _logger.error('Failed to handle callback query: $e');

      await answerCallbackQuery(
        callbackQueryId: callbackQuery.id,
        text: '❌ Something went wrong',
      );
    }
  }

  /// Handle edited message
  Future<void> _handleEditedMessage(TelegramMessage message) async {
    _logger.info('Message edited: ${message.messageId}');
    // Handle message edits if needed
  }

  /// Send welcome message
  Future<void> _sendWelcomeMessage(int chatId, String userName) async {
    await sendMessage(
      chatId: chatId,
      text:
          '🎉 Welcome to Receiptsly Bot, $userName!\n\n'
          'I can help you track expenses by processing receipt photos.\n\n'
          '📷 Just send me a photo of your receipt\n'
          '📊 Use /status to see your summary\n'
          '❓ Use /help for all commands\n\n'
          'Let\'s get started! Send me your first receipt.',
      replyMarkup: TelegramReplyKeyboardMarkup(
        keyboard: [
          [
            TelegramKeyboardButton(text: '📷 Upload Receipt'),
            TelegramKeyboardButton(text: '📊 Stats'),
          ],
          [
            TelegramKeyboardButton(text: '📋 Recent'),
            TelegramKeyboardButton(text: '❓ Help'),
          ],
        ],
        resizeKeyboard: true,
      ),
    );
  }

  /// Send help message
  Future<void> _sendHelpMessage(int chatId) async {
    await sendMessage(
      chatId: chatId,
      text:
          '📚 *Receiptsly Commands:*\n\n'
          '📷 Send a photo - Upload a receipt\n'
          '📊 /status - View your monthly summary\n'
          '⚙️ /settings - Manage your settings\n'
          '❓ /help - Show this message\n\n'
          'After uploading a receipt, you can:\n'
          '• Reply "vendor [name]" to update vendor\n'
          '• Reply "amount [value]" to update amount\n'
          '• Reply "category [name]" to change category',
      parseMode: 'Markdown',
    );
  }

  /// Send status message
  Future<void> _sendStatusMessage(int chatId) async {
    // You'll need to implement this based on your user data
    await sendMessage(
      chatId: chatId,
      text:
          '📊 *Monthly Summary*\n\n'
          'Total Expenses: \$150.00\n'
          'Receipt Count: 8\n\n'
          '*By Category:*\n'
          '• Food & Dining: \$75.00\n'
          '• Transportation: \$45.00\n'
          '• Office Supplies: \$30.00',
      parseMode: 'Markdown',
    );
  }

  /// Send settings message
  Future<void> _sendSettingsMessage(int chatId) async {
    await sendMessage(
      chatId: chatId,
      text: '⚙️ *Settings*\n\nChoose what you\'d like to configure:',
      parseMode: 'Markdown',
      replyMarkup: TelegramInlineKeyboardMarkup(
        inlineKeyboard: [
          [
            TelegramInlineKeyboardButton(
              text: '🔔 Notifications',
              callbackData: 'settings_notifications',
            ),
            TelegramInlineKeyboardButton(
              text: '📁 Categories',
              callbackData: 'settings_categories',
            ),
          ],
          [
            TelegramInlineKeyboardButton(
              text: '💰 Currency',
              callbackData: 'settings_currency',
            ),
            TelegramInlineKeyboardButton(
              text: '🔗 Account',
              callbackData: 'settings_account',
            ),
          ],
        ],
      ),
    );
  }

  /// Make authenticated request to Telegram API
  Future<Map<String, dynamic>> _makeTelegramRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl$endpoint',
    ).replace(queryParameters: queryParams);

    final headers = {'Content-Type': 'application/json'};

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await _httpClient.get(uri, headers: headers);
        break;

      case 'POST':
        final jsonBody = body != null ? jsonEncode(body) : '';
        response = await _httpClient.post(
          uri,
          headers: headers,
          body: jsonBody,
        );
        break;

      default:
        throw TelegramException('Unsupported HTTP method: $method');
    }

    if (response.statusCode != 200) {
      throw TelegramApiException(
        message: 'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (!(responseData['ok'] as bool)) {
      throw TelegramApiException(
        message: responseData['description'] ?? 'Unknown Telegram API error',
        errorCode: responseData['error_code']?.toString(),
      );
    }

    return responseData;
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Telegram models and data classes
class TelegramUpdate {
  final int updateId;
  final TelegramMessage? message;
  final TelegramMessage? editedMessage;
  final TelegramCallbackQuery? callbackQuery;

  TelegramUpdate({
    required this.updateId,
    this.message,
    this.editedMessage,
    this.callbackQuery,
  });

  factory TelegramUpdate.fromJson(Map<String, dynamic> json) {
    return TelegramUpdate(
      updateId: json['update_id'],
      message: json['message'] != null
          ? TelegramMessage.fromJson(json['message'])
          : null,
      editedMessage: json['edited_message'] != null
          ? TelegramMessage.fromJson(json['edited_message'])
          : null,
      callbackQuery: json['callback_query'] != null
          ? TelegramCallbackQuery.fromJson(json['callback_query'])
          : null,
    );
  }
}

class TelegramMessage {
  final int messageId;
  final TelegramUser? from;
  final TelegramChat chat;
  final int date;
  final String? text;
  final List<TelegramPhotoSize>? photo;
  final TelegramDocument? document;

  TelegramMessage({
    required this.messageId,
    this.from,
    required this.chat,
    required this.date,
    this.text,
    this.photo,
    this.document,
  });

  factory TelegramMessage.fromJson(Map<String, dynamic> json) {
    return TelegramMessage(
      messageId: json['message_id'],
      from: json['from'] != null ? TelegramUser.fromJson(json['from']) : null,
      chat: TelegramChat.fromJson(json['chat']),
      date: json['date'],
      text: json['text'],
      photo: json['photo'] != null
          ? (json['photo'] as List)
                .map((p) => TelegramPhotoSize.fromJson(p))
                .toList()
          : null,
      document: json['document'] != null
          ? TelegramDocument.fromJson(json['document'])
          : null,
    );
  }
}

class TelegramUser {
  final int id;
  final bool isBot;
  final String firstName;
  final String? lastName;
  final String? username;
  final String? languageCode;

  TelegramUser({
    required this.id,
    required this.isBot,
    required this.firstName,
    this.lastName,
    this.username,
    this.languageCode,
  });

  factory TelegramUser.fromJson(Map<String, dynamic> json) {
    return TelegramUser(
      id: json['id'],
      isBot: json['is_bot'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      username: json['username'],
      languageCode: json['language_code'],
    );
  }

  String get fullName {
    final parts = [
      firstName,
      lastName,
    ].where((part) => part != null && part.isNotEmpty);
    return parts.join(' ');
  }
}

class TelegramChat {
  final int id;
  final String type;
  final String? title;
  final String? username;
  final String? firstName;
  final String? lastName;

  TelegramChat({
    required this.id,
    required this.type,
    this.title,
    this.username,
    this.firstName,
    this.lastName,
  });

  factory TelegramChat.fromJson(Map<String, dynamic> json) {
    return TelegramChat(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }
}

class TelegramPhotoSize {
  final String fileId;
  final String fileUniqueId;
  final int width;
  final int height;
  final int? fileSize;

  TelegramPhotoSize({
    required this.fileId,
    required this.fileUniqueId,
    required this.width,
    required this.height,
    this.fileSize,
  });

  factory TelegramPhotoSize.fromJson(Map<String, dynamic> json) {
    return TelegramPhotoSize(
      fileId: json['file_id'],
      fileUniqueId: json['file_unique_id'],
      width: json['width'],
      height: json['height'],
      fileSize: json['file_size'],
    );
  }
}

class TelegramDocument {
  final String fileId;
  final String fileUniqueId;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;

  TelegramDocument({
    required this.fileId,
    required this.fileUniqueId,
    this.fileName,
    this.mimeType,
    this.fileSize,
  });

  factory TelegramDocument.fromJson(Map<String, dynamic> json) {
    return TelegramDocument(
      fileId: json['file_id'],
      fileUniqueId: json['file_unique_id'],
      fileName: json['file_name'],
      mimeType: json['mime_type'],
      fileSize: json['file_size'],
    );
  }
}

class TelegramCallbackQuery {
  final String id;
  final TelegramUser from;
  final TelegramMessage? message;
  final String? data;

  TelegramCallbackQuery({
    required this.id,
    required this.from,
    this.message,
    this.data,
  });

  factory TelegramCallbackQuery.fromJson(Map<String, dynamic> json) {
    return TelegramCallbackQuery(
      id: json['id'],
      from: TelegramUser.fromJson(json['from']),
      message: json['message'] != null
          ? TelegramMessage.fromJson(json['message'])
          : null,
      data: json['data'],
    );
  }
}

class TelegramFile {
  final String fileId;
  final String fileUniqueId;
  final int? fileSize;
  final String? filePath;

  TelegramFile({
    required this.fileId,
    required this.fileUniqueId,
    this.fileSize,
    this.filePath,
  });

  factory TelegramFile.fromJson(Map<String, dynamic> json) {
    return TelegramFile(
      fileId: json['file_id'],
      fileUniqueId: json['file_unique_id'],
      fileSize: json['file_size'],
      filePath: json['file_path'],
    );
  }
}

class TelegramChatMember {
  final String status;
  final TelegramUser user;

  TelegramChatMember({required this.status, required this.user});

  factory TelegramChatMember.fromJson(Map<String, dynamic> json) {
    return TelegramChatMember(
      status: json['status'],
      user: TelegramUser.fromJson(json['user']),
    );
  }
}

class WebhookInfo {
  final String url;
  final bool hasCustomCertificate;
  final int pendingUpdateCount;
  final String? ipAddress;
  final int? lastErrorDate;
  final String? lastErrorMessage;
  final int? maxConnections;
  final List<String>? allowedUpdates;

  WebhookInfo({
    required this.url,
    required this.hasCustomCertificate,
    required this.pendingUpdateCount,
    this.ipAddress,
    this.lastErrorDate,
    this.lastErrorMessage,
    this.maxConnections,
    this.allowedUpdates,
  });

  factory WebhookInfo.fromJson(Map<String, dynamic> json) {
    return WebhookInfo(
      url: json['url'],
      hasCustomCertificate: json['has_custom_certificate'],
      pendingUpdateCount: json['pending_update_count'],
      ipAddress: json['ip_address'],
      lastErrorDate: json['last_error_date'],
      lastErrorMessage: json['last_error_message'],
      maxConnections: json['max_connections'],
      allowedUpdates: json['allowed_updates']?.cast<String>(),
    );
  }
}

class TelegramWebhookResponse {
  final bool success;
  final String? message;
  final String? error;

  TelegramWebhookResponse({required this.success, this.message, this.error});
}

/// Reply markup classes
abstract class TelegramReplyMarkup {
  Map<String, dynamic> toJson();
}

class TelegramInlineKeyboardMarkup extends TelegramReplyMarkup {
  final List<List<TelegramInlineKeyboardButton>> inlineKeyboard;

  TelegramInlineKeyboardMarkup({required this.inlineKeyboard});

  @override
  Map<String, dynamic> toJson() {
    return {
      'inline_keyboard': inlineKeyboard
          .map((row) => row.map((button) => button.toJson()).toList())
          .toList(),
    };
  }
}

class TelegramInlineKeyboardButton {
  final String text;
  final String? url;
  final String? callbackData;

  TelegramInlineKeyboardButton({
    required this.text,
    this.url,
    this.callbackData,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      if (url != null) 'url': url,
      if (callbackData != null) 'callback_data': callbackData,
    };
  }
}

class TelegramReplyKeyboardMarkup extends TelegramReplyMarkup {
  final List<List<TelegramKeyboardButton>> keyboard;
  final bool? resizeKeyboard;
  final bool? oneTimeKeyboard;
  final String? inputFieldPlaceholder;
  final bool? selective;

  TelegramReplyKeyboardMarkup({
    required this.keyboard,
    this.resizeKeyboard,
    this.oneTimeKeyboard,
    this.inputFieldPlaceholder,
    this.selective,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'keyboard': keyboard
          .map((row) => row.map((button) => button.toJson()).toList())
          .toList(),
      if (resizeKeyboard != null) 'resize_keyboard': resizeKeyboard,
      if (oneTimeKeyboard != null) 'one_time_keyboard': oneTimeKeyboard,
      if (inputFieldPlaceholder != null)
        'input_field_placeholder': inputFieldPlaceholder,
      if (selective != null) 'selective': selective,
    };
  }
}

class TelegramKeyboardButton {
  final String text;
  final bool? requestContact;
  final bool? requestLocation;

  TelegramKeyboardButton({
    required this.text,
    this.requestContact,
    this.requestLocation,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      if (requestContact != null) 'request_contact': requestContact,
      if (requestLocation != null) 'request_location': requestLocation,
    };
  }
}

class TelegramReplyKeyboardRemove extends TelegramReplyMarkup {
  final bool removeKeyboard = true;
  final bool? selective;

  TelegramReplyKeyboardRemove({this.selective});

  @override
  Map<String, dynamic> toJson() {
    return {
      'remove_keyboard': removeKeyboard,
      if (selective != null) 'selective': selective,
    };
  }
}

/// Telegram exceptions
class TelegramException implements Exception {
  final String message;

  const TelegramException(this.message);

  @override
  String toString() => 'TelegramException: $message';
}

class TelegramApiException extends TelegramException {
  final String? errorCode;
  final int? statusCode;

  const TelegramApiException({
    required String message,
    this.errorCode,
    this.statusCode,
  }) : super(message);

  @override
  String toString() => 'TelegramApiException: $message (Code: $errorCode)';
}

/// Provider for Telegram service
final telegramServiceProvider = Provider<TelegramService>((ref) {
  final config = ref.read(environmentConfigProvider);

  return TelegramService(
    botToken: config.telegramBotToken,
    webhookSecret: config.telegramWebhookSecret,
    httpClient: ref.read(httpClientProvider),
    logger: ref.read(loggerProvider),
  );
});
