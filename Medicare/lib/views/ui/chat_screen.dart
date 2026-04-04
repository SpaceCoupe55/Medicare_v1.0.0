import 'package:medicare/controller/ui/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/utils/utils.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/my_text_style.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/images.dart';
import 'package:medicare/model/chat_model.dart';
import 'package:medicare/views/layout/layout.dart';
import 'package:get/get.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin, UIMixin {
  late ChatController controller;

  @override
  void initState() {
    controller = Get.put(ChatController());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        builder: (controller) {
          return Column(
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium(
                      "Chat",
                      fontSize: 18,
                      fontWeight: 600,
                    ),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Chat', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),
              Padding(
                padding: MySpacing.x(flexSpacing / 2),
                child: MyFlex(
                  children: [
                    MyFlexItem(sizes: 'lg-3 md-12', child: buildChatIndex()),
                    MyFlexItem(sizes: 'lg-9 md-12', child: buildChat()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildChatIndex() {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium("Inbox", fontWeight: 600),
          MySpacing.height(20),
          searchField(),
          MySpacing.height(20),
          MyText.bodyMedium(
            "Message (${controller.chat.length})",
            fontWeight: 600,
          ),
          MySpacing.height(20),
          SizedBox(
            height: 620,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: ListView.separated(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  itemCount: controller.searchChat.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    ChatModel chat = controller.searchChat[index];
                    bool isSelected = controller.selectedChat == index;
                    return MyContainer.bordered(
                      onTap: () {
                        controller.onChangeChat(chat);
                        controller.onSelectChat(index);
                      },
                      borderRadiusAll: 8,
                      color: isSelected ? contentTheme.secondary.withAlpha(36) : null,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              MyContainer.rounded(
                                paddingAll: 0,
                                height: 36,
                                width: 36,
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                child: Image.asset(
                                  chat.image,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              MySpacing.width(8),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: MyText.bodyMedium(
                                        chat.firstName,
                                        fontWeight: 600,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    MyText.bodySmall(
                                      '${Utils.getTimeStringFromDateTime(
                                        chat.messages.lastOrNull != null ? chat.messages.lastOrNull!.sendAt : DateTime.now(),
                                        showSecond: false,
                                      )}',
                                      fontWeight: 600,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          MySpacing.height(8),
                          MyText.bodySmall(
                            chat.messages.lastOrNull!.message,
                            fontWeight: 600,
                            muted: true,
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return MySpacing.height(20);
                  }),
            ),
          )
        ],
      ),
    );
  }

  Widget searchField() {
    return TextFormField(
      onChanged: controller.onSearchChat,
      controller: controller.searchController,
      style: MyTextStyle.bodyMedium(),
      decoration: InputDecoration(
        hintText: "Search",
        hintStyle: MyTextStyle.bodySmall(fontWeight: 600),
        prefixIcon: Icon(
          LucideIcons.search,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        isCollapsed: true,
        contentPadding: MySpacing.all(14),
      ),
    );
  }

  Widget buildChat() {
    return MyContainer(
      paddingAll: 0,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      borderRadiusAll: 12,
      child: Column(
        children: [
          Padding(
            padding: MySpacing.only(left: 23, right: 23, top: 22),
            child: Row(
              children: [
                if (controller.selectChat != null)
                  MyContainer.rounded(
                    height: 44,
                    width: 44,
                    paddingAll: 0,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Image.asset(
                      controller.selectChat!.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                MySpacing.width(12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [if (controller.selectChat != null) MyText.bodyMedium(controller.selectChat!.firstName, fontWeight: 600), MyText.bodySmall("Active Now", fontWeight: 600, muted: true)],
                ),
                Spacer(),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    InkWell(onTap: () {}, child: Icon(LucideIcons.phone_call)),
                    InkWell(onTap: () {}, child: Icon(LucideIcons.video)),
                    PopupMenuButton(
                      offset: Offset(-10, 10),
                      position: PopupMenuPosition.under,
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          padding: MySpacing.xy(16, 8),
                          height: 10,
                          child: MyText.bodySmall("View Contact"),
                        ),
                        PopupMenuItem(
                          padding: MySpacing.xy(16, 8),
                          height: 10,
                          child: MyText.bodySmall("Create Shortcut"),
                        ),
                        PopupMenuItem(
                          padding: MySpacing.xy(16, 8),
                          height: 10,
                          child: MyText.bodySmall("Clear Chat"),
                        ),
                        PopupMenuItem(
                          padding: MySpacing.xy(16, 8),
                          height: 10,
                          child: MyText.bodySmall("Block"),
                        ),
                      ],
                      child: Icon(
                        LucideIcons.ellipsis_vertical,
                        size: 18,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          Divider(height: 43),
          Padding(
            padding: MySpacing.only(left: 23, right: 23, bottom: 12),
            child: SizedBox(
              height: 614,
              child: ListView.separated(
                  controller: controller.scrollController,
                  itemCount: (controller.selectChat?.messages ?? []).length,
                  itemBuilder: (context, index) {
                    final message = (controller.selectChat?.messages ?? [])[index];
                    final isSent = message.fromMe == true;
                    final theme = isSent ? contentTheme.primary : contentTheme.secondary;
                    return Row(
                      mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isSent)
                          Column(
                            children: [
                              MyContainer.rounded(
                                height: 32,
                                width: 32,
                                paddingAll: 0,
                                child: Image.asset(
                                  controller.selectChat!.image,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              MySpacing.height(8),
                              MyText.bodySmall(
                                '${Utils.getTimeStringFromDateTime(
                                  message.sendAt,
                                  showSecond: false,
                                )}',
                                fontSize: 8,
                                muted: true,
                                fontWeight: 600,
                              ),
                            ],
                          ),
                        MySpacing.width(12),
                        Expanded(
                          child: Wrap(
                            alignment: isSent ? WrapAlignment.end : WrapAlignment.start,
                            children: [
                              MyContainer(
                                  padding: EdgeInsets.all(8),
                                  margin: EdgeInsets.only(
                                    left: isSent ? MediaQuery.of(context).size.width * 0.20 : 0,
                                    right: isSent ? 0 : MediaQuery.of(context).size.width * 0.20,
                                  ),
                                  color: theme.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  child: MyText.bodyMedium(
                                    message.message,
                                    fontWeight: 600,
                                    color: isSent ? contentTheme.primary : contentTheme.secondary,
                                    overflow: TextOverflow.clip,
                                  )),
                            ],
                          ),
                        ),
                        MySpacing.width(12),
                        if (controller.selectChat != null && isSent)
                          Column(
                            children: [
                              MyContainer.rounded(
                                height: 32,
                                width: 32,
                                paddingAll: 0,
                                child: Image.asset(
                                  Images.avatars[6],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              MySpacing.height(4),
                              MyText.bodySmall(
                                '${Utils.getTimeStringFromDateTime(
                                  message.sendAt,
                                  showSecond: false,
                                )}',
                                fontSize: 8,
                                muted: true,
                                fontWeight: 600,
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                  separatorBuilder: (context, index) {
                    return MySpacing.height(12);
                  }),
            ),
          ),
          Padding(
            padding: MySpacing.only(left: 23, right: 23, bottom: 22),
            child: sendMessage(),
          ),
        ],
      ),
    );
  }

  Widget sendMessage() {
    Widget messageOption(GestureTapCallback? onTap, IconData icon) {
      return MyContainer(
        onTap: onTap,
        paddingAll: 10,
        borderRadiusAll: 8,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        color: contentTheme.primary,
        child: Icon(icon, size: 20, color: contentTheme.onPrimary),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextFormField(
              maxLines: 1,
              minLines: 1,
              controller: controller.messageController,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              style: MyTextStyle.bodySmall(fontWeight: 600),
              decoration: InputDecoration(
                hintText: "Send message...",
                hintStyle: MyTextStyle.bodySmall(fontWeight: 600),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                isCollapsed: true,
                contentPadding: MySpacing.all(16),
              )),
        ),
        MySpacing.width(20),
        messageOption(() {}, LucideIcons.paperclip),
        MySpacing.width(20),
        messageOption(() => controller.sendMessage(), LucideIcons.send),
      ],
    );
  }
}
