import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabbar_exam/provider/firebase_item_provider.dart';

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  TextEditingController textController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  var db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final categoryAsyncValue = ref.watch(categoryProvider);
    final tabIndexProvider = ref.watch(currentTabIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TabBar Example'),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Add Tab"),
                    content: TextField(
                      controller: textController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: "Enter tab name",
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          if (textController.text.isNotEmpty) {
                            db
                                .collection("category")
                                .doc(textController.text)
                                .set({
                              "categoryName": textController.text,
                              "createdAt": FieldValue.serverTimestamp(),
                            });
                          }
                          textController.clear();
                          Navigator.pop(context);
                        },
                        child: const Text("Add"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text("tap 추가"),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection("category").orderBy("createdAt", descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tabs available."));
          }

          // Firestore 데이터로 탭 목록 구성
          List<String> tabList = snapshot.data!.docs.map((doc) {
            return doc["categoryName"] as String;
          }).toList();

          final items = snapshot.data!.docs;

          return DefaultTabController(
            length: tabList.length,
            key: ValueKey(tabList.length),
            child: Column(
              children: [
                TabBar(
                  tabs: tabList.map((tabTitle) => Tab(text: tabTitle)).toList(),
                  isScrollable: true,
                ),
                Expanded(
                  child: TabBarView(
                    children: tabList.map((tabTitle) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StreamBuilder<QuerySnapshot>(
                                stream: db
                                    .collection("category")
                                    .doc(items[tabList.indexOf(tabTitle)].id)
                                    .collection("food")
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const Center(
                                        child: Text("No data available."));
                                  }

                                  final items = snapshot.data!.docs;

                                  return Expanded(
                                    child: ListView.builder(
                                        itemCount: items.length,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            title: Text(items[index]["제품 명"]),
                                            subtitle: Text(items[index]["가격"]),
                                          );
                                        }),
                                  );
                                }),
                            Center(
                              child: Text('$tabTitle Tab'),
                            ),
                            IconButton(
                              onPressed: () {
                                print(items[tabList.indexOf(tabTitle)].id);
                                print(tabTitle);
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text("음식 입력"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: textController,
                                            autofocus: true,
                                            decoration: InputDecoration(
                                              labelText: "음식명",
                                            ),
                                          ),
                                          TextField(
                                            controller: priceController,
                                            decoration: InputDecoration(
                                              labelText: "가격",
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              db
                                                  .collection("category")
                                                  .doc(items[tabList
                                                  .indexOf(tabTitle)]
                                                  .id)
                                                  .collection("food")
                                                  .doc(textController.text)
                                                  .set({
                                                "제품 명": textController.text,
                                                "가격": priceController.text,
                                              });
                                            });
                                            textController.clear();
                                            priceController.clear();
                                            Navigator.pop(context);
                                          },
                                          child: Text("입력"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text("취소"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: Icon(Icons.add),
                            ),
                          ],
                        );
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print(categoryAsyncValue.value!.docs[0].id);
          print(tabIndexProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}