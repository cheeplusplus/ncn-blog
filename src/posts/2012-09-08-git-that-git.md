---
title: Git that Git
tags: meta,git
date: September 8, 2012
---
In addendum to the previous post, I was reminded that I wanted to write a quick bit on using Git. I mostly wanted to mention, that instead of dropping the source for FMDB into my project, I included it as a [submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) so the code is pulled in from the Github repository when you clone the project. This can help with licensing and stuff when I get around to that part. I’ll talk about licensing later, though I do note I have plans to make the source available for the Android, iOS and web versions of MyConbook.

For Git in general, I find it rather awesome. I used to use SVN a lot, and was confused why you would want a distributed source control system. There are plenty of blog posts that will explain Git better than me, but I find it much more valuable, particularly just pointing out the fact that your local repository doesn’t affect any of the others - so you can go ahead and break yours, create branches, merge like crazy, and only send back what you mean to send back.

Both Eclipse and XCode have a good integration for using Git, and no matter what source control you’re using, having it is better than nothing. I’m a little weird and don’t like to commit a project until I have something that “works”, even if it compiles. Otherwise I feel that I’m just going to be committing a lot of changes as I work out how I want to structure an application, and I could have saved time and trouble by waiting. I can miss out on some things like wanting to see how I did something in the past, but the turnover is so short at this early stage in a project that it’s not really worth it. That’s just me, though.
