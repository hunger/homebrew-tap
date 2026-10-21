class ReleasePlz < Formula
  desc "Publish Rust crates from CI with a Release PR"
  homepage "https://release-plz.dev"
  version "0.3.174"
  license any_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    regex(/^release-plz-v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-aarch64-apple-darwin.tar.gz"
      sha256 "415494b8540935e4b38f815bd4c3640092313b101323398d641e91b1f7489d80"
    end
    on_intel do
      # Upstream publishes no x86_64 macOS binary, so build from source there.
      url "https://github.com/release-plz/release-plz/archive/refs/tags/release-plz-v#{version}.tar.gz"
      sha256 "4e94e5c4a61aa9678b2d48fb8aeae4d6f9afd252d87490c923bfe5acd70eecd9"
      depends_on "rust" => :build
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-aarch64-unknown-linux-musl.tar.gz"
      sha256 "ab1a5a36d93cc4abedd9474381300a709ea06cd915c88c67c187118dbd9475d1"
    end
    on_intel do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-x86_64-unknown-linux-musl.tar.gz"
      sha256 "8240e953608d40e709d042e9ac0e206d518825de3d88a3da9ebeaf2a3ff57ea9"
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
