
TRY THIS: Try running your application with "flutter run". You'll see
the application has a purple toolbar. Then, without quitting the app,
try changing the seedColor in the colorScheme below to Colors.green
and then invoke "hot reload" (save your changes or press the "hot
reload" button in a Flutter-supported IDE, or press "r" if you used
the command line to start the app).

試してみて: "flutter run"でアプリを実行してみてください．色などの設定を変更してからコマンドラインでrを押すと
ホットリロードが走って，設定が反映されるのが見れます．

Notice that the counter didn't reset back to zero; the application
state is not lost during the reload. To reset the state, use hot
restart instead.

ホットリロードしてもアプリケーションの状態は維持されます．

This works for code too, not just values: Most code changes can be
tested with just a hot reload.

ほとんどのコードの変更に対して，ホットリロードでアプリケーションの状態は維持されます．
