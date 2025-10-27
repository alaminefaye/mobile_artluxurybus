import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/bus_api_service.dart';
import '../../models/bus_models.dart';

class InsuranceFormScreen extends StatefulWidget {
  final int busId;
  final InsuranceRecord? insurance;

  const InsuranceFormScreen({
    super.key,
    required this.busId,
    this.insurance,
  });

  @override
  State<InsuranceFormScreen> createState() => _InsuranceFormScreenState();
}

class _InsuranceFormScreenState extends State<InsuranceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = BusApiService();
  
  final _policyNumberController = TextEditingController();
  final _companyController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  String? _cost;
  String? _notes;
  File? _documentPhoto;
  final _picker = ImagePicker();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.insurance != null) {
      _policyNumberController.text = widget.insurance!.policyNumber;
      _companyController.text = widget.insurance!.insuranceCompany;
      _startDate = widget.insurance!.startDate;
      _endDate = widget.insurance!.expiryDate;
      _cost = widget.insurance!.cost.toString();
      _notes = widget.insurance!.notes;
    } else {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 365));
    }
  }

  @override
  void dispose() {
    _policyNumberController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    
    try {
      final data = {
        'policy_number': _policyNumberController.text,
        'insurance_company': _companyController.text,
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
        'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
        'cost': double.parse(_cost!),
        if (_notes != null && _notes!.isNotEmpty) 'notes': _notes,
      };

      if (widget.insurance == null) {
        await _apiService.addInsurance(widget.busId, data, photo: _documentPhoto);
      } else {
        await _apiService.updateInsurance(widget.busId, widget.insurance!.id, data, photo: _documentPhoto);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.insurance == null 
              ? 'Assurance ajoutée' 
              : 'Assurance modifiée'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner true pour rafraîchir
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.insurance == null ? 'Nouvelle assurance' : 'Modifier assurance'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _policyNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro de police *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Compagnie d\'assurance *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            
            ListTile(
              title: const Text('Date de début *'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              title: const Text('Date de fin *'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              initialValue: _cost,
              decoration: const InputDecoration(
                labelText: 'Coût (FCFA) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              onSaved: (v) => _cost = v,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              initialValue: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              onSaved: (v) => _notes = v,
            ),
            const SizedBox(height: 16),
            
            // Photo du document
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.attach_file, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Document photo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_documentPhoto != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _documentPhoto!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.edit),
                            label: const Text('Changer'),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => _documentPhoto = null),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ] else if (widget.insurance?.documentPhoto != null) ...[
                      const Text(
                        'Document actuel disponible',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.edit),
                        label: const Text('Remplacer le document'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Ajouter une photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(widget.insurance == null ? 'Ajouter' : 'Modifier', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
