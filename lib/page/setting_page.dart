import 'package:flutter/material.dart';
import "package:flutter_hooks/flutter_hooks.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:go_router/go_router.dart";

class SettingPage extends HookWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _controller = useState<TextEditingController?>(null);

    useEffect(
      () {
        Future<String?> getApiKey() async {
          final SharedPreferences preferences =
              await SharedPreferences.getInstance();
          return preferences.getString("api_key");
        }

        getApiKey().then((value) {
          _controller.value = TextEditingController(text: value);
        });
        return null;
      },
      const [],
    );

    return SafeArea(
      child: Center(
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("Settings"),
            leading: IconButton(
              //* leadingで左側にアイコンを表示
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.go("/");
              },
            ),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _controller.value,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: () async {
                        final SharedPreferences preferences =
                            await SharedPreferences.getInstance();
                        await preferences.setString(
                            "api_key", _controller.value!.text);
                        _controller.value!.clear();
                      },
                    ),
                    hintText: "API KEYを入力してください",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
