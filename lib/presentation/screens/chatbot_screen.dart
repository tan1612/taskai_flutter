import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/presentation/providers/chat_provider.dart';
import 'package:taskai/presentation/widgets/chat_bubble.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackHome;

  const ChatbotScreen({
    super.key,
    this.onBackHome,
  });

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goHome() {
    if (widget.onBackHome != null) {
      widget.onBackHome!();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _send() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    _controller.clear();
    ref.read(chatProvider.notifier).send(text);

    Future.delayed(const Duration(milliseconds: 250), _scrollToBottom);
  }

  void _sendDirectly(String text) {
    ref.read(chatProvider.notifier).send(text);
    Future.delayed(const Duration(milliseconds: 250), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 180,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget _buildQuickChip(String text, ChatState state) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: scheme.primary,
        ),
      ),
      backgroundColor: scheme.primary.withOpacity(0.08),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      onPressed: state.isLoading ? null : () => _sendDirectly(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    ref.listen(chatProvider, (previous, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        ref.read(chatProvider.notifier).clearError();
      }

      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Về trang chủ',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goHome,
        ),
        title: const Text(
          'Trợ lý ảo Năm Ái',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.messages.length + (state.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Trợ lý Năm Ái đang tính toán...'),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ChatBubble(message: state.messages[index]);
              },
            ),
          ),
          
          // Gợi ý nhanh câu hỏi cho nhà xe du lịch
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickChip('Lịch chạy xe hôm nay?', state),
                const SizedBox(width: 8),
                _buildQuickChip('Xe nào đang rảnh?', state),
                const SizedBox(width: 8),
                _buildQuickChip('Báo cáo doanh số?', state),
                const SizedBox(width: 8),
                _buildQuickChip('Xem giá xăng dầu hôm nay?', state),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.15),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Nhập câu hỏi cho Trợ lý Năm Ái...',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.isLoading ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}