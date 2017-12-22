## Description

This proof of concept describes a novel method to eliminate [correlation attacks on anonymity networks such as Tor](https://svn.torproject.org/svn/projects/design-paper/tor-design.html#tth_sEc3.1) and I2P.

It uses asymmetric crypto to enforce dummy traffic, rendering a passive global attacker unable to do correlation attacks on low-latency anonymity networks. It's not intended for actual usage due to various issues related to reliability and performance.

But since - as far as I know - it's a novel way of using crypto I'm publishing it in case someone has a use for it.

## Design

Low latency anonymity networks such as Tor and I2P are known to be vulnerable to traffic analysis attacks. A global passive attacker (anyone monitoring a large enough portion of all traffic) can use correlation to determine the source of a given stream of traffic.

This can be resolved by sending enough dummy traffic across the network. If only Alice and Bob know whether a given message is genuine or fake after decrypting the message, a passive attacker cannot know when genuine messages are sent. **If Alice and Bob and every other node in the network cannot decrypt a message until they have received a message from every other node in the network**, correlation attacks are impossible.

My approach does not defend against malicious nodes, for that you would need to implement an onion routing network on top of this.

The network operates in pulses of every node sending every other node a message. A given node cannot decrypt any message in a pulse before receiving a message from every other node. There are obvious scalability and reliability problems with this design, see further below for details and possible mitigation.

As with most things in life, the behavior I described can be enforced with public-key cryptography. For each pulse, every node generates a key pair. Each node then sends the public key to every other node. Once all the public keys are received, all nodes send each other a message (genuine or fake) that is encrypted with all of the public keys. Along with the message they also send the **private** key of the key pair they generated for that pulse.

Since every message is encrypted with every public-key, nothing can be decrypted until all the accompanying private keys are received. Assuming both fake and genuine messages are all enforced to be the same length, and an additional layer of crypto is used on top of this, correlation attacks should be prevented.

To speed things up the two steps are joined: the public key for the next pulse is included with the current message. Here is a sample flow with two nodes:

- directory server spins up
- node1 spins up, registers with directory server
- node1 is informed by directory server that there are no existing nodes
- node1 generates a key-pair for the first pulse and stores it while awaiting node2
- node2 spins up, registers with directory server
- node2 is informed by directory server that node1 exists, and what ip+port node1 can be found at
- node2 generates a key-pair for the first pulse
- node2 registers with node1 and sends its public-key for the first pulse
- node1 sends node2 a message encrypted with the pulse key-pair, along with the public-key for the second pulse
- node2 now has a public key for the next pulse and sends node1 a message along with the public key for the third pulse

## Issues with reliability and performance

### Performance and scalability

The network is only as fast as the slowest node, and the amount of bandwidth required per node increases with every node added to the network. These properties are inherent in the network design. They can be mitigated somewhat by setting up multiple networks within the network. Let's call these networks clusters.

The advantage of using clusters of nodes within the network is that the message length can be optimized for different use-cases. Nodes could also be grouped together based on their bandwidth and reliability properties. 

The disadvantage is that the identity of a given node can be narrowed down to the list of nodes in the cluster they participate in, not the entire network.

### Reliability

If one node goes down, the entire network goes down. This is by design, to prevent an attacker from discovering the identity of the source by waiting until it goes down temporarily. There should be a time-out at which point the network recovers without the unreliable node. This time-out should be large enough that an attacker cannot simply compromise anonymity by DoSing one node at a time.

It would be trivial to keep the network down by repeatedly joining the network and not sending any messages. This can be mitigated somewhat with reputation management. The cost of the attack can also be increased slightly, by requiring new nodes to successfully participate in the network for some amount of time before actually using their pulse key-pairs.

## Disclaimers

This design favors anonymity over reliability and performance so much it's impractical for actual usage. As such I am only publishing this as a curiosity, a possible inspiration. I'm not a cryptographer, so take this type of design with a rather large grain of salt until someone qualified has taken a look at it.

The code in this repository is a Proof of Concept and nothing more. It uses JSON over HTTP rather than an efficient binary protocol. It doesn't know how to deal with nodes joining later on, the directory server is extremely naive, and the network can't recover from any problems. 

## Instructions 

The test script spins up a directory server and three nodes. They send pulses until the test script forces one of the nodes to stop responding, at which point the logs will show that all traffic stops. 

```
bundle install
bundle exec ruby test.rb
```
