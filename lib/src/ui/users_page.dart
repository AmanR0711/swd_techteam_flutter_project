import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../models/paged_req_res_user.dart';
import '../providers/providers.dart';
import '../ui/user_tile.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final PagingController<int, PagedReqResUser> _pg = PagingController(
    firstPageKey: 1,
  );

  @override
  void initState() {
    super.initState();
    _pg.addPageRequestListener((pageKey) {
      _getData(pageKey);
    });
  }

  void _getData(int pageKey) async {
    try {
      final provider = ref.watch(userProvider.notifier).provider;
      final res = await provider.getUsers(pageKey);
      bool isEnd = res.users.length >= provider.total;
      if (isEnd || res.users.isEmpty) {
        _pg.value = PagingState(
          itemList: [...(_pg.value.itemList ?? []), res],
          nextPageKey: null,
        );
        // _pg.appendLastPage([res]);
      } else {
        _pg.value = PagingState(
          itemList: [...(_pg.value.itemList ?? []), res],
          nextPageKey: pageKey + 1,
        );
        // _pg.appendPage([res], pageKey + 1);
      }
    } catch (e) {
      _pg.error = e;
    }
  }

  @override
  void dispose() {
    if (mounted) _pg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView(
      pagingController: _pg,
      builderDelegate: PagedChildBuilderDelegate<PagedReqResUser>(
        animateTransitions: true,
        transitionDuration: const Duration(milliseconds: 1250),
        newPageErrorIndicatorBuilder: (context) => const Text(
          "An Error Occured. Please try again later.",
        ),
        itemBuilder: (context, item, index) => _buildItem(index),
      ),
    );
  }

  Widget _buildItem(int index) => _pg.value.itemList![index].users.isNotEmpty
      ? Padding(
          padding: const EdgeInsets.only(
            top: 8.0,
            left: 8.0,
            right: 8.0,
          ),
          child: Column(
            children: [
              Card(
                color: Theme.of(context).canvasColor,
                elevation: 8.0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Page ${_pg.value.itemList![index].page}:",
                        style: const TextStyle(fontSize: 18.0),
                      ),
                      for (final user in _pg.value.itemList![index].users)
                        UserTile(user: user)
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
      : Padding(
          padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
          child: Center(
            child: Card(
              color: Theme.of(context).errorColor,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "No more Users found.",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        );
  // );
}
