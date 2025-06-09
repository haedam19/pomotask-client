import 'package:flutter/material.dart';
import 'package:pomotask_client/main.dart';
import 'package:pomotask_client/widgets/feat_widgets.dart';
import 'package:pomotask_client/api_service.dart' as api_service;

class LoginPage extends StatefulWidget
{
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// 서버 연결 완료
class _LoginPageState extends State<LoginPage>
{
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose()
  {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async
  {
    final id = _idController.text;
    final password = _passwordController.text;

    final success = await api_service.signIn(serverAddress, id, password);
    if (success)
    {
      debugPrint('[LOGIN] 아이디: $id, 비밀번호: $password');
      loggedInUser = id;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
    else
    {
      debugPrint('⚠️ 로그인 실패: 아이디 또는 비밀번호가 잘못되었습니다.');
    }
  }

  void _handleSignUp(BuildContext context)
  {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints)
        {
          return ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 800,
              minHeight: 600,
            ),
            child: Center(
              child: SizedBox(
                width: 600,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'PomoTaskManager에 오신 것을 환영합니다.',
                        style: TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _idController,
                        decoration: InputDecoration(
                          labelText: '아이디',
                          prefixIcon: Icon(Icons.perm_identity),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          child: const Text('로그인'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleSignUp(context),
                          child: const Text('회원가입'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SignUpPage extends StatefulWidget
{
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

// 서버 연결 완료
class _SignUpPageState extends State<SignUpPage>
{
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose()
  {
    _idController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleSignUp() async
  {
    final id = _idController.text;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password != confirm)
    {
      debugPrint('⚠️ 비밀번호와 비밀번호 확인이 일치하지 않습니다.');
      return;
    }

    final success = await api_service.signUp(serverAddress, id, password);
    if (success)
    {
      debugPrint('[SIGNUP] 아이디: $id, 비밀번호: $password');
      Navigator.pop(context);
    }
    else
    {
      debugPrint('⚠️ 회원가입 실패');
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSignUp,
                    child: const Text('회원가입'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
