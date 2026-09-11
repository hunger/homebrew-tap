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
      url "https://github.com/tontinton/maki/releases/download/v0.5.3/maki-v0.5.3-aarch64-apple-darwin.tar.gz"
      sha256 "edf90814ffbd003196de54ecd2e12ea76dec4aa9f869e092890e1d1ed7419179"
    end
    on_intel do
      url "https://github.com/tontinton/maki/releases/download/v0.5.3/maki-v0.5.3-x86_64-apple-darwin.tar.gz"
      sha256 "328beab7ec9035f49b3567d2498d0ff618faa1a341e8a71b9440d44eb254b7d5"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/tontinton/maki/releases/download/v0.5.3/maki-v0.5.3-aarch64-unknown-linux-musl.tar.gz"
      sha256 "d07dd03d3d6061f05539305551c89b59920fc9b118316c9a6c1821632618d983"
    end
    on_intel do
      url "https://github.com/tontinton/maki/releases/download/v0.5.3/maki-v0.5.3-x86_64-unknown-linux-musl.tar.gz"
      sha256 "38779402a24ff769e6f6d1684d44643eb5aa7db9824e83f1cbbce38e0e2f0bae"
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
