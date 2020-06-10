require "file_utils"
require "spec"
require "../src/git_rewrite_author"

private REPO_NAME = "git_rewrite_author"

def repo_path
  Path[Dir.tempdir, REPO_NAME].to_s
end

def within_repo_path
  Dir.cd(repo_path) { yield }
end

def create_git_repository(*, remove_existing = true)
  if remove_existing && Dir.exists?(repo_path)
    FileUtils.rm_rf(repo_path)
  end
  Dir.mkdir(repo_path)

  within_repo_path do
    run "git init ."
  end
end

def stub_git_repository
  create_git_repository

  within_repo_path do
    File.write("foo.cr", "module Foo; end")
    create_git_commit "Foo comes into the game"

    File.write("bar.cr", "module Bar; end")
    create_git_commit "Foo goes to the Bar"

    File.write("baz.cr", "module Baz; end")
    create_git_commit "Busy Baz Bus"
  end
end

def create_git_commit(message = "New commit")
  within_repo_path do
    run "git add ."
    run "git commit --allow-empty --no-gpg-sign -m '#{message}'"
  end
end

def create_git_tag(name)
  within_repo_path do
    run "git tag --no-sign #{name}"
  end
end

def checkout_git_branch(name, *, create = false)
  within_repo_path do
    run "git checkout #{create ? "-b " : nil}#{name}"
  end
end

private GIT_COMMIT_LOG_FORMAT =
  "%H - %an (%ae) - %cn (%ce)"

private GIT_COMMIT_LOG_PATTERN =
  /(?<hash>.+) - (?<author_name>.+?) \((?<author_email>.+)\) - (?<committer_name>.+?) \((?<committer_email>.+)\)/

def git_commits(rev = "HEAD", *, fields = nil)
  within_repo_path do
    run("git log --format='#{GIT_COMMIT_LOG_FORMAT}' #{rev}")
      .lines
      .compact_map(&.match(GIT_COMMIT_LOG_PATTERN).try(&.named_captures))
      .tap do |commits|
        commits.map!(&.select!(fields)) if fields
      end
  end
end

def git_commits_changes(fields = nil)
  old_commits = git_commits(fields: fields)
  yield
  new_commits = git_commits(fields: fields)

  {old_commits, new_commits}
end

def run(command, *, env = nil)
  output, error = IO::Memory.new, IO::Memory.new

  Process
    .run("/bin/sh", env: env, input: IO::Memory.new(command), output: output, error: error)
    .tap do |status|
      unless status.success?
        raise "Command failed: %s (%s) (%s)" % {command, output, error}
      end
    end

  output.to_s
end
