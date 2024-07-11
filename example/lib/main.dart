import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation/riverpod_mutation.dart';

part 'main.g.dart';

void main(List<String> args) {
  runApp(
    const ProviderScope(
      child: MaterialApp(home: ExampleScreen()),
    ),
  );
}

class Repository {
  static final Repository _instance = Repository._internal();

  factory Repository() => _instance;

  Repository._internal();

  final _todos = [
    TODO(
      title: 'Buy milk',
      completed: false,
    ),
    TODO(
      title: 'Buy eggs',
      completed: true,
    ),
    TODO(
      title: 'Buy bread',
      completed: false,
    ),
  ];

  Future<List<TODO>> fetchTodos() async {
    await Future.delayed(const Duration(seconds: 1));
    return _todos;
  }

  Future<TODO> createTodo() async {
    return Future.delayed(const Duration(seconds: 1), () {
      if (Random().nextBool()) {
        throw Exception('Failed to create todo');
      } else {
        final todo = TODO(
          title: 'Buy cheese ${Random().nextInt(1000000)}',
          completed: false,
        );
        _todos.add(todo);
        return todo;
      }
    });
  }
}

class TODO {
  final String title;
  final bool completed;

  TODO({
    required this.title,
    required this.completed,
  });
}

@riverpod
class Example extends _$Example {
  @override
  Future<List<TODO>> build() {
    return Repository().fetchTodos();
  }

  Future<TODO> addTodo() async {
    final result = await Repository().createTodo();
    ref.invalidateSelf();
    return result;
  }
}

class ExampleScreen extends HookConsumerWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = exampleProvider;
    final todos = ref.watch(provider);

    final addTodo = useMutation<TODO>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: addTodo.maybeWhen(
          loading: () => const CircularProgressIndicator(),
          orElse: () => const Icon(Icons.add),
        ),
        onPressed: () {
          final notifier = ref.read(provider.notifier);

          addTodo.future(
            notifier.addTodo(),
            data: (data) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Created todo: ${data.title}'),
                ),
              );
            },
            error: (error, stackTrace) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create todo: $error'),
                ),
              );
            },
          );
        },
      ),
      body: todos.when(
        data: (data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(provider.future),
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final todo = data[index];
                return ListTile(
                  title: Text(todo.title),
                );
              },
            ),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text('Error: $error'),
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
