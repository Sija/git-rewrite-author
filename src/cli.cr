require "colorize"
require "climate"
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

  {% for field in %w[name email].map(&.id) %}
    define_flag old_{{ field }} : String,
      description: "Old author {{ field }}."

    define_flag new_{{ field }} : String,
      description: "New author {{ field }}."
  {% end %}

  protected def fail(message : String? = nil)
    if message = message.presence
      message = "!Error¡: #{message}"
    end
    abort(message.try(&.climatize))
  end

  def run
    Climate.settings.use_defaults!

    Colorize.on_tty_only!
    Colorize.enabled = false unless flags.color

    unless flags.new_name || flags.new_email
      fail "You must provide <new-name> or <new-email> flag"
    end

    refs = {% begin %}
      Rewriter.run(
        cwd: arguments.cwd,

        committer: flags.committer,
        branches: flags.branches,
        tags: flags.tags,

        {% for field in %w[name email].map(&.id) %}
          old_{{ field }}: flags.old_{{ field }},
          new_{{ field }}: flags.new_{{ field }},
        {% end %}
      )
    {% end %}

    if refs
      STDOUT << "Rewritten refs: ".colorize(:green)
      STDOUT << refs.join(", ", &.colorize.bright)
      STDOUT << '\n'
    else
      STDOUT.puts "No changes".colorize.bright
    end
  rescue ex
    fail(ex.message)
  end
end

GitRewriteAuthor::CLI.run
