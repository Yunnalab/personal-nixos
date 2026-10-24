{ ... }:

{
  # 对上游 nixpkgs 包的本地 workaround 集中放在这里，每条都写清原因和上游修复后如何回退。
  nixpkgs.overlays = [
    (final: prev: {
      python3 = prev.python3.override {
        packageOverrides = _pyFinal: pyPrev: {
          # pyopenjtalk-plus 0.4.1-post9 用 Cython 3.3.0 编译后，
          # tests/test_frontend.py::test_run_njd_from_mecab_invalid_input_should_not_break_next_call
          # 断言的是 Cython 旧版的报错文案：
          #   测试期望  TypeError("... must be str ...")   ← Cython <= 3.2 没有自动类型检查
          #   实际抛出  TypeError("Expected str, got int")  ← Cython 3.3.0 生成的检查代码
          # 1678 个测试里只有这 1 个失败，是文案不匹配而非功能问题，故只跳过这一条。
          # 上游修好后可以删掉整个模块（它只被 calibre -> piper-tts -> pyopenjtalk-plus 间接引入）。
          pyopenjtalk-plus = pyPrev.pyopenjtalk-plus.overridePythonAttrs (_: {
            disabledTests = [
              "test_run_njd_from_mecab_invalid_input_should_not_break_next_call"
            ];
          });
        };
      };
      # 注意：nixpkgs 里 python3Packages 是独立引用（= python314Packages），
      # 只覆写 python3 不会传导过去，必须显式指回被覆写后的解释器。
      python3Packages = final.python3.pkgs;

      # calibre 9.16.0 的 installCheck 里有一条测试假定 speechd 的 python 模块存在：
      #   src/calibre/test_build.py::BuildTest.test_speech_dispatcher → import speechd
      # 但本版 nixpkgs 的 speechd-minimal 只装 C 库，输出里没有
      # lib/python3.14/site-packages/speechd（上游打包问题，和本机配置无关；
      # 也解释了为什么 calibre-9.16.0 在所有二进制镜像上都 404）。
      # 影响面：calibre「朗读」的 system voices（走 speech-dispatcher）不可用，
      #        piper 内建引擎不受影响。上游修好后可删掉这条。
      calibre = prev.calibre.overrideAttrs (old: {
        installCheckPhase = prev.lib.replaceStrings
          [ "python setup.py test" ]
          [ "python setup.py test --exclude-test-name test_speech_dispatcher" ]
          old.installCheckPhase;
      });
    })
  ];
}
