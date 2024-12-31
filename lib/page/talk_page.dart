import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:groq_sdk/groq_sdk.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import "package:gpt_markdown/gpt_markdown.dart";
import 'package:url_launcher/url_launcher.dart';

class TalkPage extends HookWidget {
  const TalkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final groq = useState<Groq?>(null);
    final chat = useState<GroqChat?>(null);
    final canUseBool = useState(false);
    final chatHistory = useState([]);
    final controller = TextEditingController();
    final isFinished = useState(false);

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
                            child: chatHistory.value.isEmpty
                                ? Center(
                                    child: Text("AIに話しかけてみよう"),
                                  )
                                : ListView.builder(
                                    itemCount: chatHistory.value.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        child: Column(
                                          children: [
                                            ListTile(
                                              title: Text(chatHistory
                                                  .value[index]["name"]),
                                              subtitle: GptMarkdown(
                                                  chatHistory.value[index]
                                                      ["message"],
                                                  onLinkTab:
                                                      (url, title) async {
                                                // print(url);
                                                // print(title);
                                                if (!await launchUrl(
                                                    Uri.parse(url))) {
                                                  throw Exception(
                                                      'Could not launch ${Uri.parse(url)}');
                                                }
                                              }),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: () async {
                                    controller.clear();
                                    if (chat.value != null) {
                                      chatHistory.value = [
                                        ...chatHistory.value,
                                        {
                                          "name": "User",
                                          "message": controller.text
                                        }
                                      ];

                                      chatHistory.value = [
                                        ...chatHistory.value,
                                        {"name": "AI", "message": "AIが考え中です..."}
                                      ];

                                      final (response, usage) = await chat
                                          .value!
                                          .sendMessage(controller.text);
                                      chatHistory.value.removeLast();
                                      chatHistory.value = [
                                        ...chatHistory.value,
                                        {
                                          "name": "AI",
                                          "message":
                                              response.choices.first.message
                                        }
                                      ];
                                    }
                                  },
                                ),
                                hintText: "AIに話しかけてみよう",
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4.0)),
                                ),
                              ),
                              onSubmitted: (value) async {
                                controller.clear();
                                if (chat.value != null) {
                                  chatHistory.value = [
                                    ...chatHistory.value,
                                    {"name": "User", "message": value}
                                  ];

                                  chatHistory.value = [
                                    ...chatHistory.value,
                                    {"name": "AI", "message": "AIが考え中です..."}
                                  ];

                                  final (response, usage) =
                                      await chat.value!.sendMessage(value);
                                  chatHistory.value.removeLast();
                                  chatHistory.value = [
                                    ...chatHistory.value,
                                    {
                                      "name": "AI",
                                      "message": response.choices.first.message
                                    }
                                  ];
                                }
                              },
                            ),
                          ),
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
