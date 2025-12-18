class GitWorktrees < Formula
  desc "Simple shell helpers for Git worktrees with fzf integration"
  homepage "https://github.com/EtienneBBeaulac/git-worktrees"
  url "https://github.com/EtienneBBeaulac/git-worktrees/archive/refs/tags/v1.0.2-test.tar.gz"
  sha256 "18188509e322043b42967ea64a0cd40a29cc1fe1b81df27b99bc2bb8634baf1f"
  license "MIT"
  
  head "https://github.com/EtienneBBeaulac/git-worktrees.git", branch: "main"

  depends_on "fzf" => :recommended
  depends_on "git"
  uses_from_macos "zsh"

  def install
    # Install main scripts to libexec
    libexec.install "scripts/wt"
    libexec.install "scripts/wtnew"
    libexec.install "scripts/wtrm"
    libexec.install "scripts/wtopen"
    libexec.install "scripts/wtls"
    
    # Install ALL library modules to libexec/lib (required, not optional)
    (libexec/"lib").install "scripts/lib/wt-common.zsh"
    (libexec/"lib").install "scripts/lib/wt-recovery.zsh"
    (libexec/"lib").install "scripts/lib/wt-validation.zsh"
    (libexec/"lib").install "scripts/lib/wt-discovery.zsh"
    
    # Create executable wrapper scripts in bin (automatically added to PATH)
    # The scripts auto-discover their lib directory via ${(%):-%x}:A:h
    %w[wt wtnew wtrm wtopen wtls].each do |cmd|
      (bin/cmd).write <<~EOS
        #!/bin/zsh
        # Homebrew-installed git-worktrees
        source "#{libexec}/#{cmd}"
        #{cmd} "$@"
      EOS
    end
  end

  def caveats
    <<~EOS
      git-worktrees is now ready to use! Commands are in your PATH:

        wt          # Hub to list, open, create, and manage worktrees
        wtnew       # Create/open a worktree for a new or existing branch
        wtopen      # Open an existing worktree
        wtrm        # Safely remove a worktree
        wtls        # List worktrees with status

      Try it now:
        wt --help

      For more information: https://github.com/EtienneBBeaulac/git-worktrees
    EOS
  end

  test do
    # Test that scripts exist and are valid zsh
    system "zsh", "-n", libexec/"wt"
    system "zsh", "-n", libexec/"wtnew"
    system "zsh", "-n", libexec/"wtrm"
    system "zsh", "-n", libexec/"wtopen"
    system "zsh", "-n", libexec/"wtls"
    
    # Test all library modules exist and are valid
    system "zsh", "-n", libexec/"lib/wt-common.zsh"
    system "zsh", "-n", libexec/"lib/wt-recovery.zsh"
    system "zsh", "-n", libexec/"lib/wt-validation.zsh"
    system "zsh", "-n", libexec/"lib/wt-discovery.zsh"
  end
end

