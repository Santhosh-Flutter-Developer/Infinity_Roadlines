import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip_model.dart';
import '../../providers/local_trip_list_provider.dart';

/// "Dispatched" / "Completed" tabs for Local drivers. Each tab is a paged list
/// (20 per page) that renders every row with the same card the General list
/// uses ([cardBuilder]). The API is called again every time a tab is selected
/// (tap or swipe) and when the already-selected tab is tapped again.
class LocalTripSheetTabs extends StatefulWidget {
  final Widget Function(BuildContext context, TripModel trip) cardBuilder;

  const LocalTripSheetTabs({super.key, required this.cardBuilder});

  @override
  State<LocalTripSheetTabs> createState() => _LocalTripSheetTabsState();
}

class _LocalTripSheetTabsState extends State<LocalTripSheetTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// One signal per tab; bumped when the already-selected tab is tapped again.
  final List<ValueNotifier<int>> _retap = [
    ValueNotifier<int>(0),
    ValueNotifier<int>(0),
  ];
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => _lastIndex = _tabController.index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final n in _retap) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          // Selecting a *different* tab is handled by the list itself (it
          // refreshes when it becomes the selected tab). Tapping the tab that
          // is already selected does not change the index, so handle it here.
          onTap: (i) {
            if (i == _lastIndex) _retap[i].value++;
          },
          tabs: const [
            Tab(text: 'Dispatched'),
            Tab(text: 'Completed'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _LocalTripList(
                status: localStatusDispatched,
                emptyText: 'No Trip Sheet Assigned',
                cardBuilder: widget.cardBuilder,
                tabController: _tabController,
                tabIndex: 0,
                retapSignal: _retap[0],
              ),
              _LocalTripList(
                status: localStatusCompleted,
                emptyText: 'No Completed Trip Sheet',
                cardBuilder: widget.cardBuilder,
                tabController: _tabController,
                tabIndex: 1,
                retapSignal: _retap[1],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocalTripList extends ConsumerStatefulWidget {
  final String status;
  final String emptyText;
  final Widget Function(BuildContext context, TripModel trip) cardBuilder;
  final TabController tabController;
  final int tabIndex;
  final Listenable retapSignal;

  const _LocalTripList({
    required this.status,
    required this.emptyText,
    required this.cardBuilder,
    required this.tabController,
    required this.tabIndex,
    required this.retapSignal,
  });

  @override
  ConsumerState<_LocalTripList> createState() => _LocalTripListState();
}

class _LocalTripListState extends ConsumerState<_LocalTripList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _controller = ScrollController();

  @override
  bool get wantKeepAlive => true;

  LocalTripListNotifier get _notifier =>
      ref.read(localTripListProvider(widget.status).notifier);

  late bool _wasSelected;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    // The provider loads page 1 itself when it is created.
    _wasSelected = widget.tabController.index == widget.tabIndex;
    widget.tabController.addListener(_onTabChanged);
    widget.retapSignal.addListener(_onRetap);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    widget.retapSignal.removeListener(_onRetap);
    _controller.dispose();
    super.dispose();
  }

  /// This tab just became the selected one -> call the API again.
  void _onTabChanged() {
    final selected = widget.tabController.index == widget.tabIndex;
    if (selected && !_wasSelected && mounted) _notifier.refresh();
    _wasSelected = selected;
  }

  /// The already-selected tab was tapped again -> call the API again.
  void _onRetap() {
    if (mounted) _notifier.refresh();
  }

  /// Reached (almost) the end of the list -> request the next 20 records.
  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _notifier.loadMore();
    }
  }

  Future<void> _onPullToRefresh() async {
    final error = await _notifier.refresh();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  /// If the first page doesn't fill the screen there is nothing to scroll, so
  /// the scroll listener would never fire: keep loading until it does.
  void _fillViewportIfNeeded(LocalTripListState s) {
    if (s.items.isEmpty || !s.hasMore || s.isLoadingMore) return;
    if (s.loadMoreError != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      if (_controller.position.maxScrollExtent <= 0) _notifier.loadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = ref.watch(localTripListProvider(widget.status));

    if (s.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (s.error != null && s.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error: ${s.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _notifier.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (s.items.isEmpty) {
      // Scrollable so pull-to-refresh still works on an empty list.
      return RefreshIndicator(
        onRefresh: _onPullToRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 48),
            Center(
              child: Text(
                widget.emptyText,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    _fillViewportIfNeeded(s);

    final hasFooter = s.isLoadingMore || s.loadMoreError != null;
    return RefreshIndicator(
      onRefresh: _onPullToRefresh,
      child: ListView.builder(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: s.items.length + (hasFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < s.items.length) {
            return widget.cardBuilder(context, s.items[index]);
          }
          if (s.loadMoreError != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text(
                    s.loadMoreError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextButton.icon(
                    onPressed: () => _notifier.loadMore(retry: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}