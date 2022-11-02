# SYNOPSIS
You can run this script with below command on Shell.

```
$ ./cyberfusion.sh -f UNIQUE_IDENTIFIER_01
$ ./fileWatcher.sh [options]

$ ./fileWatcher.sh -h
USAGE:  fileWatcher.sh [OPTIONS] -f <FILENAME>

  OPTIONS:
          -f File Name
          -v Display Version Information
          -h Display Help for this program
```

## Configuration File Format:
File Trasnfer Rule Configuration has Seven Columns in the file.

It is a pipe("|") Separated file.

Sample File is below:
```
$ cat TRANSFER_RULES.cfg
#Source|SOURCE_FILENAME|SOURCE_PATH|TARGET_PATH|TARGET_FILENAME|TARGET_HOST|TARGET_USER|STATUS
UNIQUE_IDENTIFIER_01|ABC|/tmp|/some-absolute-path/|XYZ|localhost|kamal|live
UNIQUE_IDENTIFIER_02|abc|/tmp|/some-absolute-path/|XYZ|localhost|kamal|not-live
```


# Bugs:
Feel free to rreport any issue.

# Known Issues:
No Issues observed

# Author
Kamal Mehta - Having extensive experience in writing automation tools in Bash, Perl and Python.

You can contact me on kamal.h.mehta@smiansh.com

Check out my profile: http://www.smiansh.com