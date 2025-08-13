// lib/presentation/screens/invoice/widgets/client_selector.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/client/client_model.dart';

class ClientSelector extends StatefulWidget {
  final ClientModel? selectedClient;
  final List<ClientModel> clients;
  final ValueChanged<ClientModel?> onClientSelected;
  final bool isLoading;
  final String? errorText;

  const ClientSelector({
    super.key,
    this.selectedClient,
    required this.clients,
    required this.onClientSelected,
    this.isLoading = false,
    this.errorText,
  });

  @override
  State<ClientSelector> createState() => _ClientSelectorState();
}

class _ClientSelectorState extends State<ClientSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<ClientModel> _filteredClients = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _filteredClients = widget.clients;
    if (widget.selectedClient != null) {
      _searchController.text = widget.selectedClient!.name;
    }
  }

  @override
  void didUpdateWidget(ClientSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.clients != oldWidget.clients) {
      _filteredClients = widget.clients;
      _filterClients(_searchController.text);
    }

    if (widget.selectedClient != oldWidget.selectedClient) {
      _searchController.text = widget.selectedClient?.name ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterClients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClients = widget.clients;
      } else {
        _filteredClients = widget.clients
            .where(
              (client) =>
                  client.name.toLowerCase().contains(query.toLowerCase()) ||
                  client.email.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _selectClient(ClientModel client) {
    setState(() {
      _searchController.text = client.name;
      _showDropdown = false;
    });
    widget.onClientSelected(client);
    FocusScope.of(context).unfocus();
  }

  void _clearSelection() {
    setState(() {
      _searchController.clear();
      _showDropdown = false;
      _filteredClients = widget.clients;
    });
    widget.onClientSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Client search field
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Select Client *',
            hintText: 'Search clients or add new...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.person),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.selectedClient != null)
                  IconButton(
                    onPressed: _clearSelection,
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear selection',
                  ),
                IconButton(
                  onPressed: _addNewClient,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add new client',
                ),
                if (widget.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            errorText: widget.errorText,
          ),
          onChanged: (value) {
            _filterClients(value);
            setState(() {
              _showDropdown = value.isNotEmpty && _filteredClients.isNotEmpty;
            });

            // Clear selected client if text doesn't match
            if (widget.selectedClient != null &&
                value != widget.selectedClient!.name) {
              widget.onClientSelected(null);
            }
          },
          onTap: () {
            setState(() {
              _showDropdown = _filteredClients.isNotEmpty;
            });
          },
          validator: (value) {
            if (widget.selectedClient == null) {
              return 'Please select a client';
            }
            return null;
          },
        ),

        // Dropdown list
        if (_showDropdown) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _filteredClients.isEmpty
                ? _buildNoClientsFound()
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = _filteredClients[index];
                      return _buildClientListItem(client);
                    },
                  ),
          ),
        ],

        // Selected client preview
        if (widget.selectedClient != null && !_showDropdown) ...[
          const SizedBox(height: 8),
          _buildSelectedClientCard(),
        ],
      ],
    );
  }

  Widget _buildClientListItem(ClientModel client) {
    return InkWell(
      onTap: () => _selectClient(client),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (client.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      client.email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildNoClientsFound() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No clients found',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addNewClient,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add New Client'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedClientCard() {
    final client = widget.selectedClient!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green.shade100,
            child: Icon(Icons.check, color: Colors.green.shade700, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (client.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.email, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          client.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (client.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          client.address,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editClient(client),
            icon: const Icon(Icons.edit, size: 16),
            tooltip: 'Edit client',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _addNewClient() {
    setState(() {
      _showDropdown = false;
    });

    context.push('/clients/add').then((result) {
      if (result is ClientModel) {
        _selectClient(result);
      }
    });
  }

  void _editClient(ClientModel client) {
    context.push('/clients/${client.id}/edit').then((result) {
      if (result is ClientModel) {
        _selectClient(result);
      }
    });
  }
}
