# cozy-host
Personal host setup and configuration "stuff"

## Bootstrapped setup
If not logged in under a preferred username, this prompts to create your (sudo) user, and switches to that account. A shallow clone of this repository is created in the home directory (git is installed if not available), immediatly starting the actual setup afterwards.
```
bash <(wget -O - 'https://raw.githubusercontent.com/folfy/cozy-host/master/bootstrap.sh')
```
Alternative shorthand: `bash <(wget -O - bit.ly/folfhost)`

## Manual setup
Clone this repository and run `setup.sh`.
