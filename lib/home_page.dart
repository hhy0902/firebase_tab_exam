import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_tabbar_exam/provider/firebase_item_provider.dart';

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> with TickerProviderStateMixin  {
  TextEditingController textController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TabController? tabController;
  final db = FirebaseFirestore.instance;

  @override
  void dispose() {
    tabController?.dispose();
    textController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCategoryValue = ref.watch(currentCategoryProvider);
    final currentTabIndex = ref.watch(currentTabIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TabBar Example'),
        actions: [
          TextButton(
            onPressed: () async {
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
                        onPressed: () async {
                          if (textController.text.isEmpty) {
                            return;
                          }

                          final docRef = db.collection("category").doc(textController.text);

                          // 문서 존재 여부 확인
                          final docSnapshot = await docRef.get();

                          if(docSnapshot.exists) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Duplicate Tab"),
                                  content: const Text("This tab already exists."),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        textController.clear();
                                        Navigator.pop(context);
                                      },
                                      child: const Text("OK"),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            await docRef.set({
                              "categoryName": textController.text,
                              "createdAt": FieldValue.serverTimestamp(),
                            });
                            textController.clear();
                            Navigator.pop(context);
                          }

                        },
                        child: const Text("Add"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          textController.clear();
                        },
                        child: const Text("Cancel"),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text("탭 추가"),
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


          if (tabController == null || tabController!.length != tabList.length) {
            tabController?.dispose();
            tabController = TabController(length: tabList.length, vsync: this)
              ..addListener(() {
                if (tabController!.indexIsChanging) {
                  ref.read(currentTabIndexProvider.notifier).state = tabController!.index;
                }
              });

          }

          return Column(
            children: [
              TabBar(
                controller: tabController,
                tabs: tabList.map((tabTitle) => Tab(text: tabTitle)).toList(),
                isScrollable: true,
              ),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: tabList.map((tabTitle) {
                    return Column(
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: db
                              .collection("category")
                              .doc(currentCategoryValue.value!.docs[currentTabIndex].id)
                              .collection("food")
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Center(child: Text("No data available."));
                            }

                            final foodItems = snapshot.data!.docs;

                            return Expanded(
                              child: ListView.builder(
                                itemCount: foodItems.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(foodItems[index]["제품 명"]),
                                    subtitle: Text("${foodItems[index]["가격"]}원"),
                                    trailing: IconButton(
                                      onPressed: () {
                                        db.collection("category").doc(currentCategoryValue.value!.docs[currentTabIndex].id)
                                            .collection("food").doc(foodItems[index].id).delete();

                                        print(foodItems[index].id);
                                        print(currentCategoryValue.value!.docs[currentTabIndex].id);

                                        print(currentCategoryValue.value!.docs[currentTabIndex].id);
                                        print(currentTabIndex);

                                      },
                                      icon: Icon(Icons.delete),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {

              final documentId = currentCategoryValue.value!.docs[currentTabIndex].id;
              print(currentCategoryValue.value!.docs[tabController!.index].id);
              print('현재 선택된 Tab: ${tabController!.index}');
              print(currentTabIndex);
              print(documentId);

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("음식 입력"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: textController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: "음식명",
                          ),
                        ),
                        TextField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: "가격",
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {

                          if (textController.text.isEmpty || priceController.text.isEmpty) {
                            return;
                          }

                          final docRef = db.collection("category").doc(documentId).collection("food").doc(textController.text);

                          final docSnapshot = await docRef.get();
                          print(docSnapshot.exists);

                          if(docSnapshot.exists) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Duplicate item"),
                                  content: const Text("This item already exists."),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        textController.clear();
                                        priceController.clear();
                                        Navigator.pop(context);
                                      },
                                      child: const Text("OK"),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            await docRef.set({
                              "제품 명": textController.text,
                              "가격": priceController.text,
                            });

                            textController.clear();
                            priceController.clear();
                            Navigator.pop(context);
                          }

                        },
                        child: const Text("입력"),
                      ),
                      TextButton(
                        onPressed: () {
                          textController.clear();
                          priceController.clear();
                          Navigator.pop(context);
                        },
                        child: const Text("취소"),
                      ),
                    ],
                  );
                },
              );

            },
            child: const Icon(Icons.edit),
          ),
          SpeedDial(
            animatedIcon: AnimatedIcons.menu_close,
            overlayOpacity: 0.5,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.add),
                label: 'Add Item',
                onTap: () => print('Add Item tapped'),
              ),
              SpeedDialChild(
                child: const Icon(Icons.edit),
                label: 'Edit Item',
                onTap: () => print('Edit Item tapped'),
              ),
              SpeedDialChild(
                child: const Icon(Icons.delete),
                label: 'Delete Item',
                onTap: () => print('Delete Item tapped'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
