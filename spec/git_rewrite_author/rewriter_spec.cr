require "../spec_helper"

def run_rewriter(**options)
  options = {
    cwd: repo_path,

    committer: false,
    branches:  false,
    tags:      false,

    new_name:  "Foo Bar",
    new_email: "foo@bar.org",
  }.merge(options)

  GitRewriteAuthor::Rewriter.run(**options)
end

def run_rewriter_with_changes(fields = nil, **options)
  git_commits_changes(fields) do
    run_rewriter(**options)
  end
end

describe GitRewriteAuthor::Rewriter do
  describe ".run" do
    before_each do
      stub_git_repository
    end

    it "doesn't updates not matching refs" do
      run_rewriter(old_name: "whodunnit", old_email: "does@not.exist")
        .should be_nil
    end

    it "returns nil when no ref was updated" do
      run_rewriter
      run_rewriter.should be_nil
    end

    it "returns updated refs" do
      run_rewriter
        .should eq %w[heads/master]
    end

    context "(branches: false)" do
      it "doesn't rewrite branches" do
        checkout_git_branch "feature/foo", create: true
        checkout_git_branch "master"

        run_rewriter(branches: false)
          .should eq %w[heads/master]
      end
    end

    context "(branches: true)" do
      it "returns updated refs" do
        checkout_git_branch "feature/foo", create: true
        checkout_git_branch "master"

        run_rewriter(branches: true)
          .should eq %w[heads/feature/foo heads/master]
      end
    end

    context "(tags: false)" do
      it "doesn't rewrite tags" do
        create_git_tag "foo"

        run_rewriter(tags: false)
          .should eq %w[heads/master]
      end
    end

    context "(tags: true)" do
      it "returns updated refs" do
        create_git_tag "foo"

        run_rewriter(tags: true)
          .should eq %w[tags/foo]
      end
    end

    context "(branches: true, tags: true)" do
      it "returns updated refs" do
        checkout_git_branch "feature/foo", create: true
        checkout_git_branch "master"

        create_git_tag "foo"

        run_rewriter(branches: true, tags: true)
          .should eq %w[heads/feature/foo heads/master tags/foo]
      end
    end

    context "(committer: false)" do
      it "doesn't rewrite committer" do
        old_commits, new_commits = run_rewriter_with_changes(
          %w[committer_name committer_email],
          committer: false
        )
        new_commits.should eq(old_commits)
        new_commits.should_not contain({
          "committer_name"  => "Foo Bar",
          "committer_email" => "foo@bar.org",
        })
      end
    end

    context "(committer: true)" do
      it "does rewrite committer" do
        old_commits, new_commits = run_rewriter_with_changes(
          %w[committer_name committer_email],
          committer: true
        )
        new_commits.should_not eq(old_commits)
        new_commits.should contain({
          "committer_name"  => "Foo Bar",
          "committer_email" => "foo@bar.org",
        })
      end
    end

    it "always rewrites author" do
      old_commits, new_commits = run_rewriter_with_changes(
        %w[author_name author_email]
      )
      new_commits.should_not eq(old_commits)
      new_commits.should contain({
        "author_name"  => "Foo Bar",
        "author_email" => "foo@bar.org",
      })
    end
  end
end
