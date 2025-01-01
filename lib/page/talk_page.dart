import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:groq_sdk/groq_sdk.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import "package:gpt_markdown/gpt_markdown.dart";
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'dart:convert';
import 'dart:math';

class TalkPage extends HookWidget {
  const TalkPage({super.key});

  String randomString() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  @override
  Widget build(BuildContext context) {
    final groq = useState<Groq?>(null);
    final chat = useState<GroqChat?>(null);
    final canUseBool = useState(false);
    final _messages = useState<List<types.Message>>([]);
    final _user = const types.User(
        id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
        firstName: "poteto",
        lastName: "town",
        imageUrl:
            "https://pbs.twimg.com/profile_images/1722561394103685120/lEyNiiLu_400x400.jpg");
    final chatHistory = useState([]);
    final controller = TextEditingController();
    final isFinished = useState(false);

    final _other = const types.User(
        id: 'otheruser',
        firstName: "AI",
        imageUrl:
            "https://pbs.twimg.com/profile_images/1722561394103685120/lEyNiiLu_400x400.jpg");

    useEffect(() {
      Future<String?> getApiKey() async {
        final SharedPreferences preferences =
            await SharedPreferences.getInstance();
        return preferences.getString("api_key");
      }

      Future<void> initializeGroq() async {
        final apiKey = await getApiKey();
        if (apiKey == null) {
          context.go("/settings");
          return;
        }
        groq.value = Groq(apiKey);

        final canUse = await groq.value!.canUseModel(GroqModels.llama3_70b);
        canUseBool.value = canUse;
        if (canUse) {
          chat.value = groq.value!.startNewChat(GroqModels.gemma2_9b);
        }
        isFinished.value = true;
      }

      initializeGroq();
      return;
    }, []);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Talk to AI"),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  context.go("/settings");
                },
              ),
            ),
          ],
        ),
        body: isFinished.value
            ? canUseBool.value
                ? Center(
                    child: SelectionArea(
                      child: Column(
                        children: [
                          Expanded(
                            child: Chat(
                              l10n: const ChatL10nJa(),
                              theme: const DefaultChatTheme(
                                inputBackgroundColor: Colors.deepPurple,
                                backgroundColor: Colors.black,
                              ),
                              showUserAvatars: true,
                              showUserNames: true,
                              messages: _messages.value,
                              onSendPressed: (types.PartialText message) async {
                                print("send pressed");
                                print(message.text);
                                final textMessage = types.TextMessage(
                                  author: _user,
                                  createdAt:
                                      DateTime.now().millisecondsSinceEpoch,
                                  id: randomString(),
                                  text: message.text,
                                );
                                _messages.value = [
                                  textMessage,
                                  ..._messages.value
                                ];
                                final thinkingMessage = types.TextMessage(
                                  author: _other,
                                  createdAt:
                                      DateTime.now().millisecondsSinceEpoch,
                                  id: randomString(),
                                  text: "AIが考え中です...",
                                );
                                _messages.value = [
                                  thinkingMessage,
                                  ..._messages.value
                                ];
                                final (response, usage) =
                                    await chat.value!.sendMessage(message.text);
                                final aiMessage = types.TextMessage(
                                    author: _other,
                                    id: randomString(),
                                    text: response.choices.first.message);
                                _messages.value.removeAt(0);
                                _messages.value = [
                                  aiMessage,
                                  ..._messages.value
                                ];
                                // response.choices.first.message;
                              },
                              user: _user,
                            ),
                          ),
                          // Expanded(
                          //   child: chatHistory.value.isEmpty
                          //       ? Center(
                          //           child: Text("AIに話しかけてみよう"),
                          //         )
                          //       : ListView.builder(
                          //           itemCount: chatHistory.value.length,
                          //           itemBuilder: (context, index) {
                          //             return Card(
                          //               child: Column(
                          //                 children: [
                          //                   ListTile(
                          //                     title: Text(chatHistory
                          //                         .value[index]["name"]),
                          //                     subtitle: GptMarkdown(
                          //                         chatHistory.value[index]
                          //                             ["message"],
                          //                         onLinkTab:
                          //                             (url, title) async {
                          //                       // print(url);
                          //                       // print(title);
                          //                       if (UniversalPlatform.isWeb) {
                          //                       } else {
                          //                         await launchUrl(
                          //                             Uri.parse(url));
                          //                       }
                          //                     }),
                          //                   ),
                          // ],
                          //               ),
                          //             );
                          //           },
                          //         ),
                          // ),
                          // Padding(
                          //   padding: const EdgeInsets.all(10.0),
                          //   child: TextField(
                          //     controller: controller,
                          //     decoration: InputDecoration(
                          //       suffixIcon: IconButton(
                          //         icon: const Icon(Icons.send),
                          //         onPressed: () async {
                          //           controller.clear();
                          //           if (chat.value != null) {
                          //             chatHistory.value = [
                          //               ...chatHistory.value,
                          //               {
                          //                 "name": "User",
                          //                 "message": controller.text
                          //               }
                          //             ];

                          //             chatHistory.value = [
                          //               ...chatHistory.value,
                          //               {"name": "AI", "message": "AIが考え中です..."}
                          //             ];

                          //             final (response, usage) = await chat
                          //                 .value!
                          //                 .sendMessage(controller.text);
                          //             chatHistory.value.removeLast();
                          //             chatHistory.value = [
                          //               ...chatHistory.value,
                          //               {
                          //                 "name": "AI",
                          //                 "message":
                          //                     response.choices.first.message
                          //               }
                          //             ];
                          //           }
                          //         },
                          //       ),
                          //       hintText: "AIに話しかけてみよう",
                          //       border: OutlineInputBorder(
                          //         borderRadius:
                          //             BorderRadius.all(Radius.circular(4.0)),
                          //       ),
                          //     ),
                          //     onSubmitted: (value) async {
                          //       controller.clear();
                          //       if (chat.value != null) {
                          //         chatHistory.value = [
                          //           ...chatHistory.value,
                          //           {"name": "User", "message": value}
                          //         ];

                          //         chatHistory.value = [
                          //           ...chatHistory.value,
                          //           {"name": "AI", "message": "AIが考え中です..."}
                          //         ];

                          //         final (response, usage) =
                          //             await chat.value!.sendMessage(value);
                          //         chatHistory.value.removeLast();
                          //         chatHistory.value = [
                          //           ...chatHistory.value,
                          //           {
                          //             "name": "AI",
                          //             "message": response.choices.first.message
                          //           }
                          //         ];
                          //       }
                          //     },
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  )
                : const Text("can't use")
            : Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.blue,
                  size: 50,
                ),
              ),
      ),
    );
  }
}

// 適当な場所に追加
class ChatL10nJa extends ChatL10n {
  const ChatL10nJa({
    super.and = 'と',
    super.attachmentButtonAccessibilityLabel = '画像アップロード',
    super.emptyChatPlaceholder = 'メッセージがありません。',
    super.fileButtonAccessibilityLabel = 'ファイル',
    super.inputPlaceholder = 'メッセージを入力してください',
    super.isTyping = '入力中...',
    super.others = '他の人',
    super.sendButtonAccessibilityLabel = '送信',
    super.unreadMessagesLabel = '未読メッセージ',
  });
}
