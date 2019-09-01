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

The configuration file needs to be formatted like this:
```
# The name of the profile
my_profile:
  # The name of the first item to match
  my_first_error:
    # A regular expression to match from the log
    regex: /ERROR-(\d+)/
    # Color to display in log, avaible colors are: red, green, yellow, blue, magenta, cyan
    color: red
    # The severity of the match, avaible severities are: moniter, low, medium, high (moniter is not shown in the reports)
    severity: low
    # If your error uses a error code, this is the matching group of an identifying id in the regex, use 0 for the whole match
    id: 1
    # Only include if you want your error to be hidded from display (it will still be logged)
    # hide: true
  my_second_error:
    regex: /Info/
    color: blue
    severity: moniter
    hide: true
```
```
Usage: logburn [profile] [arguments]
    -q, --logging                    Disable logging
    -c, --no-color                   Displays output without color
    -l, --inline                     Toggle inline display
    -o, --log-errors                 Toggle logging of unmatched lines
    -d, --perserve-order             Perserve order of logged lines
    -a, --all-matches                Display moniter events in reports
    -t, --no-timeout                 Disables hang protection
    -p, --periodic                   Enable periodic reports
    -r, --no-report                  Disable reporting
    -l, --no-log-report              Disable reporting for logs
    -i NAME, --input-file=NAME       Specifies an input file to read from
    -d MIN, --report-delay=5         Set periodic report delay in minutes
    -f FILE, --log-file=FILE         Set file for logging
    -h, --help                       Show this help
    -v, --open-log                   Open the previous log in $EDITOR
```


    
## Contributing

1. Fork it (<https://github.com/PenguinOwl/logburn/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [PenguinOwl](https://github.com/your-github-user) - creator and maintainer
