They should be installed in the .bashtools folder with these commands:
```
git clone https://gist.github.com/d1bde0625c185fdfceb16a6602e9fb3e.git ~/.bashtools # This clones the gist where it belongs.
bash ~/.bashtools/install_tools.sh # This installs it into ~/.bash_profile.
```

# Appendix
And you can ignore these (delete later):

These are bash tools for Sean. Thay can be installed to the ~/.bashtools folder with this:
```
curl -s "https://gist.githubusercontent.com/skbergam/d1bde0625c185fdfceb16a6602e9fb3e/raw/install_tools.sh?x=$(date +%s)" | bash
```

NOTE: You can also download a JSON blob with the full gist contents with this:
```
curl https://api.github.com/gists/d1bde0625c185fdfceb16a6602e9fb3e
```
