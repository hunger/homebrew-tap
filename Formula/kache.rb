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
      url "https://github.com/kunobi-ninja/kache/releases/download/v2.4.0/kache-aarch64-apple-darwin.tar.gz"
      sha256 "547c95dc178d02d8db72a0b6217086dfc71d339640b072ccf9eece52a5f621f7"
    end
    on_intel do
      url "https://github.com/kunobi-ninja/kache/releases/download/v2.4.0/kache-x86_64-apple-darwin.tar.gz"
      sha256 "4e729f8836e669e33d60fcfaf4bd7db4806fe4a9feccb7bdaca47238445d70a3"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/kunobi-ninja/kache/releases/download/v2.4.0/kache-aarch64-unknown-linux-musl.tar.gz"
      sha256 "061e02232ba1b5f64a0bb3b8e1cdb97cd2dff12932a1522666e32671f8182aae"
    end
    on_intel do
      url "https://github.com/kunobi-ninja/kache/releases/download/v2.4.0/kache-x86_64-unknown-linux-musl.tar.gz"
      sha256 "6dc5feb2fdcc982538869bc0d0f63ad0da2c8f1a2c22649e7707ff4eb4dbaab7"
    end
  end

  def install
    bin.install %w[kache kache-engine]
    generate_completions_from_executable(bin/"kache", "completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kache --version")
    assert_match "\"command\": \"doctor\"", shell_output("#{bin}/kache doctor --json")
  end
end
