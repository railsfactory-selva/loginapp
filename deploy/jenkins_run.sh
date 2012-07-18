#!/bin/bash
profile=$1
passwd=$2
PASSWORD=proddeploy

export GIT_REVISION
echo GIT_REVISION=$GIT_REVISION
echo "Profile: $profile"

if [ "$profile" = "r2-san1-perf" ]
then
  environ="perf_san1"
elif [ "$profile" = "r2-san1-test" ]
then
  environ="test_san1"
elif [ "$profile" = "r2-san1-prod" ]
then
  environ="prod_san1"
  if [ -n "$passwd" ]
  then
      if [ "$passwd" != "$PASSWORD" ]
         then
            echo "Password incorrect"
            exit -1
      fi        
  else
     echo "no password, can not deploy prod"
     exit -1
  fi 
elif [ "$profile" = "r2-ewr1-prod" ]
then
  environ="blackflag-prod_ewr1"
  if [ -n "$passwd" ]
  then
      if [ "$passwd" != "$PASSWORD" ]
         then
            echo "Password incorrect"
            exit -1
      fi        
  else
     echo "no password, can not deploy prod"
     exit -1
  fi   
elif [ "$profile" = "r2-san1-uat" ]
then 
  environ="uat_san1"
elif [ "$profile" = "r2-san1-dev" ]
then
  environ="dev_san1"
elif [ "$profile" = "r2-san1-dev-perf" ]
then
  environ="dev-perf_san1"
elif [ "$profile" = "r2-san2-dev" ]
then
  environ="blackflag-dev_san2"
elif [ "$profile" = "r2-san2-dev-test" ]
then
  environ="blackflag-dev-test_san2"
elif [ "$profile" = "r2-san2-test" ]
then
  environ="blackflag-test_san2"
elif [ "$profile" = "r2-san2-perf" ]
then
  environ="blackflag-perf_san2"
elif [ "$profile" = "r2-san2-uat" ]
then
  environ="blackflag-uat_san2"
elif [ "$profile" = "apifoundry-dev" ]
then
  environ="apifoundry-dev"
elif [ "$profile" = "r2-ewr1-dev" ]
then
  environ="blackflag-dev_ewr1"
elif [ "$profile" = "r2-ewr1-dev-test" ]
then
  environ="blackflag-dev-test_ewr1"
else
  environ=$profile
fi
echo "environ:$environ"

echo "Environment: $environ"
# This is a hack right now, because vlad has an issue with deployting to multiple nodes, so we got to do
# each individually
# get the ips from the deploy.rb file for the profile
if [ -z $environ ]
then
   echo "Environ not set!"
   exit -1
fi

# This is a hack right now, because vlad has an issue with deployting to multiple nodes, so we got to do
# each individually
# get the ips from the deploy.rb file for the profile
if grep -q ":$environ" deploy.rb
then
   s=":$environ"
   elif grep -q ":'$environ'" deploy.rb
then
   s=":'$environ'"
fi
ips=`grep  -A 1 "$s" deploy.rb  | grep "domain"  | grep -Eo '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}'`

#get the user from the deploy.rb file
user=`cat deploy.rb | grep ":app_user" | awk -F "," '{ print $2 }' | sed "s/\"//g" | sed 's/ //g'`

for ip in $ips
do
  echo "Deploying: $environ to ip: $ip"
  echo "HOSTS=$user@$ip rake $environ vlad:deploy || exit 1"
  HOSTS=$user@$ip rake $environ vlad:deploy --trace || exit 1
done
