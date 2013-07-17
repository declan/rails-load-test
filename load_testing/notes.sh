#! /bin/sh

# get production log
ssh deploy@purplebinder.com "cat /u/apps/purplebinder/current/log/production.log | gzip" | gunzip > production.log # some timestamp?

# filter everything but the requests
cat production.log | grep 'POST\|GET\|PUT\|DELETE\|Parameters:' > requests.log
