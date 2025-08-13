// lib/presentation/screens/client/client_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/client_entity.dart';
import '../../providers/client_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/app_text_field.dart';
import 'widgets/client_card.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ClientSortOption _sortOption = ClientSortOption.name;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    // Load clients on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientProvider.notifier).loadClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Clients'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: _showSortOptions),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(clientProvider.notifier).refreshClients();
        },
        child: Column(
          children: [
            // Search and Filter Bar
            _buildSearchAndFilterBar(theme),

            // Client List
            Expanded(child: _buildClientList(clientState, theme)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddClient(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Client'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildSearchAndFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Field
          AppTextField(
            controller: _searchController,
            hintText: 'Search clients...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 12),

          // Sort and Filter Chips
          Row(
            children: [
              Chip(
                label: Text('Sort: ${_sortOption.displayName}'),
                avatar: Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
                onDeleted: _showSortOptions,
                deleteIcon: const Icon(Icons.keyboard_arrow_down, size: 16),
              ),
              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, child) {
                  final activeFilters = ref
                      .watch(clientProvider.notifier)
                      .activeFilters;
                  if (activeFilters.isEmpty) return const SizedBox.shrink();

                  return Chip(
                    label: Text(
                      '${activeFilters.length} filter${activeFilters.length > 1 ? 's' : ''}',
                    ),
                    onDeleted: () {
                      ref.read(clientProvider.notifier).clearFilters();
                    },
                    deleteIcon: const Icon(Icons.clear, size: 16),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientList(ClientState clientState, ThemeData theme) {
    if (clientState.isLoading && clientState.clients.isEmpty) {
      return const Center(child: AppLoader());
    }

    if (clientState.error != null && clientState.clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading clients', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              clientState.error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(clientProvider.notifier).loadClients(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredClients = _getFilteredAndSortedClients(clientState.clients);

    if (filteredClients.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: _searchQuery.isNotEmpty ? 'No clients found' : 'No clients yet',
        message: _searchQuery.isNotEmpty
            ? 'Try adjusting your search or filters'
            : 'Add your first client to get started',
        actionText: _searchQuery.isEmpty ? 'Add Client' : null,
        onActionPressed: _searchQuery.isEmpty
            ? () => _navigateToAddClient(context)
            : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredClients.length,
      itemBuilder: (context, index) {
        final client = filteredClients[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClientCard(
            client: client,
            onTap: () => _navigateToClientDetail(context, client.id),
            onEdit: () => _navigateToEditClient(context, client.id),
            onDelete: () => _showDeleteConfirmation(context, client),
          ),
        );
      },
    );
  }

  List<ClientEntity> _getFilteredAndSortedClients(List<ClientEntity> clients) {
    var filtered = clients;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((client) {
        final query = _searchQuery.toLowerCase();
        return client.name.toLowerCase().contains(query) ||
            client.email.toLowerCase().contains(query) ||
            client.company.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison;
      switch (_sortOption) {
        case ClientSortOption.name:
          comparison = a.name.compareTo(b.name);
          break;
        case ClientSortOption.company:
          comparison = a.company.compareTo(b.company);
          break;
        case ClientSortOption.dateAdded:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case ClientSortOption.totalInvoiced:
          comparison = a.totalInvoiced.compareTo(b.totalInvoiced);
          break;
        case ClientSortOption.lastActivity:
          comparison = (a.lastActivityAt ?? DateTime(1970)).compareTo(
            b.lastActivityAt ?? DateTime(1970),
          );
          break;
      }

      return _isAscending ? comparison : -comparison;
    });

    return filtered;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort by', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...ClientSortOption.values.map(
              (option) => ListTile(
                title: Text(option.displayName),
                leading: Radio<ClientSortOption>(
                  value: option,
                  groupValue: _sortOption,
                  onChanged: (value) {
                    setState(() {
                      _sortOption = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(_isAscending ? 'Ascending' : 'Descending'),
              leading: Icon(
                _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              ),
              onTap: () {
                setState(() {
                  _isAscending = !_isAscending;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Clients',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status filter
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ClientStatus.values
                            .map(
                              (status) => FilterChip(
                                label: Text(status.displayName),
                                selected: false, // Implement filter state
                                onSelected: (selected) {
                                  // Implement filter logic
                                },
                              ),
                            )
                            .toList(),
                      ),

                      const SizedBox(height: 24),

                      // Date range filter
                      Text(
                        'Date Added',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      // Implement date range picker
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(clientProvider.notifier).clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply filters
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ClientEntity client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
          'Are you sure you want to delete ${client.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(clientProvider.notifier).deleteClient(client.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${client.name} deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        // Implement undo functionality
                      },
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddClient(BuildContext context) {
    context.push('/clients/add');
  }

  void _navigateToClientDetail(BuildContext context, String clientId) {
    context.push('/clients/$clientId');
  }

  void _navigateToEditClient(BuildContext context, String clientId) {
    context.push('/clients/$clientId/edit');
  }
}

// Enums for sorting and filtering
enum ClientSortOption {
  name('Name'),
  company('Company'),
  dateAdded('Date Added'),
  totalInvoiced('Total Invoiced'),
  lastActivity('Last Activity');

  const ClientSortOption(this.displayName);
  final String displayName;
}

enum ClientStatus {
  active('Active'),
  inactive('Inactive'),
  archived('Archived');

  const ClientStatus(this.displayName);
  final String displayName;
}
