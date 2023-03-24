Pre-requistets:
Instance or image booted (works with ubunutu 20.04)
Google cloud storage bucket available, ensure object versioning is enabled.
Service account with "Service account" and "Storage Object Admin" permissions.

The objective is to allow B2B SFTP capability, with as minimal moving parts as possible.
To achieve this I broke down the infrastructure as such:

#Bucket to pull data from, "mount" bucket to VM, VM to allow as a proxy SFTP server
#The SFTP servers purpose is to open an SSH tunnel to client-side, from there the client side will have access to their designated bucket.
#Ensure user account on VM is the one clients will be accessing is the one mounting the bucket, permission issues will arise if not done correctly.
#For optimal build size, it depends regarding the frequency of pulls and pushes through the server
#Ideally a small deployment is only needed given the process of transferring through the proxy server with the pseudo-mounted bucket does not need much in size.
#See minimum requirements for more details


#Install Gcsfuse to do so see below:
#1. Add the gcsfuse distribution URL as a package source and import its public key:

export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

#2. Update the list of packages available and install gcsfuse.

sudo apt-get update
sudo apt-get install gcsfuse

#Mounting, there are two ways to mount gcsfuse. If you only use one known bucket, you may use static mounting. If you want to mount all the accessible buckets, you may use dynamic mounting.

#Static Mounting. If you want to mount the GCS bucket called my-bucket. First create the directory into which you want to mount the gcsfuse bucket, then run gcsfuse:

mkdir /path/to/mount/point
gcsfuse "my-bucket" /path/to/mount/point


#Dynamic Mounting. If you do not specify a bucket name while mounting gcsfuse, it will dynamically mounts the buckets you access as subdirectories.

mkdir /path/to/mount/point
gcsfuse /path/to/mount/point

#When you access a subdirectory, such as

ls /path/to/mount/point/my-bucket/foo/

#you will have my-bucket dynamically mounted.

#It is illegal to list subdirectory at the root level in the dynamic mounted file system, such as

ls /path/to/mount/point/
# ls: reading directory '/path/to/mount/point': Input/output error

#You should run gcsfuse as the user who will be using the file system, not as root. Similarly, the directory should be owned by that user. Do not use sudo for either of the steps above or you will wind up with permissions issues.

#On Linux, unmount using fuse's fusermount tool:

fusermount -u /path/to/mount/point

#See debug tips in the event unmounting is necessary

#Internal note, you may grant sudo permissions to user temporarily to give gcsfuse bucket to itself. Ensure to remove sudo permission afterwards

#SFTP SETUP AND CONFIGURATION

#We are going to set up an SFTP server on Ubuntu20.04, using OpenSSH. By default, Ubuntu Desktop and lightweight Ubuntu server come without sshd. So, we’ll need to install the SSH server using the following steps.

#Update your system

$ sudo apt update
$ sudo apt upgrade

#Install OpenSSH using the following command:
$sudo apt-get install openssh-server

#Verify that the SSH service is operational (if not, enable and restart it)

$sudo systemctl status ssh
$sudo systemctl enable ssh
$sudo systemctl start ssh
or $sudo systemctl restart ssh

#Next we are to open the necessary ports, for a simplified approach to open these ports input the commands below
sudo ufw allow ssh
sudo ufw enable
sudo ufw status

#Should be displaying ports open for TCP both standard and v6.
#Once confirmed, key generation, key integration and connectivity via encrypted keys are next.

