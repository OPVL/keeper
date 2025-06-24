import 'package:flutter/material.dart';
import '../models/token.dart';
import '../models/settings.dart';
import '../services/service_factory.dart';
import '../services/settings_service.dart';
import 'package:uuid/uuid.dart';

class TokenDialog extends StatefulWidget {
  final ServiceType? serviceType;
  final ApiToken? token;

  const TokenDialog({
    super.key,
    this.serviceType,
    this.token,
  });

  @override
  State<TokenDialog> createState() => _TokenDialogState();
}

class _TokenDialogState extends State<TokenDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tokenController = TextEditingController();
  final _settingsService = SettingsService();
  bool _isValidating = false;
  bool _isValid = false;
  bool _isLoadingServices = true;
  bool _obscureToken = true;
  DateTime _expiryDate =
      DateTime.now().add(const Duration(days: 30)); // Default to 1 month
  late ServiceType _selectedService;
  List<ServiceSettings> _enabledServices = [];

  @override
  void initState() {
    super.initState();
    _selectedService = widget.serviceType ?? ServiceType.gitlab;

    if (widget.token != null) {
      _nameController.text = widget.token!.name;
      _tokenController.text = widget.token!.token;
      _expiryDate = widget.token!.expiresAt;
      _isValid = widget.token!.isValid;
    }

    _loadEnabledServices();
  }

  Future<void> _loadEnabledServices() async {
    setState(() {
      _isLoadingServices = true;
    });

    try {
      final settings = await _settingsService.getSettings();
      setState(() {
        _enabledServices = settings.services.where((s) => s.enabled).toList();
        _isLoadingServices = false;
      });
    } catch (e) {
      debugPrint('Error loading services: $e');
      setState(() {
        _isLoadingServices = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    if (_tokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a token first')),
      );
      return;
    }

    setState(() {
      _isValidating = true;
      _isValid = false;
    });

    try {
      final isValid = await ServiceFactory.validateToken(
        _selectedService,
        _tokenController.text,
      );

      if (!mounted) return;

      setState(() {
        _isValidating = false;
        _isValid = isValid;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isValid ? 'Token is valid' : 'Invalid token'),
          backgroundColor: isValid ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isValidating = false;
        _isValid = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error validating token: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openTokenCreationPage() async {
    await ServiceFactory.openTokenCreationPage(_selectedService);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 450, // Fixed width for dialog
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.token == null ? 'Add New Token' : 'Edit Token',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.token ==
                      null) // Only show service selection for new tokens
                    _isLoadingServices
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<ServiceType>(
                            value: _selectedService,
                            decoration: const InputDecoration(
                              labelText: 'Service',
                            ),
                            items: ServiceType.values
                                .where((service) => _enabledServices.any((s) =>
                                    s.id == service.toString().split('.').last))
                                .map((ServiceType service) {
                              final serviceSettings =
                                  _enabledServices.firstWhere(
                                (s) =>
                                    s.id == service.toString().split('.').last,
                              );
                              return DropdownMenuItem<ServiceType>(
                                value: service,
                                child: Text(serviceSettings.name),
                              );
                            }).toList(),
                            onChanged: (ServiceType? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedService = newValue;
                                });
                              }
                            },
                          ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Token Name',
                      hintText: 'Enter a name for this token',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tokenController,
                          obscureText: _obscureToken,
                          decoration: InputDecoration(
                            labelText: 'Token',
                            hintText: 'Enter your API token',
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isValidating)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                else
                                  IconButton(
                                    icon: Icon(
                                      _isValid
                                          ? Icons.check_circle
                                          : Icons.error,
                                      color:
                                          _isValid ? Colors.green : Colors.grey,
                                    ),
                                    onPressed: _validateToken,
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _obscureToken
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureToken = !_obscureToken;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a token';
                            }
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_browser),
                        tooltip: 'Get new token',
                        onPressed: _openTokenCreationPage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Expiry Date: '),
                      TextButton(
                        onPressed: () => _selectDate(context),
                        child: Text(
                          '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (!_isValid) {
                        // If token hasn't been validated yet, validate it now
                        if (!_isValidating && !_isValid) {
                          await _validateToken();
                        }

                        // If validation failed, ask for confirmation
                        if (!_isValid && context.mounted) {
                          final proceed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Invalid Token'),
                              content: const Text(
                                  'The token could not be validated. Do you want to save it anyway?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Save Anyway'),
                                ),
                              ],
                            ),
                          );

                          if (proceed != true) return;
                        }
                      }

                      if (context.mounted) {
                        final token = ApiToken(
                          id: widget.token?.id ?? const Uuid().v4(),
                          name: _nameController.text,
                          token: _tokenController.text,
                          expiresAt: _expiryDate,
                          service: _selectedService.toString().split('.').last,
                        );

                        Navigator.of(context).pop(token);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
