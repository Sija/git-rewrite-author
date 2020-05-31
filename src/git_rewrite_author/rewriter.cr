class GitRewriteAuthor::Rewriter
  getter cwd : String?

  getter? committer : Bool
  getter? branches : Bool
  getter? tags : Bool

  {% for field in %w[name email].map(&.id) %}
    getter old_{{ field }} : String?
    getter new_{{ field }} : String?
  {% end %}

  def self.run(**options) : Array(String)?
    new(**options).run
  end

  {% begin %}
    def initialize(
      @cwd = nil,

      @committer = false,
      @branches = false,
      @tags = false,

      {% for field in %w[name email].map(&.id) %}
        @old_{{ field }} = nil,
        @new_{{ field }} = nil,
      {% end %}
    )
    end
  {% end %}

  protected def prepare_env_filter(io, env, field, old_value, new_value)
    return unless new_value

    env["AUTHOR_#{field}"] = new_value

    if old_value
      env["OLD_AUTHOR_#{field}"] = old_value

      if committer?
        io.puts <<-EOF
          if [ "$GIT_COMMITTER_#{field}" = "$OLD_AUTHOR_#{field}" ]; then
              export GIT_COMMITTER_#{field}="$AUTHOR_#{field}"
          fi
          EOF
      end
      io.puts <<-EOF
        if [ "$GIT_AUTHOR_#{field}" = "$OLD_AUTHOR_#{field}" ]; then
            export GIT_AUTHOR_#{field}="$AUTHOR_#{field}"
        fi
        EOF
    else
      if committer?
        io.puts <<-EOF
          export GIT_COMMITTER_#{field}="$AUTHOR_#{field}"
          EOF
      end
      io.puts <<-EOF
        export GIT_AUTHOR_#{field}="$AUTHOR_#{field}"
        EOF
    end
  end

  protected def prepare_env_filter
    env = {} of String => String
    env_filter = String.build do |io|
      {% for field in %w[name email] %}
        prepare_env_filter(io, env,
          {{ field.upcase }},
          old_{{ field.id }}.presence,
          new_{{ field.id }}.presence,
        )
      {% end %}
    end
    {env, env_filter}
  end

  protected def prepare_command
    cmd = Process.find_executable("git")
    raise "Cannot find git" unless cmd

    env, env_filter = prepare_env_filter

    args = [
      "filter-branch",
      "--force",
      "--env-filter",
      env_filter,
      "--tag-name-filter",
      "cat",
      "--",
    ]
    args << "--branches" if branches?
    args << "--tags" if tags?

    {cmd, args, env}
  end

  protected def run! : String
    cmd, args, env = prepare_command

    out_io = IO::Memory.new
    err_io = IO::Memory.new

    Process
      .run(cmd, args, shell: true, env: env, chdir: cwd, output: out_io, error: err_io)
      .tap do |status|
        raise err_io.to_s.chomp unless status.success?
      end

    out_io.to_s
  end

  protected def extract_refs(output) : Array(String)
    output
      .scan(/Ref 'refs\/(?<id>.+?)' was rewritten/)
      .map(&.["id"])
  end

  def run : Array(String)?
    refs = extract_refs(run!)
    refs unless refs.empty?
  end
end
