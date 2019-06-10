module GitRewriteAuthor
  {% begin %}
    VERSION = "{{ `shards version`.chomp }}"
  {% end %}
end
