import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/bus_models.dart';
import '../../providers/bus_provider.dart';

class PatentFormScreen extends ConsumerStatefulWidget {
  final int busId;
  final String busNumber;
  final Patent? patent;

  const PatentFormScreen({
    super.key,
    required this.busId,
    required this.busNumber,
    this.patent,
  });

  @override
  ConsumerState<PatentFormScreen> createState() => _PatentFormScreenState();
}

class _PatentFormScreenState extends ConsumerState<PatentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patentNumberController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _isLoading = false;
  
  // Variables pour le document
  File? _documentFile;
  String? _documentFileName;

  @override
  void initState() {
    super.initState();
    if (widget.patent != null) {
      _patentNumberController.text = widget.patent!.patentNumber;
      _costController.text = widget.patent!.cost.toString();
      _notesController.text = widget.patent!.notes ?? '';
      _issueDate = widget.patent!.issueDate;
      _expiryDate = widget.patent!.expiryDate;
    }
  }

  @override
  void dispose() {
    _patentNumberController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.patent != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier la Patente' : 'Ajouter une Patente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _patentNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro de patente *',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le numéro de patente';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: 'Date de délivrance *',
              date: _issueDate,
              onTap: () => _selectDate(context, isIssueDate: true),
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: 'Date d\'expiration *',
              date: _expiryDate,
              onTap: () => _selectDate(context, isIssueDate: false),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Coût (FCFA)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Bouton pour téléverser un document
            OutlinedButton.icon(
              onPressed: _pickDocument,
              icon: Icon(
                _documentFile != null ? Icons.check_circle : Icons.upload_file,
                color: _documentFile != null ? Colors.green : null,
              ),
              label: Text(
                _documentFile != null
                    ? 'Document sélectionné: $_documentFileName'
                    : 'Téléverser un document (PDF, Image)',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                side: BorderSide(
                  color: _documentFile != null ? Colors.green : Colors.grey,
                  width: _documentFile != null ? 2 : 1,
                ),
              ),
            ),
            if (_documentFile != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _removeDocument,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Retirer le document'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Modifier' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Sélectionner une date',
          style: TextStyle(
            color: date != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isIssueDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate
          ? (_issueDate ?? DateTime.now())
          : (_expiryDate ?? DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _documentFile = File(result.files.single.path!);
          _documentFileName = result.files.single.name;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document sélectionné: ${result.files.single.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection du fichier: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeDocument() {
    setState(() {
      _documentFile = null;
      _documentFileName = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document retiré'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_issueDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner les dates')),
      );
      return;
    }

    if (_expiryDate!.isBefore(_issueDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date d\'expiration doit être après la date de délivrance')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final busService = ref.read(busApiServiceProvider);
      
      final patentData = Patent(
        id: widget.patent?.id ?? 0,
        busId: widget.busId,
        patentNumber: _patentNumberController.text,
        issueDate: _issueDate!,
        expiryDate: _expiryDate!,
        cost: double.parse(_costController.text),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        documentPath: widget.patent?.documentPath,
        createdAt: widget.patent?.createdAt,
      );

      if (widget.patent != null) {
        await busService.updatePatent(widget.busId, widget.patent!.id, patentData);
      } else {
        await busService.addPatent(widget.busId, patentData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.patent != null ? 'Patente modifiée avec succès' : 'Patente ajoutée avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
