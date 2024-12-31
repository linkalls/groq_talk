import "package:go_router/go_router.dart";
import "package:groq_talk/page/talk_page.dart";
import "package:groq_talk/page/setting_page.dart";

final router = GoRouter(initialLocation: "/", routes: [
  GoRoute(
    path: "/",
    builder: (context, state) => TalkPage(),
    name: "home",
  ),
  GoRoute(
    path: "/settings",
    name: "settings",
    builder: (context, state) => SettingPage(),
  ),
]);
