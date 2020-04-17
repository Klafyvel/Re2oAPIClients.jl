# Re2oAPIClient

[![Build Status](https://travis-ci.com/klafyvel/Re2oAPIClient.jl.svg?branch=master)](https://travis-ci.com/klafyvel/Re2oAPIClient.jl)
[![Codecov](https://codecov.io/gh/klafyvel/Re2oAPIClient.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/klafyvel/Re2oAPIClient.jl)

This is a Julia client for [Re2o](https://github.com/re2o/re2o). It is strongly inspired by @MoaMoaK's work [here](https://gitlab.federez.net/re2o/re2oapi).

## Features

Connect :

```julia
client = Re2oAPIClient("url", "username", "password", use_tls=false)
```

A token will be fetched on Re2o. It is stored by default in `~/.re2otoken`.

List endpoint :

```julia
list(client, endpoint)
```

Other features will be added later.