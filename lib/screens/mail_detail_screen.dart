import 'package:flutter/material.dart';
import '../models/mail_model.dart';
import 'package:intl/intl.dart';
import 'collection_form_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MailDetailScreen extends StatefulWidget {
  final MailModel mail;

  const MailDetailScreen({super.key, required this.mail});

  @override
  State<MailDetailScreen> createState() => _MailDetailScreenState();
}

class _MailDetailScreenState extends State<MailDetailScreen> {
  late MailModel _mail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mail = widget.mail;
  }

  Future<void> _toggleCollection() async {
    if (!mounted) return;

    // Ouvrir le formulaire de collection
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionFormScreen(mail: _mail),
      ),
    );

    // Si la collection a réussi, retourner avec indication de redirection vers Collectés
    if (result == true && mounted) {
      Navigator.pop(context, {'success': true, 'goToCollected': true});
    }
  }

  Future<void> _sendTrackingLinkViaWhatsApp() async {
    try {
      // Formater le numéro de téléphone pour WhatsApp
      String phone = _mail.recipientPhone;
      
      // Ajouter l'indicatif +225 (Côte d'Ivoire) si nécessaire
      if (!phone.startsWith('+')) {
        phone = '+225$phone';
      }
      
      // Nettoyer le numéro (supprimer les espaces et caractères non numériques sauf +)
      phone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      
      // Construire l'URL de suivi
      final trackingUrl = 'https://skf-artluxurybus.com/track/mail/${_mail.id}';
      
      // Créer le message
      final message = 'Bonjour, voici le lien pour suivre votre courrier ${_mail.mailNumber}: $trackingUrl';
      
      // Encoder le message pour l'URL
      final encodedMessage = Uri.encodeComponent(message);
      
      // Construire l'URL WhatsApp
      final whatsappUrl = 'https://wa.me/$phone?text=$encodedMessage';
      
      // Ouvrir WhatsApp
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Courrier'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(),
                  const SizedBox(height: 24),
                  _buildInfoSection('Informations générales', [
                    _buildInfoRow('Numéro', _mail.mailNumber),
                    _buildInfoRow('Destination', _mail.destination),
                    _buildInfoRow('Agence de réception', _mail.receivingAgency),
                    _buildInfoRow(
                      'Montant',
                      NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0)
                          .format(_mail.amount),
                    ),
                    _buildInfoRow('Type de colis', _mail.packageType),
                    _buildInfoRow('Valeur du colis', _mail.packageValue),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection('Expéditeur', [
                    _buildInfoRow('Nom', _mail.senderName),
                    _buildInfoRow('Téléphone', _mail.senderPhone),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection('Destinataire', [
                    _buildInfoRow('Nom', _mail.recipientName),
                    _buildInfoRow('Téléphone', _mail.recipientPhone),
                  ]),
                  if (_mail.description != null) ...[
                    const SizedBox(height: 24),
                    _buildInfoSection('Description', [
                      Text(_mail.description!),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  _buildInfoSection('Informations supplémentaires', [
                    _buildInfoRow(
                      'Date de création',
                      DateFormat('dd/MM/yyyy à HH:mm').format(_mail.createdAt),
                    ),
                    if (_mail.createdByUser != null)
                      _buildInfoRow('Créé par', _mail.createdByUser!.name),
                    if (_mail.isCollected) ...[
                      _buildInfoRow(
                        'Date de collection',
                        _mail.collectedAt != null
                            ? DateFormat('dd/MM/yyyy à HH:mm')
                                .format(_mail.collectedAt!)
                            : 'N/A',
                      ),
                      if (_mail.collectedByUser != null)
                        _buildInfoRow(
                            'Agent', _mail.collectedByUser!.name),
                    ],
                  ]),
                  if (_mail.isCollected &&
                      (_mail.collectorName != null ||
                          _mail.collectorPhone != null ||
                          _mail.collectorIdCard != null ||
                          _mail.collectorSignature != null)) ...[
                    const SizedBox(height: 24),
                    _buildInfoSection('Informations du collecteur', [
                      if (_mail.collectorName != null)
                        _buildInfoRow('Nom complet', _mail.collectorName!),
                      if (_mail.collectorPhone != null)
                        _buildInfoRow('Téléphone', _mail.collectorPhone!),
                      if (_mail.collectorIdCard != null)
                        _buildInfoRow(
                            'Numéro de pièce', _mail.collectorIdCard!),
                      if (_mail.collectorSignature != null) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Signature',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSignatureImage(_mail.collectorSignature!),
                      ],
                    ]),
                  ],
                  if (_mail.clientProfile != null) ...[
                    const SizedBox(height: 24),
                    _buildInfoSection('Fidélité', [
                      _buildInfoRow('Client', _mail.clientProfile!.nom),
                      _buildInfoRow(
                        'Points fidélité',
                        _mail.clientProfile!.points.toString(),
                      ),
                      _buildInfoRow(
                        'Points courrier',
                        _mail.clientProfile!.mailPoints.toString(),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 32),
                  
                  // Bouton WhatsApp pour envoyer le lien de suivi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // Couleur WhatsApp
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _sendTrackingLinkViaWhatsApp,
                      icon: const Icon(Icons.chat, size: 20),
                      label: const Text(
                        'Envoyer lien de suivi sur WhatsApp',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  
                  if (!_mail.isCollected) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isLoading ? null : _toggleCollection,
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'Marquer comme collecté',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _mail.isCollected ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _mail.isCollected ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _mail.isCollected ? Icons.check_circle : Icons.pending,
            color: _mail.isCollected ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mail.isCollected ? 'Collecté' : 'En attente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _mail.isCollected ? Colors.green : Colors.orange,
                  ),
                ),
                if (_mail.isCollected && _mail.collectedAt != null)
                  Text(
                    'Le ${DateFormat('dd/MM/yyyy à HH:mm').format(_mail.collectedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureImage(String signaturePath) {
    // Construire l'URL complète de la signature
    String imageUrl = signaturePath;
    if (!signaturePath.startsWith('http')) {
      // Si le chemin est relatif, ajouter l'URL de base
      imageUrl = 'https://skf-artluxurybus.com/$signaturePath';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported,
                      color: Colors.grey.shade400, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Signature non disponible',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 120,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
