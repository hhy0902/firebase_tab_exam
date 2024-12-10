

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_tabbar_exam/provider/firebase_item_provider.dart';
import 'package:image_picker/image_picker.dart';

class FabSpeedDial extends ConsumerStatefulWidget {
  const FabSpeedDial({super.key});

  @override
  ConsumerState createState() => _FabSpeedDialState();
}

class _FabSpeedDialState extends ConsumerState<FabSpeedDial> {
  File? _image; // 선택한 이미지 파일 저장
  final ImagePicker _picker = ImagePicker(); // ImagePicker 인스턴스 생성

  TextEditingController textController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  final db = FirebaseFirestore.instance;


  // 갤러리에서 이미지 선택
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // 이미지 파일 저장
        print("gallery : ${_image!.path}");
      });
    }
  }

  // 카메라로 이미지 촬영
  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // 이미지 파일 저장
      });
    }
  }

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
                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: Text("${documentId} tap 음식 입력"),
                      content: SingleChildScrollView(
                        child: Column(
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
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "가격",
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_image != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Image.file(
                                      _image!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: CircleAvatar(
                                      radius: 40,
                                      child: Icon(Icons.photo, size: 30),
                                    ),
                                  ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                                        if (pickedFile != null) {
                                          setState(() {
                                            _image = File(pickedFile.path);
                                          });
                                        }
                                      },
                                      icon: Icon(Icons.camera_alt, size: 20),
                                      label: Text("카메라"),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 2,
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                                        if (pickedFile != null) {
                                          setState(() {
                                            _image = File(pickedFile.path);
                                          });
                                        }
                                      },
                                      icon: Icon(Icons.image_outlined, size: 20),
                                      label: Text("갤러리"),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 2,
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
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
                                "이미지" : "",
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
                  }
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
          onTap: () {

            final documentLength = currentCategoryValue.value!.docs.length;

            if(documentLength == 0) {
              return;
            }

            final documentId = currentCategoryValue.value!.docs[currentTabIndex].id;
            print("currentTabIndex : ${currentTabIndex}");
            print("docs.length : ${currentCategoryValue.value!.docs.length}");
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
                          print("지우기 전 currentTabIndex : ${currentTabIndex}");
                          for (var doc in snapshot.docs) {
                            doc.reference.delete();
                          }
                        });

                        await db.collection("category").doc(documentId).delete();


                        // 업데이트된 탭 가져오기
                        final updatedTabs = await db.collection("category").orderBy("createdAt").get();
                        // 탭 인덱스 업데이트
                        ref.read(currentTabIndexProvider.notifier).updateIndex(
                            currentTabIndex,
                            updatedTabs.docs.length
                        );

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

