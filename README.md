# godel2-benchmark
Godel 2 benchmark script and example code.

To run, place your own compiled versions of the Godel and migoinfer executables, and run the script.
Runs on Linux, the timings are written in timings.csv at the end of each batch of marking.

Those examples can be used with the Docker-ready `Godel` and `migoinfer` tools as explained 
in the ReadMe file of the [Godel2 repository](https://github.com/JujuYuki/godel2).

Below is a brief description of each example in this repository along with the expected output.

## Description of the examples

### no-race

A simple program presenting no race, as nothing runs concurrently – calls to the 
`Writer` process miss the `go` keyword, so they are run as part of the `main` function 
instead of as separate threads.

### no-race-mut

A variation of the previous program, running the `Writer` calls in separate threads using 
the `go` keyword, and using `Mutex` locks to ensure exclusive access to `x` and `y` between 
the `Writer` instances and `main`.

### no-race-mut-bad

The same program as before, but missing the `Unlock` call at the end of the `Writer` function, 
resulting in a deadlock if this function acquires the lock on either `m1` or `m2` before `main` does.

### simple-race

A variation on the previous programs, with only one variable and one call to `Writer`, without `Mutex` 
lock, leading to a data race on shared variable `x`. As benign as this race is, it is one of the simplest 
examples one can imagine.

### simple-race-mut-fix

A variation on the previous program, with an added `Mutex` lock to make it safe. That makes it a simpler 
version of `no-race-mut`, and is present for good measure as a comparison against `simple-race`.

### deposit-race

A program inspired by the "bank deposit" example of the Go textbook, that may under bad scheduling drop 
completely the increase of 200 to the balance in the first parallel goroutine and print `Balance: 100`. 
This is what inspires the running example of our paper, working in the same spirit and having the same 
"bad" effect upon triggering the race.

### deposit-fix

An example of a possible fix to the previous program, where the lock is massed to the `Deposit` helper 
function and used to secure access to the shared `balance` variable.

### channel-race

A program that uses an asynchronous channel as a lock, but mistakenly puts the channel buffer size as 2 
which allows for the 2 senders supposed to protect the shared emmory accesses to happen together, 
instead of havin one of them wait for the receiver of the currently running access to unlock the channel. 

### channel-fix 

Fixes the previous program by putting the channel size to 1, making the send commands to correctly block 
until the channel is empty.

### channel-bad 

Shows how one could intend to use channels as locks, with correct buffer size, but mistakenly invert 
the receive and send actions, rendering the program inefficient as it would immediately deadlock — 
there is nothing to receive from an empty, open channel.

### prod-cons-race 

A naive implementation of a producers-consumer situation, where the producers each give out a limited 
amount of ressources, and the consumer takes all of them in the order they arrive and consumes them. 
In this case, the ressources are all placed in the same shared variable (and taken from it), but the 
`Producer` helper function does not use the `Mutex` lock to protect its writes. 
In turn, those writes can clash with those of other producers using the same variable, and even with 
the — correctly protected — read accesses of the `Consumer` helper function.

Note the use of channels here as signals for the `main` function to know when the `Producer` functions 
have reached the end of their production.

### prod-cons-fix

An example of a possible fix to the previous program, enclosing all accesses to `x` in the `Producer` 
helper function under the same lock of the shared `Mutex` lock.

### dine5-unsafe 

An implementation of the Dining Philosophers problem with only shared memory and locks. 
The dining philosopher's problem implies at least two participants and has them share the 
same number of forks as participants, each one trying to grab both forks on their left and 
right to eat, before releasing both for others to use.

This version has 5 participants, and uses the locks as forks,
but inadvertently inverts the `Lock` and `Unlock` calls 
for the first lock in the `phil` function, making the program immediately stop and error as 
it is an unsafe access. 

The integers shared by the `phil` routines and increased upon access to the forks are used to 
show how we can protect such shared accesses from each other to avoir a potential race, though 
in this wrong version of the program they do not manage to be used.

### dine5-deadlock 

A variation of the former program, correctly locking each lock before unlocking them — thus reverting 
the mistake of the previous example. However, in this version, because each philosopher tries to get 
a grip of the left fork first and right fork second, a bad scheduling can deadlock the program, as
each `phil` with id `i` would manage to grab fork `i+1` but fail to grab the other fork (already taken 
by an other `phil` instance).

### dine5-fix 

The known fix to the above lock, which is to invers the order of the forks for one of the `phil` routines. 
Here we invert forks 5 and 1 for the last `phil` call, making it be in concurrency for fork 1 with `phil` "0" 
to get it as the first fork, and leaving fork 5 free if it doesn't manage to get forl 1, 
so `phil` "3" can get it and finish its round. 

### dine5-chan-race 

A channel-based implementation of the Dining Philosophers problem with 5 participants, 
using synchronous channels as locks, where the `Fork` helper should manage the channel to lock access 
to it when in use by a `phil` routine. The problem here is the accesses to the shared `fork` variables 
at the same time for sending the value in `phil` and for setting it in `Fork`, 
creating potential races (even if benign).

> **This program uses select constructs with channels, which makes it long to analyse with our 
> framework as it creates a lot of branches to explore in the associated linear process specification 
> in mCRL2. _Do not run_ unless you have a powerful machine and are ready for it to 
> compute for several hours.**

### dine5-chan-fix

A fix for the previous program, consisting in simply inverting all the channel send and receives, 
making sure the `phil` routines do not try to read the shared `fork` at the same time as the `Fork` 
routines set them.

> **This program uses select constructs with channels, which makes it long to analyse with our 
> framework as it creates a lot of branches to explore in the associated linear process specification 
> in mCRL2. _Do not run_ unless you have a powerful machine and are ready for it to 
> compute for several hours.**
