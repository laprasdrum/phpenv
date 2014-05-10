# remake phpenv with rbenv

```
git clone https://github.com/laprasdrum/phpenv.git ~/.phpenv
```

write the berow to .bashrc/.zshrc as phpenv installation

```shell
# rbenv PATH must be the former of phpenv PATH
export PATH="$HOME/.phpenv/bin:$PATH"
eval "$(phpenv init -)"
```
