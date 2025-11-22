import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/job_application_api_service.dart';
import '../theme/app_theme.dart';

class JobApplicationFormScreen extends StatefulWidget {
  const JobApplicationFormScreen({super.key});

  @override
  State<JobApplicationFormScreen> createState() =>
      _JobApplicationFormScreenState();
}

class _JobApplicationFormScreenState extends State<JobApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _motivationLetterPdf;
  File? _cvPdf;
  bool _isSubmitting = false;
  Map<String, dynamic>? _info;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await JobApplicationApiService.getInfo();
      setState(() => _info = info);
    } catch (e) {
      // Non bloquant
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf({required bool isMotivation}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isMotivation) {
          _motivationLetterPdf = File(result.files.single.path!);
        } else {
          _cvPdf = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _motivationLetterPdf == null ||
        _cvPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Veuillez remplir tous les champs et sélectionner les fichiers PDF'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = await JobApplicationApiService.submit(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        motivationLetterPdf: _motivationLetterPdf!,
        cvPdf: _cvPdf!,
      );

      setState(() => _isSubmitting = false);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Demande envoyée'),
          content: Text(
              'Votre demande a été enregistrée (ID: ${data['id'] ?? '—'}).'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demande d\'emploi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_info != null) ...[
                Text(
                  _info!['titre'] ?? 'Demande d\'emploi',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _info!['description'] ??
                      'Soumettez votre candidature en ligne.',
                  style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Téléphone requis' : null,
                onEditingComplete: () {
                  FocusScope.of(context).unfocus();
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _pickPdf(isMotivation: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_motivationLetterPdf == null
                    ? 'Sélectionner la lettre de motivation (PDF)'
                    : 'Lettre de motivation sélectionnée ✓'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _pickPdf(isMotivation: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_cvPdf == null
                    ? 'Sélectionner le CV (PDF)'
                    : 'CV sélectionné ✓'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Soumettre la demande'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
