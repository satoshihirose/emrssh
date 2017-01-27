# emrssh
emrssh was inspired by  [ec2ssh](https://github.com/sumikawa/ec2ssh)

## How to install

- install percol, inifile and AWS SDK for Ruby v2

```
pip install percol
gem install inifile aws-sdk
```

- copy files to somewhere in exec path
 
```
git clone git@github.com:satoshihirose/emrssh.git
cd emrssh
cp emrssh get_clusters.rb /usr/local/bin/
```

## Usage

- add your private key file to ssh-agent

```
ssh-add ~/.ssh/<YOUR_PRIVATE_KEY>.pem
```

- run emrssh and select an instance you want to log in to

```
emrssh
```
