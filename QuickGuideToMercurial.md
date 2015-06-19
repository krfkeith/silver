# Setting up mercurial #

Edit ~/.hgrc (create it if it's not there) to include:

```
[ui]
username = My Name <myemail@mydomain.tld>

[auth]
googlecode.prefix=https://code.google.com
googlecode.username=google_username_here
googlecode.password=random_google_code_password_here
```

This should stop mercurial from ever needing to ask you for your google code password. Note that's it's your **google code password**, not your google account password. You find this password by clicking **Profile** at the top of this page, while logged in, and then clicking **Settings** on your profile page.

Make sure the file is not world-readable, while you're at it:

```
chmod 600 ~/.hgrc
```

Contrary to the `Project Home` page, the command to clone the repository is as follows:

```
hg clone https://code.google.com/p/silver/
```

Make sure when you clone repositories that you **don't include `myusername@` in the url**, otherwise mercurial seems to have problems, and will prompt you for your password. If you mistakenly did this (because google suggests it in the urls it gives you) you can fix it by editing the `.hg/hgrc` file (in the repo, not your home directory.)

## UMN CS users ##

I was going to ask systems to get mercurial installed locally on our lab machines, but it appears we're using an LTS release of Ubuntu that only has Mercurial 1.4.  I didn't go look at the feature differences (It's quite possible it's good enough, if someone wants to go find out...) but I'm guessing there might be a reason to want a newer release.

A newer version of mercurial (1.8.1) is in the module system. Just run

```
module load soft/mercurial
```

To fetch it.  Go ahead and add it to the list in your shell startup scripts.

It includes its own whole python runtime, so start up across NFS is very slow, but once the NFS cache is warmed up, it's not bad.

```
$ time hg version
...
real	0m23.594s
user	0m0.030s
$ time hg version
...
real	0m0.179s
user	0m0.040s
```

If this startup time begins to bother people, we can explore some options:

  * Systems may support a newer version of ubuntu than the last LTS (10.04), we could ask for upgrades.
  * The old version of mercurial (1.4.3) may actually be just fine for what we need!
  * We could install things to scratch space

# Using mercurial for SVN users #

It's quite simple really: mercurial is SVN, but having separated out _local repository_ actions from _inter-repository_ actions.  DO go read a mercurial tutorial elsewhere, but assuming you understand the basics from some other tutorial, here's a cheat sheet to remind you:

| SVN command | Hg LOCAL command | Hg REMOTE command |
|:------------|:-----------------|:------------------|
| svn status  | hg status        | hg out            |
| svn up      | hg up            | hg pull           |
| svn commit  | hg commit        | hg push           |

Separating these out gives some nice advantages: `hg pull` should be always safe to do, as it doesn't change the contents of your working copy (until you `hg up`.)  Similarly, `hg commit` can be done many times, locally, without a network connection (until you want to push to everyone else.)

Merging of changes happens between repositories _after_ your changes have been committed locally, so it's a lot harder to screw up and lose everything. The general workflow for merging looks like this:

> _Make totally cool edits_ <br />
> `hg commit -m "Totally cool edits"` <br />
> `hg pull` <br />
> `hg merge` <br />
> _Fix merge conflicts, if any_ <br />
> `hg commit -m "Merge totally cool edits with tip"` <br />
> `hg push`

Note that the commit after the merge always happens, even if there weren't conflicts.

## Tutorials / reference ##

[A quirky tutorial for people totally new to Hg](http://hginit.com/).

[The mercurial book, just like the svn book](http://hgbook.red-bean.com/).

## What if I forget to merge (/ commit after a merge) and I push? ##

First, you made the repository look like a Y shape. It splits into two heads.

To fix this: just 'hg merge' and then 'hg push'. That'll join the Y into a diamond, so there's just one head again.

But, if you did merge, but forgot to commit the merge, then your local repository might be stuck in a weird state. As long as you haven't started making any further changes... who cares? commit the merge and continue. Worst case scenario is you have to merge the two merges, which is probably just a no-op changeset that does nothing but list the two parents it's joining together.

BUT, if you merged, forgot to commit the merge, then started making more changes, now you're in trouble.  The best solution so far I know is:

```
hg diff > patch.diff    (save my changes)
hg up -C tip    (wipe everything out and go to the new tip)
gedit patch.diff    (edit out any spurious changes so the diff only contains the edits you were working on)
patch -p1 --dry-run < patch.diff    (make sure no conflicts)
patch -p1 < patch.diff
hg commit
```