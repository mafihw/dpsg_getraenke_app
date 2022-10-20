import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/screens/login_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_app_bar.dart';
import 'package:dpsg_app/shared/custom_bottom_bar.dart';
import 'package:dpsg_app/shared/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:developer' as developer;

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({Key? key}) : super(key: key);

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
          : const Center(
              child: CircularProgressIndicator(),
            )),
      future: fetchUser(),
    );
  }

  void performRebuild() {
    setState(() {});
  }
}

class UserProfileScreen extends StatefulWidget {
  UserProfileScreen(
      {Key? key, required this.currentUser, required this.rebuild})
      : super(key: key);

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

  var validBorder = const UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.white, width: 1.0),
  );

  var invalidBorder = const UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.red, width: 1.0),
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
    _mailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(_mailController.text);
    _passwordValid = _passwordController.text.length >= 8 ||
        _passwordController.text.isEmpty;
    _passwordCheckValid =
        _passwordCheckController.text == _passwordController.text;
    return _nameValid && _mailValid && _passwordValid && _passwordCheckValid;
  }

  @override
  Widget build(BuildContext context) {
    _allValid = validation();
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Nutzerverwaltung"),
      drawer: const CustomDrawer(),
      backgroundColor: kBackgroundColor,
      bottomNavigationBar: const CustomBottomBar(),
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom == 0
          ? FloatingActionButton.extended(
              backgroundColor:
                  _allValid || !editMode ? kSecondaryColor : Colors.grey,
              disabledElevation: 0,
              onPressed: _allValid && editMode
                  ? () async {
                      if (editsOwnAccount!) {
                        oldPassword = await _enterOldPassword();
                      }
                      try {
                        bool passwordCorrect = false;
                        if (editsOwnAccount! && oldPassword.isNotEmpty) {
                          passwordCorrect = await GetIt.I<Backend>()
                              .login(widget.currentUser.email, oldPassword);
                        }
                        if (!editsOwnAccount! || passwordCorrect) {
                          _save();
                        }
                      } catch (e) {
                        developer.log(e.toString());
                        _displayError('Fehler beim Speichern!');
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
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profil',
                    style: TextStyle(fontSize: 24),
                  ),
                  IconButton(
                      onPressed: () {
                        setState(() {
                          if (editMode) {
                            restoreDefaults();
                          } else {
                            editMode = true;
                          }
                        });
                      },
                      icon: Icon(editMode ? Icons.cancel_outlined : Icons.edit))
                ],
              ),
              Column(
                children: [
                  TextField(
                    autofocus: true,
                    controller: _nameController,
                    decoration: InputDecoration(
                      helperText: 'Name',
                      focusedBorder: _nameValid ? validBorder : invalidBorder,
                      enabledBorder: _nameValid ? validBorder : invalidBorder,
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
                      focusedBorder: _mailValid ? validBorder : invalidBorder,
                      enabledBorder: _mailValid ? validBorder : invalidBorder,
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
                      focusedBorder:
                          _passwordValid ? validBorder : invalidBorder,
                      enabledBorder:
                          _passwordValid ? validBorder : invalidBorder,
                    ),
                    textInputAction: TextInputAction.next,
                    readOnly: !editMode,
                    onChanged: (value) {
                      setState(() {
                        validation();
                      });
                    },
                    onSubmitted: (value) {
                      if (value.isNotEmpty) FocusScope.of(context).nextFocus();
                    },
                  ),
                  Focus(
                    child: Visibility(
                      visible: _passwordController.text.isNotEmpty && editMode,
                      child: TextField(
                        obscureText: true,
                        controller: _passwordCheckController,
                        decoration: InputDecoration(
                          helperText: 'Neues Passwort bestätigen',
                          focusedBorder:
                              _passwordCheckValid ? validBorder : invalidBorder,
                          enabledBorder:
                              _passwordCheckValid ? validBorder : invalidBorder,
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
                      const Text(
                        'Rolle'
                      ),
                      DropdownButton(
                          value: userRole,
                          dropdownColor: kMainColor,
                          alignment: AlignmentDirectional.topStart,
                          items: <DropdownMenuItem<String>>[
                            DropdownMenuItem(child: Text('Admin'), value: 'admin'),
                            DropdownMenuItem(child: Text('User'), value: 'user'),
                            DropdownMenuItem(
                                child: Text('Deaktiviert'), value: 'none')
                          ],
                          onChanged: editsOwnAccount! || !editMode ? null : (String? value) {
                            setState(() {
                              userRole = value;
                            });
                          }
                      ),
                    ],
                  )
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
                                      builder: (context) => LoginScreen()),
                                  (Route<dynamic> route) => false);
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Abmelden')),
                      OutlinedButton.icon(
                          onPressed: _deleteProfile,
                          icon: const Icon(Icons.delete),
                          label: const Text('Konto löschen')),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _save() async {
    String body = '{';
    body += _nameController.text.isNotEmpty && (_nameController.text != widget.currentUser.name)
        ? '\n"name": "${_nameController.text}",'
        : '';
    body += _mailController.text.isNotEmpty && (_mailController.text != widget.currentUser.email)
        ? '\n"email": "${_mailController.text}",'
        : '';
    body += _passwordController.text.isNotEmpty
        ? '\n"password": "${_passwordController.text}",'
        : '';
    body += userRole != widget.currentUser.role
        ? '\n"roleId": "${userRole}",'
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
            await GetIt.I<Backend>().get('/user/${widget.currentUser.id}'));
      }
      setState(() {
        widget.currentUser = changedCurrentUser;
        widget.rebuild();
        restoreDefaults();
      });
      _displayError('Speichern erfolgreich!');
      return true;
    } catch (e) {
      developer.log(e.toString());
      setState(() {
        restoreDefaults();
      });
      _displayError('Fehler beim Speichern!');
      return false;
    }
  }

  Future<bool> _deleteProfile() async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Warnung'),
              content: Text(
                  'Möchtest du ${editsOwnAccount! ? 'dein' : 'dieses'} Konto wirklich löschen? ${editsOwnAccount! ? 'Du wirst dich' : 'Man wird sich'} nicht mehr mit diesem Konto anmelden können!'),
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
                        passwordCorrect = (oldPassword.isNotEmpty &&
                            await GetIt.I<Backend>()
                                .login(widget.currentUser.email, oldPassword));
                      }
                      if (!editsOwnAccount! || passwordCorrect) {
                        if (!editsOwnAccount! ||
                            await GetIt.instance<Backend>().sentLocalPurchasesToServer()) {
                          await GetIt.instance<Backend>()
                              .delete('/user/${widget.currentUser.id}', null);
                          if (editsOwnAccount!) {
                            GetIt.instance<Backend>().logout();
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()),
                                (Route<dynamic> route) => false);
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
                                  'Konto konnte nicht gelöscht werden, weil es noch nicht synchronisierte Käufe gibt.'),
                              actions: [
                                ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Okay'))
                              ],
                            ),
                          );
                        }
                      } else {
                        throw (Exception('wrong password'));
                      }
                    } catch (e) {
                      developer.log(e.toString());
                      _displayError('Fehler beim Löschen!');
                    }
                  },
                ),
              ],
            ));

    return true;
  }

  Future<String> _enterOldPassword() async {
    String enteredPassword = '';
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Profil ändern'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                  'Um die Aktion zu bestätigen, gib bitte dein aktuelles Passwort ein.'),
              TextField(
                autofocus: true,
                obscureText: true,
                onChanged: (value) => enteredPassword = value,
              )
            ]),
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
        });
    return enteredPassword;
  }

  void _displayError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
    ));

    setState(() {
      restoreDefaults();
    });
  }
}
