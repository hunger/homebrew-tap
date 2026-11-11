class Verus < Formula
  desc "Verification tool for the Rust programming language"
  homepage "https://verus-lang.github.io/verus"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "rustup"

  on_macos do
    on_arm do
      url "https://github.com/verus-lang/verus/releases/download/release/0.2026.11.02.8bf68ee/verus-0.2026.11.02.8bf68ee-arm64-macos.zip"
      sha256 "3086974d1afebf8b9f6fee2939b626486a12248c0dab528b9262ea652b863326"
    end
    on_intel do
      url "https://github.com/verus-lang/verus/releases/download/release/0.2026.11.02.8bf68ee/verus-0.2026.11.02.8bf68ee-x86-macos.zip"
      sha256 "c43dc9bac0a35a7551ffd56c838abe6145b85867b50506200631eccf221acd2e"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/verus-lang/verus/releases/download/release/0.2026.11.02.8bf68ee/verus-0.2026.11.02.8bf68ee-arm64-linux.zip"
      sha256 "bc28850dd5efd1679a4cf4ffd3309921c3523c69fa4757079e5d12d4122d400d"
    end
    on_intel do
      url "https://github.com/verus-lang/verus/releases/download/release/0.2026.11.02.8bf68ee/verus-0.2026.11.02.8bf68ee-x86-linux.zip"
      sha256 "f3a0119292df8855e4435da8130bee1873b0e6a60c306accf81a08ea687bba3c"
    end
  end

  def install
    libexec.install(*buildpath.children)
    bin.install_symlink libexec/"verus"
    bin.install_symlink libexec/"cargo-verus"
    bin.install_symlink libexec/"rust_verify"
    bin.install_symlink libexec/"z3"
  end

  def caveats
    <<~EOS
      verus needs a matching rustup toolchain. Run any verus command to
      print the exact `rustup install` command for this version.
    EOS
  end

  test do
    assert_match "Z3 version", shell_output("#{bin}/z3 --version")
    assert_predicate bin/"verus", :executable?
    assert_predicate bin/"cargo-verus", :executable?
    assert_predicate bin/"rust_verify", :executable?
  end
end
