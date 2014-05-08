PoolFS
======

Fork of https://github.com/mungler/PoolFS

PoolFS is a file system extension for OSXFUSE http://osxfuse.github.io
Similar solutions exists e.g. UnionFS, AuFS, mhddfs or "mount -o union", but none have the capability of easily presenting a merged folder structure from any folders on any drive and still function as any other folder.

This fork might wander off in another direction than the original idea.
The main focus of this fork will be on virtually merging folder structures from several locations and drives, and use it without more effort than it would be on a regular folder. Recurrency is not supported at the moment.

* Location for new files are guessed where to be put based on latest queries. Maybe we could add a UI asking for which location to put new files?
* Moving or renaming a file or folder will be done in the same node.
* Copying a file or folder are guessed as in creating files.
* Files that are found on several locations are marked with a "Duplicate" tag in Finder. (Only Mavericks)




