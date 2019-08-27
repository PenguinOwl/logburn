# logburn

logburn is a fast log analysis tool for parsing logs realtime.

## Installation

If you don't have it, install Crystal:
```
curl -sSL https://dist.crystal-lang.org/apt/setup.sh | sudo bash
sudo apt install crystal
```

For other distributions and other operating systems, refer to [crystal-lang](https://crystal-lang.org/reference/installation/).

Then clone the repo and install:
```
git clone https://github.com/PenguinOwl/logburn
cd logburn
shards build
sudo ln -s $(pwd)/bin/logburn /usr/bin/
```

## Usage

To add new profiles and errors, edit the configuration file and rebuild using `shards build`.

## Contributing

1. Fork it (<https://github.com/PenguinOwl/logburn/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [PenguinOwl](https://github.com/your-github-user) - creator and maintainer
