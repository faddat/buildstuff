# buildstuff
###Good lord when I think of the man hours that went into klouds.  Obscene..... and now, worth it.  

This is a packer build script for Manager and Worker nodes using:

* Consul
* Nomad
* Atlas (which I'd like to remove at some point)
* Ubuntu Linux
* Weave
* Weave Scope (visualizer)

This builds a pretty good architecture on GCE.  Will add QEMU, Virtualbox and ARM when possible for me to do so.  The limiting factor is of course time, and possibly money, so if you want to contribute either, please do so.  

###Some Notes

####

###Build Instructions:
0. Clone this repository
1. Install Packer.io
2. Grab a service account key from GCE at this URL:  https://console.cloud.google.com/iam-admin/iam/
3. Rename the eaccount key account.json and put it in your ~/Desktop folder
4. For a GCE-only build: packer build consul.json

###Notes
So far, I have scaled this (all "server/manager" nodes, no worker nodes) to forty virtual machine instances on GCE without incident.  Scope gets a little slow, but hey, that's why we have UE4, right @weave.works? ;)

I'm trying to eliminate my dependency on a "pointer" node with a fixed ipv4 address.  I haven't got there yet, but will continue to hammmer at it.  
