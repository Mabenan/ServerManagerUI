import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:servermanager/globals.dart';

class LoginWidget extends StatefulWidget {
  final Function loginCB;

  LoginWidget({Key? key, required this.loginCB}) : super(key: key);
  @override
  State<LoginWidget> createState() => _LoginWidgetState(loginCB: loginCB);
}

class _LoginWidgetState extends State<LoginWidget> {
  var _username = new TextEditingController();
  var _password = new TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Function loginCB;

  late Future<bool> loginWait;

  _LoginWidgetState({required this.loginCB}) : super() {
    loginWait = _checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        leading: kIsWeb ? null : Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                apiServer = null;
                this.loginCB("exit");
              },
            )
          ],
        ),
      ),
      body: FutureBuilder(
        future: loginWait,
        initialData: true,
        builder: (context, snapshot) => snapshot.data == false
            ? buildLoginForm(context)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Center(child: CircularProgressIndicator())],
              ),
      ),
    );
  }

  Row buildLoginForm(BuildContext context) {
    return Row(
      children: [
        Flexible(child: Container(), flex: 25),
        Flexible(
          flex: 50,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.account_box),
                    hintText: 'Username',
                    labelText: 'Username *',
                  ),
                  controller: _username,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a path';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.password),
                    hintText: 'Password',
                    labelText: 'Password *',
                  ),
                  obscureText: true,
                  controller: _password,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a path';
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: ElevatedButton(
                          child: Text("Login"),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              ParseUser user = ParseUser.createUser(
                                  _username.text, _password.text);

                              ParseResponse resp = await user.login();
                              if (resp.success) {
                                loginCB("login");
                              } else {
                                showDialog(
                                    context: context,
                                    builder: (cntx) => AlertDialog(
                                        title: Text("Login Failed: " +
                                            resp.error!.message)));
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        Flexible(child: Container(), flex: 25),
      ],
    );
  }

  Future<bool> _checkLogin() async {
    try {
      ParseUser user = await ParseUser.currentUser();
      ParseResponse resp = await user.getUpdatedUser();
      if (resp.success) {
        this.loginCB("login");
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
