import 'package:flutter/material.dart' hide Action, Page;
import 'package:fish_redux/fish_redux.dart';

import 'pages/count/page.dart';
import 'pages/todos/edit/page.dart';
import 'pages/todos/page/page.dart';

/// Define a basic behavior of routes.
abstract class AbstractRoutes {
  Widget get home;
  Widget buildPage(String? path, dynamic arguments);
}

/// Each page has a unique store.
@immutable
class PageRoutes implements AbstractRoutes {
  final Map<String, Page<Object, dynamic>> pages;

  PageRoutes({
    required this.pages,

    /// For common enhance
    void Function(String, Page<Object, dynamic>)? visitor,
  }) {
    if (visitor != null) {
      pages.forEach(visitor);
    }
  }

  @override
  Widget buildPage(String? path, dynamic arguments) {
    assert(path != null && path.isNotEmpty && pages.keys.contains(path));
    return pages[path]!.buildPage(arguments);
  }

  @override
  Widget get home => pages['todo_list']!.buildPage(<String, dynamic>{});
}

final AbstractRoutes routes = PageRoutes(
  pages: <String, Page<Object, dynamic>>{
    /// Register TodoList main page
    'todo_list': ToDoListPage(),

    /// Register Todo edit page
    'todo_edit': TodoEditPage(),

    /// Register Count page
    'count': CountPage(),
  },
  visitor: (String path, Page<Object, dynamic> page) {},
);
