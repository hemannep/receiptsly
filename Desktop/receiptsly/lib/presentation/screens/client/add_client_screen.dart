// lib/presentation/screens/client/add_client_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/client_entity.dart';
import '../../providers/client_provider.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_dropdown.dart';
import 'widgets/client_form.dart';

class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({super.key});

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ClientFormState> _clientFormKey =
      GlobalKey<ClientFormState>();

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add Client'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _saveClient,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeaderSection(theme),

                    const SizedBox(height: 24),

                    // Client Form
                    ClientForm(key: _clientFormKey, onChanged: _onFormChanged),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            _buildBottomActionBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_add,
              color: theme.colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Client',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a new client profile to start sending invoices',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _saveClient,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Save Client'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onFormChanged() {
    // Handle form state changes if needed
    setState(() {});
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final clientData = _clientFormKey.currentState?.getClientData();
    if (clientData == null) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create client entity
      final client = ClientEntity(
        id: '', // Will be generated by the repository
        name: clientData['name'] as String,
        email: clientData['email'] as String,
        phone: clientData['phone'] as String,
        company: clientData['company'] as String,
        address: clientData['address'] as String,
        city: clientData['city'] as String,
        state: clientData['state'] as String,
        zipCode: clientData['zipCode'] as String,
        country: clientData['country'] as String,
        taxId: clientData['taxId'] as String,
        currency: clientData['currency'] as String,
        paymentTerms: clientData['paymentTerms'] as int,
        notes: clientData['notes'] as String,
        status: ClientStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalInvoiced: 0.0,
        totalInvoices: 0,
        paidAmount: 0.0,
        outstandingAmount: 0.0,
        lastInvoiceDate: null,
        lastActivityAt: null,
      );

      // Save client
      await ref.read(clientProvider.notifier).createClient(client);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${client.name} added successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to client detail (implementation depends on routing)
              },
            ),
          ),
        );

        // Navigate back
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to add client: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
