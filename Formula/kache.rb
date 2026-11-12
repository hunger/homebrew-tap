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
      url "https://github.com/kunobi-ninja/kache/releases/download/v2.1.1/kache-aarch64-apple-darwin.tar.gz"
      sha256 "d4533baa3c57be51d5f2390b70551ca9d6c2a83a1933266fa0a57053774e08f6"
    end
    on_intel do
      url "https://github.com/kunobi-ninja/kache/releases/download/v2.1.1/kache-x86_64-apple-darwin.tar.gz"
      sha256 "69627cfec3017aa521d06a84afc6c5e74734468678bd6659d92afd57d9a4f457"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/kunobi-ninja/kache/releases/download/v2.1.1/kache-aarch64-unknown-linux-musl.tar.gz"
      sha256 "466f0aef4885f5291359b3c1bc0c9976824634194c5b67e1cee2a4fe3035155a"
    end
    on_intel do
      url "https://github.com/kunobi-ninja/kache/releases/download/v2.1.1/kache-x86_64-unknown-linux-musl.tar.gz"
      sha256 "7603022ee78b48a9afde9055b0df27e5c2cef1351a54fa2de6b4fde0f37ae22c"
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
