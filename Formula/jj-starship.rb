class JjStarship < Formula
  desc "Fast unified Starship prompt module for Git and Jujutsu repositories"
  homepage "https://github.com/dmmulroy/jj-starship"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/dmmulroy/jj-starship/releases/download/v0.7.4/jj-starship-aarch64-apple-darwin.tar.gz"
      sha256 "92c83994a1759fe5a2193119e67dc234d78c5d6ae2bc7f256b53444bf4251571"
    end
    on_intel do
      url "https://github.com/dmmulroy/jj-starship/releases/download/v0.7.4/jj-starship-x86_64-apple-darwin.tar.gz"
      sha256 "e07f37df03de4a53bb30c646d86f0ef1299db6e8ab575204739a5c1d5d735203"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/dmmulroy/jj-starship/releases/download/v0.7.4/jj-starship-aarch64-unknown-linux-musl.tar.gz"
      sha256 "b4a0d96ff9bbb7b499039990cbc3b76d3769880c5d6645150f9d7ef94556033c"
    end
    on_intel do
      url "https://github.com/dmmulroy/jj-starship/releases/download/v0.7.4/jj-starship-x86_64-unknown-linux-musl.tar.gz"
      sha256 "0c02c4cb10a6c2384c291289c8fddeb63d0ca0fbcd9d2447c9903998c939cebf"
    end
  end

  def install
    bin.install "jj-starship"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/jj-starship --version")
  end
end
