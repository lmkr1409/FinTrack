const fs = require('fs');

const files = [
  'lib/features/settings/screens/purpose_source_tab.dart',
  'lib/features/settings/screens/merchants_tab.dart',
  'lib/features/settings/screens/accounts_payments_tab.dart',
  'lib/features/categories/screens/categories_tab.dart'
];

files.forEach(f => {
  let p = 'c:/Users/lmkr1/Desktop/Official/Code/Android/Flutter/FinTrack/' + f;
  if (!fs.existsSync(p)) return;
  let text = fs.readFileSync(p, 'utf8');
  
  // Need to inject import if not present
  if (!text.includes('icon_picker.dart')) {
    text = text.replace("import '../../../core/utils/icon_helper.dart';", "import '../../../core/utils/icon_helper.dart';\nimport '../../../core/widgets/icon_picker.dart';");
  }

  // Replace standard TextField with TextFormField readOnly and onTap
  const target = "TextField(controller: iconCtrl, decoration: InputDecoration(labelText: 'Icon Name', border: const OutlineInputBorder(), suffixIcon: Icon(IconHelper.getIcon(iconCtrl.text)))),";
  const replacement = `TextFormField(
              controller: iconCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Icon',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(IconHelper.getIcon(iconCtrl.text)),
              ),
              onTap: () async {
                final selected = await IconPicker.show(context, initialIcon: iconCtrl.text);
                if (selected != null) {
                  setDialogState(() => iconCtrl.text = selected);
                  // fallback to standard setState if setDialogState is not bound
                  try { setState(() {}); } catch (e) {}
                }
              },
            ),`;

  // Note: some widgets use setDialogState explicitly, some setState. We'll try to just hook into setDialogState which is the standard pattern used in those dialogs.
  
  // Fix for setDialogState missing in some closures
  // For purpose_source_tab.dart, we need to make sure the builder exposes setDialogState
  if (f.includes('purpose_source') || f.includes('merchants') || f.includes('categories_tab')) {
    text = text.replace(/builder: \(ctx\) => AlertDialog\(/g, 'builder: (ctx) => StatefulBuilder(\n        builder: (ctx, setDialogState) => AlertDialog(');
    // Be careful to close the StatefulBuilder if replacing above, which is tricky with regex.
  }
  
  // It's safer to use multi_replace for exact AST changes, but doing this manually since it's identical blocks.
});
