# godel2-benchmark
Godel 2 benchmark script and example code.

## How to run

### Running the examples for testing

To run the artifact test for the companion paper, install the Docker image (see the main 
[Godel2 repository](https://github.com/JujuYuki/godel2)), and run the `run.sh` script. 
the script will run the main examples, and ask you whether to continue before running the 
5-participant dining philosophers with channels example (those take hours to complete).

The expected execution time before that prompt is under 20 minutes.

Alternatively, you can run the examples individually with the Docker-ready versions of 
`migoinfer` and `Godel` as explained in the main [Godel2 repository](https://github.com/JujuYuki/godel2), 
or with your own compiled versions of the programs.

### Running the benchmark for timings

To run **the benchmark for timings**, place your own compiled versions of the Godel and migoinfer executables in the 
working directory, and run the `benchmark.sh` script.
Runs on Linux, the timings are written in timings.csv at the end of each batch of marking.
This could take hours (because of the two dine5-chan-\* examples), and is not intended to be used for artifact testing.

Below is a brief description of each example in this repository along with the expected output.

## Output Propositions:

* Finite control: expected to be true for all our examples here. This means the program does not
  spawn an unbounded number of threads with nested calls using the `go` keyword. A program which 
  is not finite control will not be analysed for other properties, as mCRL2 is unable to generate 
  a linear process specification for those.
* No terminal state: is true when the program has no terminal state, meaning it would run 
  continuously if given no time constraints (e.g. in the Dining Philosophers examples, remove the 
  `Sleep` line and make the final function call synchronous by removing its `go` keyword).
* No cycle: is true if the program doesn't present an infinite cycle.
* No global deadlock: is true if the program doesn't reach a global deadlock during normal 
  execution. The final state, if it exists, does not count as a global deadlock.
* Liveness: is true if the program is "live" according to the definition of liveness in our paper,
  which includes both eventual synchronisation over channels and eventual locking of 
  `Mutex` locks.
* Safety: is true if the program is "safe" according to the definition of safety in our paper,
  which includes not trying to send a message on a closed channel, and not trying to `Unlock` — resp. 
  `RUnlock` — a `Mutex` — resp `RWmutex` — that is not already locked via a `Lock` — resp `RLock` — 
  call.
* Data race free: is true if the program does not present a data race over a shared variable. 
  This is another form of safety, but we separate it from the former one as it does not cause a Go 
  program to halt with an error, unlike the previous two forms of safety analysed by the "Safety" property.
* Eventual reception: is true if messages in a buffered channel are eventually received, without dropping 
  messages at the end of the program. We do not 
  present examples in which it is false here, and expect it to be always true. This includes channels that 
  are closed before being emptied, as we can still receive the previously queued messages before 
  starting to receive the default value on a closed asynchronous channel.

## Description of the examples

### no-race

A simple program presenting no race, as nothing runs concurrently – calls to the 
`Writer` process miss the `go` keyword, so they are run as part of the `main` function 
instead of as separate threads.

| No Terminal State | No Cycle | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:--------:|:------------------:|:--------:|:------:|:--------------:|
| **False**         | True     | True               | True     | True   | True           |

### no-race-mutex

A variation of the previous program, running the `Writer` calls in separate threads using 
the `go` keyword, and using `Mutex` locks to ensure exclusive access to `x` and `y` between 
the `Writer` instances and `main`.

| No Terminal State | No Cycle | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:--------:|:------------------:|:--------:|:------:|:--------------:|
| **False**         | True     | True               | True     | True   | True           |

### no-race-mut-bad

The same program as before, but missing the `Unlock` call at the end of the `Writer` function, 
resulting in a deadlock if this function acquires the lock on either `m1` or `m2` before `main` does.

| No Terminal State | No Cycle | No Global Deadlock | Liveness  | Safety | Data Race Free | 
|:-----------------:|:--------:|:------------------:|:---------:|:------:|:--------------:|
| **False**         | True     | **False**          | **False** | True   | True           |

### simple-race

A variation on the previous programs, with only one variable and one call to `Writer`, without `Mutex` 
lock, leading to a data race on shared variable `x`. As benign as this race is, it is one of the simplest 
examples one can imagine.

| No Terminal State | No Cycle | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:--------:|:------------------:|:--------:|:------:|:--------------:|
| **False**         | True     | True               | True     | True   | **False**      |

### simple-race-fix

A variation on the previous program, with an added `Mutex` lock to make it safe. That makes it a simpler 
version of `no-race-mut`, and is present for good measure as a comparison against `simple-race`.

| No Terminal State | No Cycle | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:--------:|:------------------:|:--------:|:------:|:--------------:|
| **False**         | True     | True               | True     | True   | True           |

### deposit-race

A program inspired by the "bank deposit" example of the Go textbook, that may under bad scheduling drop 
completely the increase of 200 to the balance in the first parallel goroutine and print `Balance: 100`. 
This is what inspires the running example of our paper, working in the same spirit and having the same 
"bad" effect upon triggering the race.

| No Terminal State | No Cycle | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:--------:|:------------------:|:--------:|:------:|:--------------:|
| **False**         | True     | True               | True     | True   | **False**      |

### deposit-fix

An example of a possible fix to the previous program, where the lock is massed to the `Deposit` helper 
function and used to secure access to the shared `balance` variable.

| No Terminal State | No Cycle | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:--------:|:------------------:|:--------:|:------:|:--------------:|
| **False**         | True     | True               | True     | True   | True           |

### ch-as-lock-race

A program that uses an asynchronous channel as a lock, but mistakenly puts the channel buffer size as 2 
which allows for the 2 senders supposed to protect the shared memory accesses to happen together, 
instead of having one of them wait for the receiver of the currently running access to unlock the channel. 

| No Terminal State | No Cycle | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:--------:|:------------------:|:--------:|:------:|:--------------:|
| **False**         | True     | True               | True     | True   | **False**      |

### ch-as-lock-fix 

Fixes the previous program by putting the channel size to 1, making the send commands to correctly block 
until the channel is empty.

| No Terminal State | No Cycle | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:--------:|:------------------:|:--------:|:------:|:--------------:|
| **False**         | True     | True               | True     | True   | True           |

### ch-as-lock-bad 

Shows how one could intend to use channels as locks, with correct buffer size, but mistakenly inverts 
the receive and send actions, rendering the program inefficient as it would immediately deadlock — 
there is nothing to receive from an empty, open channel.

| No Terminal State | No Cycle | No Global Deadlock | Liveness  | Safety | Data Race Free | 
|:-----------------:|:--------:|:------------------:|:---------:|:------:|:--------------:|
| **False**         | True     | **False**          | **False** | True   | True           |

### prod-cons-race 

A naive implementation of a producers-consumer situation, where the producers each give out a limited 
amount of resources, and the consumer takes all of them in the order they arrive and consumes them. 
In this case, the resources are all placed in the same shared variable (and taken from it), but the 
`Producer` helper function does not use the `Mutex` lock to protect its writes. 
In turn, those writes can clash with those of other producers using the same variable, and even with 
the — correctly protected — read accesses of the `Consumer` helper function.

Note the use of channels here as signals for the `main` function to know when the `Producer` functions 
have reached the end of their production.

| No Terminal State | No Cycle  | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:---------:|:------------------:|:--------:|:------:|:--------------:|
| True              | **False** | True               | True     | True   | **False**      |

### prod-cons-fix

An example of a possible fix to the previous program, enclosing all accesses to `x` in the `Producer` 
helper function under the same lock of the shared `Mutex` lock.

| No Terminal State | No Cycle  | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:---------:|:------------------:|:--------:|:------:|:--------------:|
| True              | **False** | True               | True     | True   | True           |

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
show how we can protect such shared accesses from each other to avoid a potential race, though 
in this wrong version of the program they do not manage to be used.

| No Terminal State | No Cycle | No Global Deadlock | Liveness | Safety    | Data Race Free | 
|:-----------------:|:--------:|:------------------:|:--------:|:---------:|:--------------:|
| **False**         | True     | **False**          | True     | **False** | True           |

### dine5-deadlock 

A variation of the former program, correctly locking each lock before unlocking them — thus reverting 
the mistake of the previous example. However, in this version, because each philosopher tries to get 
a grip of the left fork first and right fork second, a bad scheduling can deadlock the program, as
each `phil` with id `i` would manage to grab fork `i+1` but fail to grab the other fork (already taken 
by an other `phil` instance).

| No Terminal State | No Cycle  | No Global Deadlock | Liveness  | Safety | Data Race Free | 
|:-----------------:|:---------:|:------------------:|:---------:|:------:|:--------------:|
| **False**         | **False** | **False**          | **False** | True   | True           |

### dine5-fix 

The known fix to the above lock, which is to invert the order of the forks for one of the `phil` routines. 
Here we invert forks 5 and 1 for the last `phil` call, making it be in concurrency for fork 1 with `phil` "0" 
to get it as the first fork, and leaving fork 5 free if it doesn't manage to get fork 1, 
so `phil` "3" can get it and finish its round. 

| No Terminal State | No Cycle  | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:---------:|:------------------:|:--------:|:------:|:--------------:|
| True              | **False** | True               | True     | True   | True           |

### dineN-chan-race 

A channel-based implementation of the Dining Philosophers problem with N=3 or 5 participants, 
using synchronous channels as locks, where the `Fork` helper should manage the channel to lock access 
to it when in use by a `phil` routine. The problem here is the accesses to the shared `fork` variables 
at the same time for sending the value in `phil` and for setting it in `Fork`, 
creating potential races (even if benign).

> **This program uses select constructs with channels. This makes the version with
> 5 participants long to analyse with our 
> framework as it creates a lot of branches to explore in the associated linear process specification 
> in mCRL2. _Do not run_ the 5-participant version unless you have a powerful machine and are ready for it to 
> compute for several hours.**
> The 3-participant version is a downscaled version added for convenience. 
> It should run within a few minutes at most, and is given for reference as a way 
> to test the protocol on less powerful machines within reasonable time.

| No Terminal State | No Cycle  | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:---------:|:------------------:|:--------:|:------:|:--------------:|
| True              | **False** | True               | True     | True   | **False**      |

### dineN-chan-fix

A fix for the previous program, consisting in simply inverting all the channel send and receives, 
making sure the `phil` routines do not try to read the shared `fork` at the same time as the `Fork` 
routines set them.

> **This program uses select constructs with channels. This makes the version with
> 5 participants long to analyse with our 
> framework as it creates a lot of branches to explore in the associated linear process specification 
> in mCRL2. _Do not run_ the 5-participant version unless you have a powerful machine and are ready for it to 
> compute for several hours.**
> The 3-participant version is a downscaled version added for convenience. 
> It should run within a few minutes at most, and is given for reference as a way 
> to test the protocol on less powerful machines within reasonable time.

| No Terminal State | No Cycle  | No Global Deadlock | Liveness | Safety | Data Race Free | 
|:-----------------:|:---------:|:------------------:|:--------:|:------:|:--------------:|
| True              | **False** | True               | True     | True   | True           |

### loop

A simple loop example added to the request of a reviewer, it puts actions after the loops to handle an edge case of the cleanup process 
that is done as part of `migoinfer`'s inference process. This is mainly to show what happens when there's a (non-trivial) loop when 
checking for termination (`Godel -T <cgo file>`).
