class Kache < Formula
  desc "Zero-copy, content-addressed build cache for Rust, C/C++ and more"
  homepage "https://kunobi.ninja/product/kache"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/kunobi-ninja/kache/releases/download/v0.19.0/kache-aarch64-apple-darwin.tar.gz"
      sha256 "8dcdaa95f3678b00696ca4742d8ad67c1f00d9baa7d142cbf9337b3f3ecb03b7"
    end
    on_intel do
      url "https://github.com/kunobi-ninja/kache/releases/download/v0.19.0/kache-x86_64-apple-darwin.tar.gz"
      sha256 "162646f94403c2a2e30dc3357b9ba97acbc788a297634cd7559beb33d83c0d4c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/kunobi-ninja/kache/releases/download/v0.19.0/kache-aarch64-unknown-linux-musl.tar.gz"
      sha256 "cf9880200d28ca8b2cc33b5227b9cc26094c47c0927f7791734c02ba1a5cd6ac"
    end
    on_intel do
      url "https://github.com/kunobi-ninja/kache/releases/download/v0.19.0/kache-x86_64-unknown-linux-musl.tar.gz"
      sha256 "64d8e10abc1e916859ce5bf2937887df15933e1b65e66a1efe7dc769bcaa7798"
    end
  end

  def install
    bin.install "kache"
    generate_completions_from_executable(bin/"kache", "completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kache --version")
    assert_match "\"command\": \"doctor\"", shell_output("#{bin}/kache doctor --json")
  end
end
