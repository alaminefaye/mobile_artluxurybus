import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/bus_api_service.dart';
import '../../models/bus_models.dart';

class BreakdownFormScreen extends StatefulWidget {
  final int busId;
  final BusBreakdown? breakdown;

  const BreakdownFormScreen({
    Key? key,
    required this.busId,
    this.breakdown,
  }) : super(key: key);

  @override
  State<BreakdownFormScreen> createState() => _BreakdownFormScreenState();
}

class _BreakdownFormScreenState extends State<BreakdownFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = BusApiService();
  
  final _reparationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _diagnosticController = TextEditingController();
  final _pieceController = TextEditingController();
  
  late DateTime _datePanne;
  String? _kilometrage;
  String? _prixPiece;
  String? _notes;
  String _statut = 'en_cours';
  File? _facturePhoto;
  final _picker = ImagePicker();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.breakdown != null) {
      _reparationController.text = widget.breakdown!.reparationEffectuee;
      _descriptionController.text = widget.breakdown!.descriptionProbleme;
      _diagnosticController.text = widget.breakdown!.diagnosticMecanicien;
      _datePanne = widget.breakdown!.breakdownDate;
      _statut = widget.breakdown!.statutReparation;
      _kilometrage = widget.breakdown!.kilometrage?.toString();
      _pieceController.text = widget.breakdown!.pieceRemplacee ?? '';
      _prixPiece = widget.breakdown!.prixPiece?.toString();
      _notes = widget.breakdown!.notesComplementaires;
    } else {
      _datePanne = DateTime.now();
    }
  }

  @override
  void dispose() {
    _reparationController.dispose();
    _descriptionController.dispose();
    _diagnosticController.dispose();
    _pieceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _datePanne,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    
    if (picked != null) {
      setState(() => _datePanne = picked);
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
          _facturePhoto = File(image.path);
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
        'reparation_effectuee': _reparationController.text,
        'date_panne': DateFormat('yyyy-MM-dd').format(_datePanne),
        'description_probleme': _descriptionController.text,
        'diagnostic_mecanicien': _diagnosticController.text,
        'statut_reparation': _statut,
        if (_kilometrage != null && _kilometrage!.isNotEmpty) 
          'kilometrage': int.parse(_kilometrage!),
        if (_pieceController.text.isNotEmpty) 
          'piece_remplacee': _pieceController.text,
        if (_prixPiece != null && _prixPiece!.isNotEmpty) 
          'prix_piece': double.parse(_prixPiece!),
        if (_notes != null && _notes!.isNotEmpty) 
          'notes_complementaires': _notes,
      };

      if (widget.breakdown == null) {
        await _apiService.addBreakdown(widget.busId, data, photo: _facturePhoto);
      } else {
        await _apiService.updateBreakdown(widget.busId, widget.breakdown!.id, data, photo: _facturePhoto);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.breakdown == null ? 'Panne ajoutée' : 'Panne modifiée'),
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
        title: Text(widget.breakdown == null ? 'Nouvelle panne' : 'Modifier panne'),
        backgroundColor: Colors.orange,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _reparationController,
              decoration: const InputDecoration(
                labelText: 'Réparation effectuée *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.build),
              ),
              maxLines: 2,
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            
            ListTile(
              title: const Text('Date de panne *'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_datePanne)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description du problème *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _diagnosticController,
              decoration: const InputDecoration(
                labelText: 'Diagnostic mécanicien *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.engineering),
              ),
              maxLines: 3,
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _statut,
              decoration: const InputDecoration(
                labelText: 'Statut *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              items: const [
                DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                DropdownMenuItem(value: 'terminee', child: Text('Terminée')),
                DropdownMenuItem(value: 'en_attente_pieces', child: Text('En attente pièces')),
              ],
              onChanged: (v) => setState(() => _statut = v!),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              initialValue: _kilometrage,
              decoration: const InputDecoration(
                labelText: 'Kilométrage',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
              ),
              keyboardType: TextInputType.number,
              onSaved: (v) => _kilometrage = v,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _pieceController,
              decoration: const InputDecoration(
                labelText: 'Pièce remplacée',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              initialValue: _prixPiece,
              decoration: const InputDecoration(
                labelText: 'Prix pièce (FCFA)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              onSaved: (v) => _prixPiece = v,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              initialValue: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes complémentaires',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              onSaved: (v) => _notes = v,
            ),
            const SizedBox(height: 16),
            
            // Photo de facture
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Photo de facture',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_facturePhoto != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _facturePhoto!,
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
                            icon: Icon(Icons.edit),
                            label: Text('Changer'),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => _facturePhoto = null),
                            icon: Icon(Icons.delete, color: Colors.red),
                            label: Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ] else if (widget.breakdown?.facturePhoto != null) ...[
                      Text(
                        'Facture actuelle disponible',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.edit),
                        label: Text('Remplacer la facture'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.camera_alt),
                        label: Text('Ajouter une photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
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
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(widget.breakdown == null ? 'Ajouter' : 'Modifier', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
