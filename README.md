# ruby-ldapserver

ruby-ldapserver is a lightweight, pure Ruby framework for implementing LDAP server applications. It is intended primarily for building a gateway from LDAP queries into some other protocol or database. It does not attempt to be a full or correct implementation of the standard LDAP data model itself (although you could build one using this as a frontend).

Since it's written entirely in Ruby, it benefits from Ruby's threading engine.

## Target audience

Technically-savvy Ruby applications developers; the sort of people who are happy to read RFCs and read code to work out what it does :-)

The examples/ directory contains a few minimal LDAP servers which you can use as a starting point.

## Status

This is still an early release. It works for me as an LDAP protocol layer; the Schema stuff has not been heavily tested.

## Request router

The request router is a simple mapping of potentially parameterized routes (DNs) and actions to a *controller* action, allowing for simple, flexible and maintainable code. Alternatively the legacy `Operation` class can be used. See the `examples/` directory for more details and sample implementations.

## Configuration

```ruby
params = {
  # Bind to address (cannot be combined with socket)
  bindaddr: '127.0.0.1', # defaults to 0.0.0.0
  port: 1389,

  # Bind to socket (cannot be combined with address)
  socket: '/tmp/ldap.sock',

  # Drop process and socket privileges to user and/or group (cannot be combined with uid/gid)
  user: 'ldap',
  group: 'ldap',

  # Drop process and socket privileges to UID and/or GID (cannot be combined with user/group)
  uid: 1000,
  gid: 1000,

  # TCP_NODELAY option
  nodelay: true,

  # Socket backlog
  listen: 10,

  # SSL/TLS
  ssl_key_file: 'key.pem',
  ssl_cert_file: 'cert.pem',
  ssl_on_connect: true,

  # Request router (cannot be combined with legacy operation)
  router: MyAppRouter,

  # Legacy Operation class (cannot be combined with request router)
  operation_class: MyAppOperation,
  operation_args: ['my', 'arguments'],

  # Schema
  schema: my_schema,
  namingContexts: ['dc=example,dc=com'],

  # Limit number of attribute values in query results
  # https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ldap/searching-using-range-retrieval
  attribute_range_limit: 1500,
}

serv = LDAP::Server.new(params)
serv.run_tcpserver
```

## Libraries

ASN1 encoding and decoding is done using the 'openssl' extension, which is standard in the Ruby 1.8.2 base distribution. To check you have it, you should be able to run `ruby -ropenssl -e puts` with no error.

However, I've found in the past that Linux machines don't always build the openssl extension when compiling Ruby from source. With Red Hat 9, the solution for me was, when building Ruby itself:

```
$ export CPPFLAGS="-I/usr/kerberos/include"
$ export LDFLAGS="-L/usr/kerberos/lib"
$ ./configure ...etc
```

If you want to run the test suite then you'll need to install the `ruby-ldap` client library, and if you want to run `examples/rbslapd3.rb` then you'll need the `prefork` library. Both are available from <http://raa.ruby-lang.org/>.

## Protocol implementation

ruby-ldapserver tries to be a reasonably complete implementation of the message decoding and encoding components of LDAP. However, it does not synthesise or directly enforce the LDAP data model. It will advertise a schema in the root DSE if you configure one, and it provides helper functions which allow you to validate add and modify operations against a schema; but it's up to you to use them, if you wish. If you're just using LDAP as a convenient query interface into some other database, you probably don't care about schemas.

If your clients permit it, you can violate the LDAP specification further, eliminating some of the gross design flaws of LDAP. For example, you can ditch the LDAP idea that a Distinguished Name must consist of attr=val,attr=val,attr=val... and use whatever is convenient as a primary key (e.g. "val1,val2,val3" or "id,table_name"). The 'add' operation could allocate DNs automatically from a sequence. There's no need for the data duplication where an LDAP entry must contain the same attr=val pair which is also the entry's RDN. Violations of the LDAP spec in this way are at your own risk.

## Threading issues

The core of this library is the `LDAP::Server::Connection` object which handles communication with a single client, and the `LDAP::Server::Operation` object which handles a single request. Because the LDAP protocol allows a client to send multiple overlapping requests down the same TCP connection, I start a new Ruby thread for each Operation.

If your Operation object deals with any global shared data, then it needs to do so in a thread-safe way. If this is new to you then see

[http://www.rubycentral.com/book/tut_threads.html](http://www.rubycentral.com/book/tut_threads.html)
[http://www.rubygarden.org/ruby?MultiThreading](http://www.rubygarden.org/ruby?MultiThreading)

For incoming client connections, I have supplied a simple tcpserver method which starts a new Ruby thread for each client. This works fine, but in a multi-CPU system, all LDAP server operations will be processed on one CPU; also with a very large number of concurrent client connections, you may find you hit the a max-filedescriptors-per-process limit.

I have also provided a preforking server; see `examples/rbslapd3.rb`. In this case, your connections are handled in separate processes so they cannot share data directly in RAM.

If you are using the default threading tcpserver, then beware that a number of Ruby extension libraries block the threading interpreter. In particular, the client library `ruby-ldap` blocks when waiting for a response from a remote server, since it's a wrapper around a C library which is unaware of Ruby's threading engine. This can cause your application to 'freeze' periodically. Either choose client libraries which play well with threading, or make sure each client is handled in a different process.

For example, when talking to a MySQL database, you might want to choose `ruby-mysql` (which is a pure Ruby implementation of the MySQL protocol) rather than `mysql-ruby` (which is a wrapper around the C API, and blocks while waiting for responses from the server)

Even with something like `ruby-mysql`, beware DNS lookups: resolver libraries can block too. There is a pure Ruby resolver replacement in the standard library: if you do

```
require 'resolv-replace'
```

This changes TCPSocket and friends to use it instead of the default C resolver. Or you could just hard-code IP addresses, or put entries in /etc/hosts for the machines you want to contact.

Another threading issue to think about is abandoned and timed-out LDAP operations. The `Connection` object handles these by raising an `LDAP::Server::Abandon` or `LDAP::Server::TimeLimitExceeded` exception in the `Operation` thread, which you can either ignore or rescue. However, if in rescuing it you end up putting (say) a SQL connection back into a pool, you should beware that the SQL connection may still be mid-query, so it's probably better to discard it and use a fresh one next time.

## Performance

`examples/speedtest.rb` is a simple client which forks N processes, and in each process opens an LDAP connection, binds, and sends M search requests down it.

Using speedtest.rb and rbslapd1.rb, running on the *same* machine (single-processor AMD Athlon 2500+) I achieve around 800 searches per second with N=1,M=1000 and 300-400 searches per second with N=10,M=100.

## To-do list

- handle and test generation of LDAP referrals properly
- more cases in test suite: abandon, concurrency, performance tests, error
  handling
- extensible match filters
- extended operations
  RFC 2830 - Start TLS
  RFC 3062 - password modify
  RFC 2839 - whoami
  RFC 3909 - cancel

## References

- [RFC2251](ftp://ftp.isi.edu/in-notes/rfc2251.txt) (base protocol)
- [RFC2252](ftp://ftp.isi.edu/in-notes/rfc2252.txt) (schema)
- [RFC2253](ftp://ftp.isi.edu/in-notes/rfc2253.txt) (DN encoding)
- [X.680](http://www.itu.int/ITU-T/studygroups/com17/languages/X.680-0207.pdf)
- [X.690](http://www.itu.int/ITU-T/studygroups/com10/languages/X.690_1297.pdf)

## Contact

You are very welcome to E-mail me with bug reports, patches, comments and suggestions for this software. However, please DON'T send me any general questions about LDAP, how LDAP works, how to apply LDAP in your particular situation, or questions about any other LDAP software. The [`ldap@umich.edu` mailing list](http://listserver.itd.umich.edu/cgi-bin/lyris.pl?enter=ldap) is probably the correct place to ask such questions.

Brian Candler <B.Candler@pobox.com>
