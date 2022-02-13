## Quick ts-node deployment template

TLDR:
1. Zips up files needed to run
2. Setups environment on remote machine and pushes zipped stuff via scp
3. Setups project, installs deps and systemd service on autorestart
4. Maps ports 3000 as 443 and 3001 as 80 using iptables (clears iptables each push)

Idea behind this repo is that you want to create a small app/bot/worker
so you are renting a vps-ish instance like AWS ec2
and this repo is just quick and dirty way to kickoff project.

I want to extract parts of this project into more general
setup - like running stuff like rust or python, you can actually
modify the deploy.sh to install stuff needed for your specific
environment.

## Setup

1. Clone repo and break origin link OR use `Use as template` functionality provided by github
2. Copy `secret.env.template` as `secret.env` - `secret.env` is gitignored
3. Change `secret.env` content, for more info you can check "secret.env vars breakdown" paragraph

> Keep in mind that private key should have `700` file perms

4. Check `deploy.sh` content, there are security risks (like not checking fingerprints) to make deployment process input-less
5. Make sure you have zip command installed - more info in `deploy.sh` (TODO: move it to readme)

## secret.env vars breakdown

// TODO
