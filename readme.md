Much more detail available here: http://iwasdeportedandalligotwasthislousydomain.co.uk/static.php?page=smallpt_tp

#About

This is a Turbo Pascal 3 compatible port of the C++ smallpt renderer.
Source and binaries are available along with a ready-to-use archive of Bochs to run a Mode-13 version.

A month ago I saw an article entitled "Things that Turbo Pascal 3 is smaller than" and stumbled upon the smallpt renderer in the same week. Perhaps the fact that both had "small" in the title made my brain decide it was a good match... who knows?

There's little I enjoy more than going on a random coding spirit-quest in my spare time, because it's my time, I don't need to adhere to "best practices" or think about how best it would be to do something, or how neat my code is, I can type at the keyboard like a crazed chimp free of the shackles of expectations!

So I hurriedly and blindly went about converting the smallpt renderer C++ code to Pascal, with an idea of keeping it as backwardly-compatible as possible.

#Versions

* Turbo Pascal 3 version that simply writes the output to a file like the original does
* Turbo Pascal 4 version that renders the results in mode 13 as it goes
* Multi-threaded tiled Lazarus version (this is the fastest version and only one I recommend running)
* RemObjects PascalScript version with a pseudo IDE-kinda thing to run it in

#Note

I use "sample count" to be the actual sample count in these ports, so if you want 25000spp, you need to enter 6250 as a value (spp / 4)
