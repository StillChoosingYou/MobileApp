import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/app_user.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  Future<void> _openAddUser(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final loginIdController = TextEditingController();
    UserRole role = UserRole.student;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add user', style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: loginIdController,
                  decoration: const InputDecoration(labelText: 'Student Number / Employee ID'),
                  validator: (v) => Validators.required(v, field: 'ID'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: UserRole.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => role = v ?? role),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(sheetContext).pop(true);
                    }
                  },
                  child: const Text('Add user'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (created == true) {
      final newUser = AppUser(
        id: 'u_${DateTime.now().microsecondsSinceEpoch}',
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        role: role,
        loginId: loginIdController.text.trim(),
      );
      final result = await ref.read(adminRepositoryProvider).addUser(newUser);
      ref.invalidate(allUsersProvider);
      if (context.mounted) {
        result.when(
          ok: (_) => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User added.')),
          ),
          error: (message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddUser(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add user'),
      ),
      body: users.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final u = list[i];
            return Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: InitialsAvatar(name: u.name),
                title: Text(u.name),
                subtitle: Text('${u.loginId} • ${u.role.label}'),
                trailing: PopupMenuButton<bool>(
                  onSelected: (activate) async {
                    await ref.read(adminRepositoryProvider).setUserActive(u.id, activate);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(activate ? 'Account reactivated.' : 'Account deactivated.')),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: true, child: Text('Reactivate')),
                    PopupMenuItem(value: false, child: Text('Deactivate')),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(message: 'Could not load users.'),
      ),
    );
  }
}
