# git-rewrite-author [![CI](https://github.com/Sija/git-rewrite-author/actions/workflows/ci.yml/badge.svg)](https://github.com/Sija/git-rewrite-author/actions/workflows/ci.yml) [![Releases](https://img.shields.io/github/release/Sija/git-rewrite-author.svg)](https://github.com/Sija/git-rewrite-author/releases) [![License](https://img.shields.io/github/license/Sija/git-rewrite-author.svg)](https://github.com/Sija/git-rewrite-author/blob/master/LICENSE)

Rewrite authorship information within a history of a git repository.

## Editing Past Commits Rewrites History!

> No matter how exactly we change the information of past commits, there's one thing to always keep in mind: if we do this, we are effectively rewriting commit history.
> This is nothing to take lightly: you will create new commit objects in this process, which can become a serious problem for your collaborators - because they might have already based new work on some of the original commits.
> Therefore, think twice before you rewrite your commit history!

Further reading:

- https://help.github.com/en/github/using-git/changing-author-info
- https://www.git-tower.com/learn/git/faq/change-author-name-email

## Installation

```console
$ make build
```

In order to use it system-wide you need to copy the resulting binary into
your preferred `bin` location (`/usr/local/bin` by default).

```console
$ make install [prefix=/usr/local/bin]
```

## Usage

```console
$ git rewrite-author [--committer] [--branches] [--tags] [--old-email ...] [--new-email ...] [--old-name ...] [--new-name ...] [cwd]
```

## Contributing

1. Fork it (<https://github.com/Sija/git-rewrite-author/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Sijawusz Pur Rahnama](https://github.com/Sija) - creator and maintainer
