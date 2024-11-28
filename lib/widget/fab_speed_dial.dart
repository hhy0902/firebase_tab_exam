

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_tabbar_exam/provider/firebase_item_provider.dart';

class FabSpeedDial extends ConsumerStatefulWidget {
  const FabSpeedDial({super.key});

  @override
  ConsumerState createState() => _FabSpeedDialState();
}

class _FabSpeedDialState extends ConsumerState<FabSpeedDial> {

  TextEditingController textController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  final db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentCategoryValue = ref.watch(currentCategoryProvider);
    final currentTabIndex = ref.watch(currentTabIndexProvider);

    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      overlayOpacity: 0.5,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.add),
          label: 'Add Item',
          onTap: () {
            final documentId = currentCategoryValue.value!.docs[currentTabIndex].id;
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
                        if (textController.text.isEmpty ||
                            priceController.text.isEmpty) {
                          return;
                        }

                        final docRef = db
                            .collection("category")
                            .doc(documentId)
                            .collection("food")
                            .doc(textController.text);

                        final docSnapshot = await docRef.get();
                        print(docSnapshot.exists);

                        if (docSnapshot.exists) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Duplicate item"),
                                content:
                                const Text("This item already exists."),
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
        ),
        SpeedDialChild(
          child: const Icon(Icons.edit),
          label: '카테고리 추가',
          onTap: () async {
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
        ),
        SpeedDialChild(
          child: const Icon(Icons.delete),
          label: '카테고리 삭제',
          onTap: () async {
            final documentId = currentCategoryValue.value!.docs[currentTabIndex].id;
            print('Delete Item tapped');
            print(documentId);

            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Delete ${documentId} Tab "),
                  content: const Text("Are you sure you want to delete this tab?"),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        // await db.collection("category").doc(currentCategoryValue.value!.docs[currentTabIndex].id).delete();

                        await db.collection("category").doc(documentId).collection("food").get().then((snapshot) {
                          for (var doc in snapshot.docs) {
                            doc.reference.delete();
                          }
                        });

                        await db.collection("category").doc(documentId).delete();

                        // // 새 카테고리 목록 가져오기
                        // final newCategorySnapshot = await db.collection("category").orderBy("createdAt").get();
                        //
                        // // currentTabIndex 업데이트
                        // if (newCategorySnapshot.docs.isNotEmpty) {
                        //   // 삭제된 탭이 마지막 탭일 경우, 인덱스를 조정
                        //   final newIndex = currentTabIndex >= newCategorySnapshot.docs.length
                        //       ? newCategorySnapshot.docs.length - 1
                        //       : currentTabIndex;
                        //   ref.read(currentTabIndexProvider.notifier).state = newIndex;
                        // } else {
                        //   // 모든 탭이 삭제된 경우
                        //   ref.read(currentTabIndexProvider.notifier).state = 0;
                        // }

                        Navigator.pop(context);
                      },
                      child: const Text("Delete"),
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
            // db.collection("category").doc(currentCategoryValue.value!.docs[currentTabIndex].id).delete();
          },
        ),
      ],
    );
  }
}


