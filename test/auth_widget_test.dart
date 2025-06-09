import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomotask_client/main.dart';

void main() {
  group('LoginPage 네비게이션 테스트', () {
    testWidgets('로그인 화면 최상단 텍스트 및 회원가입 버튼 동작', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // 최상단 환영 문구 확인
      expect(
        find.text('PomoTaskManager에 오신 것을 환영합니다.'),
        findsOneWidget,
      );

      // 회원가입 버튼 확인
      final signUpBtn = find.widgetWithText(ElevatedButton, '회원가입');
      expect(signUpBtn, findsOneWidget);

      // 회원가입 버튼 클릭 시 SignUpPage로 이동
      await tester.tap(signUpBtn);
      await tester.pumpAndSettle();

      // SignUpPage 진입 확인
      expect(
        find.widgetWithText(AppBar, '회원가입'),
        findsOneWidget,
      );
    });

    testWidgets('성공적 회원가입 후 로그인 화면으로 복귀', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // 로그인 → SignUpPage 이동
      await tester.tap(find.widgetWithText(ElevatedButton, '회원가입'));
      await tester.pumpAndSettle();

      // SignUpPage 진입 확인
      expect(
        find.widgetWithText(AppBar, '회원가입'),
        findsOneWidget,
      );

      // 유효한 입력값 채우기
      await tester.enterText(find.byType(TextField).at(0), 'testID');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.enterText(find.byType(TextField).at(2), 'password123');

      // 회원가입 완료 버튼 탭
      await tester.tap(find.widgetWithText(ElevatedButton, '회원가입'));
      await tester.pumpAndSettle();

      // 다시 로그인 화면의 환영 문구가 보이는지 확인
      expect(
        find.text('PomoTaskManager에 오신 것을 환영합니다.'),
        findsOneWidget,
      );
    });
  });

  // 이 부분은 추후 구현
  group('SignUpPage 폼 유효성 검사', () {
    testWidgets('입력 없이 제출 시 필수 입력 에러 메시지 표시', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.tap(find.widgetWithText(ElevatedButton, '회원가입'));
      await tester.pump();

      expect(find.text('이메일을 입력해주세요'), findsOneWidget);
      expect(find.text('비밀번호를 입력해주세요'), findsOneWidget);
      expect(find.text('비밀번호 확인을 입력해주세요'), findsOneWidget);
    });

    testWidgets('비밀번호와 확인이 일치하지 않을 때 에러 메시지 표시', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      await tester.enterText(find.byType(TextField).at(0), 'testID');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.enterText(find.byType(TextField).at(2), 'different');

      await tester.tap(find.widgetWithText(ElevatedButton, '회원가입'));
      await tester.pump();

      expect(find.text('비밀번호가 일치하지 않습니다'), findsOneWidget);
    });
  });
}
