piface
===========

piface is an erlang application for controlling a Piface board (a Raspberry Pi io extension).

### Dependencies

To build piface you will need a working installation of Erlang R15B (or
later).<br/>
Information on building and installing [Erlang/OTP](http://www.erlang.org)
can be found [here](https://github.com/erlang/otp/wiki/Installation)
([more info](https://github.com/erlang/otp/blob/master/INSTALL.md)).

piface is built using rebar that can be found [here](https://github.com/basho/rebar), with building instructions [here](https://github.com/basho/rebar/wiki/Building-rebar).

piface also requires the following applications to be installed:
<ul>
<li>spi - https://github.com/tonyrog/spi</li>
<li>gpio - https://github.com/Feuerlabs/gpio</li>
</ul>

### Downloading

Clone the repository in a suitable location:

```
$ git clone git://github.com/tonyrog/piface.git
```
### Run

piface is started in a standard erlang fashion:

```
$ erl
(node@host) 1> application:start(piface).
```

### API

The following interface functions exist:
<ul>
<li>init_interrupt</li>
<li>gpio_get</li>
<li>gpio_set</li>
<li>gpio_clr</li>
<li>read_input</li>
<li>read_output</li>
<li>write_output</li>
</ul>

For details see the source code documentation.

### Documentation

piface is documented using edoc. To generate the documentation do:

```sh
$ cd piface
$ rebar doc
```
The result is a collection of html-documents under ```piface/doc```.
