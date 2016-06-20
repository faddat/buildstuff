# buildstuff
Good lord when I think of the man hours that went into klouds.  Obscene..... and now, worth it.  This is a build script for a server image that runs consul, nomad, weave and scope.  It is designed to form the "core" of a microservices platform.  Do not deploy fewer than three of these core nodes, and make sure that you replace my Atlas key with your own, and the IP address of the "bounce server" with your own as well.  All told, you will need to run four instances on GCE to make this shit fly.  

This builds a pretty good architecture on GCE or Virtualbox.

* Consul
* Nomad
* Ubuntu Linux
* Weave
* Weave Scope (visualizer)


###Build Instructions:
0. Clone this repository
1. Install Packer.io
2. Grab a service account key from GCE at this URL:  https://console.cloud.google.com/iam-admin/iam/
3. Rename th eaccount key account.json and put it in your ~/Desktop folder
4. For a GCE-only build, run:  packer build -except virtualbox-ovf consul.json from the buildstuff folder.
5. To build GCE and Virtualbox images (they will both ultimately connect:  This is a great architecture if you are in the awkward position of doing multi-cloud or hybrid-cloud deployments.)
  * packer build consul.json 

###Notes
So far, I have scaled this (all "server/manager" nodes, no worker nodes) to forty virtual machine instances on GCE without incident.  Scope gets a little slow, but hey, that's why we have UE4, right @weave.works? ;)



