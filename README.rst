Digital Devices DVB support for Synology NAS
==================================
This package adds DD DVB support for Synology NAS drives. It provides the
dddvb kernel drivers and a script to auto-load those drivers on boot.


Disclaimer
----------
You use everything here at your own risk. I am not responsible if this breaks
your NAS. Realistically it should not result in data loss, but it could render
your NAS unaccessible if something goes wrong.

If you are not comfortable with removing your drives from the NAS and manually
recover the data, this might not be for you.


Installation
------------
1. Compile the package using the instructions below.

2. In the Package Center, press the *Manual install* button and provide the SPK file. Follow the instructions until done.


Compiling
---------
I've used docker to compile everything, as ``pkgscripts-ng`` clutters the file
system quite a bit. First create a docker image by running the following
command in this repository:

.. code-block:: bash

    git clone https://github.com/savek-cc/synology-dddvb.git
    cd synology-dddvb/
    sudo docker build -t synobuild .

Now we can build for any platform and DSM version using:

.. code-block:: bash

    sudo docker run --rm --privileged --env PACKAGE_ARCH=<arch> --env DSM_VER=<dsm-ver> -v $(pwd)/artifacts:/result_spk synobuild

You should replace ``<arch>`` with your NAS's package arch. Using
`this table <https://www.synology.com/en-global/knowledgebase/DSM/tutorial/General/What_kind_of_CPU_does_my_NAS_have>`_
you can figure out which one to use. Note that the package arch must be
lowercase. ``<dsm-ver>`` should be replaced with the version of DSM you are
compiling for.

For the DS3622xs+ that I have, the complete command looks like this:

.. code-block:: bash

    sudo docker run --rm -it --privileged --env PACKAGE_ARCH=broadwellnk --env DSM_VER=7.2 -v $(pwd)/artifacts:/result_spk synobuild

If everything worked you should have a directory called ``artifacts`` that
contains your SPK files.


Avoiding timeouts when downloading build files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
It can take a long time to pull development files from SourceForge, including
occasional timeouts. To get around this, create a folder locally and map it to
the `/toolkit_tarballs` Docker volume using the following command:
`-v $(pwd)/<path/to/folder>:/toolkit_tarballs`
to the `docker run` command listed above. This will allow the development files
to be stored on your host machine instead of ephemerally in the container. The
image will check for existing development files in that folder and will use
them instead of pulling them from SourceForge when possible. You can also
download the files directly and put them in the folder you created by downloading
them from here: https://sourceforge.net/projects/dsgpl/files/toolkit/DSM<DSM_VER>
(e.g. https://sourceforge.net/projects/dsgpl/files/toolkit/DSM7.2)


Credits
-------
I based almost all this work on the `synology-wireguard package <https://github.com/runfalk/synology-wireguard/>`_

