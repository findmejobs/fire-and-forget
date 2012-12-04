Fire and Forget
===============

A simple daemon for storing generic actions and storing them in
MongoDB tables. It uses UDP so that the application sending the
data has very little overhead. It can literally toss actions
into the wind and this daemon will try it's best to pick them up
and store them for later retrieval.

Reasoning
---------

We needed a way to store user interactions on our website, tied
to particular users. While statsd is great for metrics and anonymous
data, it didn't help us for this more targeted data. This little app
copies the idea, while making it domain specific.

How it Works
------------

Send a JSON message to the open UDP socket that Fire and Forget opens.
The message should have the following format:

    {
      objectType: 'modelName',
      objectId: 1,
      objectDetails: { nestedJSON },
      action: 'thing',
      actionDetails: { nestedJSON }
    }
    
The objectType will have 'fnf-' prepended to it and used as the
collection name. All of the other fields will be inserted as a new
record into that collection as given.

Passphrases
-----------

Optionally, you can require a passphrase for every action that's sent
to the daemon. This passphrase can be set in the server (via the -k
command line option), and also must be added to the "passphrase" key
of every JSON action sent.

Installation
------------

 * Install node.js
 * npm install
 * Start the daemon

    node fire-and-forget

Help
----

Use `fire-and-forget --help` to see the various options.