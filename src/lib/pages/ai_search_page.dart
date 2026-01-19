import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AiSearchPage extends StatefulWidget {
  const AiSearchPage({super.key});

  @override
  State<AiSearchPage> createState() => _AiSearchPageState();
}

class _AiSearchPageState extends State<AiSearchPage> {
  static const String _model = 'gpt-5.2';

  // API key via --dart-define
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<_ChatMsg> _msgs = [];
  bool _loading = false;

  String? _previousResponseId;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _loading) return;

    if (_apiKey.isEmpty) {
      _snack(
        'Falta a API key. Corre com: flutter run --dart-define=OPENAI_API_KEY=...',
      );
      return;
    }

    setState(() {
      _msgs.add(_ChatMsg.user(text));
      _loading = true;
    });
    _input.clear();
    _autoScroll();

    try {
      final reply = await _callOpenAI(text);
      setState(() {
        _msgs.add(_ChatMsg.assistant(reply.text));
        _previousResponseId = reply.responseId;
        _loading = false;
      });
      _autoScroll();
    } catch (e) {
      setState(() => _loading = false);
      _snack('Erro IA: $e');
    }
  }

  Future<_AiReply> _callOpenAI(String userText) async {
    final uri = Uri.parse('https://api.openai.com/v1/responses');

    final body = <String, dynamic>{
      'model': _model,
      'instructions': 'Responde em PT-PT. Sê claro, direto e útil. Se não souberes, diz.',
      'input': userText,
      'text': {
        'format': {'type': 'text'}
      },
      'max_output_tokens': 600,
    };

    if (_previousResponseId != null) {
      body['previous_response_id'] = _previousResponseId;
    }

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final msg = (j['error']?['message'] ?? res.body).toString();
        throw Exception(msg);
      } catch (_) {
        throw Exception(res.body);
      }
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final responseId = (data['id'] ?? '').toString();

    final output = (data['output'] as List?) ?? const [];
    final buffer = StringBuffer();

    for (final item in output) {
      if (item is! Map) continue;
      if (item['type'] != 'message') continue;
      if (item['role'] != 'assistant') continue;

      final content = (item['content'] as List?) ?? const [];
      for (final c in content) {
        if (c is! Map) continue;
        if (c['type'] == 'output_text') {
          buffer.writeln((c['text'] ?? '').toString());
        }
      }
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw Exception('Resposta vazia do modelo.');
    }

    return _AiReply(text: text, responseId: responseId);
  }

  void _newConversation() {
    setState(() {
      _msgs.clear();
      _previousResponseId = null;
    });
    _snack('Conversa reiniciada.');
  }

  void _snack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesquisa IA'),
        actions: [
          IconButton(
            tooltip: 'Nova conversa',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _newConversation,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BACKGROUND IMAGE (muda para o teu asset)
          Image.asset(
            'assets/ai_bg.png',
            fit: BoxFit.cover,
          ),

          // OVERLAY para legibilidade
          Container(
            color: Colors.black.withAlpha(71),
          ),

          // CONTEÚDO
          SafeArea(
            child: Column(
              children: [
                // Sugestões rápidas com fundo semi-transparente
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(191),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _PromptChip(
                          text: 'Explica-me isto de forma simples',
                          onTap: _loading
                              ? null
                              : () {
                            _input.text = 'Explica-me isto de forma simples: ';
                            _input.selection = TextSelection.fromPosition(
                              TextPosition(offset: _input.text.length),
                            );
                          },
                        ),
                        _PromptChip(
                          text: 'Dá-me um plano de estudo',
                          onTap: _loading
                              ? null
                              : () {
                            _input.text = 'Cria um plano de estudo para: ';
                            _input.selection = TextSelection.fromPosition(
                              TextPosition(offset: _input.text.length),
                            );
                          },
                        ),
                        _PromptChip(
                          text: 'Ajuda com Flutter',
                          onTap: _loading
                              ? null
                              : () {
                            _input.text = 'Ajuda-me com Flutter: ';
                            _input.selection = TextSelection.fromPosition(
                              TextPosition(offset: _input.text.length),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),

                Expanded(
                  child: _msgs.isEmpty
                      ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(191),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Escreve uma pergunta para começares.\n\nModelo: $_model',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  )
                      : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: _msgs.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_loading && i == _msgs.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _TypingBubble(),
                          ),
                        );
                      }

                      final m = _msgs[i];
                      final isMe = m.role == _Role.user;

                      return Align(
                        alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? theme.colorScheme.primaryContainer.withAlpha(235)
                                  : Colors.white.withAlpha(209),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withAlpha(153),
                              ),
                            ),
                            child: SelectableText(
                              m.text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.black87,
                                fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Divider(height: 1),

                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          enabled: !_loading,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Escreve aqui…',
                            filled: true,
                            fillColor: Colors.white.withAlpha(217),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: _loading ? null : _send,
                        icon: const Icon(Icons.send),
                        tooltip: 'Enviar',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Role { user, assistant }

class _ChatMsg {
  final _Role role;
  final String text;

  _ChatMsg._(this.role, this.text);

  factory _ChatMsg.user(String t) => _ChatMsg._(_Role.user, t);
  factory _ChatMsg.assistant(String t) => _ChatMsg._(_Role.assistant, t);
}

class _AiReply {
  final String text;
  final String responseId;
  _AiReply({required this.text, required this.responseId});
}

class _PromptChip extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _PromptChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text),
        onPressed: onTap,
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withAlpha(209),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(153),
        ),
      ),
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
