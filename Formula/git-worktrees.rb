class GitWorktrees < Formula
  desc "Simple shell helpers for Git worktrees with fzf integration"
  homepage "https://github.com/EtienneBBeaulac/git-worktrees"
  url "https://github.com/EtienneBBeaulac/git-worktrees/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "4be2c0b1a25d3bb026ed623744883e80981b9ff1a7729ea9167be9b4a10cb4c2"
  license "MIT"
  
  head "https://github.com/EtienneBBeaulac/git-worktrees.git", branch: "main"

  depends_on "fzf" => :recommended
  depends_on "git"
  uses_from_macos "zsh"

  def install
    # Install scripts to libexec
    libexec.install "scripts/wt"
    libexec.install "scripts/wtnew"
    libexec.install "scripts/wtrm"
    libexec.install "scripts/wtopen"
    libexec.install "scripts/wtls"
    
    # Install library files
    (libexec/"lib").install "scripts/lib/wt-common.zsh"
    (libexec/"lib").install "scripts/lib/wt-discovery.zsh" if File.exist?("scripts/lib/wt-discovery.zsh")
    (libexec/"lib").install "scripts/lib/wt-recovery.zsh" if File.exist?("scripts/lib/wt-recovery.zsh")
    (libexec/"lib").install "scripts/lib/wt-validation.zsh" if File.exist?("scripts/lib/wt-validation.zsh")
    
    # Create wrapper scripts that source from the Homebrew installation
    (prefix/"zsh-functions").mkpath
    
    %w[wt wtnew wtrm wtopen wtls].each do |cmd|
      (prefix/"zsh-functions/#{cmd}.zsh").write <<~EOS
        # Homebrew-installed git-worktrees
        # Source the actual implementation
        source "#{libexec}/#{cmd}"
      EOS
    end
    
    # Common library needs special handling for sourcing other libs
    (prefix/"zsh-functions/wt-common.zsh").write <<~EOS
      # Homebrew-installed git-worktrees
      # Set library path for other modules
      export WT_LIB_PATH="#{libexec}/lib"
      # Source the actual implementation
      source "#{libexec}/lib/wt-common.zsh"
    EOS
  end

  def caveats
    <<~EOS
      To use git-worktrees, add the following to your ~/.zshrc:

        # Source git-worktrees functions
        for func in #{opt_prefix}/zsh-functions/*.zsh; do
          source "$func"
        done

      Or individually:
        source #{opt_prefix}/zsh-functions/wt-common.zsh
        source #{opt_prefix}/zsh-functions/wt.zsh
        source #{opt_prefix}/zsh-functions/wtnew.zsh
        source #{opt_prefix}/zsh-functions/wtrm.zsh
        source #{opt_prefix}/zsh-functions/wtopen.zsh
        source #{opt_prefix}/zsh-functions/wtls.zsh

      Then restart your shell or run: source ~/.zshrc

      Commands available:
        wt                    # Hub to list, open, create, and manage worktrees
        wtnew                 # Create/open a worktree for a new or existing branch
        wtopen                # Open an existing worktree
        wtrm                  # Safely remove a worktree
        wtls                  # List worktrees with status

      For more information, see: https://github.com/EtienneBBeaulac/git-worktrees
    EOS
  end

  test do
    # Test that scripts exist and are valid zsh
    system "zsh", "-n", libexec/"wt"
    system "zsh", "-n", libexec/"wtnew"
    system "zsh", "-n", libexec/"wtrm"
    system "zsh", "-n", libexec/"wtopen"
    system "zsh", "-n", libexec/"wtls"
    system "zsh", "-n", libexec/"lib/wt-common.zsh"
  end
end

