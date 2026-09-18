class Devbox < Formula
  desc "Blazingly fast Rust rewrite of distrobox"
  homepage "https://codeberg.org/devbox-rs/devbox"
  # Explicit version: Homebrew mis-parses "x86_64" in the asset name as the version.
  url "https://codeberg.org/devbox-rs/devbox/releases/download/v1.0.1/devbox-x86_64-unknown-linux-musl.tar.gz"
  version "1.0.1"
  sha256 "f4166e8816bffe5c403b64b10c4d5f272c25ed3f10b22cf976c8fca2c5654ba5"
  license "GPL-3.0-or-later"

  livecheck do
    url "https://codeberg.org/api/v1/repos/devbox-rs/devbox/releases/latest"
    strategy :json do |json|
      json["tag_name"]&.delete_prefix("v")
    end
  end

  # Upstream publishes a single static x86_64 Linux binary.
  depends_on arch: :x86_64
  depends_on :linux

  def install
    bin.install "devbox"
    generate_completions_from_executable(bin/"devbox", "admin", "completions")
  end

  test do
    # Inside a container devbox runs in host-proxy mode and lacks --version;
    # this test is meant to run on the host.
    assert_match version.to_s, shell_output("#{bin}/devbox --version")
  end
end
