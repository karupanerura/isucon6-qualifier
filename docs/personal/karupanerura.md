# karupanerura用の自分のユーザー用

```bash
sudo -H apt-get install -y zsh emacs24-nox
git clone git://github.com/karupanerura/dotfiles.git
cd dotfiles
perl setup.pl build install clean
sudo -H chsh -s /usr/bin/zsh `whoami`
echo 'exec zsh -l' > ~/.bashrc
```
