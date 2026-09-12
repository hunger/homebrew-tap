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
      url "https://github.com/kunobi-ninja/kache/releases/download/v0.20.0/kache-aarch64-apple-darwin.tar.gz"
      sha256 "bc19c7015b1ca449c13f827cff7235e9adcba3f48c01ac2ff902e3f93e78dc7c"
    end
    on_intel do
      url "https://github.com/kunobi-ninja/kache/releases/download/v0.20.0/kache-x86_64-apple-darwin.tar.gz"
      sha256 "2eadbf652a63e8cae80af70419a6abf48a789958765424daa9b1ec4ed377dbb5"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/kunobi-ninja/kache/releases/download/v0.20.0/kache-aarch64-unknown-linux-musl.tar.gz"
      sha256 "e7f0ebf18dbbef64d23acbf25009baab1987951bb69742697f59094a1bb04b37"
    end
    on_intel do
      url "https://github.com/kunobi-ninja/kache/releases/download/v0.20.0/kache-x86_64-unknown-linux-musl.tar.gz"
      sha256 "fe5ce52406e0dcb8c9a49798671a073440cae13a88731b1b712b7c0fa372b85b"
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
