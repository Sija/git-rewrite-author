require "colorize"
require "admiral"

require "./git_rewrite_author"

class GitRewriteAuthor::CLI < Admiral::Command
  define_version VERSION

  define_help \
    description: "Rewrites git commit history with new authorship data."

  define_argument cwd : String,
    description: "Directory with git repository."

  define_flag committer : Bool,
    description: "Rewrites committer authorship data.",
    default: true

  define_flag branches : Bool,
    description: "Rewrites commits in all branches.",
    default: false,
    short: b

  define_flag tags : Bool,
    description: "Rewrites commits in all tags.",
    default: false,
    short: t

  define_flag color : Bool,
    description: "Enables colors.",
    default: true

  define_flag old_name : String,
    description: "Old author name."

  define_flag new_name : String,
    description: "New author name."

  define_flag old_email : String,
    description: "Old author email."

  define_flag new_email : String,
    description: "New author email."

  protected def fail(message : String? = nil)
    if message && !message.blank?
      STDERR << "Failed: ".colorize(:red)
      STDERR << message.chomp.colorize.bright
      STDERR << '\n'
    end
    exit 1
  end

  private def prepare_env_filter(env)
    String.build do |io|
      {% for field in %i(name email).map(&.id) %}
        if new_author_{{field}} = flags.new_{{field}}
          env["AUTHOR_{{field.upcase}}"] = new_author_{{field}}

          if old_author_{{field}} = flags.old_{{field}}
            env["OLD_AUTHOR_{{field.upcase}}"] = old_author_{{field}}

            if flags.committer
              io.puts <<-EOF
                if [ "$GIT_COMMITTER_{{field.upcase}}" = "$OLD_AUTHOR_{{field.upcase}}" ]; then
                    export GIT_COMMITTER_{{field.upcase}}="$AUTHOR_{{field.upcase}}"
                fi
              EOF
            end
            io.puts <<-EOF
              if [ "$GIT_AUTHOR_{{field.upcase}}" = "$OLD_AUTHOR_{{field.upcase}}" ]; then
                  export GIT_AUTHOR_{{field.upcase}}="$AUTHOR_{{field.upcase}}"
              fi
            EOF
          else
            if flags.committer
              io.puts <<-EOF
                export GIT_COMMITTER_{{field.upcase}}="$AUTHOR_{{field.upcase}}"
              EOF
            end
            io.puts <<-EOF
              export GIT_AUTHOR_{{field.upcase}}="$AUTHOR_{{field.upcase}}"
            EOF
          end
        end
      {% end %}
    end
  end

  private def prepare_command
    env = {} of String => String
    cmd = "git"
    args = [
      "filter-branch",
      "--force",
      "--env-filter",
      prepare_env_filter(env),
      "--tag-name-filter",
      "cat",
      "--",
    ]
    args << "--branches" if flags.branches
    args << "--tags" if flags.tags

    {env, cmd, args}
  end

  def run
    Colorize.on_tty_only!
    Colorize.enabled = false unless flags.color

    unless flags.new_name || flags.new_email
      fail "You must provide " \
           "#{"--new-name".colorize(:green)}" \
           " or " \
           "#{"--new-email".colorize(:green)}"
    end

    env, cmd, args = prepare_command

    begin
      out_io = IO::Memory.new
      err_io = IO::Memory.new

      Process
        .run(cmd, args, shell: true, env: env, chdir: arguments.cwd, output: out_io, error: err_io)
        .tap do |status|
          fail(err_io.to_s) unless status.success?
        end

      refs = out_io.to_s
        .scan(/Ref 'refs\/(.+?)' was rewritten/)
        .map(&.[1])

      if refs.empty?
        STDOUT.puts "No changes".colorize.bright
      else
        STDOUT << "Rewritten refs: ".colorize(:green)
        STDOUT << refs.join(", ", &.colorize.bright)
        STDOUT << '\n'
      end
    rescue ex : Errno
      fail(ex.message)
    end
  end
end

GitRewriteAuthor::CLI.run
