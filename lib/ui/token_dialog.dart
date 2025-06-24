import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/token.dart';
import '../services/service_factory.dart';
import 'common/ui_components.dart';

class TokenDialog extends StatefulWidget {
  final ApiToken? token;
  final ServiceType? serviceType;

  const TokenDialog({
    super.key,
    this.token,
    this.serviceType,
  });

  @override
  State<TokenDialog> createState() => _TokenDialogState();
}

class _TokenDialogState extends State<TokenDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _tokenController;
  late DateTime _expiryDate;
  ServiceType _selectedService = ServiceType.gitlab;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.token?.name ?? '');
    _tokenController = TextEditingController(text: widget.token?.token ?? '');
    _expiryDate =
        widget.token?.expiresAt ?? DateTime.now().add(const Duration(days: 30));
    _selectedService = widget.serviceType ?? ServiceType.gitlab;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tokenController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _expiryDate.hour,
          _expiryDate.minute,
        );
      });
    }
  }

  void _saveToken() {
    if (_formKey.currentState!.validate()) {
      final token = ApiToken(
        id: widget.token?.id ?? const Uuid().v4(),
        name: _nameController.text,
        token: _tokenController.text,
        expiresAt: _expiryDate,
        service: _selectedService.toString().split('.').last,
        repositories: widget.token?.repositories ?? [],
        refreshHistory: widget.token?.refreshHistory ?? [],
        lastUsed: widget.token?.lastUsed ?? DateTime.now(),
      );
      Navigator.of(context).pop(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.token == null ? 'Add Token' : 'Edit Token'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              dividerColor: Colors.transparent,
              controller: _tabController,
              tabs: const [
                Tab(text: 'Manual Entry'),
                Tab(text: 'From Repository'),
              ],
              labelColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildManualEntryForm(),
                  _buildRepositoryImportForm(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveToken,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildManualEntryForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            DropdownButtonFormField<ServiceType>(
              value: _selectedService,
              decoration: const InputDecoration(
                labelText: 'Service',
                border: OutlineInputBorder(),
              ),
              items: ServiceType.values.map((service) {
                return DropdownMenuItem<ServiceType>(
                  value: service,
                  child: Text(service.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedService = value;
                  });

                  // Show warning for non-GitLab services
                  if (value != ServiceType.gitlab) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.amber),
                            SizedBox(width: 8),
                            Text('Limited Support'),
                          ],
                        ),
                        content: const Text(
                          'Keeper currently only supports full functionality with GitLab. '
                          'Your token will be stored, but automatic refreshing and other '
                          'GitLab-specific features will not work.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Token',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a token';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expiry Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepositoryImportForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Import a token from an existing Git repository.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // This will be handled by the parent widget
            Navigator.of(context).pop('import_from_repo');
          },
          icon: const Icon(Icons.folder_open),
          label: const Text('Select Repository'),
        ),
        const SizedBox(height: 16),
        const Text(
          'This will scan the repository\'s Git configuration for existing credentials.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
