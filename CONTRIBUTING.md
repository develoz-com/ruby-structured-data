# Contributing

Contributions must keep the public API explicit, framework-neutral, and compatible with the declared v0.1 contract. Do not add runtime dependencies without a concrete API need.

## Setup

This repository uses [asdf](https://asdf-vm.com/) and `.tool-versions`.

```bash
asdf install
ruby --version
bundle install
```

`bin/setup` is a convenience wrapper for `bundle install`.

Run focused tests while working:

```bash
bundle exec rspec spec/path/to/spec.rb
```

Before submitting, run the complete repository gate:

```bash
bin/ci
```

`bin/ci` runs RuboCop, Reek, RSpec, and Bundler Audit. Do not add exclusions to silence warnings in new code. Fix the design or update a rule only when it reflects an established project convention.

Use double-quoted Ruby strings and frozen string literals. Keep changes within the owned surface for the task; the compiler and vocabulary data require their own focused review.

## Documentation

Update `README.md` for concise user-facing navigation. Keep vocabulary data provenance documented next to the `data/` artifacts.

## Release setup

RubyGems trusted publishing requires no long-lived token:

1. Create a GitHub environment named `rubygems` with no secrets.
2. Add a pending trusted publisher for gem `ruby-structured-data` on RubyGems with owner `develoz-com`, repository `ruby-structured-data`, workflow `release.yml`, and environment `rubygems`.
3. Keep the repository's release workflow pinned to the reviewed action SHAs.

## Release process

1. Bump `StructuredData::VERSION` in `lib/structured_data/version.rb` and add user-facing changes under `Unreleased` in `CHANGELOG.md`.
2. Run `bin/ci` and review the package contents with `gem build ruby-structured-data.gemspec`.
3. Merge to `main`.
4. Publish a stable GitHub Release tagged `vX.Y.Z` at the current `main` commit.
5. Let `release.yml` validate the tag, build and inspect the exact gem, publish through RubyGems OIDC, verify API visibility/SHA, and finalize `CHANGELOG.md`.

Prereleases are not supported. If publication succeeds but changelog finalization fails, rerun the same workflow; do not create another tag or publish a second version.