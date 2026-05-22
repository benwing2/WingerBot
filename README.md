This repository contains scripts used in running WingerBot on Wiktionary.

This file will be updated with information on the specific scripts.

# Installation

This repository uses `uv` as its package manager. `uv` is a fast, modern replacement
for `pip`, written in Rust for speed. To get started:

1. Download and install `uv`. See https://docs.astral.sh/uv/getting-started/installation/
   for instructions. If you're on a Mac, the easiest way is through Homebrew, using
   `brew install uv`.
2. The setup file in `pyproject.toml` specifies that this repository requires version 3.12
   or later of Python. In reality it's likely to run on any version >= 3.7 (when data
   classes were introduced), but it will soon gain 3.12+ type hints. `uv` will automatically
   install the correct version of Python if needed.
3. Run `uv sync` in the top-level directory of the repository to download and install all
   required dependencies (e.g. Pywikibot) in a virtual environment under `.venv`.
4. Set up Pywikibot by creating a file `~/.pywikibot/user-config.py`. See below.

# Running

Use `uv run src/wingerbot/SCRIPT.py [arguments]` from the top level of the repository to run a given
script. Most scripts take arguments, and support a large, standardized collection of arguments to
specify which pages to operate on and whether to save changes (if appropriate). Some of the more
common arguments:

1. `--pages`: Comma-separated list of pages to operate on (with no space after the comma).
2. `--pagefile`: File containing a list of pages to operate on, one file per line.
3. `--cats`: Comma-separated list of categories whose pages should be operated on (with no space
   after the comma).
4. `--category-file`: File containing a list of categories whose pages should be operated on, one
   category per line.
5. `--comment`: Changelog comment to use when saving files. Only required for some scripts; others
   will automatically generate appropriate per-page changelog messages.
6. `--save`: Save changes. Most scripts will not make any changes unless explicitly requested to
   do so.
7. `--diff`: Show a unified diff of the changes that will or would be made to each file.

# Setting up Pywikibot

## For basic bot use

A sample `~/.pywikibot/user-config.py` file is

```
# -*- coding: utf-8  -*-
family = 'wiktionary'
mylang = 'en'
usernames['wiktionary']['en'] = 'MY_BOT_NAME'

put_throttle = 0
maxlag = 0
maxthrottle = 1

user_agent_description = 'MY_BOT_NAME/1.0 (https://MY_DOMAIN.com; MY_EMAIL)'
```

where `MY_BOT_NAME` is the name of your bot (e.g. `WingerBot`), `MY_DOMAIN.com` is the domain
where information on your bot is found (it may be sufficient to point it to the appropriate
page on en.wiktionary.org), and `MY_EMAIL` is an email address at which you can be contacted
concerning bot changes.

The first time you attempt to use your bot to make changes to Wiktionary, you will be prompted
for your password; or alternatively, for more security, use OAuth, or alternatively (and less
securely), create a file `~/.pywikibot/user-password.py` containing an auto-generated bot
password created through the procedure described in
https://www.mediawiki.org/wiki/Manual:Pywikibot/BotPasswords.

## For admin-account use

Note that if you have an admin account, you need to use that account (rather than your bot
account) to do admin-only operations through your bot like deleting files. This requires you to
use OAuth or a Bot password file rather than manually typing in your password. The easiest way
to use WingerBot in this capacity is by creating a separate directory containing your
admin-account settings, e.g. `~/.pywikibot-admin`. Then, invoke WingerBot using the
`PYWIKIBOT_DIR` environment variable, like this (to delete files):

`PYWIKIBOT_DIR=~/.pywikibot-admin uv run python3 delete.py [arguments]`

## For use accessing a local installation of Wiktionary

If you have a local installation of Wiktionary set up (e.g. in a Docker container, using user
Jberkel's Digero repository, found at https://gitlab.com/jberkel/digero/-/tree/main/mediawiki),
you can use WingerBot to access and make changes to the local installation by creating another
directory to hold the local-installation settings and setting `PYWIKIBOT_DIR` similarly to above
for admin-account use. For example, if you copy your `~/.pywikibot` directory to
`~/.pywikibot-local`, you will need to do the following:

1. Register a MediaWiki "family" for your local installation using a command like this in the top
   level of the Pywikibot repository (you may need to clone a local copy of Pywikibot):

   `PYWIKIBOT_DIR=~/.pywikibot-local python3 pwb.py generate_family_file.py http://localhost:8080/Main_Page localenwikt`

   assuming you are able to access your local Wiktionary installation at http://localhost:8080/.
2. Edit `~/.pywikibot-local/user-config.py`, and set the family to `localenwikt` and your user name
   to `Admin`. (Note if you try to save a file, you will be prompted to enter the Admin password.
   The default password of `admin` won't work because the local installation will try to force you
   to change the password, which won't interact well with Pywikibot. So make sure to change your
   Admin password before doing this.)
3. Run a script using `PYWIKIBOT_DIR=~/.pywikibot-local uv run src/wingerbot/SCRIPT.py [arguments]`
   as usual.
