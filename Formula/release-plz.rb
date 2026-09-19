class ReleasePlz < Formula
  desc "Publish Rust crates from CI with a Release PR"
  homepage "https://release-plz.dev"
  version "0.3.169"
  license any_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    regex(/^release-plz-v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-aarch64-apple-darwin.tar.gz"
      sha256 "3bb728a921e0f9d6aca48723de2d8a49a71099ca8a113efb9350781120648a7e"
    end
    on_intel do
      # Upstream publishes no x86_64 macOS binary, so build from source there.
      url "https://github.com/release-plz/release-plz/archive/refs/tags/release-plz-v#{version}.tar.gz"
      sha256 "1f1c7d09c80f85d1ae4a58711a41e499397f3254572070c4052901bacac3167a"
      depends_on "rust" => :build
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-aarch64-unknown-linux-musl.tar.gz"
      sha256 "9fe32973a63bf1d18f02e877becf8619abc8b283f25d294f00d951e55c9946f2"
    end
    on_intel do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-x86_64-unknown-linux-musl.tar.gz"
      sha256 "ed709642b7f5b5fda4d47309884e65f84ca097cf9176cfd9793e8e66e28b48ad"
    end
  end

  def install
    if OS.mac? && Hardware::CPU.intel?
      system "cargo", "install", *std_cargo_args(path: "crates/release_plz")
    else
      bin.install "release-plz"
    end
    generate_completions_from_executable(bin/"release-plz", "generate-completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/release-plz --version")
  end
end
