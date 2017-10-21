### Steps for setting up jenkins

#### Install jre 8

```
sudo apt-get update
sudo apt-get install default-jre
sudo update-alternatives --config java    //  This will give all the java instances installed. If there are more than one instance installed, we need to select a particular one to proceed.
``` 

#### Install Jenkins

```
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -

sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

sudo apt-get update

sudo apt-get install jenkins
```