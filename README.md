# Job test

## Using

This test uses a docker environment to run inside. 

A simple script is provided with it to help handling docker: run.sh

To use it, open terminal on project root directory and type `./run.sh` to get a list of available commands.

To start the docker environment,
just do `./run.sh up` and wait. After it, you can:

* `./run.sh bash` - Bash into the container
* `./run.sh phpunit` - Run the PHPUnit test suite
* `./run.sh tinker` - Shortcut to `php artisan tinker` inside the container

That's the most relevant commands

## The test

This test is based on TDD (Test Driven Development). Inside the `src` folder you
have an empty Laravel application set-up to this test with:

* Database factories - will guide you about the models structure
* Integration tests
* Unit tests

The environment is setup with sqlite in memory driver.

To complete this test, you must run `./run.sh phpunit` and make all tests pass (green).

Please commit your changes to this repository.
