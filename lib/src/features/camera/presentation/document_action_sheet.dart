import 'package:flutter/material.dart';
import 'package:tempcam/src/localization/app_localizations.dart';
import 'package:tempcam/src/shared/services/document_scan_service.dart';
import 'package:tempcam/src/shared/theme/app_theme.dart';

class DocumentActionSheet extends StatelessWidget {
  const DocumentActionSheet({
    super.key,
    required this.result,
    required this.onCallPhone,
    required this.onAddToContacts,
    required this.onOpenAddress,
    this.scrollController,
  });

  final DocumentScanResult result;
  final ValueChanged<String> onCallPhone;
  final ValueChanged<String> onAddToContacts;
  final ValueChanged<String> onOpenAddress;
  final ScrollController? scrollController;

  static Future<bool> show(
    BuildContext context, {
    required DocumentScanResult result,
    required ValueChanged<String> onCallPhone,
    required ValueChanged<String> onAddToContacts,
    required ValueChanged<String> onOpenAddress,
  }) async {
    final value = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, scrollController) => DocumentActionSheet(
          result: result,
          onCallPhone: onCallPhone,
          onAddToContacts: onAddToContacts,
          onOpenAddress: onOpenAddress,
          scrollController: scrollController,
        ),
      ),
    );
    return value ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: const BoxDecoration(
          color: Color(0xE6131313),
          borderRadius: BorderRadius.vertical(top: Radius.circular(42)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                child: Container(
                  width: 52,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l10n.tr('Detected details before saving'),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tr(
                  'Use the detected phone number or address first, then tap Temp Save to choose the timer.',
                ),
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (result.phoneNumbers.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionTitle(title: l10n.tr('Phone numbers')),
                const SizedBox(height: 10),
                ...result.phoneNumbers.map(
                  (phoneNumber) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PhoneActionCard(
                      phoneNumber: phoneNumber,
                      onCall: () => onCallPhone(phoneNumber),
                      onAddToContacts: () => onAddToContacts(phoneNumber),
                    ),
                  ),
                ),
              ],
              if (result.addresses.isNotEmpty) ...[
                const SizedBox(height: 10),
                _SectionTitle(title: l10n.tr('Addresses')),
                const SizedBox(height: 10),
                ...result.addresses.map(
                  (address) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AddressActionCard(
                      address: address,
                      onOpen: () => onOpenAddress(address),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: const Color(0xFF003061),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.inventory_2_rounded),
                  label: Text(
                    l10n.tr('Temp Save'),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.tr('Discard')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.onSurfaceVariant,
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PhoneActionCard extends StatelessWidget {
  const _PhoneActionCard({
    required this.phoneNumber,
    required this.onCall,
    required this.onAddToContacts,
  });

  final String phoneNumber;
  final VoidCallback onCall;
  final VoidCallback onAddToContacts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phoneNumber,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_rounded),
                  label: Text(context.l10n.tr('Call')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onAddToContacts,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(context.l10n.tr('Add to Contacts')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressActionCard extends StatelessWidget {
  const _AddressActionCard({
    required this.address,
    required this.onOpen,
  });

  final String address;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            address,
            style: const TextStyle(
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onOpen,
              icon: const Icon(Icons.map_rounded),
              label: Text(context.l10n.tr('Open in Maps')),
            ),
          ),
        ],
      ),
    );
  }
}
