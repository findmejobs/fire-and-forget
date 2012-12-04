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

Installation
------------

 * Install node.js
 * `npm install`
 * Start the daemon

    node fire-and-forget
