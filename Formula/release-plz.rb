class ReleasePlz < Formula
  desc "Publish Rust crates from CI with a Release PR"
  homepage "https://release-plz.dev"
  version "0.4.1"
  license any_of: ["MIT", "Apache-2.0"]

  livecheck do
    url :stable
    regex(/^release-plz-v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-aarch64-apple-darwin.tar.gz"
      sha256 "070da77afd6f19eaac6d89c7b1fc16468a26c7a995b992baa0b87bb17d5bcb50"
    end
    on_intel do
      # Upstream publishes no x86_64 macOS binary, so build from source there.
      url "https://github.com/release-plz/release-plz/archive/refs/tags/release-plz-v#{version}.tar.gz"
      sha256 "a3225b0f7edab2439b48762110f804186897e87eee61e0e9162996075e07adee"
      depends_on "rust" => :build
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-aarch64-unknown-linux-musl.tar.gz"
      sha256 "465dbcece9f613d52950b9837d0222b689e3948f4f6310168cdae2a1ffa4cacf"
    end
    on_intel do
      url "https://github.com/release-plz/release-plz/releases/download/release-plz-v#{version}/release-plz-x86_64-unknown-linux-musl.tar.gz"
      sha256 "5e77cf9b29a7c5b4dcb0d61cce7b03033e58e4ec74efa47a3e01f0ead1aa9664"
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
