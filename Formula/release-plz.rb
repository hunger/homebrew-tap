class ReleasePlz < Formula
  desc "Publish Rust crates from CI with a Release PR"
  homepage "https://release-plz.dev"
  version "0.3.168"
  license any_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    regex(/^release-plz-v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-aarch64-apple-darwin.tar.gz"
      sha256 "48e4fa03ee28a5e2d573105b070f2730aea8efda21f206d70ddf9a2c8365bd18"
    end
    on_intel do
      # Upstream publishes no x86_64 macOS binary, so build from source there.
      url "https://github.com/release-plz/release-plz/archive/refs/tags/release-plz-v#{version}.tar.gz"
      sha256 "b64776ecf7049ef2e87099716f98ccd1c640e684b5c0cd2bba17977b546f81f7"
      depends_on "rust" => :build
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-aarch64-unknown-linux-musl.tar.gz"
      sha256 "44cba91d0484b4ff4b82a10c83ed5ae95d24195686f772ed82e0f9319740a63e"
    end
    on_intel do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-x86_64-unknown-linux-musl.tar.gz"
      sha256 "446a2d0aabc8a3edc06199133004078304067141c23f5cff44e222d83defff63"
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
