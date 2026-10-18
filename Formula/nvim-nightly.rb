class NvimNightly < Formula
  desc "Ambitious Vim-fork focused on extensibility and agility (nightly prebuilt build)"
  homepage "https://neovim.io/"
  # bump: fixed-url
  # The `nightly` tag moves every night: the URLs never change, only the
  # version and the checksums do. The version comes from the release notes.
  version "0.13.0-dev-1895"
  license "Apache-2.0"

  livecheck do
    url :stable
    # Lists all releases (prereleases included); the version is in the nightly release notes.
    strategy :github_releases do |json, regex|
      nightly = json.find { |release| release["tag_name"] == "nightly" }
      nightly&.dig("body")&.then { |body| body[regex, 1] }
    end
    regex(/NVIM v(\d+\.\d+\.\d+-dev-\d+)/i)
  end

  on_macos do
    on_arm do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-arm64.tar.gz"
      sha256 "e93ef6829fd45c9c4a93ef06899506880abaf489a0400598549ffbfae0754cc5"
    end
    on_intel do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-x86_64.tar.gz"
      sha256 "eaa5f9bde49e6c0ba313ba78ae057f8acecb59383cbda20d9748261170bebe35"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-arm64.tar.gz"
      sha256 "893c517798eadbb69ed5dec1da36a7729e05b14587dae28a78d3398581a41bdc"
    end
    on_intel do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
      sha256 "2b077774d6517b4777f4d2f4a4876c23f1c7ebbb11d3f125e6213c825426a366"
    end
  end

  def install
    # Keep the whole tree (bin/, lib/, share/) private under libexec so nothing
    # collides with the `neovim` formula; expose only `nvim-nightly`.
    # nvim locates its runtime relative to the real executable path, so a
    # symlink is enough.
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/nvim" => "nvim-nightly"
    man1.install_symlink libexec/"share/man/man1/nvim.1" => "nvim-nightly.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nvim-nightly --version")
    (testpath/"in.txt").write "hello\n"
    system bin/"nvim-nightly", "--headless", "-u", "NONE", "-c", "normal! Aworld", "-c", "wq", testpath/"in.txt"
    assert_equal "helloworld\n", (testpath/"in.txt").read
    # The runtime must be found through the symlink.
    assert_match "runtime", shell_output("#{bin}/nvim-nightly --headless -u NONE -c 'echo $VIMRUNTIME' -c q 2>&1")
  end
end
