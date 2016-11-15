Athena for macOS/OS X
=====================
Cheetah? Puma? Jaguar? Panther? Tiger? Leopard? Snow Leopard (seriously)? Lion?
Mountain Lion (oh c'mon)?

Away with them all! With this Macathena, we'll finally bring support to the
current/latest macOS/Xes. Finally!

Install Homebrew (a useful package manager for macOS/OS X) and tap some taps:
```sh
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew tap caskroom/cask
brew tap homebrew/dupes
brew tap macathena/moira
```

Installation:
```sh
brew install krb5
brew link krb5 --force
brew cask install auristor-client # AFS
brew install hesiod
brew install moira
```
