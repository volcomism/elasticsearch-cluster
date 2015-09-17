repo for elasticsearch docker builds
* install_plugins.sh is an example of how you could install easily new plugins to your elasticsearch if you need it.
* image_properties are used to tell jenkins some variables, also you could provide information for running the container while the build job, for testing.
* Dockerfile includes everything you need to create the code and put it in an image, in this case its used to create an elasticsearch image
* docker-compose is a file wich stores all information to run the containerimage on a host
