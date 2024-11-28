import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_tabbar_exam/provider/firebase_item_provider.dart';
import 'package:flutter_tabbar_exam/widget/fab_speed_dial.dart';

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

          // Firestore 데이터를 기반으로 탭 생성
          final tabs = snapshot.data!.docs;

          // TabController 초기화 및 기존 상태 유지
          if (tabController == null) {
            tabController = TabController(length: tabs.length, vsync: this)
              ..addListener(() {
                if (tabController!.indexIsChanging) {
                  ref.read(currentTabIndexProvider.notifier).state = tabController!.index;
                }
              });
          } else if (tabController!.length != tabs.length) {
            final previousIndex = tabController!.index;
            tabController!.dispose();
            tabController = TabController(
              length: tabs.length,
              vsync: this,
              initialIndex: (previousIndex < tabs.length) ? previousIndex : 0,
            )..addListener(() {
              if (tabController!.indexIsChanging) {
                ref.read(currentTabIndexProvider.notifier).state = tabController!.index;
              }
            });
          }

          print(tabController!.index);
          print(currentTabIndex);

          return Column(
            children: [
              TabBar(
                controller: tabController,
                tabs: tabs.map((tabTitle) => Tab(text: tabTitle["categoryName"])).toList(),
                isScrollable: true,
              ),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: tabs.map((tabTitle) {
                    return Column(
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: db
                              .collection("category")
                              .doc(tabTitle.id)
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
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text("Delete ${foodItems[index]["제품 명"]}"),
                                              content: Text("Are you sure you want to delete this item?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    print(tabs[currentTabIndex].id);
                                                    print(currentCategoryValue.value!.docs[currentTabIndex].id);
                                                    print(tabController!.index);
                                                    print(tabs[tabController!.index].id);
                                                    print(tabs[currentTabIndex].id);
                                                    print(tabTitle.id);
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    db.collection("category").doc(currentCategoryValue.value!.docs[currentTabIndex].id)
                                                        .collection("food").doc(foodItems[index].id).delete();
                                                  },
                                                  child: Text("Delete"),
                                                ),
                                              ],
                                            );
                                          },
                                        );

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
      floatingActionButton: FabSpeedDial(),
    );
  }
}
