---
layout: post
title: Build a Jekyll blog with Travis CI without granting write access
slug: jekyll-blog-travis-ci
---

With the demise of Openshift Online and its free tier, I was looking for somewhere else to host my blog.  Even though it's a [Jekyll] blog, it does some image resizing, so I can't use Github's native builder.  I should be able to use [Travis CI] though, then push them to another Github repository for [Pages][github-pages] hosting.

The [Travis instructions for Github Pages][travis-gh-pages] instructions suggest you use Github personal access tokens for authentication, but that seems to give write access to all of my Github repositories - which I don't want to do.

You will need the [command line client] installed and logged in.

1. Generate a key pair for Travis to use when pushing

        ssh-keygen -t rsa -b 4096 -f travis-key

    Don't commit the generated files!

1. Create a repository on Github for the generated site to be pushed to.  In that repository, go to Settings, Deploy keys, then Add deploy key.  Copy in `travis-key.pub` which you generated in the previous step, check "Enable write access", then add the key.

1. The private key should be [encrypted][travis-encrypt].  From the blog repository:

        travis encrypt-file -r 33d/blog travis-key

    where `travis-key` is one of the files created earlier by `ssh-keygen`.

    This command will suggest you add a line to your `before_install` section - do that.

1. Put at the end of `.travis.yml`'s `before_install`, to stop `ssh-add` complaining about the key's permissions:

        - chmod 400 ../travis-key

1. Add this to `.travis.yml`, to perform the Git push:

    ```
    after_success:
     - eval "$(ssh-agent -s)"
     - ssh-add ../travis-key
     - git clone git@github.com:33d/blog-pages.git target
     - cp -pr _site/* target
     - git -C target checkout -b gh-pages
     - git -C target add .
     - git -C target commit -m "$( date --utc --iso-8601=seconds )"
     - git -C target push --force origin gh-pages
    ```

    I use a different repository for this, because I don't want the build artifacts clogging the blog repository.

You can see [my completed `.travis.yml` file](https://github.com/33d/blog/blob/blog/.travis.yml).

[travis-gh-pages]: https://docs.travis-ci.com/user/deployment/pages/
[command line client]: https://github.com/travis-ci/travis.rb
[travis-encrypt]: https://docs.travis-ci.com/user/encrypting-files/
[Jekyll]: https://jekyllrb.com/
[Travis CI]: https://travis-ci.org/
[github-pages]: https://help.github.com/categories/github-pages-basics/

