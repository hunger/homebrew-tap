class ReleasePlz < Formula
  desc "Publish Rust crates from CI with a Release PR"
  homepage "https://release-plz.dev"
  version "0.3.167"
  license any_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    regex(/^release-plz-v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-aarch64-apple-darwin.tar.gz"
      sha256 "e9dc21a6a79ee59e6e9c5dc6d8fed54380e0d2a4f768c2950cbd8cf99f5f9fba"
    end
    on_intel do
      # Upstream publishes no x86_64 macOS binary, so build from source there.
      url "https://github.com/release-plz/release-plz/archive/refs/tags/release-plz-v#{version}.tar.gz"
      sha256 "05ee0f96c26a0b55206d7468011efb2b0330232db761b7936c652a1ef6c93f65"
      depends_on "rust" => :build
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-aarch64-unknown-linux-musl.tar.gz"
      sha256 "91f7313350d329d0958d07f15b0e31e03559948f4b5f9431dbff278ee1363638"
    end
    on_intel do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-x86_64-unknown-linux-musl.tar.gz"
      sha256 "25d66b79ca52b9aa0034af09c90b5676308a55b11c20bf5dc0b5284cb68b5c93"
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
