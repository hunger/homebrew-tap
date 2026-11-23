class NvimNightly < Formula
  desc "Ambitious Vim-fork focused on extensibility and agility (nightly prebuilt build)"
  homepage "https://neovim.io/"
  # bump: fixed-url
  # The `nightly` tag moves every night: the URLs never change, only the
  # version and the checksums do. The version comes from the release notes.
  version "0.13.0-dev-2173"
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
      sha256 "eb6013f263d65ff9832493dcd28c4219e9f12bc682a3a56fe9df7b86762fd848"
    end
    on_intel do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-x86_64.tar.gz"
      sha256 "2d648563384ad2cfd42728d4a675ac5c2feaf9014320c8a25ad0ef5166411623"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-arm64.tar.gz"
      sha256 "f3aa01bddc201b226bbf6d792352246ff2bcc2ac6f5a23842e585d71d2cec8a5"
    end
    on_intel do
      url "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
      sha256 "f65c05b5ec5b6ca4571d70aabe8f5a3b5a76bf658815658b112d023c8b99906c"
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
