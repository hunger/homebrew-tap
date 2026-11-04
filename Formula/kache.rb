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
      url "https://github.com/kunobi-ninja/kache/releases/download/v2.0.0/kache-aarch64-apple-darwin.tar.gz"
      sha256 "b46139f7d42895c62962450886dd35f4554c17531209ea69b2db053d2a142bcb"
    end
    on_intel do
      url "https://github.com/kunobi-ninja/kache/releases/download/v2.0.0/kache-x86_64-apple-darwin.tar.gz"
      sha256 "0ab8b29f659d159de78f70376c6ffa7730879f18fcde397567b683796eb5fd73"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/kunobi-ninja/kache/releases/download/v2.0.0/kache-aarch64-unknown-linux-musl.tar.gz"
      sha256 "8c5ca4d1d4b6fc66e5175c8a1150e1daa85099080646322058d9083c72986bba"
    end
    on_intel do
      url "https://github.com/kunobi-ninja/kache/releases/download/v2.0.0/kache-x86_64-unknown-linux-musl.tar.gz"
      sha256 "6c59665faf1b14d0944391e6f2a1b510195e6be92c63060a9d1770ed00676824"
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
