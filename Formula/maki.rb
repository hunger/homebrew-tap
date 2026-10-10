class Maki < Formula
  desc "Efficient AI coding agent extendable by neovim-like Lua plugins"
  homepage "https://maki.sh"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/tontinton/maki/releases/download/v0.6.2/maki-v0.6.2-aarch64-apple-darwin.tar.gz"
      sha256 "58c49ef7f2af8a7b77d4d27f8a42da78c7dc97ebf8e02082d3339b51fc8192b5"
    end
    on_intel do
      url "https://github.com/tontinton/maki/releases/download/v0.6.2/maki-v0.6.2-x86_64-apple-darwin.tar.gz"
      sha256 "6e7b6be988fa1d1750e24ed3528fe35754254764808a63f1146f9f71f662ea77"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/tontinton/maki/releases/download/v0.6.2/maki-v0.6.2-aarch64-unknown-linux-musl.tar.gz"
      sha256 "086f4c64a2a702bf30d1108f5ccbaddab9ab745e078f55308c8d5a0069327b9e"
    end
    on_intel do
      url "https://github.com/tontinton/maki/releases/download/v0.6.2/maki-v0.6.2-x86_64-unknown-linux-musl.tar.gz"
      sha256 "6499801f60c15406c1e71c6c1f6d786ad2cc619c5da4a7434ded717c2dbcfdbe"
    end
  end

  def install
    bin.install "maki"
  end

  def caveats
    <<~EOS
      maki has a built-in `maki update` command. Do not use it for this
      installation; upgrade with `brew upgrade maki` instead.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/maki --version")
  end
end
