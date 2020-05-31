require "./git_rewrite_author/*"

module GitRewriteAuthor
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}
end
