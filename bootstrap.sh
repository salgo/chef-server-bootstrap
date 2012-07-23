#!/bin/sh 

export TERM=xterm

COOKBOOKS_PATH="/root/cookbooks"

txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgrn=${txtbld}$(tput setaf 2) #  green
bldylw=${txtbld}$(tput setaf 3) #  yellow
bldblu=${txtbld}$(tput setaf 4) #  blue
bldpur=${txtbld}$(tput setaf 5) #  purple
bldcyn=${txtbld}$(tput setaf 5) #  cyan 
bldwht=${txtbld}$(tput setaf 7) #  white
txtrst=$(tput sgr0)             # Reset
info=${bldwht}*${txtrst}        # Feedback
pass=${bldblu}*${txtrst}
warn=${bldred}*${txtrst}
ques=${bldblu}?${txtrst}

set -e

echo
echo "${txtbld}Chef Server bootstrap for Debian Squeeze${txtrst}"
echo "- By Andy Gale <andy@salgo.net>"
echo

echo "${bldblu}Installing Ruby and dependencies${txtrst}"
echo

apt-get -y update 
apt-get -y install ruby ruby-dev libopenssl-ruby rdoc ri irb build-essential wget ssl-cert curl lsb-release libshadow-ruby1.8

echo
echo "${bldred}Installing RubyGems${txtrst}"
echo

cd /tmp
curl -O http://production.cf.rubygems.org/rubygems/rubygems-1.8.10.tgz
tar zxf rubygems-1.8.10.tgz
cd rubygems-1.8.10
sudo ruby setup.rb --no-format-executable

echo
echo "${bldgrn}Installing Chef${txtrst}"
echo

sudo gem install chef --no-ri --no-rdoc

echo
echo "${bldpur}Chef server setup${txtrst}"
echo

mkdir -p /etc/chef
mkdir -p /tmp/chef-solo

(cat << _EOF_
file_cache_path "/tmp/chef-solo"
cookbook_path "/root/cookbooks"
_EOF_
) > /etc/chef/solo.rb 

(cat << _EOF_
{
  "chef_server": {
    "server_url": "http://localhost:4000",
    "webui_enabled": true,
    "init_style": "runit"
  },
  "run_list": [ "recipe[apt::default]", "recipe[rabbitmq::default]", "recipe[chef-server::rubygems-install]" ]
}
_EOF_
) > ~/chef.json

echo "${bldblu}Fetching cookbook dependencies${txtrst}"
echo

mkdir -p $COOKBOOKS_PATH

REQUIRED_COOKBOOKS="apache2 bluepill chef chef-server daemontools gecode nginx rabbitmq ucspi-tcp yum apt build-essential chef-client couchdb erlang java openssl runit xml zlib"

for cookbook in $REQUIRED_COOKBOOKS; do
    file="${COOKBOOKS_PATH}/${cookbook}"

    if [[ ! -e $file ]]; then
        wget http://github.com/opscode-cookbooks/$cookbook/tarball/master --output-document=${file}.tgz
        mkdir -p $file
        cd $file
        tar --strip-components=1 -zxf ${file}.tgz
	rm ${file}.tgz
        cd -
    fi
done

echo
echo "${bldgrn}Installing chef-server with chef-solo ${txtrst}"
echo

chef-solo -c /etc/chef/solo.rb -j ~/chef.json 

echo
echo "${bldcyn}Done.${txtrst}"

