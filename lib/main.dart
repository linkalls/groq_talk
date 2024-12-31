import 'package:flutter/material.dart';
import "package:flutter_hooks/flutter_hooks.dart";
import "package:groq_sdk/groq_sdk.dart";
import 'package:gpt_markdown/gpt_markdown.dart';
import "package:groq_talk/gen/env.g.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      home: TalkPage(),
    );
  }
}

class TalkPage extends HookWidget {
  const TalkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final groq =
        Groq(Env.apiKey);
    final chat = useState<GroqChat?>(null);
    final canUseBool = useState(false);
    final chatHistory = useState([]);
    final _controller = TextEditingController();

    useEffect(() {
      // if (count.value > 0) {
      Future<bool> canUse() async {
        if (!await groq.canUseModel(GroqModels.llama3_70b)) {
          return false;
        }
        return true;
      }

      canUse().then((value) {
        canUseBool.value = value;
        if (value) {
          chat.value = groq.startNewChat(GroqModels.llama3_70b);
        }
      });
      // }
    }, []);

    return Scaffold(
      body: canUseBool.value
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
                                        title: Text(
                                            chatHistory.value[index]["name"]),
                                        subtitle: GptMarkdown(
                                          (chatHistory.value[index]
                                                  ["message"] ??
                                              ""),
                                        ),
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
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "AIに話しかけてみよう",
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(4.0)),
                          ),
                        ),
                        onSubmitted: (value) async {
                          _controller.clear();
                          // print(value);
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
                            // print(usage);
                            // print(chatHistory.value);
                            // chat.value!.stream.listen((event) {
                            //   event.when(
                            //       request: (requestEvent) {},
                            //       response: (responseEvent) {
                            //         print(
                            //             'Received response: ${responseEvent.response.choices.first.message}');
                            //       });
                            // });
                          }
                        },
                      ),
                    ),

                    // TextButton(
                    //     onPressed: () async {
                    //       if (chat.value != null) {
                    //         chat.value!.sendMessage('兎田ぺこらについて知っていますか？');
                    //         chat.value!.stream.listen((event) {
                    //           event.when(request: (requestEvent) {
                    //             //Listen for user prompts
                    //             // print('Request sent...');
                    //             // print(requestEvent.message.content);
                    //           }, response: (responseEvent) {
                    //             //Listen for llm responses
                    //             print(
                    //                 'Received response: ${responseEvent.response.choices.first.message}');
                    //           });
                    //         });
                    //         // print(response);
                    //       } else {
                    //         print('Chat is not initialized');
                    //       }
                    //     },
                    //     child: Text("aaa")),
                  ],
                ),
              ),
            )
          : const Text("can't use"),
    );
  }
}
