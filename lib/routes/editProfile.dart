import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});

  @override
  _ProfileDialogState createState() => _ProfileDialogState();
}

const username = "username";

class _ProfileDialogState extends State<ProfileDialog> {
  // bool _isDialogLoading = true;
  // bool _isHealthAvailable = true;
  bool _isUpdating = false;
  late PocketBase pb;

  // Form definition
  final form = FormGroup({
    username: FormControl<String>(
        validators: [Validators.required, Validators.minLength(3)]),
  });

  @override
  void initState() {
    super.initState();

    pb = Provider.of<PocketBase>(context, listen: false);

    form.control(username).value =
        (pb.authStore.model as RecordModel).getStringValue("username");
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return ReactiveForm(
      formGroup: form,
      child: Dialog.fullscreen(
          child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            ReactiveFormConsumer(
              builder: (context, form, widget) => _isUpdating
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeCap: StrokeCap.round,
                          strokeWidth: 3,
                        ),
                      ))
                  : TextButton(
                      onPressed: (form.valid) ? _handleEdit : null,
                      child: const Text("Save"),
                    ),
            )
          ],
          title: const Text("Edit Profile"),
        ),
        body: const ProfileWidget(),
      )),
    );
  }

  void _handleEdit() async {
    setState(() {
      _isUpdating = true;
    });
    try {
      String usernameValue = form.control(username).value;
      final user = pb.authStore.model;

      await pb
          .collection("users")
          .update(user.id, body: {"username": usernameValue});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updated profile'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      print('Error updating profile: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update profile"),
          ),
        );
      }
      setState(() {
        _isUpdating = false;
      });
    }
  }
}

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final pb = Provider.of<PocketBase>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 25)
              .add(const EdgeInsets.symmetric(vertical: 25)),
          child: Row(
            children: [
              AdvancedAvatar(
                name: pb.authStore.model?.getStringValue("username"),
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onPrimary),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(50),
                ),
                size: 70,
              ),
              const SizedBox(
                width: 15,
              ),
              const SizedBox(
                width: 15,
              ),
              Text(
                pb.authStore.model?.getStringValue("username"),
                style: theme.textTheme.displaySmall,
              )
            ],
          ),
        ),
        _buildTextFields(theme)
        //FilledButton(onPressed: (){}, child: Text("Create"))
      ],
    );
  }

  Widget _buildTextFields(ThemeData theme) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return ConstraintsTransformBox(
          constraintsTransform: (constraints) => BoxConstraints(
                maxWidth:
                    constraints.maxWidth > 450 ? 400 : constraints.maxWidth,
              ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                ReactiveTextField(
                  formControlName: username,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Display Name',
                    icon: Icon(Symbols.person_rounded),
                  ),
                )
              ],
            ),
          ));
    });
  }
}
