Usage of creating influxdb-cxx RPM packages
=====================================

This directory contains the source code to create the influxdb-cxx rpm packages.

Environment for creating rpm of influxdb-cxx
=====================================
The description below is used in the specific Linux distribution RockyLinux8.
1. Docker
	- Install Docker
		```sh
		sudo yum install -y yum-utils
		sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
		sudo yum install -y docker-ce docker-ce-cli containerd.io
		sudo systemctl enable docker
		sudo systemctl start docker
		```
	- Enable the currently logged in user to use docker commands
		```sh
		sudo gpasswd -a $(whoami) docker
		sudo chgrp docker /var/run/docker.sock
		sudo systemctl restart docker
		```
	- Proxy settings (If your network must go through a proxy)
		```sh
		sudo mkdir -p /etc/systemd/system/docker.service.d
		sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
		[Service]
		Environment="HTTP_PROXY=http://proxy:port/"
		Environment="HTTPS_PROXY=http://proxy:port/"
		Environment="NO_PROXY=localhost,127.0.0.1"
		EOF
		sudo systemctl daemon-reload
		sudo systemctl restart docker
		```
2. rpm Tools
	- rpmdevtools
		```sh
		sudo yum install -y rpmdevtools
		```
	- rpm-build
		```sh
		sudo yum install -y gcc gcc-c++ make automake autoconf rpm-build
		```
3. Get the required files  
	```sh
	git clone https://tccloud2.toshiba.co.jp/swc/gitlab/db/influxdb-cxx.git
	```

Creating influxdb-cxx rpm packages
=====================================
1. File used here
	- docker/influxdb-cxx.spec
	- docker/env_rpmbuild.conf
	- docker/Dockerfile_rpm
	- docker/create_rpm_binary.sh
2. Configure `docker/env_rpmbuild.conf` file
	- Configure proxy
		```sh
		proxy=http://username:password@proxy:port
		no_proxy=localhost,127.0.0.1
		```
	- Configure the registry location to publish the package and version of the packages
		```sh
		location=gitlab 					# Fill in <gitlab> or <github>. In this project, please use <gitlab>
		ACCESS_TOKEN=						# Fill in the Access Token for authentication purposes to publish rpm packages to Package Registry
		API_V4_URL=								# Fill in API v4 URL of this repo. In this project please use <https://tccloud2.toshiba.co.jp/swc/gitlab/api/v4>
		INFLUXDB_CXX_PROJECT_ID=			# Fill in the ID of the influxdb-cxx project.		
		RPM_DISTRIBUTION_TYPE="rhel8"		# Distribution version of RedHat that the PGSpider rpm packages supports.
		INFLUXDB_CXX_PACKAGE_VERSION=0.0.1	# Base version of influxdb-cxx package registry
		INFLUXDB_CXX_RELEASE_VERSION=0.0.1	# Version of influxdb-cxx rpm package
		```
3. Build execution
	```sh
	chmod +x docker/create_rpm_binary.sh
	./docker/create_rpm_binary.sh
	```
4. Confirmation after finishing executing the script
	- Terminal displays a success message. 
		```
		{"message":"201 Created"}
		...
		{"message":"201 Created"}
		```
	- rpm Packages are stored on the Package Registry of its repository
		```sh
		Menu TaskBar -> Deploy -> Package Registry
		```
Usage of Run CI/CD pipeline
=====================================
1. Go to Pipelines Screen
	```sh
	Menu TaskBar -> Build -> Pipelines
	```
2. Click `Run Pipeline` button  
![Alt text](images/BENZAITEN/pipeline_screen.PNG)
3. Choose `Branch` or `Tag` name
4. Provide `Access Token` through `Variabes`
	- Input variable key: ACCESS_TOKEN
	- Input variable value: Your access token
5. Click `Run Pipeline` button  
![Alt text](images/BENZAITEN/run_pipeline.PNG)