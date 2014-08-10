---
author: sourcegate
comments: true
date: 2010-06-12 01:47:40+00:00
layout: post
slug: download-the-packages-for-an-offline-ubuntu-upgrade
title: Download the packages for an offline Ubuntu upgrade
wordpress_id: 70
---

Well, not really offline since you'll still have to download some files, but not all of the packages.  Use this for computers with limited internet quota.  I'm sure this could be done in a single script with some awk-fu.




  1. Produce a list of your current package selections:

    
    
    dpkg --get-selections | awk '{ print $1 }' > selections
    



  2. Get the package lists:

    
    
    for s in lucid/main lucid/multiverse lucid/restricted lucid/universe \
            lucid-updates/main lucid-updates/multiverse \
            lucid-updates/restricted lucid-updates/universe ; do \
        wget -c "http://archive.ubuntu.com/ubuntu/dists/$s/binary-i386/Packages.bz2" \
            -O Packages_${s/\//_}.bz2 ; \
    done
    


This grabs the package lists in filenames like this:  
    
    Packages_lucid-updates_restricted.bz2



  3. Extract the filenames from these package lists:

    
    
    for f in Packages*.bz2 ; do bzcat $f | awk '
    /^Package/ { package=$2 } 
    /^Filename/ { print package "\t" $2 } 
    ' > ${f%%.bz2}.filenames ; done
    



  4. Produce a list of all filenames, making sure the updates get precedence over the other ones:

    
    
    cat `ls -1 Package*.filenames | sort` | awk '
    { files[$1] = $2 }
    END {
      for (p in files) print p "\t" files[p]
    }' | sort > all.filenames
    



  5. Produce a script of your selections:

    
    
    awk '
    BEGIN { while (getline < "all.filenames" != 0) filenames[$1] = $2 }
    { if ($1 in filenames) print "wget -c http://archive.ubuntu.com/ubuntu/" filenames[$1] }
    '  < selections > downloads
    



  6. Take the file `downloads` to another computer, and run it:

    
    
    sh downloads
    



  7. Take the downloaded files back to the offline computer, copy the files to `/var/cache/apt/archives`, then `do-release-upgrade`.


You could probably save more quota by renaming the Package files and copying them to `/var/lib/apt/lists`.
