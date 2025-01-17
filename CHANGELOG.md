## 0.7.0 / 2022-12-06

* Support optional attribute range retrieval according to
  https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ldap/searching-using-range-retrieval
* Add an experimental yet incomplete request router as alternative to using OperationClass
* Add support for listening on UNIX domain sockets.
  Use `LDAP::Server.new(socket: '/tmp/server.sock')`
* Add LDAP::Server::DN to work with LDAP distinguished names
* Add CI on Github
* Use net-ldap for tests instead of unmaintained ruby-ldap.


## 0.5.3 / 2015-08-16
* Handle BN as client_timelimit; fixes incompatibility with some LDAP
implementations (notably Shibboleth IdP v2 and proftpd).
(Patch by Pete Birkinshaw.)


## 0.5.2 / 2015-06-24
* Make sure the exception used to stop the child doesn't propagate up (patch by Kasumi Hanazuki)


## 0.3.1 - 2008-01-16
* First release as a gem [Brandon Keepers]


## RELEASE_0_3

Filters now return nil instead of LDAP::Server::MatchingRule::DefaultMatch
in the case that there's no schema.
Minor changes to syntax.rb to support OpenLDAP extensions.

## 20050722

Change the 'validate' API so it works for updates too.
Change the 'modify' API so it sends a hash of attr=>[:op,data] which makes
it easier to determine which entries have been modified.
Fix modify, add and compare to normalise attribute names using the schema if
there is one.

## 20050721

Added a whole loada Schema stuff.
Moved exceptions under LDAP::ResultError for consistency with ruby-ldap.
Changed the parsed [filter] format to include a MatchingRule object always
(even if no schema is present)

## 20050711

Changed LDAPserver to LDAP::Server and rejigged the repository to match.
In your code you will have to change:
  require 'ldapserver/foo'  ->  require 'ldap/server/foo'
  LDAPserver::bar           ->  LDAP::Server::bar

I have added require 'ldap/server' which pulls in the things a basic server
will need (minus schema)

## 20050626

Factored out the SSL stuff into Connection, which should also allow the
STARTTLS extension to be implemented later

Added a Server class, with methods run_tcpserver and run_prefork.

Created an explicit preforkserver method.

## 20050625

tcpserver: add ability to drop privileges

examples/rbslapd3.rb: make work if ldapdb.yaml does not exist. Also bind
explicitly to 0.0.0.0; it seems that TCPSocket doesn't work properly in
some circumstances without it (FreeBSD 5.4 with IPv6 disabled in kernel)

## 20050620

RELEASE_0_2

Implemented SSL support in tcpserver, just by copying examples from
openssl module.

Tweak split_dn so that it should work properly with UTF-8 encoded strings

Added examples/rbslapd3.rb, a preforking LDAP server

Added :listen option to tcpserver to set listen queue size. With the default
of 5, and 100 children trying to connect, a few connections get dropped.

Added :nodelay option to tcpserver to set TCP_NODELAY socket option. This
removes 100ms of latency in responses.

Added examples/speedtest.rb

## 20050619

Modify connection.rb to ensure no memory leak in the event of exceptions
being raised in operation threads.

Fix examples/rbslapd2.rb SQLPool so that it always puts connections back
into the pool (using 'ensure' this time :-)

## 20050618

RELEASE_0_1

## 20050616
