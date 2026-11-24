class Verus < Formula
  desc "Verification tool for the Rust programming language"
  homepage "https://verus-lang.github.io/verus"
  license "MIT"

  livecheck do
    url :stable
    regex(%r{release/(\d+(?:\.\d+)*\.[0-9a-f]+)}i)
    strategy :github_latest
  end

  depends_on "rustup"

  on_macos do
    on_arm do
      url "https://github.com/verus-lang/verus/releases/download/release/0.2026.11.22.1ce6a59/verus-0.2026.11.22.1ce6a59-arm64-macos.zip"
      sha256 "8efd216b6d104bfa4fe946373fe7d260ad0db613c2c71d074744f1c91eda1e4d"
    end
    on_intel do
      url "https://github.com/verus-lang/verus/releases/download/release/0.2026.11.22.1ce6a59/verus-0.2026.11.22.1ce6a59-x86-macos.zip"
      sha256 "9833442c8d402f329a1ea2cff0117e77e04009031260d6c88b8c771df1b69982"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/verus-lang/verus/releases/download/release/0.2026.11.22.1ce6a59/verus-0.2026.11.22.1ce6a59-arm64-linux.zip"
      sha256 "69e059e0256cdfd48ce5f65b72b68dc54ac5c40e2878e07195dd87fb2b582c0e"
    end
    on_intel do
      url "https://github.com/verus-lang/verus/releases/download/release/0.2026.11.22.1ce6a59/verus-0.2026.11.22.1ce6a59-x86-linux.zip"
      sha256 "c955d5958877f4f907cce80aa996d4239a481984829d82e325938c7bf242b0db"
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
