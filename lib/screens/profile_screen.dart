import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/storage_interface.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/screens/login_screen.dart';
import 'package:dpsg_app/screens/registration_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_app_bar.dart';
import 'package:dpsg_app/shared/custom_bottom_bar.dart';
import 'package:dpsg_app/shared/custom_card.dart';
import 'package:dpsg_app/shared/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:developer' as developer;

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: ((context, snapshot) => snapshot.hasData
          ? UserProfileScreen(
              currentUser: snapshot.data as User,
              rebuild: performRebuild,
            )
          : Container()),
      future: fetchUser(),
    );
  }

  void performRebuild() {
    setState(() {});
  }
}

class UserProfileScreen extends StatefulWidget {
  UserProfileScreen({
    super.key,
    required this.currentUser,
    required this.rebuild,
  });

  User currentUser;
  final Function rebuild;
  @override
  State<UserProfileScreen> createState() => UserProfileScreenState();
}

class UserProfileScreenState extends State<UserProfileScreen> {
  bool editMode = false;
  User? changedUser;
  String? userRole;

  final _nameController = TextEditingController();
  final _mailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordCheckController = TextEditingController();
  String oldPassword = '';

  UnderlineInputBorder getValidBorder(BuildContext context) =>
      UnderlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSurface,
          width: 1.0,
        ),
      );

  UnderlineInputBorder getInvalidBorder(BuildContext context) =>
      UnderlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 1.0,
        ),
      );

  bool _nameValid = true;
  bool _mailValid = true;
  bool _passwordValid = true;
  bool _passwordCheckValid = true;

  bool _allValid = true;

  bool? editsOwnAccount;

  @override
  void initState() {
    restoreDefaults();
    editsOwnAccount =
        widget.currentUser.id == GetIt.instance<Backend>().loggedInUserId;
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mailController.dispose();
    _passwordController.dispose();
    _passwordCheckController.dispose();
    super.dispose();
  }

  void restoreDefaults() {
    editMode = false;
    changedUser = widget.currentUser;
    _nameController.text = changedUser!.name;
    _mailController.text = changedUser!.email;
    _passwordController.clear();
    _passwordCheckController.clear();
    userRole = changedUser!.role;
  }

  bool validation() {
    _nameValid = _nameController.text.isNotEmpty;
    _mailValid = emailValidationPattern.hasMatch(_mailController.text);
    _passwordValid =
        _passwordController.text.length >= 8 ||
        _passwordController.text.isEmpty;
    _passwordCheckValid =
        _passwordCheckController.text == _passwordController.text;
    return _nameValid && _mailValid && _passwordValid && _passwordCheckValid;
  }

  @override
  Widget build(BuildContext context) {
    bool isOnlineMode =
        GetIt.instance<Backend>().isOnlineMode &&
        GetIt.instance<Backend>().isTokenValid;
    _allValid = validation();
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Nutzereinstellungen"),
      drawer: const CustomDrawer(),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      bottomNavigationBar: const CustomBottomBar(),
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom == 0
          ? FloatingActionButton.extended(
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              backgroundColor: _allValid || !editMode
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.grey,
              disabledElevation: 0,
              onPressed: _allValid && editMode
                  ? () async {
                      bool? success;
                      if (editsOwnAccount!) {
                        oldPassword = await _enterOldPassword();
                      }
                      showDialog(
                        // Progress indicator while saving
                        barrierDismissible: false,
                        context: context,
                        builder: ((context) => PopScope(
                          onPopInvokedWithResult: (_, _) async => false,
                          child: const Expanded(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )),
                      );
                      try {
                        bool passwordCorrect = false;
                        if (editsOwnAccount! && oldPassword.isNotEmpty) {
                          passwordCorrect = await GetIt.I<Backend>().login(
                            widget.currentUser.email,
                            oldPassword,
                          );
                          success = passwordCorrect;
                        }
                        if (!editsOwnAccount! || passwordCorrect) {
                          success = await _save();
                        }
                      } catch (e) {
                        success = false;
                        developer.log(e.toString());
                      }
                      if (success != null && success) {
                        Navigator.pop(context);
                        _displayError('Speichern erfolgreich!');
                      } else if (success != null) {
                        Navigator.pop(context);
                        _displayError('Fehler beim Speichern!');
                      } else {
                        Navigator.pop(context);
                      }
                    }
                  : !_allValid && editMode
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              icon: Icon(editMode ? Icons.save : Icons.arrow_back),
              label: Text(editMode ? 'Speichern' : "Zurück"),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildCard(
                context: context,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Profil', style: TextStyle(fontSize: 24)),
                          isOnlineMode
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (editMode) {
                                        restoreDefaults();
                                      } else {
                                        editMode = true;
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    editMode
                                        ? Icons.cancel_outlined
                                        : Icons.edit,
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                      Column(
                        children: [
                          TextField(
                            autofocus: true,
                            controller: _nameController,
                            decoration: InputDecoration(
                              helperText: 'Name',
                              focusedBorder: _nameValid
                                  ? getValidBorder(context)
                                  : getInvalidBorder(context),
                              enabledBorder: _nameValid
                                  ? getValidBorder(context)
                                  : getInvalidBorder(context),
                            ),
                            textInputAction: TextInputAction.next,
                            readOnly: !editMode,
                            onChanged: (value) {
                              setState(() {
                                validation();
                              });
                            },
                          ),
                          TextField(
                            controller: _mailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              helperText: 'Email',
                              focusedBorder: _mailValid
                                  ? getValidBorder(context)
                                  : getInvalidBorder(context),
                              enabledBorder: _mailValid
                                  ? getValidBorder(context)
                                  : getInvalidBorder(context),
                            ),
                            textInputAction: TextInputAction.next,
                            readOnly: !editMode,
                            onChanged: (value) {
                              setState(() {
                                validation();
                              });
                            },
                          ),
                          TextField(
                            obscureText: true,
                            controller: _passwordController,
                            decoration: InputDecoration(
                              helperText: 'Passwort',
                              hintText: 'Unverändert',
                              hintStyle: const TextStyle(fontSize: 10),
                              focusedBorder: _passwordValid
                                  ? getValidBorder(context)
                                  : getInvalidBorder(context),
                              enabledBorder: _passwordValid
                                  ? getValidBorder(context)
                                  : getInvalidBorder(context),
                            ),
                            textInputAction: TextInputAction.next,
                            readOnly: !editMode,
                            onChanged: (value) {
                              setState(() {
                                validation();
                              });
                            },
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                FocusScope.of(context).nextFocus();
                              }
                            },
                          ),
                          Focus(
                            child: Visibility(
                              visible:
                                  _passwordController.text.isNotEmpty &&
                                  editMode,
                              child: TextField(
                                obscureText: true,
                                controller: _passwordCheckController,
                                decoration: InputDecoration(
                                  helperText: 'Neues Passwort bestätigen',
                                  focusedBorder: _passwordCheckValid
                                      ? getValidBorder(context)
                                      : getInvalidBorder(context),
                                  enabledBorder: _passwordCheckValid
                                      ? getValidBorder(context)
                                      : getInvalidBorder(context),
                                ),
                                textInputAction: TextInputAction.done,
                                readOnly: !editMode,
                                onChanged: (value) {
                                  setState(() {
                                    validation();
                                  });
                                },
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Rolle'),
                              DropdownButton(
                                value: userRole,
                                dropdownColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                alignment: AlignmentDirectional.topStart,
                                items: <DropdownMenuItem<String>>[
                                  DropdownMenuItem(
                                    value: 'admin',
                                    child: Text('Admin'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'user',
                                    child: Text('User'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'none',
                                    child: Text('Deaktiviert'),
                                  ),
                                ],
                                onChanged: editsOwnAccount! || !editMode
                                    ? null
                                    : (String? value) {
                                        setState(() {
                                          userRole = value;
                                        });
                                      },
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (editsOwnAccount!)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    GetIt.instance<Backend>().logout();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginScreen(),
                                      ),
                                      (Route<dynamic> route) => false,
                                    );
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Abmelden'),
                                ),
                              if (isOnlineMode)
                                OutlinedButton.icon(
                                  onPressed: _deleteProfile,
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Konto löschen'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (editsOwnAccount ?? false)
                buildCard(
                  context: context,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App-Einstellungen',
                          style: TextStyle(fontSize: 24),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Farbschema",
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            DropdownButton<ColorSchemeMenuEntry>(
                              value: kColorSchemes
                                  .where(
                                    (item) =>
                                        item.colorScheme ==
                                        Theme.of(context).colorScheme,
                                  )
                                  .firstOrNull,
                              items: kColorSchemes
                                  .map(
                                    (entry) =>
                                        DropdownMenuItem<ColorSchemeMenuEntry>(
                                          value: entry,
                                          child: Row(
                                            children: [
                                              buildColorPreview(
                                                entry.colorScheme,
                                                context,
                                              ),
                                              SizedBox(width: 10),
                                              Text(entry.name),
                                            ],
                                          ),
                                        ),
                                  )
                                  .toList(),
                              onChanged: (newColorScheme) async {
                                if (newColorScheme == null) return;
                                await GetIt.I<StorageInterface>()
                                    .setSettingByKey(
                                      'colorScheme',
                                      newColorScheme.name,
                                    );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildColorPreview(ColorScheme colorScheme, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(width: 20, height: 20, color: colorScheme.primaryContainer),
          Container(width: 20, height: 20, color: colorScheme.surface),
          Container(width: 20, height: 20, color: colorScheme.secondary),
          Container(width: 20, height: 20, color: colorScheme.primary),
        ],
      ),
    );
  }

  Future<bool> _save() async {
    String body = '{';
    body +=
        _nameController.text.isNotEmpty &&
            (_nameController.text != widget.currentUser.name)
        ? '\n"name": "${_nameController.text}",'
        : '';
    body +=
        _mailController.text.isNotEmpty &&
            (_mailController.text != widget.currentUser.email)
        ? '\n"email": "${_mailController.text}",'
        : '';
    body += _passwordController.text.isNotEmpty
        ? '\n"password": "${_passwordController.text}",'
        : '';
    body += userRole != widget.currentUser.role
        ? '\n"roleId": "$userRole",'
        : '';
    if (body.lastIndexOf(',') > 0) {
      body = body.substring(0, body.lastIndexOf(','));
    }
    body += '\n}';

    try {
      User changedCurrentUser;
      await GetIt.I<Backend>().patch('/user/${widget.currentUser.id}', body);
      if (editsOwnAccount!) {
        String password = '';
        if (_passwordController.text.isEmpty) {
          password = oldPassword;
        } else {
          password = _passwordController.text;
        }
        await GetIt.I<Backend>().login(_mailController.text, password);

        changedCurrentUser = await fetchUser();
      } else {
        changedCurrentUser = User.fromJson(
          await GetIt.I<Backend>().get('/user/${widget.currentUser.id}'),
        );
      }
      setState(() {
        widget.currentUser = changedCurrentUser;
        widget.rebuild();
        restoreDefaults();
      });
      return true;
    } catch (e) {
      developer.log(e.toString());
      setState(() {
        restoreDefaults();
      });
      return false;
    }
  }

  Future<bool> _deleteProfile() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warnung'),
        content: Text(
          'Möchtest du ${editsOwnAccount! ? 'dein' : 'dieses'} Konto wirklich löschen? ${editsOwnAccount! ? 'Du wirst dich' : 'Man wird sich'} nicht mehr mit diesem Konto anmelden können!',
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            label: const Text('Abbrechen'),
            icon: const Icon(Icons.cancel),
          ),
          ElevatedButton.icon(
            label: const Text('Konto Löschen'),
            icon: const Icon(Icons.delete),
            onPressed: () async {
              if (editsOwnAccount!) {
                oldPassword = await _enterOldPassword();
              }
              try {
                bool passwordCorrect = false;
                if (editsOwnAccount!) {
                  passwordCorrect =
                      (oldPassword.isNotEmpty &&
                      await GetIt.I<Backend>().login(
                        widget.currentUser.email,
                        oldPassword,
                      ));
                }
                if (!editsOwnAccount! || passwordCorrect) {
                  if (!editsOwnAccount! ||
                      await GetIt.instance<Backend>()
                          .sendLocalPurchasesToServer()) {
                    await GetIt.instance<Backend>().delete(
                      '/user/${widget.currentUser.id}',
                      null,
                    );
                    if (editsOwnAccount!) {
                      GetIt.instance<Backend>().logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    } else {
                      Navigator.pop(context);
                      _displayError('Löschen erfolgreich!');
                    }
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Fehler'),
                        content: const Text(
                          'Konto konnte nicht gelöscht werden, weil es noch nicht synchronisierte Käufe gibt.',
                        ),
                        actions: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Okay'),
                          ),
                        ],
                      ),
                    );
                  }
                } else if (oldPassword.isNotEmpty) {
                  throw (Exception('wrong password'));
                }
              } catch (e) {
                developer.log(e.toString());
                _displayError('Fehler beim Löschen!');
              }
            },
          ),
        ],
      ),
    );

    return true;
  }

  Future<String> _enterOldPassword() async {
    String enteredPassword = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Profil ändern'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Um die Aktion zu bestätigen, gib bitte dein aktuelles Passwort ein.',
              ),
              TextField(
                autofocus: true,
                obscureText: true,
                onChanged: (value) => enteredPassword = value,
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                enteredPassword = '';
                Navigator.pop(context);
              },
              icon: const Icon(Icons.cancel),
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
            ),
          ],
        );
      },
    );
    return enteredPassword;
  }

  void _displayError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );

    setState(() {
      restoreDefaults();
    });
  }
}

class ColorSchemeMenuEntry {
  final ColorScheme colorScheme;
  final String name;

  ColorSchemeMenuEntry(this.colorScheme, this.name);

  @override
  String toString() {
    return name;
  }
}
