# ActiveFedora::Datastreams

Datastreams support for ActiveFedora 11. This functionality previously was a part of ActiveFedora, but has been moved here as it is not required functionality.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_fedora-datastreams'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_fedora-datastreams

## Usage

To create a XML datastream extend `ActiveFedora::OmDatastream`. To create an RDF::Datastream, extend `ActiveFedora::NtriplesRDFDatastream`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

If you're working on a PR for this project, create a feature branch off of `main`.

This repository follows the [Samvera Community Code of Conduct](https://samvera.atlassian.net/wiki/spaces/samvera/pages/405212316/Code+of+Conduct) and [language recommendations](https://github.com/samvera/maintenance/blob/main/templates/CONTRIBUTING.md#language).  Please ***do not*** create a branch called `master` for this repository or as part of your pull request; the branch will either need to be removed or renamed before it can be considered for inclusion in the code base and history of this repository.

Bug reports and pull requests are welcome on GitHub at https://github.com/samvera-labs/active_fedora-datastreams. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
