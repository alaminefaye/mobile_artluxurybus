import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/bus_api_service.dart';
import '../../models/bus_models.dart';

class TechnicalVisitFormScreen extends StatefulWidget {
  final int busId;
  final TechnicalVisit? visit; // Pour l'édition

  const TechnicalVisitFormScreen({
    super.key,
    required this.busId,
    this.visit,
  });

  @override
  State<TechnicalVisitFormScreen> createState() => _TechnicalVisitFormScreenState();
}

class _TechnicalVisitFormScreenState extends State<TechnicalVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = BusApiService();
  final _picker = ImagePicker();
  
  late DateTime _visitDate;
  late DateTime _expirationDate;
  String? _notes;
  File? _documentPhoto;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.visit != null) {
      // Mode édition
      _visitDate = widget.visit!.visitDate;
      _expirationDate = widget.visit!.expirationDate;
      _notes = widget.visit!.notes;
    } else {
      // Mode création
      _visitDate = DateTime.now();
      _expirationDate = DateTime.now().add(const Duration(days: 365));
    }
  }

  Future<void> _selectDate(BuildContext context, bool isVisitDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isVisitDate ? _visitDate : _expirationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
    );
    
    if (picked != null) {
      setState(() {
        if (isVisitDate) {
          _visitDate = picked;
        } else {
          _expirationDate = picked;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _documentPhoto = File(image.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    
    try {
      final data = {
        'visit_date': DateFormat('yyyy-MM-dd').format(_visitDate),
        'expiration_date': DateFormat('yyyy-MM-dd').format(_expirationDate),
        if (_notes != null && _notes!.isNotEmpty) 'notes': _notes,
      };

      if (widget.visit == null) {
        // Création
        await _apiService.addTechnicalVisit(widget.busId, data, photo: _documentPhoto);
      } else {
        // Modification
        await _apiService.updateTechnicalVisit(
          widget.busId,
          widget.visit!.id,
          data,
          photo: _documentPhoto,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.visit == null 
              ? 'Visite technique ajoutée' 
              : 'Visite technique modifiée'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner true pour indiquer le succès
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.visit == null 
          ? 'Nouvelle visite technique' 
          : 'Modifier visite technique'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date de visite
            ListTile(
              title: const Text('Date de visite *'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_visitDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 16),
            
            // Date d'expiration
            ListTile(
              title: const Text('Date d\'expiration *'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_expirationDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 16),
            
            // Notes
            TextFormField(
              initialValue: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              onSaved: (value) => _notes = value,
            ),
            const SizedBox(height: 16),
            
            // Photo du document
            Card(
              child: ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
                title: const Text('Photo du document'),
                subtitle: _documentPhoto != null 
                  ? const Text('Photo sélectionnée ✓', style: TextStyle(color: Colors.green))
                  : const Text('Aucune photo'),
                trailing: _documentPhoto != null
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _documentPhoto = null),
                    )
                  : null,
                onTap: _pickImage,
              ),
            ),
            if (_documentPhoto != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _documentPhoto!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Bouton
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.visit == null ? 'Ajouter' : 'Modifier',
                    style: const TextStyle(fontSize: 16),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
