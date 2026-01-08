import 'package:flutter/material.dart';
import '../../core/services/ai_service.dart';
import '../../design_system/tokens/color_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';

class AiChatScreen extends StatefulWidget {
  final String className; // Context for RAG

  const AiChatScreen({Key? key, required this.className}) : super(key: key);

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final AiService _aiService = AiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    "How do I take attendance?",
    "How to enroll students?",
    "What does red box mean?",
    "Show attendance summary",
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'content': 'Hello! I am your Smart Assistant. I can help you with app features or attendance records for ${widget.className}.'
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = quickText ?? _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final response = await _aiService.askGemini(text, widget.className);
      setState(() {
        _messages.add({'role': 'ai', 'content': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'content': 'Error: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textOnAccent)),
            Text(widget.className, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colors.textOnAccent.withOpacity(0.8))),
          ],
        ),
        backgroundColor: colors.accentPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textOnAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear Chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'ai',
                  'content': 'Chat cleared. How can I help you now?'
                });
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.space16,
                vertical: SpacingTokens.space20,
              ),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator(colors);
                }

                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg['content']!, isUser, colors);
              },
            ),
          ),
          if (_messages.length < 3)
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: SpacingTokens.space8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.space16),
                itemCount: _quickPrompts.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: SpacingTokens.space8),
                    child: ActionChip(
                      label: Text(_quickPrompts[index]),
                      backgroundColor: colors.accentPrimary.withOpacity(0.15),
                      labelStyle: TextStyle(color: colors.accentPrimary, fontSize: 12),
                      side: BorderSide(color: colors.borderSubtle),
                      onPressed: () => _sendMessage(_quickPrompts[index]),
                    ),
                  );
                },
              ),
            ),
          _buildInputArea(colors),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser, SemanticColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.space16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: colors.accentPrimary,
              radius: 16,
              child: Icon(Icons.smart_toy, size: 18, color: colors.textOnAccent),
            ),
            const SizedBox(width: SpacingTokens.space8),
          ],
          Flexible(
            child: Container(
              padding: Insets.cardPadding,
              decoration: BoxDecoration(
                color: isUser ? colors.accentPrimary : colors.backgroundSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(RadiusTokens.radiusLarge),
                  topRight: const Radius.circular(RadiusTokens.radiusLarge),
                  bottomLeft: isUser ? const Radius.circular(RadiusTokens.radiusLarge) : const Radius.circular(RadiusTokens.radiusSmall),
                  bottomRight: isUser ? const Radius.circular(RadiusTokens.radiusSmall) : const Radius.circular(RadiusTokens.radiusLarge),
                ),
                border: Border.all(
                  color: isUser ? Colors.transparent : colors.borderSubtle,
                  width: 1,
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isUser ? colors.textOnAccent : colors.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: SpacingTokens.space8),
            CircleAvatar(
              backgroundColor: colors.accentSecondary,
              radius: 16,
              child: Icon(Icons.person, size: 18, color: colors.textOnAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(SemanticColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.space16, left: 40),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.space16,
          vertical: SpacingTokens.space12,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundSurface,
          borderRadius: BorderRadius.circular(RadiusTokens.radiusLarge),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Text(
          '...',
          style: TextStyle(fontSize: 24, height: 0.5, color: colors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildInputArea(SemanticColors colors) {
    return Container(
      padding: Insets.cardPadding,
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        border: Border(top: BorderSide(color: colors.borderSubtle, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                hintStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.backgroundPrimary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.space16,
                  vertical: SpacingTokens.space12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.radiusXL),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.radiusXL),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.radiusXL),
                  borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: SpacingTokens.space12),
          FloatingActionButton(
            onPressed: () => _sendMessage(),
            backgroundColor: colors.accentPrimary,
            elevation: 2,
            mini: true,
            child: Icon(Icons.send_rounded, size: 20, color: colors.textOnAccent),
          ),
        ],
      ),
    );
  }
}
